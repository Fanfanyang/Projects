
library('Matrix')
require('TTR')
require('igraph')
require('survey')
require('grr')
require('RcppEigen')
require('Rcpp')

load("data_exec/Xt_real_fan.RData")
load("data_exec/Yt_fan.RData")
load("data_exec/m.time.fan.RData")
load("data_exec/obs.matrix.RData")
load('data_prep/tower_dakar.RData')
load('data_exec/vehicle.state.d.RData')

# particle fitering
RunTimes = 3
obs.scale = 10
particles = 1e3
par_inc = 1
nodes = max(tower_dakar)
obs.lanes = c((nodes+1):ncol(Xt_real))
step = 1
small.prob = 1e-8
lane.nums = dim(m.time)[1]

for(yy in c(1:RunTimes)) {
  print(yy)
  W_particles = array(0,dim=c(nrow(Xt_real),particles*par_inc))
  Xt_est = array(0,dim=c(nrow(Xt_real),lane.nums))
  Xi_1 = array(0,dim =c(particles,lane.nums))
  Xi_2 = array(0,dim =c(particles*par_inc,lane.nums))
  ndx_particles = array(1,dim = c(nrow(vehicle.state.d),particles))
  
  t0=1
  W_particles[1,] = array(1/particles,dim=particles)
  Xt_est[t0,1:ncol(Yt)] = Yt[t0,]*obs.scale
  Xi_1 = matrix(rep(Xt_est[t0,],each=particles),nrow=particles)
  saveRDS(Xi_1,file = "data/snapshot_1.RDS")
  
  for(t in c((t0+1):nrow(Xt_real))) {
  #for(t in c(442:nrow(Xt_real))) {
    print(t)
    t1 = min(trunc((t-1)/120)+1,12)
    Xi_2[,] = 0
    
    if(TRUE) {
      Xi_1 = matrix(rep(Xi_1,each=par_inc),ncol=ncol(Xi_1))
      ndx_lane_from = which(colSums(Xi_1)>0)
      for(j in ndx_lane_from){
        idx = which(m.time[j,,t1]>0)
        sample_result = sample.int(length(idx), sum(Xi_1[,j]), replace=TRUE,prob=m.time[j,idx,t1])
        ndx = rep(0, length(sample_result))
        ndx2 = which(Xi_1[,j]>0)
        ndx3 = Xi_1[ndx2,j]
        ndx[ cumsum(c(1,head(ndx3,-1))) ] = 1 #diff(c(0,ndx2))
        ndx = cumsum(ndx)
        Xi_2[ndx2,idx] = Xi_2[ndx2,idx] + matrix(tabulate( ndx+(sample_result-1)*length(ndx2), nbins=length(ndx2)*length(idx) ), nrow=length(ndx2))
      }
    }
    
    if((t %% step)!=0) {
      ndx_particles[t,] = c(1:particles)
      Xi_1 = Xi_2
      Xt_est[t,] = round(colMeans(Xi_1))
      name.file = paste('data/snapshot',t,sep = '_')
      name.file = paste(name.file,'RDS',sep = '.')
      saveRDS(Xi_1,file = name.file)
      next
    }
    
    W_lane = obs.matrix[cbind( c(Xi_2[,obs.lanes]+1),rep(Yt[t,obs.lanes]+1, each=particles*par_inc) )]
    W_lane = matrix(W_lane, nrow=particles*par_inc)
    
    W = apply(W_lane,1,sum)
    # W contains P(Xt|Ki) for all particles at each time step
    W_particles[t,] = W
    W = exp(W-max(W))
    
    #resampling
    print(sum(W))
    W = W/sum(W)
    resample_particles = sample(c(1:length(W)),particles,replace=TRUE,prob=W)
    ndx_particles[t,] = resample_particles
    Xi_1 = Xi_2[resample_particles,]
    
    #output estimation state
    Xt_est[t,] = round(colMeans(Xi_1))
    name.file = paste('data/snapshot',t,sep = '_')
    name.file = paste(name.file,'RDS',sep = '.')
    saveRDS(Xi_1,file = name.file)
  }
  
  #save 1 run result
  if (TRUE) {
    if (TRUE) {
      total.time = nrow(vehicle.state.d)
      bt_particles = array(0,dim = c(total.time,ncol(m.time)))
      ndx_particles = trunc((ndx_particles-1)/par_inc)+1
      ndx = ndx_particles*0 # initialization
      ndx[total.time,] = 1:ncol(ndx)
      for (i in c(total.time:2)) {
        #print(i)
        ndx[i-1,] = ndx_particles[i,ndx[i,]]
      }
      for (i in c(1:total.time)) {
        print(i)
        idx = ndx[i,1]
        name.file = paste('data/snapshot',i,sep = '_')
        name.file = paste(name.file,'RDS',sep = '.')
        tmp_particles = readRDS(name.file)
        bt_particles[i,] = t(tmp_particles[idx,])
      }
    }
    save(Xt_est,file='data_result/Xt_est.RData')
    save(ndx_particles,file='data_result/ndx_particles.RData')
    save(W_particles,file='data_result/W_particles.RData')
    name.file = paste('data_result/run1/bt_particles',yy,sep = '_')
    name.file = paste(name.file,'RDS',sep = '.')
    saveRDS(bt_particles,file=name.file)
  }
  
  #back tracing, too large
  if (FALSE) {
    total.time = nrow(vehicle.state.d)
    Xt_particles = array(0,dim = c(total.time,ncol(m.time),particles))
    bt_particles = array(0,dim = c(total.time,ncol(m.time),particles))
    
    if (TRUE) {
      ndx_particles = trunc((ndx_particles-1)/par_inc)+1
      ndx = ndx_particles*0 # initialization
      ndx[total.time,] = 1:ncol(ndx)
      for (i in c(total.time:2)) {
        #print(i)
        ndx[i-1,] = ndx_particles[i,ndx[i,]]
      }
    }
    for (i in c(1:total.time)) {
      #print(i)
      idx = ndx[i,]
      name.file = paste('data/snapshot',i,sep = '_')
      name.file = paste(name.file,'RDS',sep = '.')
      tmp_particles = readRDS(name.file)
      Xt_particles[i,,] = t(tmp_particles)
      bt_particles[i,,] = t(tmp_particles[idx,])
    }
    name.file = paste('data_result/run1/Xt_particles',yy,sep = '_')
    name.file = paste(name.file,'RDS',sep = '.')
    saveRDS(Xt_particles,file = name.file)
    name.file = paste('data_result/run1/W_particles',yy,sep = '_')
    name.file = paste(name.file,'RDS',sep = '.')
    saveRDS(W_particles,file=name.file)
    name.file = paste('data_result/run1/bt_particles',yy,sep = '_')
    name.file = paste(name.file,'RDS',sep = '.')
    saveRDS(bt_particles,file=name.file)
  }
}










#generate estimation snapshot, location
# id, loc.x, loc.y, dir, loc.ndx, time.t
if (TRUE) {
  load('data_prep/lane_ndx.RData')
  load('data_exec/vehicle.state.d.RData')
  road = readRDS('../../data_download1/ContextData/Senegal_roads.RDS')
  load('data_prep/tower_node_dakar.RData')
  load('data_prep/tower_dakar.RData')
  bt_particles=readRDS('data_result/run1/bt_particles_1.RDS')
  load('data_exec/position.RData')
  load('data_exec/Xt_real_fan.RData')
  
  if (FALSE) {
    position = matrix(0,nrow = ncol(Xt_real),ncol = 2)
    th = max(tower_dakar)
    for (i in c(1:nrow(position))) {
      if (i %% 10 == 0)
        print(trunc(i/10))
      if (i<=th) {
        ndx = which(tower_dakar==i)
        if (any(ndx)) {
          idx = tower_node[ndx]
          position[i,1] = road$n$x[idx]
          position[i,2] = road$n$y[idx]
        } 
      }
      else {
        ndx = lane_ndx[i-th]-1666
        idx1 = which(rownames(road$n)==road$e$from[ndx])
        idx2 = which(rownames(road$n)==road$e$to[ndx])
        position[i,1] = (road$n$x[idx1]+road$n$x[idx2])/2
        position[i,2] = (road$n$y[idx1]+road$n$y[idx2])/2
      }
    }
    save(position,file='data_exec/position.RData') 
  }
  
  # execution, contineous viewing
  if (TRUE) {
    #Xt_real
    bt_particles = Xt_real
    
    max.person = sum(bt_particles[1,])
    min.time = 1
    
    loc.x=c()
    loc.y=c()
    time.t=c()
    speed.s=c()
    ndx.id=c()
    for (i in c(1:800)) {
      print(i)
      
      #find moving
      th = max(tower_dakar)+1
      max.person = sum(bt_particles[i,th:ncol(bt_particles)])
      
      tmp.s = array(40,dim = max.person)
      tmp.t = array(((i-1)*60+min.time),dim = max.person)
      tmp.id = array(1,dim = max.person)
      
      person_bt = rep(c(th:ncol(bt_particles)),bt_particles[i,th:ncol(bt_particles)])
      tmp.x = position[person_bt,1]
      tmp.y = position[person_bt,2]
      
      time.t = c(time.t,tmp.t)
      loc.x = c(loc.x,tmp.x)
      loc.y = c(loc.y,tmp.y)
      speed.s = c(speed.s,tmp.s)
      ndx.id = c(ndx.id,tmp.id)
    }
    
    snapshot.loc1 = data.frame(ndx.id,loc.x,loc.y,speed.s,time.t)
    colnames(snapshot.loc1) = c('id','x','y','s','time')
    
    saveRDS(snapshot.loc1,file = "snapshot.loc1.RDS")
    #saveRDS(snapshot.loc1,file = "snapshot.moving.gt.RDS")
    
    #6001-30061
    start.time = 500
    end.time = 700
    start.ndx = which(snapshot.loc1$time >= (min.time+start.time*60))[1]
    end.ndx = which(snapshot.loc1$time > (min.time+end.time*60))[1]
    if(is.na(end.ndx))
      end.ndx = nrow(snapshot.loc1)
    snapshot.loc2 = snapshot.loc1[start.ndx:end.ndx,]
    saveRDS(snapshot.loc2,file = "snapshot.loc2.RDS")
    #saveRDS(snapshot.loc2,file = "snapshot.obs.RDS")
  }
  
  # execution, discrete viewing
  if (TRUE) {
    #Xt_real
    bt_particles = Xt_real
    
    max.person = sum(bt_particles[1,])
    min.time = 1
    
    loc.x=c()
    loc.y=c()
    time.t=c()
    speed.s=c()
    ndx.id=c()
    time.step = c(1:23,23.8)*60
    for (i in c(1:length(time.step))) {
      print(i)
      
      #find moving
      th = max(tower_dakar)+1
      max.person = sum(bt_particles[time.step[i],th:ncol(bt_particles)])
      
      tmp.s = array(40,dim = max.person)
      tmp.t = array(((i-1)*60+min.time),dim = max.person)
      tmp.id = array(1,dim = max.person)
      
      person_bt = rep(c(th:ncol(bt_particles)),bt_particles[time.step[i],th:ncol(bt_particles)])
      tmp.x = position[person_bt,1]
      tmp.y = position[person_bt,2]
      
      time.t = c(time.t,tmp.t)
      loc.x = c(loc.x,tmp.x)
      loc.y = c(loc.y,tmp.y)
      speed.s = c(speed.s,tmp.s)
      ndx.id = c(ndx.id,tmp.id)
    }
    
    snapshot.loc1 = data.frame(ndx.id,loc.x,loc.y,speed.s,time.t)
    colnames(snapshot.loc1) = c('id','x','y','s','time')
    
    saveRDS(snapshot.loc1,file = "snapshot.gt.RDS")
    #saveRDS(snapshot.loc1,file = "snapshot.obs.RDS")
    
    #6001-30061
    start.time = 500
    end.time = 700
    start.ndx = which(snapshot.loc1$time >= (min.time+start.time*60))[1]
    end.ndx = which(snapshot.loc1$time > (min.time+end.time*60))[1]
    if(is.na(end.ndx))
      end.ndx = nrow(snapshot.loc1)
    snapshot.loc2 = snapshot.loc1[start.ndx:end.ndx,]
    saveRDS(snapshot.loc2,file = "snapshot.loc2.RDS")
    #saveRDS(snapshot.loc2,file = "snapshot.obs.RDS")
  }
}





#generate snapshot using vehicle location
if (FALSE) {
  load('data_exec/vehicle.state.d')
  load('data_exec/position.RData')
  
  max.person = ncol(vehicle.state.d)
  min.time = 1
  
  loc.x=c()
  loc.y=c()
  time.t=c()
  speed.s=c()
  ndx.id=c()
  #61-47941
  for (i in c(1:800)) {
    print(i)
    
    #find moving
    th = 316
    moving_curr = vehicle.state.d[i,]
    moving_next = vehicle.state.d[i+1,]
    moving_diff = which(moving_curr != moving_next)
    moving_lane = which(moving_curr > th)
    moving_vehicle = unique(c(moving_diff,moving_lane))
    max.person = length(moving_vehicle)
    
    tmp.s = array(40,dim = max.person)
    tmp.t = array(((i-1)*60+min.time),dim = max.person)
    tmp.id = moving_vehicle
    
    tmp.x = position[moving_curr[moving_vehicle],1]
    tmp.y = position[moving_curr[moving_vehicle],2]
    
    time.t = c(time.t,tmp.t)
    loc.x = c(loc.x,tmp.x)
    loc.y = c(loc.y,tmp.y)
    speed.s = c(speed.s,tmp.s)
    ndx.id = c(ndx.id,tmp.id)
  }
  
  snapshot.loc1 = data.frame(ndx.id,loc.x,loc.y,speed.s,time.t)
  colnames(snapshot.loc1) = c('id','x','y','s','time')
  
  saveRDS(snapshot.loc1,file = "snapshot.moving.gt.RDS")
  
}



#find which columns are choosing from Xt_Real to Yt
a = data.frame(Xt_real)
b = data.frame(Yt)
choosing_columns=match(b,a)
bt_particles = Xt_real[1:total.time,-choosing_columns]










#dump road network
if(TRUE) {
  #load
  network = readRDS('../../data_download1/ContextData/Senegal_roads.RDS')
  load('data_prep/tower_dakar.RData')
  load('data_prep/lane.RData')  #edge number
  load('data_prep/shortest_path.RData')   #node name

  #preprocessing
  lane = unique(unlist(lane))
  node = unique(unlist(shortest_path))
  node = match(node,as.numeric(rownames(network$n)))
  node=node[-which(is.na(node))]
  node = unique(c(node,tower_dakar))
  e = network$e[lane,]
  n = network$n[node,]
  network_dakar = list(n=n,e=e)
  network = network_dakar
  
  #write shape file
  require(sp)
  require(rgdal)
  n = SpatialPointsDataFrame(coords=network$n, data=data.frame(ID=rownames(network$n)), proj4string=CRS("+proj=longlat"))
  require(maptools)
  writeSpatialShape(x=n, fn='nodes')
  
  e = SpatialLinesDataFrame(SpatialLines(lapply(1:nrow(network$e),function(i) Lines(list(Line(coords = with(network,rbind(n[as.character(e[i,'from']),],n[as.character(e[i,'to']),],make.row.names=FALSE)))),ID=rownames(network$e)[i])),proj4string=CRS("+proj=longlat")),data=network$e[,c('length','lanes','freespeed','capacity')],match.ID=TRUE)
  writeSpatialShape(x=e, fn='links')
}












#debug visualization
person_idx = which(snapshot.loc2$id == snapshot.loc2$id[1])
time_idx = snapshot.loc2$time[person_idx]
coordinates_idx = cbind(snapshot.loc2$x[person_idx],snapshot.loc2$y[person_idx])

lane.a = bt_particles[1:10,272]
location.ndx[lane.a]
e.a = network$e[7884,]
e.b = network$e[12582,]
network$n[which(rownames(network$n) == e.a$from),]
network$n[which(rownames(network$n) == e.b$from),]

#0.01 == 1km

#plot and analyze data
if(FALSE) {
  colnames(Xt_real) = c(1:ncol(Xt_real))
  sort(colSums(Xt_real[,]),decreasing = TRUE)[1:10]
  # 202   216    28    70   355    49    45   191    23   210 
  #43775 26062 20467 18956 18027 17757 16911 16142 15928 15779 
  
  plot_lane = 23
  time_period=c(1:1440)
  SMA_scale = 10
  plot(SMA(Xt_est[time_period,plot_lane],SMA_scale),type='l',ylim = c())
  #lines(SMA(Xt_real[time_period,plot_lane],SMA_scale),type='l',col='red')
  lines(SMA(Yt[time_period,plot_lane]*10,SMA_scale),type='l',col='red')
  legend('topleft',legend=c('estimation','observation scaled'),lty=c(1,1),col=c('black','red'))
  
}

bias1 = sum(abs(Xt_real_1 - Xt_est_1k))
bias2 = sum(abs(Xt_real_1 - Xt_est_10k))








