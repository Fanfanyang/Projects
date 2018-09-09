library(data.table)

#load data
#construct event
if (TRUE) {
  realdata = readRDS(file = "data_prep/100.events.RDS")
  network = readRDS(file = "data_prep/network.RDS")
  saveRDS(network,'network.RDS')
  e=network$e
  n=network$n
  activity.end = realdata$activity.end
  link.leave = realdata$link.leave
  link.enter = realdata$link.enter
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


#functions
Location <- function(events,network) {
  types1=unique(paste(events[[1]]$type,events[[1]]$link,sep = '@'))
  types2=unique(paste(events[[4]]$type,events[[4]]$link,sep = '@'))
  types=unique(c(types1,types2))
  links <- c(1:nrow(network$e))
  types = c(types,'home@7627')
  locations <- c(types,links)
  
  #test 
  if (FALSE) {
    person.state.d = matrix(as.numeric(factor(person.state.d, levels=locations)), nrow=nrow(person.state.d))
    a=matrix(person.state.d %in% locations,nrow=nrow(person.state.d))
    b=which(a!=TRUE,arr.ind = TRUE)
    #col=3579,home@7627
  }
  
  return(list(locations=locations,facility_length=length(types)))
}

PersonStateT <- function(events,extend) {
  types <- levels(events[[4]]$type)
  min.time <- min(sapply(1:length(events),function(n) min(events[[n]]$time[!is.infinite(events[[n]]$time)])))
  max.time <- min(min.time+24*3600,max(sapply(1:length(events),function(n) max(events[[n]]$time[!is.infinite(events[[n]]$time)]))))
  delta.t <- 60
  td <- seq(from=min.time, to=max.time+delta.t-1, by=delta.t)
  
  person.state.d <- matrix(0,nrow = length(td), ncol = length(unique(activity.end$person)))
  person.state.d[1,] <- paste(types[1],0,sep = '@')
  ndx <- integer(length=length(events))
  ndx[] <- 1
  ctime <- min.time
  last <- 1
  
  while(any(ndx<sapply(events, nrow))){
    ctime <- min(sapply(1:length(events),function(n) events[[n]]$time[ndx[n]] ))
    if(ctime > max.time)
      break
    ndx0 <- which(td>=ctime)[1]
    if (ndx0 > last) {
      print(ndx0)
      for(i in c((last+1):ndx0)) {
        person.state.d[i,] <- person.state.d[last,]
      }
    }
    # update site state according to events
    switch(which.min(sapply(1:length(events),function(n)events[[n]]$time[ndx[n]] )),
           {# activity end
             #person.state[ndx0, events[[1]]$person[ndx[1]] ] =  events[[1]]$link[ndx[1]]
             ndx[1]<-ndx[1]+1
           },
           {# link.leave
             ndx[2]<-ndx[2]+1
           },
           {# link.enter
             person.state.d[ndx0, events[[3]]$person[ndx[3]] ] <-  events[[3]]$link[ndx[3]] 
             ndx[3]<-ndx[3]+1
           },
           {# activity.start
             person.state.d[ndx0, events[[4]]$person[ndx[4]] ] <-  paste(as.character(events[[4]]$type[ndx[4]]), events[[4]]$link[ndx[4]],sep = '@')
             ndx[4]<-ndx[4]+1
           })
    #person.state.d[ndx0+1,] = person.state.d[ndx0,]
    last <- ndx0
  }
  #take care of initial
  for (i in c(1:ncol(person.state.d))) {
    if ((i %% 10) == 0)
      print(i/10)
    t = sapply(1:length(events),function(n)events[[n]]$time[which(events[[n]]$person == i)[1]] )
    t[is.na(t)] = Inf
    b=which(person.state.d[,i]=='home@0')
    c=events[[which.min(t)]]$link[which(events[[which.min(t)]]$person == i)[1]]
    person.state.d[b,i] = paste('home',c,sep = '@')
  }
  
  #person.state.d <- matrix(as.numeric(factor(person.state.d, levels=locations)), nrow=nrow(person.state.d))
  #inc
  td <- c(seq(to=min.time-60,by=60,length.out = extend),td)
  person.state.d <- rbind(array('h',dim=c(extend,ncol(person.state.d))),person.state.d)
  return(list(person.state.d=person.state.d,td=td))
}

MTime <- function(person.state.d,td,locations,smoother) {
  m <- table(factor(head(person.state.d,-1),levels=locations), factor(tail(person.state.d,-1),levels=locations))
  m <- sweep(m, 1, STATS=rowSums(m), FUN='/')
  rownames(m) <- colnames(m) <- locations
  
  m.time <- table(factor(head(person.state.d,-1),levels=locations), factor(tail(person.state.d,-1),levels=locations),cut(td[row(head(person.state.d,-1))]/3600,breaks = 0:24))
  m.time <- sweep(m.time*smoother, MARGIN = 1:2, STATS = table(factor(head(person.state.d,-1),levels=locations), factor(tail(person.state.d,-1),levels=locations))*(1-smoother), FUN = '+')
  m.time <- sweep(m.time, MARGIN = c(1,3), STATS = colSums(aperm(m.time,perm = c(2,1,3)),dims = 1),FUN = '/')
  dimnames(m.time)[[1]] <- dimnames(m.time)[[2]] <- locations
  
  return(list(m=m,m.time=m.time))
}

MTimePlot <- function(m) {
  image(z=asinh(t(m)*1000),x=1:ncol(m), y=1:nrow(m),ylim=c(nrow(m)+.5,.5),xlab='to', ylab='from', xaxt='n', yaxt='n',asp=1)
  axis(side=1, at=1:ncol(m), labels=colnames(m), las=2)
  axis(side=2, at=1:nrow(m), labels=rownames(m), las=2)
}

YT <- function(person.state.d,scale,locations) {
  numbers <- dim(person.state.d)[2]
  probe.person <- sample.int(ncol(person.state.d),trunc(ncol(person.state.d)/scale))
  Yt <- person.state.d[,probe.person]
  return(list(probe.person=probe.person,Yt=Yt))
}

LogObsMatrix <- function(obs.scale,N) {
  n <- trunc(N/obs.scale)
  obs.matrix <- array(0,dim = c(N+1,n+1))
  c <- lchoose(N,n)
  for (i in c(1:nrow(obs.matrix))) {
    M <- i-1
    m <- c(0:n)
    a <- lchoose(M,m)
    b <- lchoose(N-M,n-m)
    d <- a+b-c
    obs.matrix[i,] <- exp(d)
  }
  obs.matrix <- pmax(obs.matrix, 1e-300)
  obs.matrix <- log(obs.matrix)
}

LogObsMatrixPlot <- function(obs.matrix) {
  image(z=t(asinh(1000*obs.matrix)),x=1:ncol(obs.matrix) -1, y=1:nrow(obs.matrix) -1,xlab='# oberved vehicles scaled', ylab='# vehicles', asp=1)
}

#constructing prerequisite matrices
if (TRUE) {
  extend = 60
  info_locations = Location(events,network)
  locations = info_locations$locations
  facility_length = info_locations$facility_length
  person.track = PersonStateT(events,extend)
  person.state.d = person.track$person.state.d
  td = person.track$td
  #person.state.d <- matrix(as.numeric(factor(person.state.d, levels=locations)), nrow=nrow(person.state.d))
  #transition =MTime(person.state.d,td,locations,0.9999)
  #m.time = transition$m.time
  Xt_real = person.state.d
  observation = YT(person.state.d,10,locations)
  Yt = observation$Yt
  probe.person = observation$probe.person
  obs.matrix = LogObsMatrix(10,dim(person.state.d)[2])
  
  #MTimePlot(transition$m)
  
  save(person.state.d,file='data_prep/person.state.d.RData')
  #save(m.time,file='data_exec/m.time.RData')
  save(Xt_real,file='data_exec/Xt_real.RData')
  save(probe.person,file='data_prep/probe.person.RData')
  save(Yt,file = 'data_exec/Yt.RData')
  save(obs.matrix,file='data_exec/obs.matrix.RData')
  save(td,file='data_prep/td.RData')
  save(locations,file='data_prep/locations.RData')
  save(facility_length, file='data_prep/facility_length.RData')
}









































