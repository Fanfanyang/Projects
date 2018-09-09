
source('vi-functions.R')

# policy network
if (TRUE) {
  # SynthTown
  #policy_network = keras_model_sequential() %>% layer_dense(units=12, input_shape = c(length(input_state)+1), activation='relu') %>% layer_dense(units=24, input_shape = c(3), activation='relu') %>% layer_dense(units=length(learnable), activation='relu')%>% compile(optimizer = optimizer_adam(lr=.001),loss = 'mse')
  # Berlin
  policy_network = keras_model_sequential() %>% layer_dense(units=64, input_shape = c(length(input_state)+1), activation='relu') %>% layer_dense(units=64, input_shape = c(3), activation='relu') %>% layer_dense(units=length(learnable), activation='relu')%>% compile(optimizer = optimizer_adam(lr=.001),loss = 'mse')
  
  # pretrain
  history <- policy_network %>% fit(x=train_x, y=train_y, epochs=1000, batch_size=100,verbose=0)
  print(summary(history$metrics[[1]]))
  
  action = policy_network %>% predict(train_x)
  
  plot(rowSums(train_y[,1:9]),type='l')
  lines(rowSums(action[,1:9]),type='l',col='red')
  lines(train_y[,10],type='l')
  lines(action[,10],type='l',col='blue')
}

# Main loop
#######################################################################################################
for(iter_r in 1:RLITER){
  cat(sprintf("iter_r: %d\n",iter_r))

  la_E = la_original
  lb_E = lb_original
  xt_est = array(0,dim=c(nrow(obs),ncol(obs)))
  train_x = c()
  train_y = c()
  
  t0 = 1
  start.time = 1
  end.time = 1441
  H = end.time - start.time
  obs = loc.d
  
  # E-step
  #######################################################################################################
  if (TRUE) {
    cat(sprintf("E-step\n"))
    aaa = forward2(start.time, end.time, la_E, lb_E, action_list, max.person,policy_network,learnable)
    la_E=aaa$la
    
    #estimate vehicle distribution
    for(ii in 1:ncol(obs)){
      xt_est[start.time:end.time,ii] = sapply(start.time:end.time, function(n){ 
        gamma=la_E[[n]][[ii]]
        gamma=gamma/sum(gamma)
        sum(gamma* (0:(length(gamma)-1))) })
    }
    
    # compute rewards
    lr_accum = 0
    for(tt in start.time:(end.time-1)) {
      lg_test = la_E[[tt]]
      group_idx = 1
      lr = RewardFunction(max.person, tt, locations, action_list, info_network)
      lr = RewardNormalization(lr,R_min)
      lr_l = unlist(sapply(c(1:length(locations)),function(n) sum(lr[[n]]*lg_test[[n]])))
      lr_accum = lr_accum + sum(lr_l/length(locations)/(end.time-start.time))
    }
    lr_accum = log(lr_accum)
  }
  
  # M-step
  #######################################################################################################
  if (TRUE) {
    cat(sprintf("M-step\n"))
    for(iter_v in 1:VIITER) {
      bbb = backward2(start.time, end.time, la_E, lb_E, action_list, max.person,policy_network,learnable)
      lb_E=bbb$lb 
      aaa = forward2(start.time, end.time, la_E, lb_E, action_list, max.person,policy_network,learnable)
      la_E=aaa$la
      exp_events_list=aaa$exp_events_list
      cv_old=aaa$cv_old
      new.t=aaa$new.t
      mini_timesteps=aaa$mini_timesteps
    }
    
    mstep = M_step(start.time, end.time, la_E, lb_E, theta, action_list, max.person, new.t, mini_timesteps,exp_events_list,policy_network,learnable,cv_old)
    train_x = rbind(train_x,mstep$train_x)
    train_y = rbind(train_y,mstep$train_y)
  }
  
  if (TRUE) {
    train_y = train_y*action_scale
    train_x = train_x/state_scale
    history <- policy_network %>% fit(x=train_x, y=train_y, epochs=2000, batch_size=100,verbose=0)
    
    print(summary(history$metrics[[1]]))
    action = policy_network %>% predict(train_x)
    plot(rowSums(train_y[,1:9]),type='l')
    lines(rowSums(action[,1:9]),type='l',col='red')
    lines(train_y[,10],type='l')
    lines(action[,10],type='l',col='blue') 
  }
  
  # plot
  #######################################################################################################
  if (TRUE) {
    if (iter_r == 1) {
      xt_baseline = xt_est
    }
    
    #plot vechile distribution
    layout(matrix(1:ncol(obs),ncol=1), heights=pmax(apply(obs,2,max),apply(loc.d,2,max))+10)
    par(mar=c(0,0,0,0),oma=c(5,2,0,1)+.1)
    for(ii in 1:ncol(obs)){
      plot(xt_baseline[,ii],type='l',col='black',xaxt='n',xlab='',ylab=colnames(obs)[ii],ylim = c(0,max(loc.d[,ii])+1))
      lines(xt_est[,ii],col="red",lty=1)
      if(ii==1) text(1300,10,paste(iter_r, " f lg" ),col = 'red',lwd=3)
      abline(v=c(540,1020),col='gray')
    }
    axis(side=1)
    
    # compute rewards
    lr_history = lappend(lr_history,lr_accum)
    cat(sprintf("System log expected future rewards at %d: %f\n",t0,lr_accum))
  }
  
  # save data
  if (TRUE) {
    xt_est_vi = xt_est
    save(xt_est_vi,file='result/xt_est_vi.RData')
    save(lr_history,file='result/lr_history.RData')
  }
}









