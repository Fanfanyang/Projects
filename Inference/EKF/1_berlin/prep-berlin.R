library(ggplot2)
library('Matrix')
require('TTR')
require('igraph')
require('survey')
require('grr')
library(MASS)
require('numDeriv')
require('mvtnorm')
require('Rcpp')
sourceCpp('rcpp_prep.cpp')

# pre-processing
if (TRUE) {
  network = readRDS('../../particle_filtering/data_download1/ContextData/Senegal_roads.RDS')
  load('../../particle_filtering/2_Senegal/bench_senegal1/data_prep/tower_dakar.RData')
  load('../../particle_filtering/2_Senegal/bench_senegal1/data_prep/lane.RData')  #edge number
  load('../../particle_filtering/2_Senegal/bench_senegal1/data_prep/shortest_path.RData')   #node name
  
  #preprocessing
  lane = unique(unlist(lane))
  lane=lane-1666
  node = unique(unlist(shortest_path))
  node = match(node,as.numeric(rownames(network$n)))
  node=node[-which(is.na(node))]
  node = unique(c(node,tower_dakar))
  e = network$e[lane,]
  n = network$n[node,]
  network_dakar = list(n=n,e=e)
  saveRDS(network_dakar,file='data_prep/network_dakar.RData')
}

# generate stoichiometry matrix S1 according to real road map
# row: links column: events
if (TRUE) {
  network_dakar = readRDS('data_prep/network_dakar.RData')
  e = network_dakar$e
  e$from = as.numeric(levels(e$from))[e$from]
  e$to = as.numeric(levels(e$to))[e$to]
  #18219
  inx = CPInx(e$from,e$to)
  S = CPS1(e$from,e$to,inx)
  save(S,file='data_exec/S1.RData')
}

#generate S2
if (TRUE) {
  load('data_exec/m.RData')
  S = CPS2(m,7877)
  save(S,file = 'data_exec/S2.RData')
}








# home:1, work:2, other links 3:25
S = matrix(0,nrow=25,ncol=43)
inx = 1
for(i in 1:length(e$from)){
    #   print(i)
    #   sinfrom = as.integer(e$from[i])
    sinto = as.integer(e$to[i])
    for(j in 1:length(e$from)){
        if (sinto == e$from[j]){
            S[i+2,inx] = -1
            S[j+2,inx] = 1
            inx = inx + 1
        }
    }
}
# 31 events before, now handle home and work case
home = 2 # node value
work = 13 # node value
for(i in 1:length(e$from)){
    sinfrom = as.integer(e$from[i])
    sinto = as.integer(e$to[i])
    if (sinto == home){  # enter home
        S[i+2,inx] = -1
        S[1,inx] = 1
        inx = inx + 1
    }
    if (sinfrom == home){  # leave home
        S[1,inx] = -1
        S[i+2,inx] = 1
        inx = inx + 1
    }
    if (sinto == work){  # enter work
        S[i+2,inx] = -1
        S[2,inx] = 1
        inx = inx + 1
    }
    if (sinfrom == work){  # leave work
        S[2,inx] = -1
        S[i+2,inx] = 1
        inx = inx + 1
    }
}

# initialization 2000 cars in total, observe for 24 hours
# observations matrix: loc.d, initial state: loc.d[1,]
# use the simplest event rate as before, derive the vector for each event
event_rate = matrix(0, nrow = ncol(S), ncol = 1)
for(i in 1:nrow(event_rate)){
    efrom = match(-1,S[,i])
    eto = match(1,S[,i])
    event_rate[i] = m[efrom, eto]
}

event_rate.by.time = matrix(0, nrow = ncol(S), ncol = dim(m.by.time)[1]) #@
for(i in 1:nrow(event_rate)){
    efrom = match(-1,S[,i])
    eto = match(1,S[,i])
    event_rate.by.time[i,] = c(m.by.time[,efrom, eto])
}






















