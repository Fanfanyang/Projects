
library(data.table)

#load data
load("data_exec/Xt_real.RData")
load("data_exec/m.time.RData")
load('data_exec/obs.matrix.RData')
load('data_prep/person.state.d.RData')
load('data_exec/Yt.RData')
load('data_prep/td.RData')
load('data_prep/locations.RData')
events = readRDS('10_events_1_5.RDS')
network = readRDS('network.RDS')
e=network$e
n=network$n
activity.end = events$activity.end
activity.start = events$activity.start
link.enter = events$link.enter
link.leave = events$link.leave
events = list(activity.end = activity.end, link.leave = link.leave, link.enter = link.enter, activity.start = activity.start)

#model definition
Agents = c(1:ncol(person.state.d))
Time = c(1:nrow(person.state.d))
Actions = locations
States = locations
NumAgents = length(Agents)
NumTime = length(Time)
NumActions = length(Actions)
NumStates = length(States)

# events
events = list(activity.end = activity.end, link.leave = link.leave, link.enter = link.enter, activity.start = activity.start)
invisible(lapply(1:length(events), function(n) if(!is.infinite(events[[n]]$time[nrow(events[[n]])])){
  events[[n]] <<- events[[n]][order(events[[n]]$time),]
  events[[n]] <<- rbind(events[[n]], tail(events[[n]],1))
  events[[n]]$time[nrow(events[[n]])] <<- Inf
}))

#functions
Location <- function(events,network) {
  types <- as.character(levels(events$activity.start$type))
  links <- rownames(network$e)
  locations <- c(types,links)
  return(locations)
}

lappend <- function (lst, ...){
  lst <- c(lst, list(...))
  return(lst)
}

PolicyFunction <- function(person.state.d,locations, possible_actions, SmallProb) {
  Ppolicy <- list()
  for (i in c(1:(nrow(person.state.d)-1))) {
    if (i %% 100 == 0)
      print(i/100)
    policy_tmp1 <- table(factor(person.state.d[i,],levels=locations), factor(person.state.d[i+1,],levels=locations))
    policy_tmp2 <- policy_tmp1[possible_actions] + SmallProb
    policy_tmp3 <- list()
    for (i in c(1:length(locations))) {
      from <- which(possible_actions[,1]==i)
      policy_tmp3 <- lappend(policy_tmp3,policy_tmp2[from])
    }
    policy_tmp3 <- lapply(policy_tmp3, function(x) x/sum(x))
    Ppolicy <- lappend(Ppolicy,policy_tmp3)
  }
  action_list <- list()
  for (i in c(1:length(locations))) {
    from <- which(possible_actions[,1]==i)
    action_list <- lappend(action_list,possible_actions[from,2])
  }
  return(list(Ppolicy=Ppolicy,action_list=action_list))
}

PossibleActionFunction <- function(network) {
  e = network$e
  S = matrix(0,nrow=25,ncol=43)
  inx = 1
  for(i in 1:length(e$from)){
    #print(i)
    sinto = as.integer(as.character(e$to[i]))
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
    sinfrom = as.integer(as.character(e$from[i]))
    sinto = as.integer(as.character(e$to[i]))
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
  possible_actions <- cbind(which(S==-1,arr.ind = TRUE)[,1],which(S==1,arr.ind = TRUE)[,1])
  facility_stay <- array(c(1,2,1,2),dim=c(2,2))
  possible_actions <- rbind(possible_actions,facility_stay)
  return(possible_actions)
}

TransitFunction <- function(NumStatesFrom,NumActions,NumStatesTo) {
  Ptransit <- array(0,dim=c(NumStatesFrom,NumActions,NumStatesTo))
  for (i in c(1:nrow(Ptransit))) {
    Ptransit[i,,] <- diag(NumActions)
  }
  return(Ptransit)
}

RoadLoadFunction <- function(network,scale_factor) {
  Roadload <- array(0,dim=nrow(network$e))
  Roadload <- as.numeric(as.character(network$e$length))/as.numeric(as.character(network$e$freespeed)) * (as.numeric(as.character(network$e$capacity))/3600) * as.numeric(as.character(network$e$lanes)) * scale_factor
  
  TimeMoveOut <- array(0,dim=nrow(network$e))
  TimeMoveOut <- as.numeric(as.character(network$e$length))/as.numeric(as.character(network$e$freespeed))/60
  
  return(list(Roadload=Roadload,TimeMoveOut=TimeMoveOut))
}

#constructing prerequisite matrices
if (TRUE) {
  SmallProb = 0.2
  locations = Location(events,network)
  
  #constructing ppolicy,ptransit,preward
  Ppolicy = PolicyFunction(person.state.d,locations, possible_actions, SmallProb)
  Ptransit = TransitFunction(NumStates,NumActions,NumStates)
  
  home = data.frame(begin=16,end=8,typ.dur=16)
  work = data.frame(begin=8,end=16,typ.dur=8)
  info_facility = as.data.frame(matrix(c(home,work),ncol=3,byrow = TRUE),row.names = c('home','work'))
  colnames(info_facility) = c('begin','end','typ.dur')
  Roadload = RoadLoadFunction(network,0.2)
  possible_actions = PossibleActionFunction(network)
  PpolicyUpdate = Ppolicy$Ppolicy
  action_list = Ppolicy$action_list
  
  #save(Ppolicy,file = 'data_exec/Ppolicy.RData')
  save(Ptransit,file='data_exec/Ptransit,RData')
  save(info_facility,file='data_exec/info_facility.RData')
  save(Roadload,file='data_exec/Roadload.RData')
  saveRDS(PpolicyUpdate,file='data_exec/PpolicyUpdate.RDS')
  save(possible_actions,file='data_exec/possible_actions.RData')
  save(action_list,file = 'data_exec/action_list.RData')
}





#server collecting data
#../target/matsim-inference-1.0-SNAPSHOT-jar-with-dependencies.jar
#~/MATSIM/matsim/matsim/target/matsim-0.7.0-SNAPSHOT-jar-with-dependencies.jar
#~/transportation/matsim-R/target/matsim-inference-1.0-SNAPSHOT-jar-with-dependencies.jar































