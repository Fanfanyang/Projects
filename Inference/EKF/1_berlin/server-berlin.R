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
    
    #xyz = list(mu=mu.update, P=P.update, mu.predict=mu.predict, P.predict=P.predict, F=F)
    saveRDS(mu.update,file='data_result/Xt_ekf.RDS')
}




















