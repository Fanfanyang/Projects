library('Matrix')
require('TTR')
require('igraph')
require('survey')
require('grr')
require('graphics')
require('RcppEigen')
require('Rcpp')
require('deldir')

#construct event
if (TRUE) {
  realdata = readRDS(file = "data_prep/300.events.RDS")
  network = readRDS(file = "data_prep/network.RDS")
  activity.end = realdata$activity.end
  link.leave = realdata$leave
  link.enter = realdata$enter
  activity.start = realdata$activity.start
  
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
  unique_person = c(levels(events[[1]]$person),levels(events[[2]]$person),levels(events[[3]]$person),levels(events[[4]]$person))
  unique_person = unique_person[!duplicated(unique_person)]
  unique_lane = rownames(network$e)
  
  events[[1]]$person = factor(events[[1]]$person,levels = unique_person)
  events[[2]]$person = factor(events[[2]]$person,levels = unique_person)
  events[[3]]$person = factor(events[[3]]$person,levels = unique_person)
  events[[4]]$person = factor(events[[4]]$person,levels = unique_person)
  events[[1]]$link = factor(events[[1]]$link,levels = unique_lane)
  events[[2]]$link = factor(events[[2]]$link,levels = unique_lane)
  events[[3]]$link = factor(events[[3]]$link,levels = unique_lane)
  events[[4]]$link = factor(events[[4]]$link,levels = unique_lane)
  
  levels(events[[3]]$person) = c(1:length(unique_person))
  levels(events[[4]]$person) = c(1:length(unique_person))
  levels(events[[2]]$person) = c(1:length(unique_person))
  levels(events[[1]]$person) = c(1:length(unique_person))
  levels(events[[1]]$link) = c(1:length(unique_lane))
  levels(events[[2]]$link) = c(1:length(unique_lane))
  levels(events[[3]]$link) = c(1:length(unique_lane))
  levels(events[[4]]$link) = c(1:length(unique_lane)) 
}

#construct person.state.d
if (TRUE) {
  #compute person.state.d
  e = nrow(network$e)
  types = levels(events[[4]]$type)
  min.time = min(sapply(1:length(events),function(n) min(events[[n]]$time[!is.infinite(events[[n]]$time)])))
  max.time = min.time+22*3600
  delta.t = 60
  td = seq(from=min.time, to=max.time, by=delta.t)
  
  #compute person.state.d, initial home? find person road
  person.state.d = matrix(0,nrow = length(td), ncol = length(unique(activity.end$person)))
  person.state.d[1,] = paste(types[1],0,sep = '@')
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
             person.state.d[ndx0, events[[4]]$person[ndx[4]] ] =  paste(as.character(events[[4]]$type[ndx[4]]), events[[4]]$link[ndx[4]],sep = '@')
             ndx[4]=ndx[4]+1
           })
    #person.state.d[ndx0+1,] = person.state.d[ndx0,]
    last = ndx0
  }

  #update home@0
  for (i in c(1:ncol(person.state.d))) {
    if ((i %% 10) == 0)
      print(i/10)
    t = sapply(1:length(events),function(n)events[[n]]$time[which(events[[n]]$person == i)[1]] )
    t[is.na(t)] = Inf
    b=which(person.state.d[,i]=='home@0')
    c=events[[which.min(t)]]$link[which(events[[which.min(t)]]$person == i)[1]]
    person.state.d[b,i] = paste('home',c,sep = '@')
  }
  
  save(person.state.d,file = "data_prep/person.state.d.RData") 
}

#transition matrix m.time
if (TRUE) {
  types1=unique(paste(events[[1]]$type,events[[1]]$link,sep = '@'))
  types2=unique(paste(events[[4]]$type,events[[4]]$link,sep = '@'))
  types=unique(c(types1,types2))
  
  
  m = table(factor(head(person.state.d,-1),levels=c(types,c(1:e))), factor(tail(person.state.d,-1),levels=c(types,c(1:e))))
  m = sweep(m, 1, STATS=rowSums(m), FUN='/')
  m[is.nan(m)] = 0
  m = as(m, "sparseMatrix")
  save(m,file="m.RData")
  
  
  
  
  
  
  a = factor(head(person.state.d,-1),levels = c(types))
  b = factor(tail(person.state.d,-1),levels = c(types))
  m = table(factor(head(person.state.d,-1),levels=c(types)), factor(tail(person.state.d,-1),levels=c(types)))
  m = sweep(m, 1, STATS=rowSums(m), FUN='/')
  m[is.nan(m)] = 0
  save(m,file="data_exec/m.RData")
  
  m.time = table(factor(head(person.state.d,-1),levels=c(types)), factor(tail(person.state.d,-1),levels=c(types)),cut(td[row(head(person.state.d,-1))]/3600,breaks = 0:23+trunc(min(td)/3600)))
  #m.time = sweep(m.time*.99, MARGIN = 1:2, STATS = table(c(head(person.state.d,-1)), c(tail(person.state.d,-1)))*.01, FUN = '+')
  m.time = sweep(m.time*.9999, MARGIN = 1:2, STATS = table(factor(head(person.state.d,-1),levels=c(types)), factor(tail(person.state.d,-1),levels=c(types)))*.0001, FUN = '+')
  m.time = sweep(m.time, MARGIN = c(1,3), STATS = colSums(aperm(m.time,perm = c(2,1,3)),dims = 1),FUN = '/')
  dimnames(m.time)[[1]] = dimnames(m.time)[[2]] = c(types)
  save(m.time,file = "data_exec/m.time.RData") 
}

#generate Xt_real
if (TRUE) {
  Xt_real = t(apply(person.state.d,1,function(x) table(factor(x, levels=types)))) 
  save(Xt_real,file='data_exec/Xt_real.RData')
}

#generate Yt
if (FALSE) {
  numbers = ncol(Xt_real)
  scale = 10
  probe.person = sample.int(ncol(person.state.d),trunc(ncol(person.state.d)/scale))
  save(probe.person,file='data_exec/probe.person.fan.10.RData')
  Yt = array(0,dim=c(nrow(person.state.d),numbers))
  person.probe.d = person.state.d[,probe.person]
  Yt = t(apply(person.probe.d,1,function(x) table(factor(x, levels=types)))) 
  save(Yt,file = 'data_exec/Yt.RData')
}

#log obs.matrix
if (TRUE) {
  #log obs.matrix
  obs.scale = 10
  N = 2200
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










