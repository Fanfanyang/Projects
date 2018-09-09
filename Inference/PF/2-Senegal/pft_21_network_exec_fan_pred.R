
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
load('../bench_senegal1/data_result/Xt_est.RData')
Xt_est_track = Xt_est

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
pred.window = 10
pred.times = trunc((nrow(Xt_real)-1)/pred.window)

for(yy in c(1:RunTimes)) {
  print(yy)
  
  Xt_est = array(0,dim=c(nrow(Xt_real),lane.nums))
  Xi_1 = array(0,dim =c(particles,lane.nums))
  Xi_2 = array(0,dim =c(particles*par_inc,lane.nums))
  Xt_est[1,1:ncol(Yt)] = Yt[1,]*obs.scale
  
  for (pp in c(1:pred.times)) {
      t0=1+(pp-1)*pred.window
      Xi_1 = matrix(rep(Xt_est_track[t0,],each=particles),nrow=particles)
      Xt_pred = array(0,dim=c(pred.window,ncol(Xt_real)))
      if (pp==1)
      Xt_pred[1,] = Xt_est[1,]
      
      for(t in c((t0+1):(t0+pred.window))) {
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
          if(TRUE) {
              Xi_1 = Xi_2
              Xt_est[t,] = colMeans(Xi_1)
              Xt_pred[t-t0,] = colMeans(Xi_1)
              next
          }
      }
      name.file = paste('data_result/pred',pred.window,sep='_')
      name.file = paste(name.file,'Xt_pred',sep='/')
      name.file = paste(name.file,pp,sep = '_')
      name.file = paste(name.file,'RDS',sep = '.')
      saveRDS(Xt_pred,file = name.file)
  }
  name.file = paste('data_result/Xt_est',pred.window,sep='_')
  name.file = paste(name.file,'RData',sep = '.')
  save(Xt_est,file=name.file)
}
















