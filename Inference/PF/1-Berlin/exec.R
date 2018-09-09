
library('Matrix')
require('TTR')
require('igraph')
require('survey')
require('grr')
require('RcppEigen')
require('Rcpp')
library(ggplot2)

load("data_exec/Xt_real.RData")
load("data_exec/m.time.RData")
load("data_exec/obs.matrix.RData")
load('data_prep/person.state.d.RData')
load('data_exec/Yt.RData')

# particle fitering
RunTimes = 300
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
    print(t)
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
    
    if (FALSE) {
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
    #W_particles[t,] = W
    resample_particles = sample(c(1:length(W)),particles,replace=TRUE,prob=W)
    ndx_particles[t,] = resample_particles
    Xi_1 = Xi_2[resample_particles,]
    
    #output estimation state
    Xt_est[t,] = round(colMeans(Xi_1))
    name.file = paste('data/snapshot',t,sep = '_')
    name.file = paste(name.file,'RDS',sep = '.')
    saveRDS(Xi_1,file = name.file)
  }
  
  #box plot particle results, 1 run
  if (FALSE) {
    #> sort(colSums(Xt_real),decreasing = TRUE)[1:10]
    #home@31  home@20  home@98  home@32 home@137   home@2  home@95   home@5  home@49  home@46 
    #1086263   390163   360099   323615   239915   233460   207538   204146   203821   190954 
    
    plot_lane=31
    SMA_scale = 10
    plot(SMA(Xt_real[,plot_lane],SMA_scale),type='l')
    lines(SMA(Xt_est[,plot_lane],SMA_scale),type='l',col='red')
    lines(SMA(Yt[,plot_lane]*obs.scale,SMA_scale),type='l',col='blue')
    
    #sum
    plot_lane = c(2:10+2)
    a = apply(Xt_real[,plot_lane],1,sum)
    b = apply(Xt_est[,plot_lane],1,sum)
    c = apply(Yt[,plot_lane]*obs.scale,1,sum)
    plot(SMA(a,SMA_scale),type='l')
    lines(SMA(b,SMA_scale),type='l',col='red')
    lines(SMA(c,SMA_scale),type='l',col='blue')
    #legend(legend=c('ground truth','estimation','observation scaled'),lty=c(1,1,1),col=c('black','red','blue'))
    
    total.time = nrow(person.state.d)
    bt_particles = array(0,dim = c(total.time,ncol(m.time),particles))
    for (i in c(1:total.time)) {
      print(i)
      name.file = paste('data/snapshot',i,sep = '_')
      name.file = paste(name.file,'RDS',sep = '.')
      Xt_particles = readRDS(name.file)
      bt_particles[i,,] = t(Xt_particles)
    }
    tt = seq(from=1,to=23,by=2)*60
    bt_particles = bt_particles[tt,,]
    for (plot_lane in c(1:25)) {
      print(plot_lane)
      boxthis = {}
      seq1 = {}
      for (i in c(1:nrow(bt_particles))) {
        tmp_box = bt_particles[i,plot_lane,]
        boxthis = c(boxthis,tmp_box)
      }
      seq1 = rep(c(1:12),each=(length(boxthis)/12))
      seq1 = factor(seq1)
      target = data.frame(boxthis,seq1)
      title = '1k particles, after resampling particles'
      a = ggplot() + geom_boxplot(aes(y = boxthis, x = seq1), data = target) + labs(title = title,x='time period',y='number of vehicles')
      #add groundtruth
      y=Xt_real[c(min(tt):max(tt)),plot_lane]
      x=seq(from=1,to=12,length.out =length(y))
      ground_truth = data.frame(x=x,y=y)
      a + geom_line(data = ground_truth, aes_string(x=ground_truth$x, y=ground_truth$y),col='black')
      name = paste(title,plot_lane,sep='_')
      name = paste('ob10 all lanes without facilities','jpg',sep = '.')
      dev.copy(file=name, device=jpeg, quality=100, width=1024, height=1024)
      dev.off()
    }
    bt_100 = bt_particles
    bt_1k = bt_particles
    bt_10k = bt_particles
  }
  
  #back tracing
  # ndx_particles, snapshot, bt_particles
  if (FALSE) {
    total.time = nrow(person.state.d)
    bt_particles = array(0,dim = c(total.time,ncol(m.time),particles))
    
    if (FALSE) {
      ndx = ndx_particles*0 # initialization
      ndx[total.time,] = 1:ncol(ndx)
      for (i in c(total.time:2)) {
        #print(i)
        ndx[i-1,] = ndx_particles[i,ndx[i,]]
      }
    }
    for (i in c(1:total.time)) {
      #print(i)
      #idx = ndx[i,]
      name.file = paste('data/snapshot',i,sep = '_')
      name.file = paste(name.file,'RDS',sep = '.')
      Xt_particles = readRDS(name.file)
      bt_particles[i,,] = t(Xt_particles)
    }
    name.file = paste('data_result/run2/bt_particles',yy,sep = '_')
    name.file = paste(name.file,'RDS',sep = '.')
    saveRDS(bt_particles,file = name.file)
    name.file = paste('data_result/run2/W_particles',yy,sep = '_')
    name.file = paste(name.file,'RDS',sep = '.')
    saveRDS(W_particles,file=name.file)
  }
  #back tracing
  if (TRUE) {
    total.time = nrow(person.state.d)
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
    name.file = paste('data_result/run2/Xt_particles',yy,sep = '_')
    name.file = paste(name.file,'RDS',sep = '.')
    saveRDS(Xt_particles,file = name.file)
    name.file = paste('data_result/run2/W_particles',yy,sep = '_')
    name.file = paste(name.file,'RDS',sep = '.')
    saveRDS(W_particles,file=name.file)
    name.file = paste('data_result/run2/bt_particles',yy,sep = '_')
    name.file = paste(name.file,'RDS',sep = '.')
    saveRDS(bt_particles,file=name.file)
  }
}

#compute Zt and trajectories (Xt_all)
if (TRUE) {
  
  ComputZt = function(Xt_particles,obs.lanes,particles) {
    Z_lane <- obs.matrix[cbind( c(Xt_particles[,obs.lanes,]+1),rep( c(Yt[,obs.lanes]+1), times=particles) )]
    Z_lane <- array(Z_lane, dim=c(dim(Xt_particles)[1],length(obs.lanes),particles))
    Z1 <- apply(Z_lane, c(1,3), sum)    #multiply lanes
    Z2 <- apply(exp(Z1),1,sum)          #add particles
    Z3 <- sum(log(Z2))                  #multiply in time
    list(Z_lane=Z_lane,Z1=Z1,Z2=Z2,Z3=Z3)
  }
  
  LoadResult_Particle = function(direction,i,obs.lanes,particles) {
    name.file <- paste(direction,i,sep = '_')
    name.file <- paste(name.file,'RDS',sep = '.')
    Xt_particles <- readRDS(name.file)
    # compute weight
    Zt=ComputZt(Xt_particles,obs.lanes,particles)
    list(Xt=Xt_particles,Zt=Zt$Z3)
  }
  
  Xt_all = array(0,dim=c(dim(Xt_real),RunTimes))
  direction = 'data_result/tra100_ob2_p1k_yt50/bt_particles'
  Zt = array(0,dim=RunTimes)
  for (i in c(1:RunTimes)) {
    print(i)
    result=LoadResult_Particle(direction,i,obs.lanes,particles)
    Xt_all[,,i] = result$Xt[,,1]
    Zt[i] = result$Zt
  }
  save(Zt,file='data_result/tra100_ob2_p1k_yt50/Zt.RData')
  save(Xt_all,file='data_result/tra100_ob2_p1k_yt50/Xt_all.RData')
}

#plot filtering
if (TRUE) {
  Xt_all = array(0,dim=c(dim(Xt_real),particles,RunTimes))
  direction = 'data_result/run2/Xt_particles'
  for (i in c(1:RunTimes)) {
    print(i)
    result=LoadResult_Particle(direction,i,obs.lanes,particles)
    Xt_all[,,,i] = result$Xt
  }
  save(Xt_all,file='data_result/run2/Xt_all.RData')
  
  #plot
  load('data_result/run2/Xt_all.RData')
  tt = seq(from=1,to=23,by=2)*60
  Xt_all = Xt_all[tt,,,]
  
  print(plot_lane)
  boxthis = {}
  seq1 = {}
  seq2 = {}
  label = {}
  for (i in c(1:nrow(Xt_all))) {
    tmp_box = c(Xt_all[i,plot_lane,,1],Xt_all[i,plot_lane,,2],Xt_all[i,plot_lane,,3])
    tmp_seq2 = rep(c(1:3),each=(length(tmp_box)/3))
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
  
  a = ggplot() + geom_boxplot(aes(y = boxthis, x = seq1,fill=method), data = target) + labs(title = "100 particles filtering, observe lane 1, 20",x='time period',y='number of vehicles')
  
  #add groundtruth
  y=Xt_real[c(min(tt):max(tt)),plot_lane]
  x=seq(from=1,to=12,length.out =length(y))
  ground_truth = data.frame(x=x,y=y)
  a + geom_line(data = ground_truth, aes_string(x=ground_truth$x, y=ground_truth$y),col='black')
  
  name = paste('100*1home','jpg',sep = '.')
  dev.copy(file=name, device=jpeg, quality=100, width=1024, height=1024)
  dev.off()
}

#plot new
if (TRUE) {
  if (TRUE) {
    #Xt_all contains all trajectories, Zt contains all weights
    tt = seq(from=1,to=23,by=2)*60
    time_period = c(1:1440)
    numbers = 10000
    Xt_weight = array(0,dim=c(length(tt),ncol(Xt_all),numbers,3))
    
    #sampling
    Zt = matrix(Zt,nrow = 3, byrow = TRUE)
    for (i in c(1:3)) {
      print(i)
      W2 = exp(Zt[i,]-max(Zt[i,]))
      W = W2/sum(W2)
      resample_particles = sample(c(1:length(W)),numbers,replace=TRUE,prob=W)+(i-1)*dim(Xt_all)[3]/3
      Xt_weight[,,,i] = Xt_all[tt,,resample_particles]
    }
    
  }
  
  for (plot_lane in c(1:25)) {
    print(plot_lane)
    
    boxthis = {}
    seq1 = {}
    seq2 = {}
    label = {}
    for (i in c(1:nrow(Xt_weight))) {
      tmp_box = c(Xt_weight[i,plot_lane,,1],Xt_weight[i,plot_lane,,2],Xt_weight[i,plot_lane,,3])
      tmp_seq2 = rep(c(1:3),each=(length(tmp_box)/3))
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
    
    a = ggplot() + geom_boxplot(aes(y = boxthis, x = seq1,fill=method), data = target) + labs(title = "10 trajectories,10k particles, observe lane 1, 20",x='time period',y='number of vehicles')
    
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
    name = paste('10_1kparticles_ob1&20',plot_lane,sep = '@')
    name = paste(name,'jpg',sep = '.')
    dev.copy(file=name, device=jpeg, quality=100, width=1024, height=1024)
    dev.off()
  }
}

#test
if(FALSE) {
  
  # plot Zt for 100,1k,10k particles for 100 trajectories
  if (TRUE) {
    load('data_result/tra100_ob2_p10k_yt50/run1/Xt_all.RData')
    load('data_result/tra100_ob2_p10k_yt50/run1/Zt.RData')
    load('data_result/tra100_ob2_p1k_yt50/Xt_all.RData')
    load('data_result/tra100_ob2_p1k_yt50/Zt.RData')
    load('data_result/tra100_ob2_p100_yt50/run2/Xt_all.RData')
    load('data_result/tra100_ob2_p100_yt50/run2/Zt.RData')
    
    names(Zt) = c(1:length(Zt))
    weights = sort(Zt,decreasing = TRUE)
    index = weights[c(1,length(weights)/2)]
    direction = 'data_result/tra100_ob2_p10k_yt50/run1/bt_particles'
    direction = 'data_result/tra100_ob2_p1k_yt50/bt_particles'
    direction = 'data_result/tra1k_ob2_p100_yt50/run2/bt_particles'
    particles = 1e3
    result1 = LoadResult_Particle(direction,names(index[1]),obs.lanes,particles)
    result2 = LoadResult_Particle(direction,names(index[2]),obs.lanes,particles)
    test.Zt1 = ComputZt(result1$Xt,obs.lanes,particles)
    test.Zt2 = ComputZt(result2$Xt,obs.lanes,particles)

    #normalize
    test.Zt1$Z2 = test.Zt1$Z2/particles
    test.Zt2$Z2 = test.Zt2$Z2/particles
    Zt_cmp = matrix(c(test.Zt1$Z2,test.Zt2$Z2),ncol=2)
    
    #plot
    title = 'SMA weight of 100 particles trajectories: higheset weight, median'
    SMA_scale = 10
    plot(SMA(Zt_cmp[,1],SMA_scale),type='l',xlab='time',ylab='Zt',main=title)
    lines(SMA(Zt_cmp[,2],SMA_scale),type='l',col='red')
    legend('bottomright',legend=paste('weight',c(1,50),sep='@'),lty=c(1,1),col=c('black','red'))
    
    name = paste('SMA_100particles_highest_1-3','jpg',sep = '.')
    dev.copy(file=name, device=jpeg, quality=100, width=1024, height=1024)
    dev.off()
    
    # compare three cases
    abc100 = Zt_cmp[,1]
    abc1k = Zt_cmp[,1]
    abc10k = Zt_cmp[,1]
    abcgt = Z2

    title = 'SMA 10 weight of ground truth and 100,1k,10k particles trajectories'
    plot(SMA(abcgt,SMA_scale),type='l',xlab='time',ylab='Zt',main=title)
    lines(SMA(abc100,SMA_scale),type='l',col='blue')
    lines(SMA(abc1k,SMA_scale),type='l',col='red')
    lines(SMA(abc10k,SMA_scale),type='l',col='green')
    legend('bottomright',legend=paste('particles',c('gt','100','1k','10k'),sep='@'),lty=c(1,1,1),col=c('black','red','blue','green'))
    name = paste(title,'jpg',sep = '.')
    dev.copy(file=name, device=jpeg, quality=100, width=1024, height=1024)
    dev.off()
    
    #effective particles
    W_particles = readRDS('data_result/tra_100p_10u//W_particles_3.RDS')
    particle_density = W_particles
    for (i in c(1:nrow(particle_density))) {
      particle_density[i,] = exp(particle_density[i,]-max(particle_density[i,]))
      particle_density[i,] = particle_density[i,]/sum(particle_density[i,]) 
    }
    particle_density = particle_density^2
    PDt = apply(particle_density, 1, sum)
    PDt = 1/PDt
    title = 'effective particles in 100 particles filtering'
    plot(PDt,type='l',log='y',main = title)
  }
  
  #normalize weight
  if (TRUE) {
    
    ComputZt = function(Xt_particles,obs.lanes,particles) {
      Z_lane <- obs.matrix[cbind( c(Xt_particles[,obs.lanes,]+1),rep( c(Yt[,obs.lanes]+1), times=particles) )]
      Z_lane <- array(Z_lane, dim=c(dim(Xt_particles)[1],length(obs.lanes),particles))
      Z1 <- apply(Z_lane, c(1,3), sum)    #multiply lanes
      Z2 <- apply(exp(Z1),1,sum)          #add particles
      Z3 <- sum(log(Z2))                  #multiply in time
      list(Z_lane=Z_lane,Z1=Z1,Z2=Z2,Z3=Z3)
    }
    
    LoadResult_Particle = function(direction,i,obs.lanes,particles) {
      name.file <- paste(direction,i,sep = '_')
      name.file <- paste(name.file,'RDS',sep = '.')
      Xt_particles <- readRDS(name.file)
      # compute weight
      Zt=ComputZt(Xt_particles,obs.lanes,particles)
      list(Zt2 = Zt$Z2, Zt3=Zt$Z3)
    }
    Xt_all = array(0,dim=c(dim(Xt_real),RunTimes))
    
    direction = 'data_result/tra100_ob2_p10k_yt50/run1/bt_particles'
    direction = 'data_result/tra100_ob2_p1k_yt50/run2/bt_particles'
    direction = 'data_result/tra1k_ob2_p100_yt50/run2/bt_particles'
    particles = 1e3
    RunTimes = 100
    Zt_1e4 = array(0,dim=c(RunTimes,1441))
    Zt_4 = array(0,dim=RunTimes)
    
    for (i in c(1:RunTimes)) {
      print(i)
      result=LoadResult_Particle(direction,i,obs.lanes,particles)
      Zt_1e4[i,] = result$Zt2
      Zt_4[i] = result$Zt3
    }
    
    #save
    save(Zt_1e4,file='data_result/tra100_ob2_p10k_yt50/run1/Zt2.RData')
    save(Zt_1e4,file='data_result/tra100_ob2_p1k_yt50/run2/Zt2.RData')
    save(Zt_1e4,file='data_result/tra1k_ob2_p100_yt50/run2/Zt2.RData')
    
    #plot
    title = 'SMA weight of 100 particles trajectories: higheset weight, median'
    SMA_scale = 100
    plot(SMA(Zt_cmp[,1],SMA_scale),type='l',xlab='time',ylab='Zt',main=title)
    lines(SMA(Zt_cmp[,2],SMA_scale),type='l',col='red')
    legend('bottomright',legend=paste('weight',c(1,50),sep='@'),lty=c(1,1),col=c('black','red'))
    name = paste('SMA_100particles_highest_1-3','jpg',sep = '.')
    dev.copy(file=name, device=jpeg, quality=100, width=1024, height=1024)
    dev.off()
    
  }
  
  # look into large weight trajectory, stage 1, find time points
  if (TRUE) {
    names(Zt) = rep(c(1:(length(Zt)/3)),times=3)
    W = Zt[c(1:(length(Zt)/3))]
    weights = sort(W,decreasing = TRUE)
    index = weights[c(1,length(weights)/2)]
    index = weights[c(1:3)]
    direction = 'data_result/run2/bt_particles'
    result1 = LoadResult_Particle(direction,names(index[1]),obs.lanes,particles)
    result2 = LoadResult_Particle(direction,names(index[2]),obs.lanes,particles)
    result3 = LoadResult_Particle(direction,names(index[3]),obs.lanes,particles)
    test.Zt1 = ComputZt(result1$Xt,obs.lanes,particles)
    test.Zt2 = ComputZt(result2$Xt,obs.lanes,particles)
    test.Zt3 = ComputZt(result3$Xt,obs.lanes,particles)
    

    #normalize
    Zt_cmp = matrix(c(test.Zt1$Z2,test.Zt2$Z2,test.Zt3$Z2),ncol=3)
    Zt_cmp = matrix(c(test.Zt1$Z2,test.Zt2$Z2),ncol=2)
    
    #difference
    difference = test.Zt1$Z2-test.Zt2$Z2
    names(difference) = c(1:length(difference))
    sort(difference,decreasing = TRUE)[1:10]
    
    #plot
    title = 'Weight of trajectories with higheset 1-3 weights'
    #title = 'Weight of trajectories: higheset weight, median'
    plot(Zt_cmp[,1],type='l',xlab='time',ylab='Zt',main=title)
    lines(Zt_cmp[,2],type='l',col='red')
    #legend('bottomright',legend=paste('weight',c(1,50),sep='@'),lty=c(1,1),col=c('black','red'))
    lines(Zt_cmp[,3],type='l',col='blue')
    legend('bottomright',legend=paste('weight',c(1,2,3),sep='@'),lty=c(1,1),col=c('black','red','blue'))
    
    #SMA
    if (FALSE) {
      title = 'SMA weight of trajectories with higheset 1-3 weights'
      #title = 'SMA weight of trajectories: higheset weight, median'
      SMA_scale = 10
      plot(SMA(Zt_cmp[,1],SMA_scale),type='l',xlab='time',ylab='Zt',main=title)
      lines(SMA(Zt_cmp[,2],SMA_scale),type='l',col='red')
      #legend('bottomright',legend=paste('weight',c(1,50),sep='@'),lty=c(1,1),col=c('black','red'))
      lines(SMA(Zt_cmp[,3],SMA_scale),type='l',col='blue')
      legend('bottomright',legend=paste('weight',c(1,2,3),sep='@'),lty=c(1,1,1),col=c('black','red','blue'))
    }
    
    #save
    #name = paste('SMA_run1_highest_median','jpg',sep = '.')
    name = paste('SMA_run1_highest_1-3','jpg',sep = '.')
    dev.copy(file=name, device=jpeg, quality=100, width=1024, height=1024)
    dev.off()
  }
  
  #stage 2, looking at time point 645-650
  if (TRUE) {
    time.points = c(1371:1372)
    time.obs = c(2:5)   #1371-1374
    t1 = 4
    m = m.time[obs.lanes,,t1]
    gt = Xt_real[time.points,obs.lanes]
    est = Xt_all[time.points,obs.lanes,c(1:100)]
    rand_pick = unique(c(as.integer(c(names(index))),sample(c(1:100),10)))
    est = est[,,rand_pick]
    est[,,]
    
    #using index, obs.matrix
    Zt_cmp.run1 = Zt_cmp[time.points,]
    
    plot(time.points,Zt_cmp.run1[,1],type='l',xlab = 'time', ylab = 'Zt', ylim = c(10,100), main = 'Zt for highest weight 1-2')
    lines(time.points,Zt_cmp.run1[,2],type='l',col='red')
    legend('bottomright',legend=paste('weight',c(1,2),sep='@'),lty=c(1,1),col=c('black','red'))
    
    name = paste('run1_1370-1375','jpg',sep = '.')
    dev.copy(file=name, device=jpeg, quality=100, width=1024, height=1024)
    dev.off()
    
    table(person.state.d[time.points[1],],person.state.d[time.points[2],])
    table(factor(person.state.d[time.points[1],],levels = c(1:25)),factor(person.state.d[time.points[2],],levels = c(1:25)))
    m.time[,25,t1]
    table(factor(person.state.d[time.points[1],],levels = c(1:25)))
    table(factor(person.state.d[time.points[2],],levels = c(1:25)))
    
    a=table(person.state.d[time.points[1],],person.state.d[time.points[2],])
    b=m[cbind(c(3,23,24),c(1,24,25))]
    c=prod(b)*m[1,1]^1963*m[2,2]^31*m[24,24]^2*m[25,25]
  }
}









