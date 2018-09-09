library('Matrix')
require('TTR')
require('igraph')
require('survey')
require('grr')
require('RcppEigen')
require('Rcpp')
require('deldir')
sourceCpp("rcpp_try6_extract_vehicle.cpp")

#dakar vehicles
if(TRUE) {
  load('data_prep/person.state.d.original.RData')
  load('data_prep/tower_dakar.RData')
  dakar_person = {}
  for (i in c(1:ncol(person.state.d))) {
    if (i %% 1000 == 0)
      print(trunc(i/1000))
    if (!any(!(person.state.d[,i] %in% tower_dakar)))
      dakar_person = c(dakar_person,i)
  }
  person.state.d = person.state.d[,dakar_person]
  save(person.state.d,file='data_prep/person.state.d.dakar.RData')
}

#dakar speed extract
if(TRUE) {
  load('data_prep/person.state.d.dakar.RData')
  location = readRDS("../../data_download1/ContextData/SITE_ARR_LONLAT.RDS")
  load('data_prep/shortest_path_cb.RData')
  load('data_prep/dist.RData')
  load('data_prep/lane.RData')
  load('data_prep/tower_node_dakar.RData')
  load('data_prep/tower_dakar.RData')
  load('data_prep/lane_transist_dakar.RData')
  numbers = 489
  
  tower_dakar_rev = array(0,dim=max(tower_dakar))
  for (i in c(1:length(tower_dakar_rev))) {
    if (any(which(tower_dakar==i))) {
      tower_dakar_rev[i] = which(tower_dakar==i) 
    }
  }
  
  #sum length
  dist_array = c(0,dim=length(dist))
  for (i in c(1:length(dist))) {
    if (i %% 1000==0)
      print(i/1000)
    dist_array[i] = sum(dist[[i]])
  }
  save(dist_array,file='data_prep/dist_array.RData')
  
  #change person.state.d: (10mins, 14days,2016) -> (1mins, 1days,1440)
  #method 1, 1 day
  if (FALSE) {
    days = 1
    person.state.d = person.state.d[rep(1:(days*144),each=10),]
    save(person.state.d,file='data_prep/person.state.d.dakar.1mins.RData')
  }
  # method 2, 7 days
  if (TRUE) {
    days = 7
    person.state.d.merg = array(0,dim=c(nrow(person.state.d)/14,ncol(person.state.d)*days)) 
    for (i in c(1:days)) {
      print(i)
      person.state.d.merg[,1:ncol(person.state.d) + (i-1)*ncol(person.state.d)] = person.state.d[1:nrow(person.state.d.merg) + (i-1)*nrow(person.state.d.merg),] 
    }
    save(person.state.d.merg,file='data_prep/person.state.d.merg')
    person.state.d = person.state.d.merg[rep(1:nrow(person.state.d.merg),each=10),]
    save(person.state.d,file='data_prep/person.state.d.dakar.1mins.RData')
  }
  
  th = 15/60
  sourceCpp("rcpp_try6_extract_vehicle.cpp")
  person.extract.fast = ExtractFast( person.state.d,dist_array, tower_dakar_rev,dist, lane, numbers, th)
  save(person.extract.fast,file='data_prep/person.extract.fast.RData')
  
  #rename transition lanes
  load('data_prep/person.extract.fast.RData')
  th = max(tower_dakar)
  lane_ndx = unique(person.extract.fast[which(person.extract.fast>th)])
  person.extract.fast = ReName(person.extract.fast,lane_ndx,th)
  save(person.extract.fast,file = 'data_prep/person.extract.fast.re.RData')
  save(lane_ndx,file='data_prep/lane_ndx.RData')
}

#Xt_real
if (TRUE) {
  load('data_prep/person.extract.fast.re.RData')
  sourceCpp("rcpp_try6_extract_vehicle.cpp")
  numbers = max(person.extract.fast)
  
  Xt_real = Xt_relative_vehicle(person.extract.fast,numbers)
  for (i in c(1:ncol(Xt_real))) {
    Xt_real[,i] = cumsum(Xt_real[,i])
  }
  for (i in c(1:ncol(Xt_real))) {
    off = min(Xt_real[,i])
    Xt_real[,i] = Xt_real[,i]-off
  }
  save(Xt_real,file='data_exec/Xt_real.RData')
}

#vehicle.state and update Xt_real
# have prolem, i=84-85 (i=85), Xt_real != vehicle.state.d
if (TRUE) {
  load('data_prep/person.extract.fast.re.RData')
  load('data_exec/Xt_real.RData')
  
  #Xt_real update
  #Xt_real[i,prev] when executing stucks, only executing once
  if(FALSE) {
    # 20km/h, ignore short trip less than 1 time unit
    Xt_real[,51] = Xt_real[,51]+1
    Xt_real[,14] = Xt_real[,14]+1
    Xt_real[,163] = Xt_real[,163]+1
    Xt_real[,25] = Xt_real[,25]+1
    Xt_real[,50] = Xt_real[,50]+1 
    
    #15km/h, 1mins, dakar & pikine
    Xt_real = Xt_real+1
    
    # 15km/h, 1mins, dakar region
    Xt_real = Xt_real + 1
  }
  
  total_vehicles = sum(Xt_real[1,])
  vehicle.state.d = array(0,dim=c(nrow(Xt_real),total_vehicles))
  vehicle.state.d[1,] = rep(c(1:ncol(Xt_real)),Xt_real[1,])
  
  for (i in c(2:nrow(vehicle.state.d))) {
    print(i)
    vehicle.state.d[i,]=vehicle.state.d[i-1,]
    ndx_prev = which(person.extract.fast[i-1,]>0)
    ndx_curr = which(person.extract.fast[i,]>0)
    ndx_extract = ndx_curr[match(ndx_prev,ndx_curr)]
    ndx_extract = ndx_extract[!is.na(ndx_extract)]
    move_flag = {}
    
    k=1
    while (k<=length(ndx_extract)) {
      j=ndx_extract[k]
      k=k+1
      prev = person.extract.fast[i-1,j]
      curr = person.extract.fast[i,j]
      vehicle_potential = which(vehicle.state.d[i-1,]==prev)
      
      have_moved = which(vehicle_potential %in% move_flag)
      if (any(have_moved)) {
        vehicle_choose = vehicle_potential[-which(vehicle_potential %in% move_flag)][1] 
      } else {
        vehicle_choose = vehicle_potential[1] 
      }
      if (is.na(vehicle_choose)||(!any(vehicle_choose))) {
        ndx_extract = c(ndx_extract,j)
        next
      } else {
        vehicle.state.d[i,vehicle_choose] = curr
        move_flag=c(move_flag,vehicle_choose)
      }
    }
  }
  
  
  
  #get rid of unmoving vehicles
  if (TRUE) {
    moving_cols = {}
    for (i in c(1:ncol(vehicle.state.d))) {
      test_number = vehicle.state.d[1,i]
      test_vector = rep(test_number,nrow(vehicle.state.d))
      if (any(vehicle.state.d[,i]!=test_vector)) {
        moving_cols = c(moving_cols,i)
      }
    }
    vehicle.state.d = vehicle.state.d[,moving_cols]
  }
  
  save(vehicle.state.d,file='data_exec/vehicle.state.d.RData')
}

#m.time
if (TRUE) {
  load('data_exec/vehicle.state.d.RData')
  sourceCpp('rcpp_try4.cpp')
  
  numbers = max(vehicle.state.d)
  m.total = TransitionM(vehicle.state.d,numbers)
  m.total = sweep(m.total, 1, STATS=rowSums(m.total), FUN='/')
  save(m.total,file = 'data_exec/m.total.fan.RData')
  
  # 1 day m.time.rcpp
  if (TRUE) {
    reg = 12
    tmp.seq = seq(from=1,to=nrow(vehicle.state.d)/reg,by=1)
    m.time = array(0,dim=c(numbers,numbers,reg))
    m.total = TransitionM(vehicle.state.d,numbers)
    for (i in c(1:reg)) {
      print(i)
      ndx = tmp.seq + length(tmp.seq)*(i-1)
      person.tmp = vehicle.state.d[ndx,]
      m.tmp = TransitionMTime(person.tmp,numbers,length(tmp.seq))
      m.tmp = m.tmp*0.9999+m.total*0.0001
      m.tmp = sweep(m.tmp, 1, STATS=rowSums(m.tmp), FUN='/')
      m.time[,,i] = m.tmp 
    }
  }
  
  save(m.time,file = "data_exec/m.time.fan.RData")
}

#Xt_real,Yt
if (TRUE) {
  load('data_exec/vehicle.state.d.RData')
  numbers=max(vehicle.state.d)
  Xt_real = array(0,dim=c(nrow(vehicle.state.d),numbers))
  for (i in c(1:nrow(vehicle.state.d))) {
    print(i)
    Xt_real[i,] = tabulate(vehicle.state.d[i,],nbins = numbers)
  }
  save(Xt_real,file = 'data_exec/Xt_real_fan.RData')
  
  scale = 10
  probe.person = sample.int(ncol(vehicle.state.d),trunc(ncol(vehicle.state.d)/scale))
  save(probe.person,file='data_exec/probe.person.fan.RData')
  
  Yt = array(0,dim=c(nrow(vehicle.state.d),numbers))
  person.probe.d = vehicle.state.d[,probe.person]
  for (i in c(1:nrow(person.probe.d))) {
    print(i)
    Yt[i,] = tabulate(person.probe.d[i,],nbins = numbers)
  }
  save(Yt,file = 'data_exec/Yt_fan.RData')
}

#log obs.matrix
if (TRUE) {
  #log obs.matrix
  obs.scale = 10
  N = 1000
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
  
  #method2
  if (FALSE) {
    n = 100
    N = 100
    obs.compute = array(0,dim = c(N+1,n+1))
    for (i in c(1:nrow(obs.compute))) {
      obs.compute[i,] = dbinom(c(0:n),n,(i-1)/N)
    }
    obs.compute = pmax(obs.compute,1e-300)
    image(z=t(asinh(1000*obs.compute)),x=1:ncol(obs.compute) -1, y=1:nrow(obs.compute) -1,xlab='# oberved vehicles scaled', ylab='# vehicles', asp=1)
    obs.matrix = log(obs.compute)
  }
}



































