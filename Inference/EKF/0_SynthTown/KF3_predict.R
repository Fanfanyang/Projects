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
  load('EK2.RData')
  Xt_track = readRDS('data_result/Xt_ekf.RDS')
}

### method 3: to construct Kalman filter
#EKF = function(Y, f, h, dfdX, dhdX, Q, R, X0, P0)
# updating R
if (TRUE) {
    scale = 10
    obs.lanes = c(3,22)
    from.to = cbind(which(S==-1, arr.ind=TRUE)[,1],which(S==1, arr.ind=TRUE)[,1])
    
    #input
    Y=Yt[,obs.lanes]*1
    f = function(t, X, W=0, Theta) X+S%*%(m.time[cbind(from.to ,min(trunc(t/60)+1,24))]*X[which(S==-1, arr.ind=TRUE)[,1]])
    h = local(function(t, X, W=0, Theta) C %*% X/scale, envir=list(C=diag(nrow(S))[obs.lanes,]))
    Q=function(t, X, W, Theta){ S %*% diag(m.time[cbind(from.to ,min(trunc(t/60)+1,24))]*X[which(S==-1, arr.ind=TRUE)[,1]]) %*% t(S) }
    R= function(t, X, W, Theta) {
        #R_matrix = diag(length(obs.lanes))*2
        value = var.obs[abs(X)+1]
        value = var.obs[pmin( round(abs(X)+2), length(var.obs))]
        diag(value,length(obs.lanes),length(obs.lanes))
    }
    X0=c(Yt[1,]*scale)
    P0=diag(nrow(S))*.1
    
    #EKF
    K = matrix(0,nrow=length(X0),ncol=ncol(Y)) # Kalman gain
    mu.update = mu.predict = matrix(0, ncol=length(X0), nrow=nrow(Y))
    mu.update[1,] = mu.predict[1,] = X0
    F = P.predict = P.update = array(0, dim=c(length(X0),length(X0),nrow(Y)))
    P.predict[,,1] = P.update[,,1] = P0
    dfdX = function(t, X, W, Theta)
    jacobian(function(X, t, W, Theta) f(t, X, W, Theta), X, t=t, W=W, Theta=Theta)
    dhdX = function(t, X, W, Theta)
    jacobian(function(X, t, W, Theta) h(t, X, W, Theta), X, t=t, W=W, Theta=Theta)
    
    pred.window = 10
    pred.time = 1440/pred.window
    pred.seq = c(1:pred.time-1)*pred.window+2
    
    for(i in 2:nrow(Y)){
        print(i)
        F[,,i-1] = dfdX(i, mu.update[i-1,])
        #H = dhdX(i, mu.update[i-1,])
        mu.predict[i,] = f(i, mu.update[i-1,])
        #P.predict[,,i] = F[,,i-1] %*% P.update[,,i-1] %*% t(F[,,i-1]) + Q(i, mu.update[i-1,])
        #K = P.predict[,,i] %*% t(H) %*% ginv( H %*% P.predict[,,i] %*% t(H) + R(i, mu.update[i-1,obs.lanes]))
        
        if (i %in% pred.seq) {
          mu.tmp = Xt_track[i-1,]
          #P.tmp = P0
          F[,,i-1] = dfdX(i, mu.tmp)
          #H = dhdX(i, mu.tmp)
          mu.predict[i,] = f(i, mu.tmp)
          #P.predict[,,i] = F[,,i-1] %*% P.tmp %*% t(F[,,i-1]) + Q(i, mu.tmp)
        }
        
        #P.update[,,i] = P.predict[,,i]
        mu.update[i,] = mu.predict[i,]
    }
    
    xyz = list(mu=mu.update, P=P.update, mu.predict=mu.predict, P.predict=P.predict, F=F)
    saveRDS(mu.update,file='data_result/Xt_ekf_pred_10.RDS')
  
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



















