
#load from prep1
if (TRUE) {
  rm(list=ls())
  load('data_result1/m.time.RData')
  load('data_result1/Xt_real.RData')
  load('data_result1/person.state.d.RData')
}

#data
if (TRUE) {
  loc.d=Xt_real
}

#values
if (TRUE) {
  locations=colnames(m.time)
  
  #only consider neighbors
  rate_in=list()
  rate_out=list()
  loc_in=list()
  loc_out=list()
  
  for(i in 1:dim(m.time)[3]){
    m=m.time[,,i]
    diag(m)=0
    rownames(m)=1:nrow(m)
    colnames(m)=1:ncol(m)
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
  
  rate_in_f=function(i) rate_in[[ceiling(i/(nrow(loc.d)/length(rate_in)))]]
  rate_out_f=function(i) rate_out[[ceiling(i/(nrow(loc.d)/length(rate_out)))]]
  loc_in_f=function(i) loc_in[[ceiling(i/(nrow(loc.d)/length(loc_in)))]]
  loc_out_f=function(i) loc_out[[ceiling(i/(nrow(loc.d)/length(loc_out)))]]
  
  #only main links are observable
  observable=c(3,22) # setdiff(dimnames(obs.prob)$location,c("h","w"))
  unobservable=setdiff(1:length(locations),observable)
  observable_nominal=as.character(observable)
  
  maxloc.d=apply(loc.d,2, max )
  max.person=ifelse(maxloc.d<=10,maxloc.d+5,maxloc.d+10)
  #max.person=apply(loc.d,2, max )
  #max.person[] = max(max.person)+5
  
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
  lb[[1441]]=end
  
  # change by Fan Yang, lb end dont know? To be done
  #lb[[length(lb)]]=end
  
  lg=la
  for(i in 1:length(lg)){
    lg[[i]]=lapply(1:length(locations), function(n) la[[i]][[n]]*lb[[i]][[n]]/sum(la[[i]][[n]]*lb[[i]][[n]]))
  } 
  
  attr(la,'t') =attr(lb,'t') = attr(lg,'t') = 1:nrow(loc.d)
  attr(la,'c')="a"
  attr(lb,'c')="b"
  attr(lg,'c')="a"
}

#functions
if (TRUE) {
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
}

#save data
if (TRUE) {
  remove(list = setdiff(ls(),c('lg','loc.d','rate_in',
                               'rate_out','rate_in_f','rate_out_f',
                               'loc_in','loc_out','loc_in_f','loc_out_f',
                               'la','lb','m','m.time','max.person','observable_nominal',
                               'unobservable','observable','alloc','getSlice','locations',
                               'Xt_real','person.state.d'
                               )))
  
  save.image(file = "data_result2/inference_1_synthtown.RData")
}






















