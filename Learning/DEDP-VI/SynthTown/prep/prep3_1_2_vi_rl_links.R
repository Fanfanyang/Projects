
library(data.table)

#load data
load('data_result1/person.state.d.RData')
load('data_result1/locations.RData')
network = readRDS('data_exec/network.RDS')
e=network$e
n=network$n

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

PolicyFunction <- function(person.state.d,locations, possible_actions, trunc, SmallProb, SmallProb_offset,info_network) {
  action_list <- list()
  for (i in c(1:length(locations))) {
    from <- which(possible_actions[,1]==i)
    action_list <- lappend(action_list,possible_actions[from,2])
  }
  
  Ppolicy <- list()
  policy_all <- list()
  policy_truc <- rep(list(list()),trunc)
  for(i in c(1:length(locations))) {
    policy_all <- lappend(policy_all,array(0,dim=length(action_list[[i]])))
    policy_truc <- lapply(policy_truc, function(x) lappend(x,array(0,dim=length(action_list[[i]]))))
  }
  for (i in c(1:(nrow(person.state.d)-1))) {
    if (i %% 100 == 0)
      print(i/100)
    policy_tmp1 <- table(factor(person.state.d[i,],levels=locations), factor(person.state.d[i+1,],levels=locations))
    policy_tmp2 <- policy_tmp1[possible_actions]
    policy_tmp3 <- list()
    for (j in c(1:length(locations))) {
      from <- which(possible_actions[,1]==j)
      policy_tmp3 <- lappend(policy_tmp3,policy_tmp2[from])
    }
    policy_all <- Map('+',policy_all,policy_tmp3)
    policy_truc[[ceiling(i/(nrow(person.state.d)/trunc))]] <- Map('+',policy_truc[[ceiling(i/(nrow(person.state.d)/trunc))]],policy_tmp3)
  }
  
  policy_truc <- lapply(policy_truc,function(x) Map('+',x,Map('+',SmallProb_offset,Map('*',policy_all,SmallProb/trunc))))
  policy_truc <- lapply(policy_truc,function(x) lapply(x,function(y) y/sum(y)))
  
  Pmoveout <- 1/info_network$info_road$TimeMoveOut
  Ptransit = c(0.1,0.1,Pmoveout)
  
  #policy_truc <- lapply(policy_truc,function(x) lapply(1:length(x),function(n) {
  #  tmp_x = x[[n]]
  #  tmp_go = tmp_x[-1]/Ptransit[n]
  #  tmp_left = pmax(1 - sum(tmp_go),0.1)
  #  tmp_y = c(tmp_left,tmp_go)
  #  tmp_y/sum(tmp_y)
  #}))
  
  # to be changed: whether we need this?
  policy_truc <- lapply(policy_truc,function(x) Map('+',x,SmallProb_offset))
  # to be deleted: uniform distribution initial policy
  #policy_truc <- lapply(policy_truc,function(x) lapply(x,function(y) y+10))
  policy_truc <- lapply(policy_truc,function(x) lapply(x,function(y) y/sum(y)))
  #policy_truc <- lapply(policy_truc,function(x) lapply(x,function(y) matrix(rep(y,each=max.person[[1]]+1),byrow = F,nrow = max.person[[1]]+1)))
  
  for (i in c(1:(nrow(person.state.d)-1))) {
    #Ppolicy <- lappend(Ppolicy,policy_init)
    Ppolicy <- lappend(Ppolicy,policy_truc[[ceiling(i/(nrow(person.state.d)/trunc))]])
  }
  
  return(list(Ppolicy=Ppolicy,WorldModel=policy_truc,action_list=action_list))
}

LocationInOutFunction <- function(locations, possible_actions) {
  locout <- list()
  locin <- list()
  for (i in c(1:length(locations))) {
    from <- which(possible_actions[,1]==i)
    to <- which(possible_actions[,2]==i)
    locout <- lappend(locout,possible_actions[from[-1],2])
    locin <- lappend(locin,possible_actions[to[-1],1])
  }
  return(list(locout=locout,locin=locin))
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
  #facility_stay <- array(c(1,2,1,2),dim=c(2,2))
  action_stay <- array(c(1:nrow(S),1:nrow(S)),dim=c(nrow(S),2))
  
  possible_actions <- rbind(action_stay,possible_actions)
  return(possible_actions)
}

TransitFunction <- function(NumStatesFrom,NumActions,NumStatesTo) {
  Ptransit <- array(0,dim=c(NumStatesFrom,NumActions,NumStatesTo))
  for (i in c(1:nrow(Ptransit))) {
    Ptransit[i,,] <- diag(NumActions)
  }
  return(Ptransit)
}

# 2000 t0 50 people differs here, to be changed
RoadLoadFunction <- function(network,scale_factor) {
  Roadload <- array(0,dim=nrow(network$e))
  Roadload <- as.numeric(as.character(network$e$length))/as.numeric(as.character(network$e$freespeed)) * (as.numeric(as.character(network$e$capacity))/3600*scale_factor) * as.numeric(as.character(network$e$lanes)) #* scale_factor
  
  TimeMoveOut <- array(0,dim=nrow(network$e))
  TimeMoveOut <- as.numeric(as.character(network$e$length))/as.numeric(as.character(network$e$freespeed))/60
  
  return(list(Roadload=Roadload,TimeMoveOut=TimeMoveOut))
}

AgentGoals <- function(person.state.d,groups,locations,info_network) {
  goal_agents <- array(0,dim=c(nrow(person.state.d),length(groups)))
  for(i in c(1:length(groups))) {
    xt_real <- t(apply(person.state.d[,groups[[i]]],1,function(x) table(factor(x, levels=locations))))
    goal_agents[,i] <- apply(xt_real,1,function(x) which.max(x[info_network$facility]))
  }
  # 8-5
  goal_agents[(8*60):(17*60),] <- 2
  goal_agents[-((8*60):(17*60)),] <- 1
  return(goal_agents)
}

#constructing prerequisite matrices
if (TRUE) {
  SmallProb = 0.02
  # to be changed, whether we need this?
  SmallProb_offset = 1e-6
  trunc = 4
  #locations = Location(events,network)
  
  home = data.frame(begin=16,end=8,typ.dur=16)
  work = data.frame(begin=8,end=16,typ.dur=8)
  info_facility = as.data.frame(matrix(c(home,work),ncol=3,byrow = TRUE),row.names = c('home','work'))
  colnames(info_facility) = c('begin','end','typ.dur')
  Roadload = RoadLoadFunction(network,400/2000)
  possible_actions = PossibleActionFunction(network)
  facility = c(1,2)
  link = c(3:25)
  info_network = list(info_facility=info_facility,info_road=Roadload,facility=facility,link=link)
  groups = list(c(1:20),c(21:30),c(31:50))
  goal_agents = AgentGoals(person.state.d,groups,locations,info_network)
  Locationinout = LocationInOutFunction(locations, possible_actions)
  locin = Locationinout$locin
  locout = Locationinout$locout
  
  #constructing ppolicy,ptransit,preward
  Ppolicy = PolicyFunction(person.state.d,locations, possible_actions, trunc,SmallProb,SmallProb_offset,info_network)
  #Ptransit = TransitFunction(NumStates,NumActions,NumStates)
  PpolicyUpdate = Ppolicy$Ppolicy
  WorldModel = Ppolicy$WorldModel
  #PpolicyUpdate = rapply( PpolicyUpdate, f=function(x) ifelse(is.nan(x),0,x), how="replace" ) 
  action_list = Ppolicy$action_list
  
  #save(Ppolicy,file = 'data_exec/Ppolicy.RData')
  #save(Ptransit,file='data_result3/Ptransit.RData')
  save(info_network,file='data_result3/info_network.RData')
  save(goal_agents,file='data_result3/goal_agents.RData')
  saveRDS(PpolicyUpdate,file='data_result3/PpolicyUpdate.RDS')
  save(possible_actions,file='data_result3/possible_actions.RData')
  save(action_list,file = 'data_result3/action_list.RData')
  save(locin,file = 'data_result3/locin.RData')
  save(locout,file = 'data_result3/locout.RData')
  save(groups,file = 'data_result3/groups.RData')
  save(WorldModel,file='data_result3/WorldModel.RData')
}

if (TRUE) {
  load('data_result3/info_network.RData')
  load('data_result3/goal_agents.RData')
  PpolicyUpdate = readRDS('data_result3/PpolicyUpdate.RDS')
  load('data_result3/possible_actions.RData')
  load('data_result3/action_list.RData')
  load('data_result3/WorldModel.RData')
  load('data_result2/inference_1_synthtown.RData')
  
  #la_TMt
  #lalbTmt = ComputelalbTmt(loc.d,locations,max.person,action_list,PpolicyUpdate)
  if (TRUE) {
    # normal
    la_Tmt = la
    lb_Tmt = lb
    attr(la_Tmt,'t') =attr(lb_Tmt,'t') = 1:nrow(loc.d)
    attr(la_Tmt,'c')="a"
    attr(lb_Tmt,'c')="b"
    remove(list = setdiff(ls(),c('lg','loc.d','rate_in',
                                 'rate_out','rate_in_f','rate_out_f',
                                 'loc_in','loc_out','loc_in_f','loc_out_f',
                                 'la_Tmt','lb_Tmt','m','m.time','max.person','observable_nominal',
                                 'unobservable','observable','alloc','getSlice','locations',
                                 'Xt_real','person.state.d',
                                 'info_network','PpolicyUpdate','goal_agents',
                                 'possible_actions','action_list','locin','locout',
                                 'groups','WorldModel'
    )))
  }
  
  save.image(file = "data_result3/inference_1_synthtown.RData")
  
}


#topython
if (FALSE) {
  #action_list_1 = unlist(sapply(1:25,function(n) rep(n,length(action_list[[n]][-1]))))
  #action_list_2 = cbind(action_list_1,unlist(lapply(action_list,function(n) n[-1])))
  #actions = sapply(1:25,function(n) length(action_list[[n]][-1]))
  
  #write.table(actions,"topython//actions.csv",sep=",",row.names=F,col.names=F)
  #write.table(action_list_2,"topython//action_list.csv",sep=",",row.names=F,col.names=F)
  write.table(info_network$info_road,"topython//info_road.csv",sep=",",row.names=F,col.names=F)
  write.table(possible_actions,"topython//possible_actions.csv",sep=",",row.names=F,col.names=F)
  policy_init = output <- matrix(unlist(lapply(PpolicyUpdate,function(n) lapply(n,function(m) m[-1]))), ncol = 43, byrow = TRUE)
  write.table(policy_init,"topython//policy_init.csv",sep=",",row.names=F,col.names=F)
  
  person.state.d <- matrix(as.numeric(factor(person.state.d, levels=c('h','w',1:23))), nrow=nrow(person.state.d))
  write.table(person.state.d,"topython//person_state_d.csv",sep=",",row.names=F,col.names=F)
  write.table(Xt_real,"topython//xt_real.csv",sep=",",row.names=F,col.names=F)
}

#server collecting data
#../target/matsim-inference-1.0-SNAPSHOT-jar-with-dependencies.jar
#~/MATSIM/matsim/matsim/target/matsim-0.7.0-SNAPSHOT-jar-with-dependencies.jar
#~/transportation/matsim-R/target/matsim-inference-1.0-SNAPSHOT-jar-with-dependencies.jar































