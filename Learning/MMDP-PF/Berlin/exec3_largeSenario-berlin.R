
library('Matrix')
require('TTR')
require('igraph')
require('survey')
require('grr')
require('RcppEigen')
require('Rcpp')
library(ggplot2)
sourceCpp("rcpp_pf_location.cpp")

load("data_exec/Xt_real.RData")
load('data_exec/obs.matrix.RData')
load('data_prep/person.state.d.RData')
load('data_exec/Yt.RData')
load('data_prep/locations.RData')
load('data_exec/info_facility.RData')
network = readRDS('network.RDS')
load('data_exec/Roadload.RData')
Ppolicy = readRDS('data_exec/PpolicyUpdate.RDS')
load('data_exec/possible_actions.RData')
load('data_prep/td.RData')
load('data_exec/action_list.RData')
load('data_prep/facility_length.RData')
load('data_exec/facility_index.RData')
Xt_real = matrix(as.numeric(factor(Xt_real, levels=locations)), nrow=nrow(Xt_real))
Xt_est = array(0,dim=dim(Xt_real))
Yt = matrix(as.numeric(factor(Yt, levels=locations)), nrow=nrow(Yt))
if (FALSE) {
  Yt_vehicles = t(apply(Yt,1,function(x) table(factor(x, levels=c(1:length(locations)) ))))
  save(Yt_vehicles,file='data_exec/Yt_vehicles.RData')
  Xt_real_1 = t(apply(Xt_real,1,function(x) table(factor(x, levels=c(1:length(locations)) ))))
  save(Xt_real_1,file='data_exec/Xt_real_1.RData')
}
load('data_exec/Xt_real_1.RData')
load('data_exec/Yt_vehicles.RData')
load('data_exec/policy_template.RData')
policy_origin = Ppolicy
system.reward.updated = list()

#model
TEST = 0
Agents = c(1:ncol(person.state.d))
Time = c(1:nrow(person.state.d))
Actions = locations
States = locations
NumAgents = length(Agents)
NumTime = length(Time)
NumActions = length(Actions)
NumStates = length(States)

#functions
PFPredict <- function(t0, pred.window, Xi_1, Ppolicy, Roadload, action_list, facility_length) {
  upper.time <- pred.window+2
  x_sample <- array(0,dim=c(dim(Xi_1),upper.time))
  u_sample <- array(0,dim=c(dim(Xi_1),upper.time))
  #P_traj_transit <- array(0,dim=c(dim(Xi_1),upper.time))
  Xi_2 <- array(0,dim=dim(Xi_1))
  Xi_3 <- array(0,dim=dim(Xi_1))
  x_sample[,,1] <- Xi_1
  for(i in c(2:upper.time)) {
    t <- t0+i-2
    print(t)
    Xi_2[,] <- 0
    Xi_3[,] <- 0
    
    xyz <- matrix(runif(length(Xi_1)), nrow=nrow(Xi_1))
    AccumPpolicy <- Ppolicy[[t]]
    AccumPpolicy <- lapply(AccumPpolicy, cumsum)
    Xi_2 <- SamplingAction(Xi_1, xyz, AccumPpolicy, action_list)

    #n_cur <- t(apply(Xi_1,1,function(x) table(factor(x, levels=c(1:length(locations))))))
    n_cur <- t(apply(Xi_1,1,function(x) tabulate(x,nbins = length(locations))))
    TimeMoveOut <- t(apply(n_cur[,(facility_length+1):ncol(n_cur)], 1, function(x) x/Roadload$Roadload*Roadload$TimeMoveOut))
    for (j in c(1:ncol(TimeMoveOut))) {
      TimeMoveOut[,j] <- pmax(TimeMoveOut[,j],Roadload$TimeMoveOut[j])
    }
    Pmoveout <- 1/TimeMoveOut
    Pfacility = array(1,dim = c(nrow(Pmoveout),facility_length))
    Ptransit = cbind(Pfacility,Pmoveout)
    
    xyz <- matrix(runif(length(Xi_1)), nrow=nrow(Xi_1))
    Xi_3 <- SamplingState(Xi_1, Xi_2, xyz, Ptransit)
    
    #P_traj_transit[,,i-1] <- StateProb(Xi_1,Xi_2,Xi_3,Ptransit)
    u_sample[,,i-1] <- Xi_2
    x_sample[,,i] <- Xi_3
    Xi_1 <- Xi_3
  }
  #P_traj_transit=P_traj_transit[,,1:(upper.time-1)]
  return(list(u_sample=u_sample[,,1:(upper.time-1)],x_sample=x_sample[,,1:(upper.time-1)]))
}

#t_cur < 24*60, todo: 1. ensure no f to different f, 2. currently no duration 3. l-l to which facility?
RewardFunction <- function(state.origin,t_cur,info_facility,goal_facility,facility_index,facility_length) {
  home <- 1
  leis <- 2
  other <- 3
  work <- 4
  shop <- 5
  BETA_late.ar <- -18
  BETA_early.dp <- -1
  #BETA_wait <- 0
  BETA_short.dur <- 0
  BETA_dur <- 6 #staying in goal facility
  t_0.q <- 2
  C_mode.q = 0
  BETA_m = 1
  BETA_trav.modeq = -6
  
  if ((t_cur/60 > info_facility$begin[[goal_facility]]) && (t_cur/60 < info_facility$end[[goal_facility]]) && (!(state.origin %in% facility_index$work)) && (goal_facility == work)) {
    mid <- (info_facility$begin[[goal_facility]] + info_facility$end[[goal_facility]])/2
    if (t_cur/60 < mid) {
      S_late.ar.q <- BETA_late.ar
      S_early.dp.q <- 0
    } else {
      S_late.ar.q <- 0
      S_early.dp.q <- BETA_early.dp
    }
  } else if (((t_cur/60 > info_facility$begin[[goal_facility]]) || (t_cur/60 < info_facility$end[[goal_facility]])) && (!(state.origin %in% facility_index$home)) && (goal_facility == home)) {
    mid <- (info_facility$begin[[goal_facility]] + info_facility$end[[goal_facility]])/2
    if (t_cur/60 > mid) {
      S_late.ar.q <- BETA_late.ar
      S_early.dp.q <- 0
    } else {
      S_late.ar.q <- 0
      S_early.dp.q <- BETA_early.dp
    }
  } else {
    S_late.ar.q <- 0
    S_early.dp.q <- 0
  }
  
  #usefule working time: f-f, l-f
  if (state.origin %in% facility_index[[goal_facility]]) {
    S_dur.q <- BETA_dur
  } else {
    S_dur.q <- 0 
  }
  
  #four cases: f-f, f-l, l-f, l-l
  if(state.origin <= facility_length) {
    #f-f, f-l
    S_act.q <- S_dur.q + S_late.ar.q + S_early.dp.q
    S_trav.q <- 0
  } else {
      #l-f, l-l
      S_act.q <- S_late.ar.q + S_early.dp.q
      S_trav.q <- C_mode.q + BETA_trav.modeq
  }
  S_plan <- S_act.q + S_trav.q
  return(S_plan)
}

RewardTrajectoryFunction <- function(Xi_1, x_sample, info_facility, t_cur, goal_facility,facility_index,facility_length) {
  S_plan <- array(0,dim=dim(x_sample))
  for (i in c(1:dim(x_sample)[1])) {
    print(i)
    for (j in c(1:dim(x_sample)[2])) {
      for (k in c(1:dim(x_sample)[3])) {
        t <- t_cur +k - 1
        state.origin <- x_sample[i,j,k]
        S_plan[i,j,k] <- RewardFunction(state.origin,t,info_facility,goal_facility[k],facility_index,facility_length)
      }
      S_plan[i,j,] <- cumsum(S_plan[i,j,]) 
    }
  }
  return (S_plan)
}

GoalFacility <- function(length,t_cur,info_facility) {
  home <- 1
  leis <- 2
  other <- 3
  work <- 4
  shop <- 5
  goal_facility <- array(0,dim=length)
  for (i in c(1:length(goal_facility))) {
    tt <- t_cur+i-1
    if ((tt/60>info_facility$begin[[work]])&&(tt/60<info_facility$end[[work]])) {
      goal_facility[i] <- work
    } else {
      goal_facility[i] <- home
    } 
  }
  return(goal_facility)
}

lappend <- function (lst, ...){
  lst <- c(lst, list(...))
  return(lst)
}

#add <- function(x) Reduce("+", x)

# RL
time.th = min(td)/60-1
pred.window = 120
moving.step = 90
obs.scale = 10
tot_iter = 5
tot_T = 1e1
gamma = 0.998
delta = 0.999
alpha_k = 0.5
a<-function(t) (1-delta)*delta^t
b<-function(t) (1-gamma/delta)*(gamma/delta)^t

t0.min = 181
t0.max = 360
t0 = t0.min
#t0.max = trunc((nrow(Xt_real)-1)/pred.window)*pred.window
Xt_est[t0,] = rep(Yt[t0,],each=(obs.scale+1))[1:ncol(person.state.d)]
while(t0 < t0.max) {
  cat(sprintf('current time: %i\n',t0))
  iter = 1
  if (TEST) {
    x_model = array(0,dim=c(tot_iter,tot_T,ncol(person.state.d),pred.window+1))
    r_model = array(0,dim=c(tot_iter,tot_T,ncol(person.state.d),pred.window+1)) 
  }
  while (iter <= tot_iter) {
    cat(sprintf('t0 = %i, iter = %i\n',t0,iter))
    # 1.sample T
    time.period = c(1:pred.window)
    T = sample(time.period,tot_T,replace = TRUE,prob = a(time.period))
    
    # 2. sample trejectories
    print('sample trajectories')
    Xi_1 = matrix(rep(Xt_est[t0,],each=tot_T),nrow=tot_T)
    sample_trajectory = PFPredict(t0,pred.window,Xi_1,Ppolicy,Roadload,action_list,facility_length)
    x_sample = sample_trajectory$x_sample
    u_sample = sample_trajectory$u_sample
    
    # 3. computing weights
    print('computing weights')
    t_cur = t0+time.th
    goal_facility = GoalFacility(dim(x_sample)[3],t_cur,info_facility)
    r_sample = RewardTrajectoryFunction(Xi_1, x_sample, info_facility, t_cur, goal_facility,facility_index,facility_length)
    r_prob = (r_sample-min(r_sample)+1)
    r_prob = r_prob/max(r_prob)
    w = array(0,dim=dim(r_prob)[1:2])
    w = r_prob[,,pred.window+1]
    
    # 4. update F
    print('update F')
    action_percent = list()
    
    sourceCpp("rcpp_pf_location.cpp")
    load('data_exec/policy_template.RData')
    for (k in c(1:(pred.window+1))) {
      print(k)
      tmp_count = ListCountAction3(x_sample[,,k],u_sample[,,k],w,policy_template,action_list)
      tmp_list <- lapply(tmp_count, function(x) x/sum(x))
      action_percent <- lappend(action_percent,tmp_list)
    }
    action_percent = rapply( action_percent, f=function(x) ifelse(is.nan(x),0,x), how="replace" )
    for (i in c(t0:(t0+pred.window))) {
      Ppolicy[[i]] = ListAdd(Ppolicy[[i]],action_percent[[i-t0+1]],alpha_k)
      Ppolicy[[i]] = lapply(Ppolicy[[i]], function(x) x/sum(x))
    }
    
    # test
    if (TEST) {
      r_model[iter,,,] = r_sample
      x_model[iter,,,] = x_sample
      title = paste('SMA pf result',iter,sep='@')
      SMA_scale = 10
      Xt_est_vehicles = t(apply(x_sample[1,,],2,function(x) table(factor(x, levels=c(1:length(locations))))))
      Xt_real_vehicles = t(apply(Xt_real,1,function(x) table(factor(x, levels=c(1:length(locations))))))
      others = c(2,3,4,5,7,8,9,10)+2
      vehicle_others_gt = apply(Xt_real_vehicles[,others], 1, sum)
      vehicle_others_est = apply(Xt_est_vehicles[,others], 1, sum)
      print(vehicle_others_est)
      plot_lane = 2
      plot(Xt_real_vehicles[,plot_lane],type='l',xlab='time',ylab='Vechiles',main=title,ylim = c(0,2000))
      cl = rainbow(3)
      lines(Xt_real_vehicles[,8],type='l',col='black')
      lines(c(t0:(t0+pred.window)),Xt_est_vehicles[,2],type='l',col=cl[1])
      lines(c(t0:(t0+pred.window)),Xt_est_vehicles[,8],type='l',col=cl[2])
      lines(c(t0:(t0+pred.window)),vehicle_others_est,type='l',col=cl[3])
      legend('topright',legend=c('gt@w','gt@6','est@w','est@6','est_others'),lty=array(1,dim=5),col=c('black','black',cl))
      file.name = paste(title,'png',sep='.')
      dev.copy(file=file.name, device=png, width=1024, height=768)
      dev.off()
      if(FALSE) {
        test_time = pred.window
        apply(apply(r_model[,,,test_time],c(1,2),sum),1,mean)
        x_end=trunc(t(apply(x_model[,,,test_time], 1, function (x) table(factor(x,levels = c(1:length(locations))))))/dim(x_model)[2])
        colnames(x_end) = locations
        x_end
      }
    }
    iter = iter + 1
  }
  
  # 5. Simulation
  print('simulation')
  #improved policy
  Xi_1 = matrix(rep(Xt_est[t0,],each=tot_T),nrow=tot_T)
  sample_trajectory = PFPredict(t0,pred.window,Xi_1,Ppolicy,Roadload,action_list,facility_length)
  x_sample = sample_trajectory$x_sample
  u_sample = sample_trajectory$u_sample
  t_cur = t0+time.th
  goal_facility = GoalFacility(dim(x_sample)[3],t_cur,info_facility)
  r_sample = RewardTrajectoryFunction(Xi_1, x_sample, info_facility, t_cur, goal_facility,facility_index,facility_length)
  system.reward.updated = append(system.reward.updated,mean(r_sample[,,length(pred.window)]))
  Xt_est[t0:(t0+moving.step),] = t(x_sample[1,,1:(moving.step+1)])
  t0 = t0 + moving.step
}

StatisticsVehicles <- function(real.time, Xt_est_1,message,facility_index, t0) {
  #Xt_est_1=Xt_real_1[t0.min:t0.max,]
  Xt_athome <- apply(Xt_est_1[,facility_index$home], 1, sum)
  Xt_atleis <- apply(Xt_est_1[,facility_index$leis], 1, sum)
  Xt_atother <- apply(Xt_est_1[,facility_index$other], 1, sum)
  Xt_atwork <- apply(Xt_est_1[,facility_index$work], 1, sum)
  Xt_atshop <- apply(Xt_est_1[,facility_index$shop], 1, sum)
  Xt_facilities_not_home <- Xt_atleis + Xt_atother + Xt_atshop + Xt_atwork
  Xt_onroad <- apply(Xt_est_1, 1, sum) - Xt_athome - Xt_atleis - Xt_atother - Xt_atwork - Xt_atshop
  title <- paste('Vehicle Distribution',message,sep='@')
  plot(real.time/60,Xt_athome,type='l',col='red',main = title,ylim = c(0,max(Xt_athome)))
  lines(real.time/60,Xt_atwork,type='l',col='blue')
  lines(real.time/60,Xt_onroad,type='l',col='green')
  abline(v=info_facility$begin[[4]],col='gray')
  legend('topright',legend=c('vehicles at home','vehicles at work', 'vehicles on roads'),lty=array(1,dim=3),col=c('red','blue','green'))
  file.name <- paste(title,'png',sep='.')
  dev.copy(file=file.name, device=png, width=1024, height=768)
  dev.off()
  time <- c(0,10,30,60,120)
  result <- Xt_atwork[ceiling(info_facility$begin[[2]]*60-time.th+time-t0)]/2000
  return(result)
}

'%!in%' <- function(x,y)!('%in%'(x,y))

#Comparing statistics
if (TRUE) {
  real.time = c(t0.min:t0.max) + time.th
  t0 = t0.min
  # updated policy
  if (TRUE) {
    Xt_est_updated = t(apply(Xt_est[c(t0:(t0+length(real.time)-1)),], 1, function(x) tabulate(x,nbins = dim(Yt_vehicles)[2])))
    percentage.ontime.updated = StatisticsVehicles(real.time, Xt_est_updated, 'updated', facility_index, t0)
    #home to work
    tmp1 = apply(Xt_est[c(t0:(t0+length(real.time)-1)),], 2, function(x) which(x %!in% facility_index$home)[1])
    tmp2 = apply(Xt_est[c(t0:(t0+length(real.time)-1)),], 2, function(x) which(x %in% facility_index$work)[1])
    Xt_time_updated = tmp2 - tmp1
    Xt_time_updated[is.na(Xt_time_updated)] = 0
    cat(sprintf('updated work on time percetage : %f\n',percentage.ontime.updated))
    cat(sprintf('updated average time on road h->w : %f\n',sum(c(Xt_time_updated))/length(which(Xt_time_updated>0))))
    cat(sprintf('updated system reward: %e\n',mean(unlist(system.reward.updated))))
  }
  # original
  if (TRUE) {
    Xi_1 = matrix(rep(Xt_est[t0,],each=tot_T),nrow=tot_T)
    sample_trajectory = PFPredict(t0,t0.max-t0.min,Xi_1,policy_origin,Roadload,action_list,facility_length)
    x_sample = sample_trajectory$x_sample
    u_sample = sample_trajectory$u_sample
    t_cur = t0+time.th
    goal_facility = GoalFacility(dim(x_sample)[3],t_cur,info_facility)
    r_sample = RewardTrajectoryFunction(Xi_1, x_sample, info_facility, t_cur, goal_facility,facility_index,facility_length)
    system.reward.original = mean(r_sample[,,length(real.time)])
    
    Xt_est_original_all = apply(x_sample, c(1,3), function(x) tabulate(x,nbins = dim(Yt_vehicles)[2]))
    Xt_est_original = t(apply(Xt_est_original_all, c(1,3), mean))
    percentage.ontime.original = StatisticsVehicles(real.time, Xt_est_original, 'original', facility_index, t0)
    #home to work
    tmp1 = apply(x_sample, c(1,2), function(x) which(x %!in% facility_index$home)[1])
    tmp2 = apply(x_sample, c(1,2), function(x) which(x %in% facility_index$work)[1])
    Xt_time_original = tmp2 - tmp1
    Xt_time_original[is.na(Xt_time_original)] = 0
    cat(sprintf('original work on time percetage : %f\n',percentage.ontime.original))
    cat(sprintf('original average time on road h->w : %f\n',sum(c(Xt_time_original))/length(which(Xt_time_original>0))))
    cat(sprintf('original system reward: %e\n',system.reward.original))
  }
}





































