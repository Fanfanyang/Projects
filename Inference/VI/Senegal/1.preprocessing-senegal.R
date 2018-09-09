load("benchmark with dakar dataset/person.state.d.RData")

#240
person.state.d=person.state.d[(240+1):nrow(person.state.d),]

n.row=nrow(person.state.d)
n.col=ncol(person.state.d)
n.locations=length(unique(as.vector(person.state.d)))
person.state.d=matrix(match(as.vector(person.state.d), sort(unique(as.vector(person.state.d)))),nrow = n.row,ncol = n.col)



locations=1:n.locations
loc.d = t(apply(person.state.d, 1, function(x) table(factor(x, levels=locations ))))

td=seq(from=0,to=24*3600,by=60)
m.time = table(c(head(person.state.d,-1)), c(tail(person.state.d,-1)),cut(td[row(head(person.state.d,-1)) + 240 ]/3600,breaks = 0:4 *6))
m.time = sweep(m.time*.99, MARGIN = 1:2, STATS = table(c(head(person.state.d,-1)), c(tail(person.state.d,-1)))*.01, FUN = '+')
m.time = sweep(m.time, MARGIN = c(1,3), STATS = colSums(aperm(m.time,perm = c(2,1,3)),dims = 1),FUN = '/')
dimnames(m.time)[[1]] = dimnames(m.time)[[2]] = 1:length(locations)


#only consider neighbors
rate_in=list()
rate_out=list()
loc_in=list()
loc_out=list()

for(i in 1:dim(m.time)[3]){
  m=m.time[,,i]
  diag(m)=0
  rownames(m)=1:length(locations)
  colnames(m)=1:length(locations)
  
  rate_in[[i]]=lapply(1:ncol(m), function(n) {
    m[,n][m[,n]!=0]
  })
  loc_in[[i]]=lapply(1:ncol(m), function(n) {
    as.integer(names(rate_in[[i]][[n]]))
  })
  rate_out[[i]]=lapply(1:ncol(m), function(n) {
    m[n,][m[n,]!=0]
  })
  loc_out[[i]]=lapply(1:ncol(m), function(n) {
    as.integer(names(rate_out[[i]][[n]]))
  })
}

rate_in_f=function(i) rate_in[[ceiling((i+240)/(nrow(loc.d)+240)*length(rate_in))]]
rate_out_f=function(i) rate_out[[ceiling((i+240)/(nrow(loc.d)+240)*length(rate_out))]]
loc_in_f=function(i) loc_in[[ceiling((i+240)/(nrow(loc.d)+240)*length(loc_in))]]
loc_out_f=function(i) loc_out[[ceiling((i+240)/(nrow(loc.d)+240)*length(loc_out))]]


sample.obs.matrix = function(person.state.d, obs.scale){
  obs.training = lapply(1:100, function(n){
    ndx0 = sample(1:ncol(person.state.d), ceiling(ncol(person.state.d)/obs.scale))
    obs = t(apply(person.state.d[,ndx0], 1, function(x) table(factor(x, levels=locations) )))
    ndx2 = which(loc.d>0)
    data.frame(groundtruth=loc.d[ndx2], obs = trunc(obs[ndx2]*ncol(person.state.d)/length(ndx0)) )
    
  })
  obs.training = do.call(rbind, obs.training)
  obs.training = rbind(obs.training, c(0,0))
  obs.table = table(obs.training[,1], obs.training[,2])
  max.obs=max(obs.training)+10
  obs.rows = approx(as.numeric(rownames(obs.table)), 1:nrow(obs.table),  0:max.obs, method = 'constant', ties = 'ordered', f = 0, rule = 2)
  obs.cols = approx(as.numeric(colnames(obs.table)), 1:ncol(obs.table),  0:max.obs, method = 'constant', ties = 'ordered', f = 0, rule = 2)
  obs.matrix=obs.table[obs.rows$y,obs.cols$y] #
  obs.matrix=sweep(obs.matrix, 1, rowSums(obs.matrix),'/') #
  obs.matrix
}
obs.scale = 2
obs.matrix = sample.obs.matrix(person.state.d, obs.scale = obs.scale)
#image(z=t(asinh(1000*obs.matrix)),x=1:ncol(obs.matrix) -1, y=1:nrow(obs.matrix) -1,xlab='# oberved vehicles scaled', ylab='# vehicles', asp=1)
#abline(coef=c(0,1))


obs.matrix[obs.matrix==0]=1e-20
obs.matrix=sweep(obs.matrix,1,rowSums(obs.matrix),FUN = '/')

maxloc.d=apply(loc.d,2, max )
max.person=ifelse(maxloc.d<=10,maxloc.d+5,maxloc.d+10)

dataempty=lapply(1:nrow(loc.d), function(n){
  lapply(1:length(locations), function(m){
    rep(1,max.person[m]+1)
  })
})

sliceempty=lapply(1:length(locations), function(m){
  rep(0,max.person[m]+1)
})

start=sliceempty
for( i in 1:length(locations)) start[[i]][loc.d[1,i]+1]=1

end=sliceempty
for( i in 1:length(locations)) end[[i]][loc.d[nrow(loc.d),i]+1]=1

la=dataempty
la[[1]]=start
lb=dataempty
lb[[length(lb)]]=end


alloc = function(x){
  old.t = attr(x,'t')
  old.c = attr(x,'c')
  if(length(attr(x, 't'))==length(x)) length(x) = length(x)*2 #alloc memory
  attr(x,'t') = old.t
  attr(x,'c') = old.c
  x
}

# read a slice from filtration, previous nearest one
getSlice <- function(x, t ){
  tt = attr(x, 't')
  
  if(attr(x,'c')=="a"){
    t0 = which(tt==max(tt[tt<=t]))
    y=x[[t0]]
  }
  if(attr(x,'c')=="b"){
    t0 = which(tt==min(tt[tt>=t]))
    y=x[[t0]]
  }
  y
}


lg=la
for(i in 1:length(lg)){
  lg[[i]]=lapply(1:length(locations), function(n) la[[i]][[n]]*lb[[i]][[n]]/sum(la[[i]][[n]]*lb[[i]][[n]]))
} 


attr(la,'t') =attr(lb,'t') = attr(lg,'t') = 1:nrow(loc.d)
attr(la,'c')="a"
attr(lb,'c')="b"
attr(lg,'c')="a"

obs.scale=5
observable= sort( order( sapply(rate_in_f(500),length), decreasing = T)   [1:ceiling(length(locations)/obs.scale)]  ) # setdiff(dimnames(obs.prob)$location,c("h","w"))
unobservable=setdiff(1:length(locations),observable)
observable_nominal=as.character(observable)

if(max(max.person[observable])+1 > nrow(obs.matrix) ){
  k1=max(max.person[observable])+1
  k2=nrow(obs.matrix)
  
  obs.matrix=rbind(obs.matrix,matrix(0,nrow = k1-k2,ncol=ncol(obs.matrix)))
  for(k in (k2+1):k1){
    obs.matrix[k,(1+k-k2):ncol(obs.matrix)]=obs.matrix[k2,1:(ncol(obs.matrix)+k2-k)]
  }
}
obs.matrix[obs.matrix==0]=1e-20
obs.matrix=sweep(obs.matrix,1,rowSums(obs.matrix),FUN = '/')

#obs = t(apply(person.state.d[,observable], 1, function(x) table(factor(x, levels=locations) )))
#obs=sapply(1:ncol(obs),function(n) pmin(max.person[n],round(obs[,n]*obs.scale)))
obs=loc.d

observation=lapply(observable, function(n) obs[,n])
names(observation)=observable_nominal

remove(list = setdiff(ls(),c('observation','obs.matrix','lg','loc.d','rate_in','obs','person.state.d',
                             'rate_out','rate_in_f','rate_out_f',
                             'loc_in','loc_out','loc_in_f','loc_out_f',
    'la','lb','m.time','max.person','observable_nominal','unobservable','observable','alloc','getSlice','locations')))

save.image(file = "benchmark with dakar dataset/inference.RData")