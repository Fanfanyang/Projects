
library('Matrix')
require('TTR')
require('igraph')

realdata = readRDS(file = "../300.events.RDS")
network = readRDS(file = "../network.RDS")
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
unique_person = c(levels(events[[3]]$person),levels(events[[4]]$person))
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

#any(is.na(match(c(1,2,4),c(1,2,3))))
any(is.na(match(c(1:ncol(person.state.d)),events[[1]]$person)))
for (i in c(1:ncol(person.state.d))) {
  print(i)
  ndx1 = which.min(sapply(1:length(events),function(n) events[[n]]$time[which(events[[n]]$person==i)[1]] ))
  if(ndx1!=1) {
    print("end")
    stop("find ndx1 != 1")
  }
}


if (FALSE) {
for (i in c(1:ncol(person.state.d))) {
  #print(i)
  a=which(events[[1]]$person == i)
  b=which(person.state.d[,i]=='home@0')
  person.state.d[b,i] = paste(as.character(events[[1]]$type[a[1]]), events[[1]]$link[a[1]],sep = '@')
}
}

save(person.state.d,file = "person.state.d.RData")

types1=unique(paste(events[[1]]$type,events[[1]]$link,sep = '@'))
types2=unique(paste(events[[4]]$type,events[[4]]$link,sep = '@'))
types=unique(c(types1,types2))


m = table(factor(head(person.state.d,-1),levels=c(types,c(1:e))), factor(tail(person.state.d,-1),levels=c(types,c(1:e))))
m = sweep(m, 1, STATS=rowSums(m), FUN='/')
m[is.nan(m)] = 0
m = as(m, "sparseMatrix")
save(m,file="m.RData")

m=as.matrix(m)
time.cut = seq(0,30,6)
time.ndx = (time.cut*3600-min.time)/60

m.time1 = table(factor(head(person.state.d[1:time.ndx[2],],-1),levels=c(types,c(1:e))), factor(tail(person.state.d[1:time.ndx[2],],-1),levels=c(types,c(1:e))))*0.99 + m*0.01
m.time1 = sweep(m.time1, 1, STATS=rowSums(m.time1), FUN='/')
m.time1[is.nan(m.time1)] = 0
m.time1 = as(m.time1, "sparseMatrix")
save(m.time1,file="m.time1.RData")
rm(m.time1)

m.time2 = table(factor(head(person.state.d[time.ndx[2]:time.ndx[3],],-1),levels=c(types,c(1:e))), factor(tail(person.state.d[time.ndx[2]:time.ndx[3],],-1),levels=c(types,c(1:e))))*0.99 + m*0.01
m.time2 = sweep(m.time2, 1, STATS=rowSums(m.time2), FUN='/')
m.time2[is.nan(m.time2)] = 0
m.time2 = as(m.time2, "sparseMatrix")
save(m.time2,file="m.time2.RData")
rm(m.time2)

m.time3 = table(factor(head(person.state.d[time.ndx[3]:time.ndx[4],],-1),levels=c(types,c(1:e))), factor(tail(person.state.d[time.ndx[3]:time.ndx[4],],-1),levels=c(types,c(1:e))))*0.99 + m*0.01
m.time3 = sweep(m.time3, 1, STATS=rowSums(m.time3), FUN='/')
m.time3[is.nan(m.time3)] = 0
m.time3 = as(m.time3, "sparseMatrix")
save(m.time3,file="m.time3.RData")
rm(m.time3)

m.time4 = table(factor(head(person.state.d[time.ndx[4]:time.ndx[5],],-1),levels=c(types,c(1:e))), factor(tail(person.state.d[time.ndx[4]:time.ndx[5],],-1),levels=c(types,c(1:e))))*0.99 + m*0.01
m.time4 = sweep(m.time4, 1, STATS=rowSums(m.time4), FUN='/')
m.time4[is.nan(m.time4)] = 0
m.time4 = as(m.time4, "sparseMatrix")
save(m.time4,file="m.time4.RData")
rm(m.time4)

m.time5 = table(factor(head(person.state.d[time.ndx[5]:nrow(person.state.d),],-1),levels=c(types,c(1:e))), factor(tail(person.state.d[time.ndx[5]:nrow(person.state.d),],-1),levels=c(types,c(1:e))))*0.99 + m*0.01
m.time5 = sweep(m.time5, 1, STATS=rowSums(m.time5), FUN='/')
m.time5[is.nan(m.time5)] = 0
m.time5 = as(m.time5, "sparseMatrix")
save(m.time5,file="m.time5.RData")
rm(m.time5)


#log obs.matrix
obs.scale = 10
N = ncol(person.state.d)
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
obs.matrix = pmax(obs.matrix, 1e-8)
obs.matrix = log(obs.matrix)
save(obs.matrix,file = "obs.matrix.RData")













