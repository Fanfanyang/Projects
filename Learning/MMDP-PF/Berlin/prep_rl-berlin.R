
library(data.table)
require('RcppEigen')
require('Rcpp')
sourceCpp("rcpp_prep_rl.cpp")

#load data
load("data_exec/Xt_real.RData")
load('data_exec/obs.matrix.RData')
load('data_prep/person.state.d.RData')
load('data_exec/Yt.RData')
load('data_prep/td.RData')
load('data_prep/locations.RData')
load('data_prep/facility_length.RData')
network = readRDS(file = "data_prep/network.RDS")
#policy tmp
if (FALSE) {
  policy_template <- list()
  for (i in c(1:length(locations))) {
    from <- which(possible_actions[,1]==i)
    policy_template <- lappend(policy_template,array(0,dim=length(from)))
  }
  save(policy_template,file='data_exec/policy_template.RData')
}
load('data_exec/policy_template.RData')

#model definition
Agents = c(1:ncol(person.state.d))
Time = c(1:nrow(person.state.d))
Actions = locations
States = locations
NumAgents = length(Agents)
NumTime = length(Time)
NumActions = length(Actions)
NumStates = length(States)


#functions
lappend <- function (lst, ...){
  lst <- c(lst, list(...))
  return(lst)
}

PolicyFunction <- function(person.state.d,locations, possible_actions, SmallProb,policy_template) {
  
  action_list <- list()
  for (i in c(1:length(locations))) {
    from <- which(possible_actions[,1]==i)
    action_list <- lappend(action_list,possible_actions[from,2])
  }
  if (FALSE) {  
    policy_template <- list()
    for (i in c(1:length(locations))) {
      from <- which(possible_actions[,1]==i)
      policy_template <- lappend(policy_template,array(SmallProb,dim=length(from)))
    }
  }
  person.state.d <- matrix(as.numeric(factor(person.state.d, levels=locations)), nrow=nrow(person.state.d))
  
  Ppolicy <- list()
  for (i in c(1:(nrow(person.state.d)-1))) {
    print(i)
    sourceCpp("rcpp_prep_rl.cpp")
    policy_tmp3 <- PolicyList(person.state.d[i,],person.state.d[i+1,],policy_template,action_list,SmallProb)
    policy_tmp3 <- lapply(policy_tmp3, function(x) x/sum(x))
    Ppolicy <- lappend(Ppolicy,policy_tmp3)
  }
  
  return(list(Ppolicy=Ppolicy,action_list=action_list))
}

PossibleActionFunction <- function(network,locations,facility_length) {
  e = network$e
  #sinto: node e$to, e in network$e sequence
  sinto = array(0,dim=length(locations))
  for (i in c(1:length(locations))) {
    if (i <= facility_length) {
      link_tmp = as.numeric(strsplit(locations[i],'@')[[1]][2])
    } else {
      link_tmp = as.numeric(locations[i])
    }
    sinto[i] = as.integer(as.character(e$to[link_tmp]))
  }
  sinfrom = array(0,dim=length(locations))
  for (i in c(1:length(locations))) {
    if (i <= facility_length) {
      link_tmp = as.numeric(strsplit(locations[i],'@')[[1]][2])
    } else {
      link_tmp = as.numeric(locations[i])
    }
    sinfrom[i] = as.integer(as.character(e$from[link_tmp]))
  }
  
  #156430
  possible_actions = PossibleAction(sinto,sinfrom,facility_length)
  return(possible_actions)
}

RoadLoadFunction <- function(network,scale_factor) {
  Roadload <- array(0,dim=nrow(network$e))
  Roadload <- as.numeric(as.character(network$e$length))/as.numeric(as.character(network$e$freespeed)) * (as.numeric(as.character(network$e$capacity))/3600) * as.numeric(as.character(network$e$lanes)) * scale_factor
  
  TimeMoveOut <- array(0,dim=nrow(network$e))
  TimeMoveOut <- as.numeric(as.character(network$e$length))/as.numeric(as.character(network$e$freespeed))/60
  TimeMoveOut <- pmax(TimeMoveOut,1)
  
  return(list(Roadload=Roadload,TimeMoveOut=TimeMoveOut))
}


FacilityIndex <- function(locations,facility_length) {
  #home,leis,other,work,shop
  home={}
  leis={}
  other={}
  work={}
  shop={}
  road_facilities = array(0,dim=c(length(locations)-facility_length,5))
  for (i in c(1:facility_length)) {
    idx1 <- strsplit(locations[i],'@')[[1]][1]
    idx2 <- as.numeric(strsplit(locations[i],'@')[[1]][2])
    switch(idx1,'home' = {home=c(home,i) 
          road_facilities[idx2,1]=i},
           'leis' = {leis=c(leis,i) 
           road_facilities[idx2,2]=i},
           'other' = {other=c(other,i) 
           road_facilities[idx2,3]=i},
           'work' = {work=c(work,i) 
           road_facilities[idx2,4]=i},
           'shop' = {shop=c(shop,i) 
           road_facilities[idx2,5]=i})
  }
  facility_index = list(home=home,leis=leis,other=other,work=work,shop=shop)
  return(list(facility_index=facility_index,road_facilities=road_facilities))
}

#constructing prerequisite matrices
if (TRUE) {
  SmallProb = 1e-2
  FlowCapacity = 2*1e-2
  #locations = Location(events,network)
  facility_indexes = FacilityIndex(locations,facility_length)
  facility_index = facility_indexes$facility_index
  road_facilities = facility_indexes$road_facilities
  
  possible_actions = PossibleActionFunction(network,locations,facility_length)
  
  #constructing ppolicy,ptransit,preward
  Ppolicy = PolicyFunction(person.state.d,locations, possible_actions, SmallProb,policy_template)
  PpolicyUpdate = Ppolicy$Ppolicy
  action_list = Ppolicy$action_list
  Roadload = RoadLoadFunction(network,FlowCapacity)
  
  home = data.frame(begin=16,end=8,typ.dur=16)
  leis = data.frame(begin=8,end=16,typ.dur=8)
  other = data.frame(begin=8,end=16,typ.dur=8)
  shop = data.frame(begin=8,end=16,typ.dur=8)
  work = data.frame(begin=8,end=16,typ.dur=8)
  info_facility = as.data.frame(matrix(c(home,leis,other,work,shop),ncol=3,byrow = TRUE),row.names = c('home','leis','other','work','shop'))
  colnames(info_facility) = c('begin','end','typ.dur')
  
  #save(Ppolicy,file = 'data_exec/Ppolicy.RData')
  save(info_facility,file='data_exec/info_facility.RData')
  save(Roadload,file='data_exec/Roadload.RData')
  saveRDS(PpolicyUpdate,file='data_exec/PpolicyUpdate_full.RDS')
  save(possible_actions,file='data_exec/possible_actions.RData')
  save(action_list,file = 'data_exec/action_list.RData')
  save(facility_index,file='data_exec/facility_index.RData')
}





#server collecting data
#../target/matsim-inference-1.0-SNAPSHOT-jar-with-dependencies.jar
#~/MATSIM/matsim/matsim/target/matsim-0.7.0-SNAPSHOT-jar-with-dependencies.jar
#~/transportation/matsim-R/target/matsim-inference-1.0-SNAPSHOT-jar-with-dependencies.jar

#change to 8. hours
if (FALSE) {
  PpolicyUpdate = readRDS('data_exec/PpolicyUpdate_full.RDS')
  tmp_policy = list()
  for (i in c(1:500)) {
    tmp_policy <- lappend(tmp_policy,PpolicyUpdate[[i]])
  }
  saveRDS(tmp_policy,file='data_exec/PpolicyUpdate.RDS')
}





























