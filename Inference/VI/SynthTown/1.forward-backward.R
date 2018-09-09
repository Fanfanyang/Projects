
source('0.MH_fb_functions.R')

# preprocessing: observation steps
if (TRUE) {
  step = 60
}

for(iter in 1:5){
  la_old=la
  lb_old=lb
  
  aaa = forward2(la, lb, obs, rate_in_f, rate_out_f, max.person, step)
  
  la=aaa$la
  
  la_int = unclass(la)[match(1:1441,attr(la,'t'))]; attr(la_int,'t') = 1:1441;  attr(la_int,'c')="a"
  lb_int = unclass(lb)[match(1:1441,attr(lb,'t'))]; attr(lb_int,'t') = 1:1441; attr(lb_int,'c') ="b"
  
  print(sprintf('The %d forward completed',iter))

  la_old=la
  lb_old=lb
  
  bbb = backward2(la, lb, obs, rate_in_f, rate_out_f, max.person, step)
  
  lb=bbb$lb
  
  la_int = unclass(la)[match(1:1441,attr(la,'t'))]; attr(la_int,'t') = 1:1441;  attr(la_int,'c')="a"
  lb_int = unclass(lb)[match(1:1441,attr(lb,'t'))]; attr(lb_int,'t') = 1:1441; attr(lb_int,'c') ="b"
  
  print(sprintf('The %d backward completed',iter))
  
  layout(matrix(1:ncol(obs),ncol=1), heights=pmax(apply(obs,2,max),apply(loc.d,2,max))+1)
  par(mar=c(0,0,0,0),oma=c(5,2,0,1)+.1)
  for(ii in 1:ncol(obs)){
    plot(loc.d[,ii],type='l',col='black',xaxt='n',xlab='',ylab=colnames(obs)[ii],ylim = c(0,max(loc.d[,ii])+1))
    lines(obs[,ii],type='l',lty=2,col='black',xaxt='n',xlab='',ylab=colnames(obs)[ii],ylim = c(0,max(obs[,ii])+1))
    lines(sapply(1:(nrow(obs)), function(n){ 
      gamma=la_int[[n]][[ii]]*lb_int[[n]][[ii]]
      gamma=gamma/sum(gamma)
      sum(gamma* (0:(length(gamma)-1)) ) }),col="red",lty=1)
    if(ii==1) text(1300,10,paste(iter, " f lg" ),col = 'red',lwd=3)
  }
  axis(side=1)
  #dev.off()
}

name.file = paste('data_result/la',step,sep = '_')
name.file = paste(name.file,'RDS',sep = '.')
saveRDS(la,file = name.file)
name.file = paste('data_result/lb',step,sep = '_')
name.file = paste(name.file,'RDS',sep = '.')
saveRDS(lb,file = name.file)









if (FALSE) {
  
  for(iter in 1:300){
    
    la_old=la
    lb_old=lb
    
    aaa = forward2(la, lb, obs, rate_in_f, rate_out_f, max.person)
    
    la=aaa$la
    
    la_int = unclass(la)[match(1:1441,attr(la,'t'))]; attr(la_int,'t') = 1:1441;  attr(la_int,'c')="a"
    lb_int = unclass(lb)[match(1:1441,attr(lb,'t'))]; attr(lb_int,'t') = 1:1441; attr(lb_int,'c') ="b"
    
    #plot the mean of la
    layout(matrix(1:ncol(obs),ncol=1), heights=pmax(apply(obs,2,max),apply(loc.d,2,max))+1)
    par(mar=c(0,0,0,0),oma=c(5,2,0,1)+.1)
    for(ii in 1:ncol(obs)){
      plot(loc.d[,ii],type='l',col='black',xaxt='n',xlab='',ylab=colnames(obs)[ii],ylim = c(0,max(loc.d[,ii])+1))
      lines(obs[,ii],type='l',lty=2,col='black',xaxt='n',xlab='',ylab=colnames(obs)[ii],ylim = c(0,max(obs[,ii])+1))
      lines(sapply(1:(nrow(obs)), function(n){ 
        gamma=la_int[[n]][[ii]]
        gamma=gamma/sum(gamma)
        sum(gamma* (0:(length(gamma)-1))) }),col="red",lty=1)
      if(ii==1) text(1300,10,paste(iter, " f la" ),col = 'red',lwd=3)
    }
    axis(side=1)
    
    
    #  png(paste("The ", i, " forward.png" ))
    #plot the mean of la*lb
    layout(matrix(1:ncol(obs),ncol=1), heights=pmax(apply(obs,2,max),apply(loc.d,2,max))+1)
    par(mar=c(0,0,0,0),oma=c(5,2,0,1)+.1)
    for(ii in 1:ncol(obs)){
      plot(loc.d[,ii],type='l',col='black',xaxt='n',xlab='',ylab=colnames(obs)[ii],ylim = c(0,max(loc.d[,ii])+1))
      lines(obs[,ii],type='l',lty=2,col='black',xaxt='n',xlab='',ylab=colnames(obs)[ii],ylim = c(0,max(obs[,ii])+1))
      lines(sapply(1:(nrow(obs)), function(n){ 
        gamma=la_int[[n]][[ii]]*lb_int[[n]][[ii]]
        gamma=gamma/sum(gamma)
        sum(gamma* (0:(length(gamma)-1)) ) }),col="red",lty=1)
      if(ii==1) text(1300,10,paste(iter, " f lg" ),col = 'red',lwd=3)
    }
    axis(side=1)
    #  dev.off()
    print(sprintf('The %d forward completed',iter))
    
    la_old=la
    lb_old=lb
    
    bbb = backward2(la, lb, obs, rate_in_f, rate_out_f, max.person)
    
    lb=bbb$lb
    
    la_int = unclass(la)[match(1:1441,attr(la,'t'))]; attr(la_int,'t') = 1:1441;  attr(la_int,'c')="a"
    lb_int = unclass(lb)[match(1:1441,attr(lb,'t'))]; attr(lb_int,'t') = 1:1441; attr(lb_int,'c') ="b"
    
    #plot the mean of lb
    layout(matrix(1:ncol(obs),ncol=1), heights=pmax(apply(obs,2,max),apply(loc.d,2,max))+1)
    par(mar=c(0,0,0,0),oma=c(5,2,0,1)+.1)
    for(ii in 1:ncol(obs)){
      plot(loc.d[,ii],type='l',col='black',xaxt='n',xlab='',ylab=colnames(obs)[ii],ylim = c(0,max(loc.d[,ii])+1))
      lines(obs[,ii],type='l',lty=2,col='black',xaxt='n',xlab='',ylab=colnames(obs)[ii],ylim = c(0,max(obs[,ii])+1))
      lines(sapply(1:(nrow(obs)), function(n){ 
        gamma=lb_int[[n]][[ii]]
        gamma=gamma/sum(gamma)
        sum(gamma* (0:(length(gamma)-1)) ) }),col="red",lty=1)
      if(ii==1) text(1300,10,paste(iter, "b lb" ),col = 'red',lwd=3)
    }
    axis(side=1)
    
    
    
    #  png(paste("The ", i, " backward.png" ))
    #plot the mean of la*lb
    layout(matrix(1:ncol(obs),ncol=1), heights=pmax(apply(obs,2,max),apply(loc.d,2,max))+1)
    par(mar=c(0,0,0,0),oma=c(5,2,0,1)+.1)
    for(ii in 1:ncol(obs)){
      plot(loc.d[,ii],type='l',col='black',xaxt='n',xlab='',ylab=colnames(obs)[ii],ylim = c(0,max(loc.d[,ii])+1))
      lines(obs[,ii],type='l',lty=2,col='black',xaxt='n',xlab='',ylab=colnames(obs)[ii],ylim = c(0,max(obs[,ii])+1))
      lines(sapply(1:(nrow(obs)), function(n){ 
        gamma=la_int[[n]][[ii]]*lb_int[[n]][[ii]]
        gamma=gamma/sum(gamma)
        sum(gamma* (0:(length(gamma)-1))) }),col="red",lty=1)
      if(ii==1) text(1300,10,paste(iter, "b lg" ),col = 'red',lwd=3)
    }
    axis(side=1)
    #  dev.off()
    print(sprintf('The %d backward completed',iter))
  }
}



