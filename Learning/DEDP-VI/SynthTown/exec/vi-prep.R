

source('vi-functions.R')

# to be put in preparation
if (TRUE) {
  lr_history = list()
  la_original = la_Tmt
  lb_original = lb_Tmt
  obs = loc.d
  
  info_network$info_facility$begin[[1]] = 16
  info_network$info_facility$begin[[2]] = 8    
  info_network$info_facility$end[[1]] = 8
  info_network$info_facility$end[[2]] = 16
  max.person = unlist(lapply(la_original[[1]],function(x) length(x)))-1
  R_min = max.person[1]*(-18)
  RLITER = 5
  VIITER = 1
  t0 = 1
  t0.max = 1441
  learnable = c(1:10)
  action_scale = 1e3
  state_scale = 10
  
  train_x = cbind(Xt_real[1:1440,1:2],c(1:1440))
  train_y = array(0,dim=c(nrow(train_x),length(learnable)))
  
  for(t0 in c(1:1440)) {
    theta = unlist(lapply(PpolicyUpdate[[t0]],function(x) x[-1]))
    train_y[t0,] = theta[learnable]
  }
  train_y = train_y*action_scale*0.9
  train_x = train_x/state_scale
  
  tot_theta = 43
  input_state = c(1:2)
}

save.image("inference_1_synthtown.RData")










