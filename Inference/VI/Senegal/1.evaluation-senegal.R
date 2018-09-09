
iter=1
ss=1
ee=300

la1300=readRDS(paste("~/Google Drive/Online/Lab/@multi-agent simulation/update/benchmark with dakar dataset/server/", ss, " to ", ee,  " the ", iter,  " forward la.RDS", sep = "")) 
lb=readRDS(paste("~/Google Drive/Online/Lab/@multi-agent simulation/update/benchmark with dakar dataset/server/", ss, " to ", ee,  " the ", iter,  "backward lb.RDS", sep = "")) 



cols=sample(1:ncol(loc.d),10)
#cols=sample(observable,10)
#cols=sample(unobservable,10)

layout(matrix(1:10,ncol=1), heights=apply(loc.d[ss:ee,cols],2,max)+1)
par(mar=c(0,0,0,0),oma=c(5,2,0,1)+.1)
for(ii in cols){
  plot(loc.d[ss:ee,ii],type='l',col='black',xaxt='n',xlab='',ylab=colnames(loc.d)[ii],ylim = c(0,max(loc.d[ss:ee,ii])+1))
  lines(sapply(1:(ee-ss+1), function(n){   
    a=la[[n]][[ii]]
    sum( a* (0:(length( a )-1)))
  }),col="red",lty=1)
  text(90,0.5,as.character(ii),col = 'red',lwd=2)
}
axis(side=1)



#cols=sample(1:ncol(loc.d),10)
cols=sample(observable,10)
#cols=sample(unobservable,10)

layout(matrix(1:10,ncol=1), heights=apply(loc.d[ss:ee,cols],2,max)+1)
par(mar=c(0,0,0,0),oma=c(5,2,0,1)+.1)
for(ii in cols){
  plot(loc.d[ss:ee,ii],type='l',col='black',xaxt='n',xlab='',ylab=colnames(loc.d)[ii],ylim = c(0,max(loc.d[ss:ee,ii])+1))
  lines(sapply(1:(ee-ss+1), function(n){   
    gamma=la[[n]][[ii]]*lb[[n]][[ii]]
    gamma=gamma/sum(gamma)
    sum(gamma* (0:(length(gamma)-1))) }),col="red",lty=1)
  text(90,0.5,as.character(ii),col = 'red',lwd=2)
}
axis(side=1)