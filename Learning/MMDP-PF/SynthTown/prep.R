library(data.table)

events = readRDS('10_events_1_5.RDS')
network = readRDS('network.RDS')
e=network$e
n=network$n
activity.end = events$activity.end
activity.start = events$activity.start
link.enter = events$link.enter
link.leave = events$link.leave
events = list(activity.end = activity.end, link.leave = link.leave, link.enter = link.enter, activity.start = activity.start)

# events
events = list(activity.end = activity.end, link.leave = link.leave, link.enter = link.enter, activity.start = activity.start)
invisible(lapply(1:length(events), function(n) if(!is.infinite(events[[n]]$time[nrow(events[[n]])])){
  events[[n]] <<- events[[n]][order(events[[n]]$time),]
  events[[n]] <<- rbind(events[[n]], tail(events[[n]],1))
  events[[n]]$time[nrow(events[[n]])] <<- Inf
}))
ndx = integer(length=length(events))
ndx[] = 1

# has problem, 4 person != 3 person, fixed
unique_person = c(1:2000)
unique_lane = c('h','w',rownames(network$e))

#construct person.state.d
if (TRUE) {
  #compute person.state.d
  types = levels(events[[4]]$type)
  min.time = min(sapply(1:length(events),function(n) min(events[[n]]$time[!is.infinite(events[[n]]$time)])))
  max.time = min(min.time+24*3600,max(sapply(1:length(events),function(n) max(events[[n]]$time[!is.infinite(events[[n]]$time)]))))
  delta.t = 60
  td = seq(from=min.time, to=max.time+delta.t-1, by=delta.t)
  
  #compute person.state.d, initial home? find person road
  person.state.d = matrix(0,nrow = length(td), ncol = length(unique(activity.end$person)))
  person.state.d[1,] = types[1]
  ndx = integer(length=length(events))
  ndx[] = 1
  ctime = min.time
  last = 1
  
  while(any(ndx<sapply(events, nrow))){
    ctime = min(sapply(1:length(events),function(n) events[[n]]$time[ndx[n]] ))
    if(ctime > max.time)
      break
    ndx0 = which(td>=ctime)[1]
    if (ndx0 > last) {
      print(ndx0)
      for(i in c((last+1):ndx0)) {
        person.state.d[i,] = person.state.d[last,]
      }
    }
    # update site state according to events
    switch(which.min(sapply(1:length(events),function(n)events[[n]]$time[ndx[n]] )),
           {# activity end
             #person.state[ndx0, events[[1]]$person[ndx[1]] ] =  events[[1]]$link[ndx[1]]
             ndx[1]=ndx[1]+1
           },
           {# link.leave
             ndx[2]=ndx[2]+1
           },
           {# link.enter
             person.state.d[ndx0, events[[3]]$person[ndx[3]] ] =  events[[3]]$link[ndx[3]] 
             ndx[3]=ndx[3]+1
           },
           {# activity.start
             person.state.d[ndx0, events[[4]]$person[ndx[4]] ] =  as.character(events[[4]]$type[ndx[4]])
             ndx[4]=ndx[4]+1
           })
    #person.state.d[ndx0+1,] = person.state.d[ndx0,]
    last = ndx0
  }
  person.state.d = matrix(as.numeric(factor(person.state.d, levels=c('h','w',rownames(e)))), nrow=nrow(person.state.d))
  save(person.state.d,file = "data_prep/person.state.d.RData") 
}

# m and m.time, get rid of c
# table(factor(person.state.d,levels=1:25))
m = table(factor(head(person.state.d,-1),levels=1:25), factor(tail(person.state.d,-1),levels=1:25))
m = sweep(m, 1, STATS=rowSums(m), FUN='/')
rownames(m) = colnames(m) = c('h','w',rownames(e))
image(z=asinh(t(m)*1000),x=1:ncol(m), y=1:nrow(m),ylim=c(nrow(m)+.5,.5),xlab='to', ylab='from', xaxt='n', yaxt='n',asp=1)
axis(side=1, at=1:ncol(m), labels=colnames(m), las=2)
axis(side=2, at=1:nrow(m), labels=rownames(m), las=2)

m.time = table(factor(head(person.state.d,-1),levels=1:25), factor(tail(person.state.d,-1),levels=1:25),cut(td[row(head(person.state.d,-1))]/3600,breaks = 0:24))
m.time = sweep(m.time*.9999, MARGIN = 1:2, STATS = table(factor(head(person.state.d,-1),levels=1:25), factor(tail(person.state.d,-1),levels=1:25))*.0001, FUN = '+')
m.time = sweep(m.time, MARGIN = c(1,3), STATS = colSums(aperm(m.time,perm = c(2,1,3)),dims = 1),FUN = '/')
dimnames(m.time)[[1]] = dimnames(m.time)[[2]] = c('h','w',rownames(e))

Xt_real = t(apply(person.state.d,1,function(x) table(factor(x, levels=1:(nrow(e)+2)))))

#generate Yt
if (FALSE) {
  numbers = 2000
  scale = 10
  probe.person = sample.int(ncol(person.state.d),trunc(ncol(person.state.d)/scale))
  save(probe.person,file='data_prep/probe.person.fan.10.RData')
  Yt = array(0,dim=c(nrow(person.state.d),numbers))
  person.probe.d = person.state.d[,probe.person]
  for (i in c(1:nrow(person.probe.d))) {
    Yt[i,] = tabulate(person.probe.d[i,],nbins = numbers)
  }
  save(Yt,file = 'data_exec/Yt.RData')
}

#log obs.matrix
if (TRUE) {
  #log obs.matrix
  obs.scale = 10
  N = 2000
  n = trunc(N/obs.scale)
  obs.matrix = array(0,dim = c(N+1,n+1))
  c = lchoose(N,n)
  for (i in c(1:nrow(obs.matrix))) {
    M = i-1
    m = c(0:n)
    a = lchoose(M,m)
    b = lchoose(N-M,n-m)
    d = a+b-c
    obs.matrix[i,] = exp(d)
  }
  
  obs.matrix = pmax(obs.matrix, 1e-300)
  obs.matrix = log(obs.matrix)
  save(obs.matrix,file = "data_exec/obs.matrix.RData")
  
  image(z=t(asinh(1000*obs.matrix)),x=1:ncol(obs.matrix) -1, y=1:nrow(obs.matrix) -1,xlab='# oberved vehicles scaled', ylab='# vehicles', asp=1)
}

save(person.state.d,file='data_prep/person.state.d.RData')
save(m.time,file='data_exec/m.time.RData')
save(Xt_real,file='data_exec/Xt_real.RData')
save(obs.matrix,file='data_exec/obs.matrix.RData')









































