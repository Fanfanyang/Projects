
library(ggplot2)
require(Hmisc)
require(numDeriv)
require(keras)

# SynthTown
load("synthtown.RData")
# berlin
#load("berlin.RData")

theta2policy <- function(theta) {
  
  theta_list <- list()
  tmp_accum = 0
  for (tt in 1:length(action_list)) {
    tmp_idx <- c((tmp_accum+1): (tmp_accum+length(action_list[[tt]])-1))
    tmp_l <- theta[tmp_idx]
    if (sum(tmp_l)>0.99999999) tmp_l = tmp_l/(sum(tmp_l)+1e-8)
    theta_list[[tt]] <- c(1-sum(tmp_l),tmp_l)
    tmp_accum <- tmp_accum + length(tmp_idx)
  }
  theta_list
}

la_init <- function(loc.d,locations,max.person,action_list,PpolicyUpdate,start.time,la) {
  sliceempty=lapply(1:length(locations), function(m){
    array(0,dim=max.person[m]+1)
  })
  start=sliceempty
  for( i in 1:length(locations)) start[[i]][loc.d[start.time,i]+1]=1
  
  la[[start.time]]=start
  return(la)
}

lappend <- function (lst, ...){
  lst <- c(lst, list(...))
  return(lst)
}

RewardNormalization <- function(lr,R_min) {
  result = lapply(lr,function(x) x-R_min)
  result[[1]] = result[[1]]-min(result[[1]])
  result[[2]] = result[[2]]-min(result[[2]])
  result
}

theta_g<-function(max.person) {
  offset_facility <- length(info_network$facility)
  TimeMoveOut <- sapply(c(1:length(info_network$link)), function(n) {
    list(pmax(c(0:max.person[n+length(info_network$facility)])/info_network$info_road$Roadload[n]*info_network$info_road$TimeMoveOut[n],info_network$info_road$TimeMoveOut[n]))
  })
  Pmoveout <- lapply(TimeMoveOut,function(x) 1/x)
  Pfacility <- rep(list(1),length(info_network$facility))
  for(i in c(1:length(info_network$facility))) {
    Pfacility[[i]] <- array(1e-3,dim=max.person[info_network$facility[i]]+1)
  }
  
  Ptransit = append(Pfacility,Pmoveout)
  
  Ptransit
}

action2rate <- function(action,max.person,la1,lb1) {
  theta = array(1e-1,dim=tot_theta)
  theta[learnable] = action
  rate_slice = theta2policy(theta)
  
  theta_moveout = theta_g(max.person)
  lg=sapply(1:length(locations),function(n) {
    gamma=la1[[n]]*lb1[[n]]
    gamma=gamma/sum(gamma)
    sum(gamma* (0:(length(gamma)-1)))
  })
  for(n in c(4:21,23:25)) {
    rate_slice[[n]][-1][] = theta_moveout[[n]][trunc(lg[n])+1]
    rate_slice[[n]][1] = 1-sum(rate_slice[[n]][-1])
  }
  n = 22
  rate_slice[[n]][3] = theta_moveout[[n]][trunc(lg[n])+1]
  rate_slice[[n]][2] = 1e-8
  rate_slice[[n]][1] = 1-sum(rate_slice[[n]][-1])
  n = 3
  rate_slice[[n]][length(rate_slice[[n]])] = theta_moveout[[n]][trunc(lg[n])+1]
  rate_slice[[n]][-c(1,length(rate_slice[[n]]))] = 1e-8
  rate_slice[[n]][1] = 1-sum(rate_slice[[n]][-1])
  
  rate_slice
}

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
RewardFunction<-function(max.person, cur_time, locations, action_list, info_network){
  
  BETA_dur <- 6 #staying in goal facility
  BETA_trav.modeq = -6
  t = cur_time
  if ((t <= info_network$info_facility$begin[[2]]*60)||(t > info_network$info_facility$end[[2]]*60)) {
    goal_agents_cur = 1
  } else {
    goal_agents_cur = 2
  }
  
  # state
  S_plan <- list()
  for(l in c(1:length(locations))) {
    S_plan_l <- 0
    S_trav.q = 0
    S.dur.q = 0
    S.ear.lat.penalty = 0
    if(l %in% info_network$facility) {
      if(l==goal_agents_cur) {
        S.dur.q <- BETA_dur
      } else {
        S.ear.lat.penalty <- EarlyLatePenalty(t,goal_agents_cur,info_network)
      }
    } else {
      S_trav.q <- BETA_trav.modeq
      S.ear.lat.penalty <- EarlyLatePenalty(t,goal_agents_cur,info_network)
    }
    S_plan_l[] <- S_trav.q + S.dur.q + S.ear.lat.penalty
    S_plan <- lappend(S_plan,S_plan_l)
  }
  
  xt_reward = lapply(c(1:length(locations)),function(n) {
    0:max.person[n]*S_plan[[n]]
  })
  
  
  return(xt_reward)
}

# forward
#######################################################################################################

upd_forward<-function(v1,inc,out,pn,dec,len){
  v2=v1*pn - 0:(len-1)*v1*out
  v2[2:len]=v2[2:len] + v1[1:(len-1)]*inc
  v2[1:(len-1)]=v2[1:(len-1)] + 1:(len-1)*v1[2:len]*dec
  v2[v2<0] = 0
  v2[v2>1e100] = 1e100
  v2
}

transition_forward_fra<-function(la1,lb2,ratein, locin, rateout, locout, pout, pnull){
  m.inc=sapply(1:length(locations),function(n) sum( la1[[n]][1:max.person[n]] * lb2[[n]][2:(max.person[n]+1)] ) )
  m.eq.x=sapply(1:length(locations),function(n) sum(0:max.person[n]*la1[[n]]*lb2[[n]]))
  m.eq=sapply(1:length(locations),function(n) sum(la1[[n]]*lb2[[n]]))
  m.eq[m.eq==0]=1e-20
  m.dec=sapply(1:length(locations),function(n) sum( 1:max.person[n] * la1[[n]][2:(max.person[n]+1)] * lb2[[n]][1:max.person[n]] ))
  
  fra.eq=m.eq.x/m.eq
  fra.inc=m.inc/m.eq
  fra.dec=m.dec/m.eq
  pinc=sapply(1:length(locations),function(n) sum(  ratein[[n]] * fra.dec[locin[[n]] ] )) 
  pdec= sapply(1:length(locations),function(n)  sum(  rateout[[n]] * fra.inc[locout[[n]]  ] ) )
  
  #for each link, calculate the prob of transition at all other links 
  tran=lapply(1:length(locations), function(n)  rateout[[n]] * fra.dec[n] * fra.inc[locout[[n]]  ] )
  alltran=sum(unlist(tran))
  trother=numeric(length = length(locations))
  trother[]=alltran
  trother=trother-sapply(tran,sum) # transition at other links = all transition - transition from local link - transition to local link
  for(n in 1:length(locations)) trother[locout[[n]]]=trother[locout[[n]]]-tran[[n]]
  pn=1-pnull+trother
  
  la2_tilde = lapply(1:length(locations), function(n) upd_forward(la1[[n]],pinc[n],pout[n],pn[n],pdec[n],max.person[n]+1) )
  
  lg2=lapply(1:length(locations), function(n) la2_tilde[[n]]*lb2[[n]] )
  K=sapply(lg2, sum )
  la2_tilde=lapply(1:length(locations), function(n) la2_tilde[[n]]/K[n])
  
  # expected events
  exp_null = lapply(1:length(locations), function(n)  rateout[[n]] * array(fra.eq[n],dim=length(locout[[n]]))  )
  event_normalization = sum(unlist(tran))+(1-sum(unlist(exp_null)))
  exp_event = Map('/',tran,event_normalization)
  
  
  list(la2_tilde=la2_tilde,exp_event=exp_event)
}

rate_in_out_f <- function(rate_slice,action_list) {
  rateout = lapply(rate_slice,function(x) x[-1])
  
  ratein = list()
  for(t1 in 1:length(locations)) {
    tmp1 = locin[[t1]]
    for(t2 in 1:length(tmp1)) {
      tmp1[t2] = rate_slice[[tmp1[t2]]][which(action_list[[tmp1[t2]]]==t1)]
    }
    ratein[[t1]] = tmp1
  }
  list(rateout=rateout,ratein=ratein)
}

forward2 = function(start.time, end.time, la, lb, action_list, max.person,policy_network,learnable){
  
  exp_events_list = list()
  mini_timesteps = array(0,dim=1441)
  new.t = c()
  length.la = length(la)
  length(exp_events_list) = 1441
  cv_old = array(0,dim=c((end.time-start.time),length(learnable)))
  
  for(i in start.time:(end.time-1)){
    la1=la[[i]]
    lb1=lb[[i]]
    lb2=lb[[i+1]]
    
    lg=matrix(c(sapply(input_state,function(n) {
      gamma=la1[[n]]*lb1[[n]]
      gamma=gamma/sum(gamma)
      sum(gamma* (0:(length(gamma)-1)))
    }),i),nrow = 1)
    lg = lg/state_scale
    
    action = policy_network %>% predict(lg)
    action = action/action_scale
    
    cv_old[i-start.time+1,] = action
    
    rate_slice = action2rate(action,max.person,la1,lb1)
    
    rate = rate_in_out_f(rate_slice,action_list)
    ratein_original=rate$ratein 
    rateout_original=rate$rateout
    
    m.eq=numeric(length = length(locations))
    m.eq=sapply(1:length(locations),function(n) sum(la1[[n]]*lb2[[n]]))
    m.eq[m.eq==0]=1e-20
    
    m.eq.x=numeric(length = length(locations))
    m.eq.x=sapply(1:length(locations),function(n) sum(0:max.person[n]*la1[[n]]*lb2[[n]]))
    
    pout=sapply(rateout_original, sum)
    pnull= sum(pout*m.eq.x/m.eq) - pout*m.eq.x/m.eq
    r_nnn=max.person*pout+pnull
    nnn = max(ceiling(r_nnn))
    nnn = min(nnn,3000)
    
    pout=pout/nnn
    pnull=pnull/nnn
    ratein=lapply(1:length(ratein_original), function(n) ratein_original[[n]]/nnn)
    rateout=lapply(1:length(rateout_original), function(n) rateout_original[[n]]/nnn)
    
    #print("--------------------------------nnn---------")
    #print(nnn)
    mini_timesteps[i] = nnn
    if(nnn>1) new.t=c(new.t,i+1:(nnn-1)/nnn)
    
    cv = sapply(1:length(locations), function(n) {
      array(0,dim=length(action_list[[n]])-1)
    })
    
    for (k in 1:nnn){
      t1 = i+(k-1)/nnn; t2 = i+k/nnn;
      lb2=getSlice(lb,t2);
      
      if(k!=nnn) {
        tran=transition_forward_fra(la1,lb2,ratein, locin, rateout, locout, pout, pnull)
        la2=tran$la2_tilde
        
        if(length(attr(la,'t'))==length.la){la = alloc(la); length.la = length(la)}
        if(min(abs(t2-attr(la,'t')))<1e-6) {
          idx = which.min(abs(t2-attr(la,'t')))
        } else {
          attr(la,'t') = c(attr(la,'t'),t2);
          idx = length(attr(la,'t'))
        }
        la[[idx]] = la2
      } else {
        tran=transition_forward_fra(la1,lb2,ratein, locin, rateout, locout, pout, pnull)
        la2=tran$la2_tilde
        la[[i+1]]=la2
      }
      
      exp_events = tran$exp_event
      cv_t = sapply(1:length(locations), function(n) {
        tmp_vector = exp_events[[n]]/sum(la1[[n]]*lb1[[n]]*0:max.person[n])
        tmp_vector[is.na(tmp_vector)] = 0
        tmp_vector
      })
      cv = Map('+',cv,cv_t)
      
      la1=la2
      lb1=lb2
    } # k
    
    exp_events_list[[i+1]]=cv
  }
  
  #length.t = c(start.time:end.time,new.t)
  new.t=c(1:1441,new.t)
  la = unclass(la)[match(new.t,attr(la,'t'))]; attr(la,'t') = new.t;  attr(la,'c')="a"
  
  list(la=la, new.t=new.t, mini_timesteps=mini_timesteps, exp_events_list=exp_events_list, cv_old=cv_old)
}

# backward
#######################################################################################################

upd_backward<-function(v1,inc,out,pn,dec,len,lb_tm_n,lb_factor){
  v2=v1*pn - 0:(len-1)*v1*out
  v2[1:(len-1)]=v2[1:(len-1)]+v1[2:len]*inc
  v2[2:len]=v2[2:len]+1:(len-1)*v1[1:(len-1)]*dec
  v2=v2+lb_tm_n*lb_factor
  v2[v2<0] = 0
  v2[v2>1e100] = 1e100
  v2
}

transition_backward_fra<-function(la1,lb2,ratein, locin, rateout, locout, pout, pnull,lb_tm,lb_factor){
  m.inc=sapply(1:length(locations),function(n) sum( la1[[n]][1:max.person[n]] * lb2[[n]][2:(max.person[n]+1)] ) )
  m.eq=sapply(1:length(locations),function(n) sum(la1[[n]]*lb2[[n]]))
  m.eq[m.eq==0]=1e-20
  m.dec=sapply(1:length(locations),function(n) sum( 1:max.person[n] * la1[[n]][2:(max.person[n]+1)] * lb2[[n]][1:max.person[n]] ))
  
  fra.inc=m.inc/m.eq
  fra.dec=m.dec/m.eq
  pinc=sapply(1:length(locations),function(n) sum(  ratein[[n]] * fra.dec[locin[[n]] ] )) 
  pdec= sapply(1:length(locations),function(n)  sum(  rateout[[n]] * fra.inc[locout[[n]]  ] ) )
  
  #for each link, calculate the prob of transition at all other links 
  tran=lapply(1:length(locations), function(n)  rateout[[n]] * fra.dec[n] * fra.inc[locout[[n]]  ] )
  alltran=sum(unlist(tran))
  trother=numeric(length = length(locations))
  trother[]=alltran
  trother=trother-sapply(tran,sum) # transition at other links = all transition - transition from local link - transition to local link
  for(n in 1:length(locations)) trother[locout[[n]]]=trother[locout[[n]]]-tran[[n]]
  pn=1-pnull+trother
  
  lb1_tilde = lapply(1:length(locations), function(n) upd_backward(lb2[[n]],pinc[n],pout[n],pn[n],pdec[n],max.person[n]+1,lb_tm[[n]],lb_factor) )
  
  lg1=lapply(1:length(locations), function(n) la1[[n]]*lb1_tilde[[n]] )
  K=sapply(lg1, sum )
  lb1_tilde=lapply(1:length(locations), function(n) lb1_tilde[[n]]/K[n])
  
  list(lb1_tilde=lb1_tilde)
}

backward2 = function(start.time, end.time, la, lb, action_list, max.person,policy_network,learnable){
  new.t = c()
  length.lb = length(lb)
  
  lb_tm = sapply(1:length(locations),function(n) array(1,dim=length(lb[[1]][[n]])))
  lb_factor = 1/(end.time-start.time)/length(locations)
  
  for(i in (end.time-1):start.time){
    #print(i)
    
    la1=la[[i]]
    lb1=lb[[i]]
    lb2=lb[[i+1]]
    
    lg=matrix(c(sapply(input_state,function(n) {
      gamma=la1[[n]]*lb1[[n]]
      gamma=gamma/sum(gamma)
      sum(gamma* (0:(length(gamma)-1)))
    }),i),nrow = 1)
    lg = lg/state_scale
    
    action = policy_network %>% predict(lg)
    action = action/action_scale
    
    rate_slice = action2rate(action,max.person,la1,lb1)
    
    rate = rate_in_out_f(rate_slice,action_list)
    ratein_original=rate$ratein 
    rateout_original=rate$rateout
    
    m.eq=numeric(length = length(locations))
    m.eq=sapply(1:length(locations),function(n) sum(la1[[n]]*lb2[[n]]))
    m.eq[m.eq==0]=1e-20
    
    m.eq.x=numeric(length = length(locations))
    m.eq.x=sapply(1:length(locations),function(n) sum(0:max.person[n]*la1[[n]]*lb2[[n]]))
    
    pout=sapply(rateout_original, sum)
    pnull= sum(pout*m.eq.x/m.eq) - pout*m.eq.x/m.eq
    r_nnn=max.person*pout+pnull
    nnn = max(ceiling(r_nnn))
    nnn = min(nnn,3000)
    
    pout=pout/nnn
    pnull=pnull/nnn
    ratein=lapply(1:length(ratein_original), function(n) ratein_original[[n]]/nnn)
    rateout=lapply(1:length(rateout_original), function(n) rateout_original[[n]]/nnn)
    
    #print("--------------------------------nnn---------")
    #print(nnn)
    
    if(nnn>1) new.t=c(new.t,i+(nnn-1):1/nnn)
    
    for (k in nnn:1){
      t1 = i+(k-1)/nnn; t2 = i+k/nnn;
      la1=getSlice(la,t1)
      
      if(k!=nnn) {
        lb_tm = sapply(1:length(locations),function(n) array(0,dim=length(lb[[1]][[n]])))
        tran=transition_backward_fra(la1,lb2,ratein, locin, rateout, locout, pout, pnull,lb_tm,lb_factor)        
      } else {
        lr = RewardFunction(max.person, i, locations, action_list, info_network)
        lr = RewardNormalization(lr,R_min)
        lb_tm = Map('+',lr,(length(locations)-1))
        tran=transition_backward_fra(la1,lb2,ratein, locin, rateout, locout, pout, pnull,lb_tm,lb_factor)
      }
      
      lb1=tran$lb1_tilde
      lb2 = lb1
      
      if(k==1){
        lb[[i]]=lb1
      } else{
        if(length(attr(lb,'t'))==length.lb){lb = alloc(lb); length.lb = length(lb)}
        if(min(abs(t1-attr(lb,'t')))<1e-12) {
          lb[[which.min(abs(t1-attr(lb,'t')))]] <- lb1
        } else{
          attr(lb,'t') = c(attr(lb,'t'),t1)
          lb[[length(attr(lb,'t'))]]<-lb1
        }
      }
      
    } #k
  }
  
  #length.t = c(start.time:end.time,new.t)
  new.t=c(1:1441,rev(new.t) )
  lb = unclass(lb)[match(new.t,attr(lb,'t'))]; attr(lb,'t') = new.t;  attr(lb,'c')="b"
  list(lb = lb)
}

# M step
#######################################################################################################

M_step = function(start.time, end.time, la, lb, theta, action_list, max.person, new.t, mini_timesteps,exp_events_list,policy_network,learnable,cv_old){
  
  train_x = array(0,dim=c(end.time-start.time,2+1))
  train_y = array(0,dim=c(end.time-start.time,length(learnable)))
  
  for(i in start.time:(end.time-1)){
    cv = exp_events_list[[i+1]]
    la1 = la[[i]]
    lb1 = lb[[i]]
    train_x[i-start.time+1,1:2] = sapply(1:2,function(n) {
      gamma=la1[[n]]*lb1[[n]]
      gamma=gamma/sum(gamma)
      sum(gamma* (0:(length(gamma)-1)))
    })
    train_x[i-start.time+1,3] = i
    train_y[i-start.time+1,] = unlist(cv)[learnable]
  }
  
  # line search
  train_y = cv_old + 2*(train_y-cv_old)
  train_y = pmax(train_y,0)
  
  list(train_x=train_x,train_y=train_y)
}

#######################################################################################################








































