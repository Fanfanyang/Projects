
iter=2
ss=401
ee=500

la=readRDS(paste("~/Google Drive/Online/Lab/@multi-agent simulation/update/benchmark with dakar dataset/server/2- ", ss, " to ", ee,  " the ", iter,  " forward la.RDS", sep = "")) 
lb=readRDS(paste("~/Google Drive/Online/Lab/@multi-agent simulation/update/benchmark with dakar dataset/server/2- ", ss, " to ", ee,  " the ", iter,  "backward lb.RDS", sep = "")) 

normproduct_mv<-function(m1,v1,m2,v2){
  v=v1*v2/(v1+v2)
  m=(m1*v2+m2*v1)/(v1+v2)
  rbind(m,v)
}

#cols=sample(1:ncol(loc.d),10)
cols=sample(observable,10)
#cols=sample(unobservable,10)

layout(matrix(1:10,ncol=1), heights=apply(loc.d[ss:ee,cols],2,max)+1)
par(mar=c(0,0,0,0),oma=c(5,2,0,1)+.1)
for(ii in cols){
  plot(loc.d[ss:ee,ii],type='l',col='black',xaxt='n',xlab='',ylab=colnames(loc.d)[ii],ylim = c(0,max(loc.d[ss:ee,ii])+1))
  lines(sapply(1:(ee-ss+1), function(n){   
    la[[n]][1,ii]
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
  plot(loc.d[ss:ee,ii],type='l',col='black',xaxt='n',xlab='',ylab=colnames(loc.d)[ii],ylim = c(0,max(loc.d[ss:ee,ii])+1) )
  lines(sapply(1:(ee-ss+1), function(n){   
    a=la[[n]][,ii]
    b=lb[[n]][,ii]
    normproduct_mv(a[1],a[2],b[1],b[2])[1] }),col="red",lty=1)
  text(90,0.5,as.character(ii),col = 'red',lwd=2)
}
axis(side=1)