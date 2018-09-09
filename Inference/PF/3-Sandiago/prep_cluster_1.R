
library('Matrix')
require('TTR')
require('igraph')
require('survey')
require('grr')
require('graphics')
require('RcppEigen')
require('Rcpp')
require('deldir')

# road cluster
if (FALSE) {
  network = readRDS(file = "data_prep/network.RDS")
  e = network$e
  n = network$n
  
  #method 1, assign 'e' to 'from'
  net_data_frame = array(0,dim = c(nrow(e),2))
  net_data_frame[,1] = match(e$from,rownames(n))
  net_data_frame[,2] = match(e$to,rownames(n))
  
  net_graph = graph_from_data_frame(net_data_frame)
  c_node <- cluster_walktrap(net_graph)
  r_node = membership(c_node)
  
  # membership of edge, assigned to be same as 'from node'
  r_edge = array(0,dim=nrow(e))
  r_edge_from = match(e$from,rownames(n))
  r_edge = r_node[match(r_edge_from,as.numeric(names(r_node)))]
  
  # cluster center location
  cluster_location = array(0,dim=c(length(tabulate(r_node)),2))
  for (i in c(1:length(r_node))) {
    idx = as.numeric(names(r_node[i]))
    cluster_location[r_node[i],1] = cluster_location[r_node[i],1] + n[idx,1]
    cluster_location[r_node[i],2] = cluster_location[r_node[i],2] + n[idx,2]
  }
  cluster_location=cluster_location/tabulate(r_node)
  
  save(cluster_location,file='data_prep/cluster_location.RData')
  save(r_edge,file = "data_prep/r_edge.RData")
}

#construct events
if (TRUE) {
  realdata = readRDS(file = "data_prep/100.events.RDS")
  network = readRDS(file='data_prep/network.RDS')
  activity.end = realdata$activity.end
  link.leave = realdata$leave
  link.enter = realdata$enter
  activity.start = realdata$activity.start
  e = length(table(factor(link.enter$link)))
  
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
  unique_person = unique(unique_person)
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
  
  # change facility
  facility_old = unique(levels(events$activity.end$type))
  facility_new = facility_old
  for (i in c(1:length(facility_old))) {
    a = substr(facility_old[i],1,4)
    facility_new[i] = a
  }
  text = unique(facility_new)
  target = c('business','education','health','home','leis','other','other','shop','visits','work')
  for (i in c(1:length(facility_old))) {
    a = facility_new[i]
    for (j in c(1:length(text))) {
      if (text[j]==a) {
        facility_new[i]=target[j]
        break
      }
    }
  }
  levels(events$activity.end$type) = facility_new
  
  facility_old = unique(levels(events$activity.start$type))
  facility_new = facility_old
  for (i in c(1:length(facility_old))) {
    a = substr(facility_old[i],1,4)
    facility_new[i] = a
  }
  text = unique(facility_new)
  target = c('business','education','health','home','leis','other','other','shop','visits','work')
  for (i in c(1:length(facility_old))) {
    a = facility_new[i]
    for (j in c(1:length(text))) {
      if (text[j]==a) {
        facility_new[i]=target[j]
        break
      }
    }
  }
  levels(events$activity.start$type) = facility_new
  
}

#compute person.state.d, initial home? find person road
if (TRUE) {
  load('data_prep/r_edge.RData')
  PersonStateR_C = function(network,events,r_edge) {
    e = nrow(network$e)
    min.time = min(sapply(1:length(events),function(n) min(events[[n]]$time[!is.infinite(events[[n]]$time)])))
    max.time = min.time+20*3600
    delta.t = 60
    td = seq(from=min.time, to=max.time, by=delta.t)
    
    person.state.d = matrix(0,nrow = length(td), ncol = length(unique_person))
    person.state.d[1,] = paste('home',0,sep='@')
    ndx = integer(length=length(events))
    ndx[] = 1
    ctime = min.time
    last = 1
    e = nrow(network$e)
    
    while(any(ndx<sapply(events, nrow))){
      ctime = min(sapply(1:length(events),function(n)events[[n]]$time[ndx[n]] ))
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
               person.state.d[ndx0, events[[3]]$person[ndx[3]] ] = r_edge[events[[3]]$link[ndx[3]] ]
               ndx[3]=ndx[3]+1
             },
             {# activity.start
               person.state.d[ndx0, events[[4]]$person[ndx[4]] ] =  r_edge[events[[4]]$link[ndx[4]] ]
               ndx[4]=ndx[4]+1
             })
      #person.state.d[ndx0+1,] = person.state.d[ndx0,]
      last = ndx0
    }
    
    #init home location, have problem
    if (TRUE) {
      for (i in c(1:ncol(person.state.d))) {
        a=person.state.d[which(person.state.d[,i]!='home@0')[1],i]
        b=which(person.state.d[,i]=='home@0')
        person.state.d[b,i] = a
      }
    }
    
    return(person.state.d)
  }
  
  person.state.d = PersonStateR_C(network,events,r_edge)
  save(person.state.d,file = "data_exec/person.state.d.RData")
  
  person.state.d = person.state.d[,-which(is.na(person.state.d[1,]))]
  person.state.d = as.numeric(person.state.d)
  person.state.d = matrix(person.state.d,nrow = 1201)
}




#compute m.time
if (TRUE) {
  load('data_prep/person.state.d.RData')
  load('data_prep/r_edge.RData')
  types = as.numeric(names(table(r_edge)))
  m = table(factor(head(person.state.d,-1),levels=types), factor(tail(person.state.d,-1),levels=types))
  m = sweep(m, 1, STATS=rowSums(m), FUN='/')
  m[is.nan(m)] = 0
  save(m,file="data_exec/m.RData")
  
  min.time = min(sapply(1:length(events),function(n) min(events[[n]]$time[!is.infinite(events[[n]]$time)])))
  max.time = min.time+20*3600
  delta.t = 60
  td = seq(from=min.time, to=max.time, by=delta.t)
  m.time = table(factor(head(person.state.d,-1),levels=types), factor(tail(person.state.d,-1),levels=types),cut(td[row(head(person.state.d,-1))]/3600,breaks = 0:4 *6))
  m.time = sweep(m.time*.99, MARGIN = 1:2, STATS = table(factor(head(person.state.d,-1),levels=types), factor(tail(person.state.d,-1),levels=types))*.01, FUN = '+')
  m.time = sweep(m.time, MARGIN = c(1,3), STATS = colSums(aperm(m.time,perm = c(2,1,3)),dims = 1),FUN = '/')
  dimnames(m.time)[[1]] = dimnames(m.time)[[2]] = types
  save(m.time,file = "data_exec/m.time.RData")
  
}

#Xt,Yt
if (TRUE) {
  load('data_prep/r_edge.RData')
  load('data_exec/person.state.d.RData')
  types = as.numeric(names(table(r_edge)))
  locations = types
  
  Xt_real = factor(person.state.d,levels = locations)
  levels(Xt_real) = c(1:length(locations))
  Xt_real = matrix(as.numeric(Xt_real),nrow = nrow(person.state.d))
  Xt_real_1 = t(apply(Xt_real,1,function(x) table(factor(x, levels=c(1:length(locations)) ))))
  save(Xt_real,file='data_exec/Xt_real.RData')
  save(Xt_real_1,file='data_exec/Xt_real_1.RData')
  
  probe.vehicle = trunc(sum(Xt_real_1[1,])/10)
  probe.ndx = sample(1:ncol(person.state.d), probe.vehicle)
  Yt = Xt_real[,probe.ndx]
  Yt_1 = t(apply(Yt,1,function(x) table(factor(x, levels=c(1:length(locations)) ))))
  save(Yt,file='data_exec/Yt.RData')
  save(Yt_1,file='data_exec/Yt_1.RData')
  save(probe.ndx,file='data_exec/probe.ndx.RData')
}

#compute log obs.matrix
if (TRUE) {
  #log obs.matrix
  obs.scale = 10
  N = 30000
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
}







