# GPS with known model dynamics

library(ggplot2)
library('Matrix')
require('TTR')
require('igraph')
require('survey')
require('grr')
library(MASS)
require('numDeriv')
require('mvtnorm')
library(MASS)

# load data
if (TRUE) {
  source('gps-functions.R')
  S = readRDS('S.RDS')
  
  scale = 1
  FSCALE = 30 # 60
  f_scale = FSCALE
  state_idx = 1:25
  action_idx = 26:35
  state_action_idx = 1:35
  smallnumber = array(0,dim=length(state_idx))
  ITER_LQR = 3
  ITER_GPS = 30
  stats_cost = c()
  stats_cost_nn = c()
  start_time = ceiling(1/f_scale)
  end_time = trunc(1440/f_scale) # 1400
  obs.lanes = c(3,22)
  from.to = cbind(which(S==-1, arr.ind=TRUE)[,1],which(S==1, arr.ind=TRUE)[,1])
  
  # policy network
  policy_network = keras_model_sequential() %>% layer_dense(units=6, input_shape = c(length(input_state)+1), activation='relu') %>% layer_dense(units=12, activation='relu') %>% layer_dense(units=24, activation='relu') %>% layer_dense(units=length(learnable), activation='relu')%>% compile(optimizer = optimizer_adam(lr=1e-3),loss = 'mse')
  
  train_idx = start_time:end_time*f_scale
  train_x = train_x[train_idx,] #/10
  train_y = train_y[train_idx,]
  history <- policy_network %>% fit(x=train_x, y=train_y, epochs=1000, batch_size=100,verbose=0)
  print(summary(history$metrics[[1]]))
  
  action = policy_network %>% predict(train_x)
  
  plot(rowSums(train_y[,1:9]),type='l')
  lines(rowSums(action[,1:9]),type='l',col='red')
  lines(train_y[,10],type='l')
  lines(action[,10],type='l',col='blue')
  
  load('m.time.RData')
  Yt = Xt_real
}

# prep
################################################################################################################
home = data.frame(begin=16,end=8,typ.dur=16)
work = data.frame(begin=8,end=16,typ.dur=8)
info_facility = as.data.frame(matrix(c(home,work),ncol=3,byrow = TRUE),row.names = c('home','work'))
colnames(info_facility) = c('begin','end','typ.dur')
facility = c(1,2)
link = c(3:25)
info_network = list(info_facility=info_facility,facility=facility,link=link)

EarlyLatePenalty <- function(t,goal_agents_cur,info_network) {
  BETA_late.ar <- -18
  BETA_early.dp <- -1
  S_late.ar.q <- 0
  S_early.dp.q <- 0
  mid <- (info_network$info_facility$begin[[goal_agents_cur]] + info_network$info_facility$end[[goal_agents_cur]])/2
  switch(goal_agents_cur,
         '1'={
           if (t/60 > mid) {
             S_late.ar.q <- BETA_late.ar
           } else {
             S_early.dp.q <- BETA_early.dp
           }
         },
         '2'={
           if (t/60 < mid) {
             S_late.ar.q <- BETA_late.ar
           } else {
             S_early.dp.q <- BETA_early.dp
           }
         })
  
  return(S_late.ar.q+S_early.dp.q)
}

################################################################################################################

Y=Yt[,obs.lanes]*1
policy_idx = which(from.to[,1] %in% c(1,2))
f = function(t, X, f_scale = FSCALE) {
  t = t * f_scale
  X_u = X[action_idx]
  X_x = X[state_idx]
  X_u = X_u/action_scale
  X_u = pmin(pmax(X_u,1e-8),(0.5-1e-8))
  transition_matrix = m.time[,,12]
  transition_matrix[1,4:12] = X_u[1:9]
  transition_matrix[2,23] = X_u[10]
  transition_matrix[2,1] = 0
  transition_matrix = sweep(transition_matrix,1,rowSums(transition_matrix),'/')
  transition_dynamics = transition_matrix[from.to]
  x_idx = which(S==-1, arr.ind=TRUE)[,1]
  for(i in c(1:f_scale)) {
    X_x = X_x+S%*%(transition_dynamics*X_x[x_idx])
  }
  X_x
}
fc = function(t, X, f_scale = FSCALE) {
  t = t * f_scale
  locations = state_idx
  BETA_dur <- 12 #staying in goal facility
  BETA_trav.modeq = -1
  if ((t <= info_network$info_facility$begin[[2]]*60)||(t > info_network$info_facility$end[[2]]*60)) {
    goal_agents_cur = 1
  } else {
    goal_agents_cur = 2
  }
  S_plan <- c()
  for(l in c(1:2)) {
    S.dur.q = 0
    if(l==goal_agents_cur) {
      S.dur.q <- BETA_dur
    }
    S_plan <- c(S_plan,S.dur.q)
  }
  S.ear.lat.penalty = EarlyLatePenalty(t,goal_agents_cur,info_network)
  S_road = array(BETA_trav.modeq,dim=23)
  S_plan = c(S_plan,S_road)
  S_plan[-goal_agents_cur] = S_plan[-goal_agents_cur] + S.ear.lat.penalty 
  
  # shift to positive, TBD
  #S_plan = S_plan + 4
  
  X_u = X[action_idx]
  X_x = X[state_idx]
  X_u = X_u/action_scale
  X_u = pmin(pmax(X_u,1e-8),(0.5-1e-8))
  transition_matrix = m.time[,,12]
  transition_matrix[1,4:12] = X_u[1:9]
  transition_matrix[2,23] = X_u[10]
  transition_matrix[2,1] = 0
  transition_matrix = sweep(transition_matrix,1,rowSums(transition_matrix),'/')
  transition_dynamics = transition_matrix[from.to]
  x_idx = which(S==-1, arr.ind=TRUE)[,1]
  
  #state_cost = sum(X_x*S_plan)/sum(X_x)
  for(i in c(1:f_scale)) {
    X_x = X_x+S%*%(transition_dynamics*X_x[x_idx]) 
    #state_cost = state_cost + sum(X_x*S_plan)/sum(X_x)
  }
  state_cost = sum(X_x*S_plan)/sum(X_x)
  
  state_cost
}
dfdX = function(t, X) {
  jacobian(function(X, t) f(t, X), X, t=t) 
}
dcdX = function(t, X) {
  jacobian(function(X, t) fc(t, X), X, t=t) 
}
d2cdX = function(t, X) {
  hessian(function(X, t) fc(t, X), X, t=t) 
}

for(iter_gps in 1:ITER_GPS) {
  X0=c(Yt[start_time,]*scale)
  Kt_all = array(0,dim=c(nrow(Y),length(action_idx),length(state_idx))) 
  kt_all = array(0,dim=c(nrow(Y),length(action_idx))) 
  xt.estimate = matrix(0, ncol=length(state_idx), nrow=nrow(Y))
  ut.estimate = matrix(0, ncol=length(action_idx), nrow=nrow(Y))
  ct.estimate = array(0, dim=nrow(Y))
  xt.estimate[start_time,] = X0
  
  # init
  for(i in (start_time+1):end_time){
    X = xt.estimate[i-1,]
    lg = matrix(c(X[input_state],i*f_scale),nrow = 1)
    lg = lg/state_scale
    U = policy_network %>% predict(lg)
    U = pmin(pmax(U,1e-8*action_scale),(0.5-1e-8)*action_scale)
    XU = c(X,U)
    xt.estimate[i,] = f(i,XU)
    ut.estimate[i-1,] = U
    ct.estimate[i-1] = fc(i,XU)
  }
  ut.estimate[i,] = ut.estimate[i-1,]
  ct.estimate[i] = fc(i,c(xt.estimate[i,],ut.estimate[i,]))
  
  plot(xt.estimate[start_time:end_time,1],ylim = c(0,50),type='l',col='black')
  lines(xt.estimate[start_time:end_time,2],type='l',col='red')
  cat(sprintf("cost: %f\n",sum(ct.estimate)))
  stats_cost = c(stats_cost,sum(ct.estimate))
  stats_cost_nn = c(stats_cost_nn,sum(ct.estimate))
  if (iter_gps==1) saveRDS(xt.estimate,file='data_result/init.xt_1.RDS')
  
  for(iter_lqr in 1:ITER_LQR) {
    # backward
    for(i in end_time:start_time) {
      X = xt.estimate[i,]
      U = ut.estimate[i,]
      XU = c(X,U)
      Ft = dfdX(i,XU)
      ft = array(0,dim=length(state_idx))
      ct = dcdX(i,XU)
      Ct = d2cdX(i,XU)
      
      if (i==end_time) {
        Qt = Ct
        qt = c(ct)
      } else {
        Qt = Ct + t(Ft) %*% Vt_1 %*% Ft
        qt = c(ct) + t(Ft) %*% Vt_1 %*% ft + t(Ft) %*% vt_1 
      }
      
      Kt = -ginv(Qt[action_idx,action_idx]) %*% Qt[action_idx,state_idx]
      
      kt = qt[action_idx]
      Vt = Qt[state_idx,state_idx] + Qt[state_idx,action_idx] %*% Kt + t(Kt) %*% Qt[action_idx,state_idx] + t(Kt) %*% Qt[action_idx,action_idx] %*% Kt
      vt = qt[state_idx] + Qt[state_idx,action_idx] %*% kt + t(Kt) %*% qt[action_idx] + t(Kt) %*% Qt[action_idx,action_idx] %*% kt
      
      Kt_all[i,,] = Kt
      kt_all[i,] = kt
      Vt_1 = Vt
      vt_1 = vt
    }
    
    # forward
    for(i in (start_time+1):end_time) {
      
      xt_hat = xt.estimate[i-1,]
      ut_hat = ut.estimate[i-1,]
      smallnumber[which(xt_hat>1)] = -1e-2
      smallnumber[which(xt_hat<=1)] = -sum(smallnumber[which(xt_hat>1)])/length(which(xt_hat<=1))
      xt = xt_hat + smallnumber
      delta_xt = xt - xt_hat
      
      Kt = Kt_all[i-1,,]
      kt = kt_all[i-1,]
      
      delta_ut = Kt %*% (delta_xt) + kt
      delta_ut = delta_ut/10
      
      U = ut_hat + delta_ut
      U = pmin(pmax(U,1e-8*action_scale),(0.5-1e-8)*action_scale)
      X = xt
      XU = c(X,U)
      xt.estimate[i,] = f(i,XU)
      ut.estimate[i-1,] = U
      ct.estimate[i-1] = fc(i,XU)
    } 
    ut.estimate[i,] = ut.estimate[i-1,]
    ct.estimate[i] = fc(i,c(xt.estimate[i,],ut.estimate[i,]))
    
    plot(xt.estimate[start_time:end_time,1],ylim = c(0,50),type='l',col='black')
    lines(xt.estimate[start_time:end_time,2],type='l',col='red')
    cat(sprintf("cost: %f\n",sum(ct.estimate)))
    stats_cost = c(stats_cost,sum(ct.estimate))
    if ((iter_gps==1) && (iter_lqr == 1)) saveRDS(xt.estimate,file='data_result/init.xt_2.RDS')
  }
  
  # train global policy
  train_x_tmp = cbind(xt.estimate[start_time:end_time,1:2],start_time:end_time*f_scale)
  train_y_tmp = ut.estimate[start_time:end_time,]
  train_x_tmp = train_x_tmp/state_scale
  train_x = rbind(train_x_tmp,train_x)
  train_y = rbind(train_y_tmp,train_y)
  
  history <- policy_network %>% fit(x=train_x, y=train_y, epochs=1000, batch_size=100,verbose=0)
  print(summary(history$metrics[[1]]))
  
  action = policy_network %>% predict(train_x_tmp)
  
  plot(rowSums(train_y_tmp[,1:9]),type='l')
  lines(rowSums(action[,1:9]),type='l',col='red')
  lines(train_y_tmp[,10],type='l')
  lines(action[,10],type='l',col='blue')
  
  saveRDS(xt.estimate,file='data_result/xt.estimate.RDS')
}
saveRDS(stats_cost,file='data_result/stats_cost.RDS')
















































