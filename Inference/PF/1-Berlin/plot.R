library('Matrix')
require('TTR')
require('igraph')
require('survey')
require('grr')
require('graphics')
require('RcppEigen')
require('Rcpp')
require('deldir')
require('RColorBrewer')

#construct event
if (TRUE) {
  realdata = readRDS(file = "data_prep/300.events.RDS")
  network = readRDS(file = "data_prep/network.RDS")
  activity.end = realdata$activity.end
  link.leave = realdata$leave
  link.enter = realdata$enter
  activity.start = realdata$activity.start
  
  # events
  events = list(activity.end = activity.end, link.leave = link.leave, link.enter = link.enter, activity.start = activity.start)
  invisible(lapply(1:length(events), function(n) if(!is.infinite(events[[n]]$time[nrow(events[[n]])])){
    events[[n]] <<- events[[n]][order(events[[n]]$time),]
    events[[n]] <<- rbind(events[[n]], tail(events[[n]],1))
    events[[n]]$time[nrow(events[[n]])] <<- Inf
  }))
  ndx = integer(length=length(events))
  ndx[] = 1
  
  # has problem, 4 person != 3 person, fixed
  unique_person = c(levels(events[[1]]$person),levels(events[[2]]$person),levels(events[[3]]$person),levels(events[[4]]$person))
  unique_person = unique_person[!duplicated(unique_person)]
  unique_lane = rownames(network$e)
  
  events[[1]]$person = factor(events[[1]]$person,levels = unique_person)
  events[[2]]$person = factor(events[[2]]$person,levels = unique_person)
  events[[3]]$person = factor(events[[3]]$person,levels = unique_person)
  events[[4]]$person = factor(events[[4]]$person,levels = unique_person)
  events[[1]]$link = factor(events[[1]]$link,levels = unique_lane)
  events[[2]]$link = factor(events[[2]]$link,levels = unique_lane)
  events[[3]]$link = factor(events[[3]]$link,levels = unique_lane)
  events[[4]]$link = factor(events[[4]]$link,levels = unique_lane)
  
  levels(events[[3]]$person) = c(1:length(unique_person))
  levels(events[[4]]$person) = c(1:length(unique_person))
  levels(events[[2]]$person) = c(1:length(unique_person))
  levels(events[[1]]$person) = c(1:length(unique_person))
  levels(events[[1]]$link) = c(1:length(unique_lane))
  levels(events[[2]]$link) = c(1:length(unique_lane))
  levels(events[[3]]$link) = c(1:length(unique_lane))
  levels(events[[4]]$link) = c(1:length(unique_lane)) 
  
  types1=unique(paste(events[[1]]$type,events[[1]]$link,sep = '@'))
  types2=unique(paste(events[[4]]$type,events[[4]]$link,sep = '@'))
  types=unique(c(types1,types2))
  min.time = min(sapply(1:length(events),function(n) min(events[[n]]$time[!is.infinite(events[[n]]$time)])))
}

#plot latent state network intensity, should use in all lanes not clusters
if (TRUE) {
  load('data_prep/person.state.d.RData')
  load("data_exec/Xt_real_1.RData")
  load('data_result/Xt_est_1.RData')
  network = readRDS(file = "data_prep/network.RDS")
  
  #find road number index
  e = network$e
  n = network$n
  net_data_frame = array(0,dim = c(nrow(e),2))
  net_data_frame[,1] = match(e$from,rownames(n))
  net_data_frame[,2] = match(e$to,rownames(n))
  location.ndx = c(types,c(1:nrow(e)))
  types.ndx = unlist(strsplit(types,'@'))
  types.ndx = as.numeric(types.ndx[(c(1:length(types.ndx)) %% 2 == 0)])
  edge.ndx = c(types.ndx,c(1:nrow(e)))
  
  time.th = 231-1
  tt = c(8,17,21,24)*60 - time.th
  Xt_est = Xt_est_1[tt,]
  Xt_real = Xt_real_1[tt,]
  
  #plot
  x=n$x
  y=n$y
  max.person = max(c(Xt_real[,length(types):ncol(Xt_real)],Xt_est[,length(types):ncol(Xt_real)]))
  lw = seq(0.5,5,length.out = (max.person+1))

  #estimation
  rbPal <- colorRampPalette(c('red','white'))
  #rbPal = colorRampPalette( colors = brewer.pal(9,"Blues") )
  cl = rbPal(max.person+1)
  for (t in c(1:length(tt))) {
    title = paste('Berlin_visualization_est',(tt[t]+time.th)/60,sep = '@')
    plot(x, y, type="n", asp=1)
    rect(par("usr")[1], par("usr")[3], par("usr")[2], par("usr")[4], col = 
           "black")
    segments(x[net_data_frame[,1]],y[net_data_frame[,1]],x[net_data_frame[,2]],y[net_data_frame[,2]],lwd = lw[1],col=cl[2])
    plot_lanes = which(Xt_est[t,]>0)
    # only plot vehicles on roads but not facilities
    plot_lanes = plot_lanes[which(plot_lanes > length(types))]
    for (i in plot_lanes) {
      idx = edge.ndx[i]
      segments(x[net_data_frame[idx,1]],y[net_data_frame[idx,1]],x[net_data_frame[idx,2]],y[net_data_frame[idx,2]],col=cl[pmin(Xt_est[t,i]+4,length(cl))],lwd=lw[Xt_est[t,i]+1])
    }
    file.name = paste(title,'png',sep='.')
    dev.copy(file=file.name, device=png, width=1024, height=768)
    dev.off()
  }
  #groud truth
  rbPal <- colorRampPalette(c('blue','white'))
  cl = rbPal(max.person+1)
  for (t in c(1:length(tt))) {
    title = paste('Berlin_visualization_gt',(tt[t]+time.th)/60,sep = '@')
    plot(x, y, type="n", asp=1)
    rect(par("usr")[1], par("usr")[3], par("usr")[2], par("usr")[4], col = 
           "black")
    segments(x[net_data_frame[,1]],y[net_data_frame[,1]],x[net_data_frame[,2]],y[net_data_frame[,2]],lwd = lw[1],col=cl[2])
    plot_lanes = which(Xt_real[t,]>0)
    plot_lanes = plot_lanes[which(plot_lanes > length(types))]
    for (i in plot_lanes) {
      idx = edge.ndx[i]
      segments(x[net_data_frame[idx,1]],y[net_data_frame[idx,1]],x[net_data_frame[idx,2]],y[net_data_frame[idx,2]],col=cl[pmin(Xt_real[t,i]+4,length(cl))],lwd=lw[Xt_real[t,i]+1])
    }
    file.name = paste(title,'png',sep='.')
    dev.copy(file=file.name, device=png, width=1024, height=768)
    dev.off()
  }
}























