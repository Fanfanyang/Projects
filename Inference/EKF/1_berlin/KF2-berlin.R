library(ggplot2)
library('Matrix')
require('TTR')
require('igraph')
require('survey')
require('grr')
library(MASS)
require('numDeriv')
require('mvtnorm')

# load data
if (TRUE) {
  load("data_exec/Xt_real.RData")
  load("data_exec/m.time.RData")
  load("data_exec/obs.matrix.RData")
  load('data_prep/person.state.d.RData')
  load('data_exec/Yt.RData')
  load('data_exec/S2.RData')
}

#obs.matrix,mu.obs, Yt scale 2
if (TRUE) {
  obs.matrix = exp(obs.matrix)
  colnames(obs.matrix) = c(1:ncol(obs.matrix))
  rownames(obs.matrix) = c(1:nrow(obs.matrix))
  N = nrow(obs.matrix)
  mu.obs = array(0,dim = N)
  mu.obs = apply(obs.matrix, 1, function(x) sum(x*c(1:ncol(obs.matrix)-1)))
  var.obs = array(0,dim = N)
  var.tmp = matrix(rep(c(1:ncol(obs.matrix)-1),each=nrow(obs.matrix)),nrow = nrow(obs.matrix))
  var.tmp = apply(var.tmp, 2, function(x) x-mu.obs)
  var.tmp = var.tmp^2
  var.obs = rowSums(var.tmp*obs.matrix)
}


### method 3: to construct Kalman filter

#EKF = function(Y, f, h, dfdX, dhdX, Q, R, X0, P0)
# updating R
if (TRUE) {
    scale = 10
    time.th = 231-2
    obs.lanes = c(1276:ncol(Xt_real))
    from.to = cbind(which(S==-1, arr.ind=TRUE)[,1],which(S==1, arr.ind=TRUE)[,1])
    
    #input
    Y=Yt[,obs.lanes]*1
    f = function(t, X, W=0, Theta) X+S%*%(m.time[cbind(from.to ,min(trunc((t+time.th)/60)-2,23))]*X[which(S==-1, arr.ind=TRUE)[,1]])
    h = local(function(t, X, W=0, Theta) C %*% X/scale, envir=list(C=diag(nrow(S))[obs.lanes,]))
    Q=function(t, X, W, Theta){
      val_diag <- m.time[cbind(from.to ,min(trunc(t/60)+1,24))]*X[which(S==-1, arr.ind=TRUE)[,1]]
      val_S <- sweep(S,2,STATS = val_diag,FUN = '*')
      return(val_S %*% t(S))
      #S %*% diag(m.time[cbind(from.to ,min(trunc(t/60)+1,24))]*X[which(S==-1, arr.ind=TRUE)[,1]]) %*% t(S) 
    }
    R= function(t, X, W, Theta) {
        #R_matrix = diag(length(obs.lanes))*2
        value = var.obs[abs(X)+1]
        value = var.obs[pmin( round(abs(X)+2), length(var.obs))]
        diag(value,length(obs.lanes),length(obs.lanes))
    }
    X0=c(Xt_real[1,])
    P0=diag(nrow(S))*.1
    
    #EKF
    K = matrix(0,nrow=length(X0),ncol=ncol(Y)) # Kalman gain
    mu.update = mu.predict = matrix(0, ncol=length(X0), nrow=nrow(Y))
    mu.update[1,] = mu.predict[1,] = X0
    F = P.predict = P.update = array(0, dim=c(length(X0),length(X0)))
    P.predict = P.update = P0
    
    #dfdX = function(t, X, W, Theta)
    #  jacobian(function(X, t, W, Theta) f(t, X, W, Theta), X, t=t, W=W, Theta=Theta)
    #dhdX = function(t, X, W, Theta)
    #  jacobian(function(X, t, W, Theta) h(t, X, W, Theta), X, t=t, W=W, Theta=Theta)
    
    dfdX = local({
      drdx = 0*t(S)
      ndx = which(S==-1, arr.ind=TRUE)
      function(t, X, W, Theta){
        drdx[ndx[,2:1]] <<- m.time[cbind(from.to, min(trunc(t/60)+1,24))]
        diag(rep(1,nrow(S))) + S %*% drdx
      }
    })
    dhdX = local(function(t, X, W=0, Theta) C /scale, envir=list(C=diag(nrow(S))[obs.lanes,]))
    
    
    for(i in 2:nrow(Y)){
        print(i)
        F = dfdX(i, mu.update[i-1,])
        H = dhdX(i, mu.update[i-1,])
        mu.predict[i,] = f(i, mu.update[i-1,])
        P.predict = F %*% P.update %*% t(F) + Q(i, mu.update[i-1,])
        K = P.predict %*% t(H) %*% ginv( H %*% P.predict %*% t(H) + R(i, mu.update[i-1,obs.lanes]))
        P.update = P.predict - K %*% H %*% P.predict
        mu.update[i,] = mu.predict[i,] + K %*% (Y[i,]- h(t, mu.predict[i,]))
    }
    
    xyz = list(mu=mu.update, P=P.update, mu.predict=mu.predict, P.predict=P.predict, F=F)
    saveRDS(mu.update,file='data_result/Xt_ekf.RDS')
  
  #test
  if (FALSE) {
    plot_lane = 1
    plot(xyz$P[plot_lane,plot_lane,c(1:1441)],type='l',col='red',log = 'y') 
    
    load('../../particle_filtering/0_toy/bench_try1/data_exec/Xt_real.RData')
    time_period = c(1:1441)
    SMA_scale = 10
    plot_lane = 1
    title = paste('EKF observe ',length(obs.lanes),sep=' ')
    plot(SMA(xyz$mu[time_period,plot_lane],SMA_scale),type='l',col='red',main = title) 
    lines(SMA(Xt_real[time_period,plot_lane],SMA_scale),type='l',col='black')
    legend('topleft',legend=c('EKF','GT'),col=c('red','black'),lty=c(1,1))
    
    name = paste('EKF_ob1&20',plot_lane,sep = '@')
    name = paste(name,'jpg',sep = '.')
    dev.copy(file=name, device=jpeg, quality=100, width=1024, height=1024)
    dev.off()
  }
}

#EKS
EKS = function(Y, F, mu.predict, mu.update, P.predict, P.update){
  mu = mu.update
  P = P.update
  for(i in nrow(Y):2 -1){
    K = P.update[,,i] %*% t(F[,,i]) %*% solve(P.predict[,,i+1])
    mu[i,] = mu.update[i,] + K %*% (mu[i+1,]-mu.predict[i+1,])
    P[,,i] = P.update[,,i] + K %*% (P[,,i+1]-P.predict[,,i+1]) %*% t(K)
  }
  list(mu=mu,P=P)
}

abc = with(xyz, EKS(Y=Yt[,obs.lanes],F=F,mu.predict=mu.predict, mu.update=mu, P.predict=P.predict, P.update=P))

require(numDeriv)






#plot
if (FALSE) {
    sample_nums = 10
    Xt_real = loc.d
    
    XT_EKF = xyz$mu
    sd_EKF = apply(xyz$P, 3, diag)
    sd_EKF = sqrt(sd_EKF)
    sd_EKF[is.na(sd_EKF)]=0
    sd_EKF = t(sd_EKF)
    Xt_ekf = array(0,dim=c(dim(Xt_real),sample_nums))
    for (i in c(1:nrow(Xt_real))) {
        Xt_ekf[i,,]=t(rmvnorm(n=sample_nums,mean = XT_EKF[i,],sigma = diag(sd_EKF[i,])))[1:25,]
    }
    
    XT_EKS = abc$mu
    sd_EKS = apply(xyz$P, 3, diag)
    sd_EKS = sqrt(sd_EKS)
    sd_EKS[is.na(sd_EKS)]=0
    sd_EKS = t(sd_EKS)
    Xt_eks = array(0,dim=c(dim(Xt_real),sample_nums))
    for (i in c(1:nrow(Xt_real))) {
        Xt_eks[i,,]=t(rmvnorm(n=sample_nums,mean = XT_EKS[i,],sigma = diag(sd_EKS[i,])))[1:25,]
    }
    
    #boxplot
    if (TRUE) {
        #Xt_all contains 100 trajectories (1k particles per run, 1 trajectory per run)
        Xt_particle = Xt_all[,,1]
        
        group = 2
        text = c('PF','EKF','EKS')
        time_period=c(1:1440)
        tt = seq(from=1,to=23,by=2)*60
        Xt_particle = Xt_all[tt,,]
        Xt_ekf = Xt_ekf[tt,,]
        Xt_eks = Xt_eks[tt,,]
        
        lanes = sample(c(1:25),5)
        lanes = unique(c(lanes,1,2))
        for (plot_lane in lanes) {
            print(plot_lane)
            
            boxthis = {}
            seq1 = {}
            seq2 = {}
            label = {}
            for (i in c(1:nrow(Xt_particle))) {
                #tmp_box = c(Xt_particle[i,plot_lane,],Xt_ekf[i,plot_lane,])
                tmp_box = c(Xt_particle[i,plot_lane,],Xt_ekf[i,plot_lane,],Xt_eks[i,plot_lane,])
                tmp_seq2 = rep(c(1:group),each=(length(tmp_box)/group))
                boxthis = c(boxthis,tmp_box)
                seq2 = c(seq2,tmp_seq2)
            }
            
            seq1 = rep(c(1:12),each=(length(boxthis)/12))
            #seq2 = rep(c(1:3),each=(length(boxthis)/3))
            label = interaction(seq1,seq2)
            
            seq1 = factor(seq1)
            seq2 = factor(seq2)
            method = seq2
            levels(method) = text[1:group]
            target = data.frame(boxthis,label,seq1,method)
            a = ggplot() + geom_boxplot(aes(y = boxthis, x = seq1,fill=method), data = target) + labs(title = "Boxplot of PF,EKF and EKS",x='time period',y='number of vehicles')
            
            #add groundtruth
            x=seq(from=1,to=12,length.out =length(time_period))
            y=Xt_real[time_period,plot_lane]
            x2=seq(from=1,to=12,length.out =length(boxthis))
            y2 = approx(x=x,y=y,xout=x2,method = 'linear')[[2]]
            y2 = SMA(y2,100)
            y2 = c(rep(y2[100],99),y2[100:length(y2)])
            ground_truth = data.frame(x=x2,y=y2)
            a + geom_line(data = ground_truth, aes_string(x=ground_truth$x, y=ground_truth$y),col='black')
            
            name = paste('ob3to25',plot_lane,sep='_')
            name = paste(name,'jpg',sep = '.')
            dev.copy(file=name, device=jpeg, quality=100, width=1024, height=1024)
            dev.off()
        }
    }
}




















