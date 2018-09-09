
library('Matrix')
require('TTR')
require('igraph')
require('survey')
require('grr')
require('RcppEigen')
require('Rcpp')

network = readRDS(file='data_prep/network.RDS')
load('data_prep/r_edge.RData')

#compute person.state.d
min.time = 1

load("data_exec/m.time.100.RData")
load("data_exec/obs.matrix.RData")
load('data_exec/Xt_real_1.RData')
load('data_exec/Yt_1.RData')
Xt_real = Xt_real_1
Yt = Yt_1
rm(Xt_real_1)
rm(Yt_1)

# particle fitering
RunTimes = 1
obs.scale = 10
particles = 1000
obs.lanes = c(1:ncol(Xt_real))
step = 1
small.prob = 1e-8
max.person = sum(Xt_real[1,])
probe.vehicle = trunc(max.person/obs.scale)

for(yy in c(1:RunTimes)) {
  Xt_est = array(0,dim=dim(Xt_real))
  Xi_1 = array(0,dim =c(particles,ncol(Xt_real)))
  Xi_2 = array(0,dim =c(particles,ncol(Xt_real)))
  
  t0=100
  Xt_est[t0,] = Yt[t0,]*obs.scale
  Xi_1 = matrix(rep(Xt_est[t0,],each=particles),nrow=particles)
  
  for(t in c((t0+1):nrow(Xt_real))) {
    print(t)
    #t1 = min(trunc(t/(24*6))+1,14)
    t1 = min(trunc(t/360)+1,4)
    Xi_2[,] = 0
    
    ndx_lane_from = which(colSums(Xi_1)>0)
    #521
    for(j in ndx_lane_from){
      idx = which(m.time[j,,t1]>0)
      if (any(idx)) {
        sample_result = sample.int(length(idx), sum(Xi_1[,j]), replace=TRUE,prob=m.time[j,idx,t1])
        ndx = rep(0, length(sample_result))
        ndx2 = which(Xi_1[,j]>0)
        ndx3 = Xi_1[ndx2,j]
        ndx[ cumsum(c(1,head(ndx3,-1))) ] = 1 #diff(c(0,ndx2))
        ndx = cumsum(ndx)
        Xi_2[ndx2,idx] = Xi_2[ndx2,idx] + matrix(tabulate( ndx+(sample_result-1)*length(ndx2), nbins=length(ndx2)*length(idx) ), nrow=length(ndx2))
      }
      else {
        Xi_2[,j] = Xi_1[,j]
        print('enter no out')
      }
    }
    
    if((t %% step)!=0) {
      Xi_1 = Xi_2
      Xt_est[t,] = round(colMeans(Xi_1))
      #Xt_particles[t,,] = Xi[1,,]
      next
    }
    
    W_lane = obs.matrix[cbind( c(Xi_2[,]+1),rep(Yt[t,]+1, each=particles) )]
    W_lane = matrix(W_lane, nrow=particles)
    
    if(FALSE) {
    a=t(W_lane[c(24,38),])
    b=a[which(a[,1]<0),1]
    c=a[which(a[,2]<0),2]
    d=data.frame(b,c[1:513])
    d=b-c[1:513]
    d[which(d!=0)]
    }
    
    if(TRUE) {
      W = apply(W_lane,1,sum)
      W = exp(W-max(W))
    }
    
    #resampling
    print(sum(W))
    W = W/sum(W)
    resample_particles = sample(c(1:length(W)),particles,replace=TRUE,prob=W)
    #ndx_particles[t,] = resample_particles
    Xi_1 = Xi_2[resample_particles,]
    
    #output estimation state
    Xt_est[t,] = round(colMeans(Xi_1))
  }
  save(Xt_est,file='data_result/Xt_est.RData')
}



#back tracing
# ndx_particles, snapshot, bt_particles
total.time = nrow(person.state.d)
bt_particles = array(0,dim = c(total.time,ncol(person.state.d)))

ndx = ndx_particles*0 # initialization
ndx[total.time,] = 1:ncol(ndx)
for (i in c(total.time:2)) {
  ndx[i-1,] = ndx_particles[i,ndx[i,]]
}
if (FALSE) {
for (i in c(total.time:2)) {
  ndx_particles[(i-1),] = ndx_particles[(i-1),ndx_particles[i,]]
  #ndx_particles[1:(i-1),] = ndx_particles[1:(i-1),ndx_particles[i,]]
}
}

for (i in c(1:total.time)) {
  idx = ndx[i,1]
  name.file = paste('data/snapshot',i,sep = '_')
  name.file = paste(name.file,'RDS',sep = '.')
  Xt_particles = readRDS(name.file)
  bt_particles[i,] = Xt_particles[idx,]
}

save(bt_particles,file = "bt_particles.RData")

Xt_bt = t(apply(bt_particles,1,function(x) table(factor(x, levels=c(1:length(location.ndx)) ))))



#generate snapshot, location
# id, loc.x, loc.y, dir, loc.ndx, time.t
home.ndx = unlist(strsplit(location.ndx[1:length(types)],'@'))[2*(1:length(types))-1]
home.ndx = which(home.ndx == 'home')

loc.x=c()
loc.y=c()
time.t=c()
speed.s=c()
ndx.id=c()
dir=c()
loc.ndx=c()
for (i in c(1:total.time)) {

  print(i)
  person_observe = which(is.na(match(bt_particles[i,],home.ndx)))
  if(length(person_observe)==0) next
  
  tmp.id = person_observe
  tmp.speed = array(10,dim=length(person_observe))
  tmp.t = array(((i-1)*60+min.time),dim = length(person_observe))
  tmp.loc = location.ndx[bt_particles[i,person_observe]]
  
  vehicle_location = bt_particles[i,person_observe]
  vehicle_lane = which(vehicle_location>length(types))
  vehicle_facility = which(vehicle_location<=length(types))
    
  vehicle_location[vehicle_lane] = vehicle_location[vehicle_lane]-length(types)
  vehicle_location[vehicle_facility] = tmp.loc[vehicle_facility]
  vehicle_location[vehicle_facility] = unlist(strsplit(vehicle_location[vehicle_facility],'@'))[2*(1:length(vehicle_facility))]
  
  vehicle_location = as.numeric(vehicle_location)

  point_from = match(network$e$from[vehicle_location],rownames(network$n))
  point_to = match(network$e$to[vehicle_location],rownames(network$n))
  
  tmp.x = (network$n$x[point_from]+network$n$x[point_to])/2
  tmp.y = (network$n$y[point_from]+network$n$y[point_to])/2
  
  tmp.dir = network$n$x[point_to]-network$n$x[point_from]
  
  time.t = c(time.t,tmp.t)
  loc.x = c(loc.x,tmp.x)
  loc.y = c(loc.y,tmp.y)
  speed.s = c(speed.s,tmp.speed)
  ndx.id = c(ndx.id,tmp.id)
  dir = c(dir,tmp.dir)
  loc.ndx = c(loc.ndx,tmp.loc)
}

snapshot.loc1 = data.frame(ndx.id,loc.x,loc.y,speed.s,time.t,dir,loc.ndx)
colnames(snapshot.loc1) = c('id','x','y','s','time','dir','loc_ndx')

saveRDS(snapshot.loc1,file = "snapshot.loc1.RDS")
#saveRDS(snapshot.loc1,file = "snapshot.loc_gt_obs.RDS")

#19860-37920
start.time = 100
end.time = 400
start.ndx = which(snapshot.loc1$time >= (min.time+start.time*60))[1]
end.ndx = which(snapshot.loc1$time > (min.time+end.time*60))[1]
if(is.na(end.ndx))
  end.ndx = nrow(snapshot.loc1)
snapshot.loc2 = snapshot.loc1[start.ndx:end.ndx,]
saveRDS(snapshot.loc2,file = "snapshot.loc2.RDS")



#generate observation visualization Yt
loc.x=c()
loc.y=c()
time.t=c()
speed.s=c()
ndx.id=c()
dir=c()
loc.ndx=c()
for (i in c(1:total.time)) {
  
  print(i)
  person_observe = which(is.na(match(Yt[i,],home.ndx)))
  #person_observe = which(Yt[i,]>0)
  if(length(person_observe)==0) next
  
  tmp.id = person_observe
  tmp.speed = array(10,dim=length(person_observe))
  tmp.t = array(((i-1)*60+min.time),dim = length(person_observe))
  tmp.loc = location.ndx[Yt[i,person_observe]]
  
  vehicle_location = Yt[i,person_observe]
  vehicle_lane = which(vehicle_location>length(types))
  vehicle_facility = which(vehicle_location<=length(types))
  
  vehicle_location[vehicle_lane] = vehicle_location[vehicle_lane]-length(types)
  vehicle_location[vehicle_facility] = tmp.loc[vehicle_facility]
  vehicle_location[vehicle_facility] = unlist(strsplit(vehicle_location[vehicle_facility],'@'))[2*(1:length(vehicle_facility))]
  
  vehicle_location = as.numeric(vehicle_location)
  
  point_from = match(network$e$from[vehicle_location],rownames(network$n))
  point_to = match(network$e$to[vehicle_location],rownames(network$n))
  
  tmp.x = (network$n$x[point_from]+network$n$x[point_to])/2
  tmp.y = (network$n$y[point_from]+network$n$y[point_to])/2
  
  tmp.dir = network$n$x[point_to]-network$n$x[point_from]
  
  time.t = c(time.t,tmp.t)
  loc.x = c(loc.x,tmp.x)
  loc.y = c(loc.y,tmp.y)
  speed.s = c(speed.s,tmp.speed)
  ndx.id = c(ndx.id,tmp.id)
  dir = c(dir,tmp.dir)
  loc.ndx = c(loc.ndx,tmp.loc)
}

snapshot.loc3 = data.frame(ndx.id,loc.x,loc.y,speed.s,time.t,dir,loc.ndx)
colnames(snapshot.loc3) = c('id','x','y','s','time','dir','loc_ndx')

saveRDS(snapshot.loc3,file = "snapshot.loc3.RDS")

#13860-31860
start.time = 100
end.time = 400
start.ndx = which(snapshot.loc3$time >= (min.time+start.time*60))[1]
end.ndx = which(snapshot.loc3$time > (min.time+end.time*60))[1]
if(is.na(end.ndx))
  end.ndx = nrow(snapshot.loc3)
snapshot.loc4 = snapshot.loc3[start.ndx:end.ndx,]
saveRDS(snapshot.loc4,file = "snapshot.loc4.RDS")



#find which columns are choosing from Xt_Real to Yt
a = data.frame(Xt_real)
b = data.frame(Yt)
choosing_columns=match(b,a)
bt_particles = Xt_real[1:total.time,-choosing_columns]















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
  sort(colSums(Xt_real),decreasing = TRUE)[1:10]
  #     7      64     104      11     241      72      99     153      22      81 
  #4451123 3512497  587105  521831  287579  278596  274311  271126  236685  219700 
  #   1009    3176    3175     245    3196    1383    3434     446    3249    2408 
  #3512497  433933  263033  252045  235461  216706  196520  189124  184787  181803 
  
  ndx=1009
  plot_time = c(100:950)
  SMA_scale = 10
  plot(SMA(Xt_real[plot_time,ndx],SMA_scale),type='l',ylim=c(2920,3080))
  lines(SMA(Xt_est[plot_time,ndx],SMA_scale),type='l',col='red')
  lines(SMA(Yt[plot_time,ndx]*10,SMA_scale),type='l',col='blue')
  legend('topleft',legend=c('groundtruth','estimation','observation'),lty=c(1,1,1),col=c('black','red','blue'))
  
  SMA_scale = 1
  ndx = as.numeric(names(sort(colSums(Xt_real),decreasing = TRUE)[9]))
  plot(SMA(Xt_real[,ndx],SMA_scale),type='l')
}

bias1 = sum(abs(Xt_real_1 - Xt_est_1k))
bias2 = sum(abs(Xt_real_1 - Xt_est_10k))








