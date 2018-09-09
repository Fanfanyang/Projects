la_int = unclass(la)[match(1:1441,attr(la,'t'))]; attr(la_int,'t') = 1:1441;  attr(la_int,'c')="a"
lb_int = unclass(lb)[match(1:1441,attr(lb,'t'))]; attr(lb_int,'t') = 1:1441; attr(lb_int,'c') ="b"

#plot the mean of lb
layout(matrix(1:ncol(obs),ncol=1), heights=pmax(apply(obs,2,max),apply(loc.d,2,max))+1)
par(mar=c(0,0,0,0),oma=c(5,2,0,1)+.1)
for(ii in 1:ncol(obs)){
  plot(loc.d[,ii],type='l',col='black',xaxt='n',xlab='',ylab=colnames(obs)[ii],ylim = c(0,max(loc.d[,ii])+1))
  lines(obs[,ii],type='l',lty=2,col='black',xaxt='n',xlab='',ylab=colnames(obs)[ii],ylim = c(0,max(obs[,ii])+1))
  lines(sapply(1:(nrow(obs)), function(n){ 
    gamma=la_int[[n]][[ii]]*lb_int[[n]][[ii]]
    gamma=gamma/sum(gamma)
    sum(gamma* (0:(length(gamma)-1))) }),col="red",lty=1)
}
axis(side=1)


lg_int = unclass(lg)[match(1:1441,attr(lg,'t'))]; attr(lg_int,'t') = 1:1441;  attr(lg_int,'c')="a"
layout(matrix(1:ncol(obs),ncol=1), heights=pmax(apply(obs,2,max),apply(loc.d,2,max))+1)
par(mar=c(0,0,0,0),oma=c(5,2,0,1)+.1)
for(ii in 1:ncol(obs)){
  plot(loc.d[,ii],type='l',col='black',xaxt='n',xlab='',ylab=colnames(obs)[ii],ylim = c(0,max(loc.d[,ii])+1))
  lines(obs[,ii],type='l',lty=2,col='black',xaxt='n',xlab='',ylab=colnames(obs)[ii],ylim = c(0,max(obs[,ii])+1))
  lines(sapply(1:(nrow(obs)), function(n){ 
    gamma=lg[[n]][[ii]]
    sum(gamma* (0:(length(gamma)-1))) }),col="red",lty=1)
}
axis(side=1)