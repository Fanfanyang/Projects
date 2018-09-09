library('Matrix')
require('TTR')
require('igraph')
require('survey')
require('grr')
require('RcppEigen')
require('Rcpp')
sourceCpp("rcpp_try4.cpp")


location = readRDS("../../data_download1/ContextData/SITE_ARR_LONLAT.RDS")

for (i in c(1:20)) {
  print(i)
  if(i<10) {
    file.name = paste('../../data_download1/SET2/SET2_P0',i,sep='')
  } else {
    file.name = paste('../../data_download1/SET2/SET2_P',i,sep='')
  }
  file.name = paste(file.name,'RDS',sep='.')
  realdata = readRDS(file = file.name)
  
  x=realdata$timestamp
  day = x$mday
  hour = x$hour
  min = x$min
  time = (day*24 + hour)*6 + min/10
  
  tower = realdata$site_id
  person = realdata$userid
  
  unique.person = unique(person)
  
  person = factor(person,levels = unique(person))
  levels(person) = c(1:length(unique.person))
  person = as.numeric(person)
  
  min.time = min(time)
  max.time = max(time)
  delta.t = 1
  td = seq(from=min.time, to=max.time, by=delta.t)
  
  rm(realdata)
  realdata = data.frame(person,time,tower)
  realdata = realdata[order(realdata[,2]),]
  
  #person.state.d
  person.state.d = PersonState(realdata$time,realdata$tower,realdata$person,length(td),length(unique.person),min.time)
  person.state.d = InitLoc(person.state.d)
  
  file.name = paste('orig_dynamics/person.state.d.original',i,sep = '.')
  file.name = paste(file.name,'RDS',sep='.')
  saveRDS(person.state.d,file=file.name)
}














