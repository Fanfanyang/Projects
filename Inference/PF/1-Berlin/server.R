
library('Matrix')
require('TTR')
require('igraph')
require('survey')
require('grr')
require('RcppEigen')
require('Rcpp')

load("data_exec/Xt_real.RData")
load("data_exec/m.time.RData")
load("data_exec/obs.matrix.RData")
load('data_exec/person.state.d.RData')
load('data_exec/Yt.RData')

# particle fitering
RunTimes = 3
obs.scale = 10
particles = 1e3
par_inc = 1
#obs.lanes = c(3:ncol(Xt_real))
obs.lanes = c(1276:ncol(Xt_real))
time.th = 231-2
step = 1
small.prob = 1e-8
lane.nums = dim(m.time)[1]

for(yy in c(1:RunTimes)) {
    print(yy)
    W_particles = array(0,dim=c(nrow(Xt_real),particles*par_inc))
    Xt_est = array(0,dim=c(nrow(Xt_real),lane.nums))
    Xi_1 = array(0,dim =c(particles,lane.nums))
    Xi_2 = array(0,dim =c(particles*par_inc,lane.nums))
    ndx_particles = array(1,dim = c(nrow(person.state.d),particles))
    
    t0=1
    W_particles[1,] = array(1/particles,dim=particles)
    Xt_est[t0,1:ncol(Yt)] = Yt[t0,]*obs.scale
    Xi_1 = matrix(rep(Xt_est[t0,],each=particles),nrow=particles)
    saveRDS(Xi_1,file = "data/snapshot_1.RDS")
    
    for(t in c((t0+1):nrow(Xt_real))) {
        #print(t)
        #t1 = min(trunc((t-1)/60)+1,24)
        t1 = min(trunc((t+time.th)/60)-2,23)
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
        #print(sum(W))
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
    
    #back tracing
    if (TRUE) {
        tt = seq(from=1,to=22,by=2)*60
        total.time = nrow(person.state.d)
        Xt_particles = array(0,dim = c(length(tt),ncol(m.time),particles))
        bt_particles = array(0,dim = c(length(tt),ncol(m.time),particles))
        
        if (TRUE) {
            ndx_particles = trunc((ndx_particles-1)/par_inc)+1
            ndx = ndx_particles*0 # initialization
            ndx[total.time,] = 1:ncol(ndx)
            for (i in c(total.time:2)) {
                #print(i)
                ndx[i-1,] = ndx_particles[i,ndx[i,]]
            }
        }
        for (i in c(1:length(tt))) {
            #print(i)
            idx = ndx[tt[i],]
            name.file = paste('data/snapshot',tt[i],sep = '_')
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

#compute Xt_all and Zt
if (FALSE) {
    LoadResult_Particle = function(direction,i) {
        name.file <- paste(direction,i,sep = '_')
        name.file <- paste(name.file,'RDS',sep = '.')
        Xt_particles <- readRDS(name.file)
        list(Xt=Xt_particles)
    }
    
    Xt_all = array(0,dim=c(dim(Xt_real),RunTimes))
    direction = 'data_result/run1/bt_particles'
    for (i in c(1:RunTimes)) {
        print(i)
        result=LoadResult_Particle(direction,i)
        Xt_all[,,i] = result$Xt[,,1]
    }
    
    Zt = array(0,dim=RunTimes)
    Zt2 = array(0, dim=c(nrow(Xt_real),RunTimes))
    direction = 'data_result/run1/W_particles'
    for (i in c(1:RunTimes)) {
        print(i)
        result=LoadResult_Particle(direction,i)
        tmp = exp(result$Xt)
        Zt2[,i] = apply(tmp,1,sum)   #normal, exp
        Zt[i] = sum(log(Zt2[,i]))    # log
    }
    
    save(Zt,file='data_result/run1/Zt.RData')
    save(Xt_all,file='data_result/run1/Xt_all.RData')
}

#plot trajectories
if (FALSE) {
  #Xt_all contains all trajectories, Zt contains all weights
  tt = seq(from=1,to=22,by=2)*60
  time_period = c(1:1440)
  numbers = 10000
  group=3
  Xt_weight = array(0,dim=c(length(tt),ncol(Xt_all),numbers,group))
  
  #sampling
  Zt = matrix(Zt,nrow = group, byrow = TRUE)
  for (i in c(1:group)) {
    print(i)
    W2 = exp(Zt[i,]-max(Zt[i,]))
    W = W2/sum(W2)
    resample_particles = sample(c(1:length(W)),numbers,replace=TRUE,prob=W)+(i-1)*dim(Xt_all)[3]/group
    Xt_weight[,,,i] = Xt_all[tt,,resample_particles]
  }
  
  for (plot_lane in c(1:25)) {
    print(plot_lane)
    
    boxthis = {}
    seq1 = {}
    seq2 = {}
    label = {}
    for (i in c(1:nrow(Xt_weight))) {
      tmp_box = c(Xt_weight[i,plot_lane,,1],Xt_weight[i,plot_lane,,2],Xt_weight[i,plot_lane,,3])
      #tmp_box = c(Xt_weight[i,plot_lane,,1],Xt_weight[i,plot_lane,,2])
      tmp_seq2 = rep(c(1:group),each=(length(tmp_box)/group))
      boxthis = c(boxthis,tmp_box)
      seq2 = c(seq2,tmp_seq2)
    }
    
    seq1 = rep(c(1:12),each=(length(boxthis)/12))
    label = interaction(seq1,seq2)
    
    seq1 = factor(seq1)
    seq2 = factor(seq2)
    method = seq2
    levels(method) = c('run1','run2','run3')
    target = data.frame(boxthis,label,seq1,method)
    
    a = ggplot() + geom_boxplot(aes(y = boxthis, x = seq1,fill=method), data = target) + labs(title = "100 trajectories,100 particles, observe lane 1, 20",x='time period',y='number of vehicles')
    
    #add groundtruth
    y=Xt_real[c(min(tt):max(tt)),plot_lane]
    #y = SMA(y,100)
    #y = y[!is.na(y)]
    #y = c(rep(y[1],50),y,rep(y[length(y)],50))
    x=seq(from=1,to=12,length.out =length(y))
    ground_truth = data.frame(x=x,y=y)
    a + geom_line(data = ground_truth, aes_string(x=ground_truth$x, y=ground_truth$y),col='black')
    
    #groundtruth at tt
    if (FALSE) {
      y2 = Xt_real[tt,plot_lane]
      x2 = c(1:12)
      ground_truth = data.frame(x=x2,y=y2)
      a + geom_point(data = ground_truth, aes_string(x=ground_truth$x, y=ground_truth$y),col='purple')
    }
    name = paste('100particles_ob1&20',plot_lane,sep = '@')
    name = paste(name,'jpg',sep = '.')
    dev.copy(file=name, device=jpeg, quality=100, width=1024, height=1024)
    dev.off()
  }
}

# effective particles
if (FALSE) {
  if (FALSE) {
    #W_t^i
    W_particles0 = Zt2[,c(1:particles)]
    for(i in c(1:nrow(W_particles0))) {
      W_particles0[i,] = W_particles0[i,]/sum(W_particles0[i,])
    }
    particle_density = W_particles0^2
    #particle_density = (exp(test.Zt1$Z1)/test.Zt1$Z2)^2
    PDt = apply(particle_density, 1, sum)
    PDt = 1/PDt
    plot(PDt,type='l',log='y')
  }
  
  #should be
  1/sum(W^2)
}
























