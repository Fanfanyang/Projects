library('Matrix')
require('TTR')
require('igraph')
require('survey')
require('grr')
require('graphics')
require('RcppEigen')
require('Rcpp')
require('deldir')
sourceCpp('rcpp_try6_road.cpp')

#plot
if (TRUE) {
  road = readRDS('../../data_download1/ContextData/Senegal_roads.RDS')
  
  x=road[[1]]$x
  y=road[[1]]$y
  edge = road[[2]]
  
  plot(x, y, type="n", asp=1)
  points(x, y, pch=20, col="red", cex=0.5)
  segments(x[edge$from],y[edge$from],x[edge$to],y[edge$to],col='black')
  dev.copy(file='road_network.jpg', device=jpeg, quality=100, width=1024, height=1024)
  dev.off()
}

#assign tower to nodes, dakar region
if (TRUE) {
  description = readRDS("../../data_download1/ContextData/SENEGAL_ARR.RDS")
  road = readRDS('../../data_download1/ContextData/Senegal_roads.RDS')
  location = readRDS("../../data_download1/ContextData/SITE_ARR_LONLAT.RDS")
  
  #tower within a city (dakar)
  ndx = description$ARR_ID[which(description$REG == 'DAKAR')]
  flow={}
  for (i in c(1:length(ndx))) {
    idx = location$site_id[which(location$arr_id==ndx[i])]
    flow = c(flow,idx)
  }
  flow = unique(flow)
  tower_dakar = flow
  
  
  mat1 = as.matrix(data.frame(location$lon[tower_dakar],location$lat[tower_dakar]))
  mat2 = as.matrix(road$n)
  
  tower_node = {}
  for (i in c(1:nrow(mat1))) {
    print(i)
    a=matrix(rep(mat1[i,],each=nrow(mat2)),ncol = 2)
    dist = (a-mat2)
    dist = dist[,1]^2 + dist[,2]^2
    b=which.min(dist)
    tower_node=c(tower_node,b)
  }
  save(tower_dakar,file='data_prep/tower_dakar.RData')
  save(tower_node,file='data_prep/tower_node_dakar.RData')
  
  #plot
  if(FALSE) {
    x = location$lon[tower_dakar]
    y = location$lat[tower_dakar]
    x = mat2[tower_node,1]
    y = mat2[tower_node,2]
    # Voronoi
    plot(x, y, type="n", asp=1)
    points(x,y)
  }
}

#find lane transist
if (TRUE) {
  load('data_prep/person.state.d.original.RData')
  load('data_prep/tower_dakar.RData')
  #count person.state.d transitions
  lane_transist = array(0,dim=c(1666,1666))
  for (j in c(1:ncol(person.state.d))) {
    if ((j %% 1000) == 0) 
      print(j/1000)
    for (i in c(2:nrow(person.state.d))) {
      curr = person.state.d[i,j]
      prev = person.state.d[i-1,j]
      if (curr != prev) {
        if ((curr %in% tower_dakar) & (prev %in% tower_dakar))
          lane_transist[prev,curr] = lane_transist[prev,curr] + 1
      }
    }
  }
  save(lane_transist,file = 'data_prep/lane_transist_dakar.RData')
}

#compute shortest path
if (TRUE) {
  road = readRDS('../../data_download1/ContextData/Senegal_roads.RDS')
  load('data_prep/tower_node_dakar.RData')
  load('data_prep/lane_transist_dakar.RData')
  load('data_prep/tower_dakar.RData')
  location = readRDS("../../data_download1/ContextData/SITE_ARR_LONLAT.RDS")
  
  node = road$n
  edge = data.frame(road$e$from,road$e$to)
  
  if(FALSE) {
    plot(node$x, node$y, type="n", asp=1)
    a = match(shortest_path_cb[[53548]][,1],rownames(node))
    b = match(shortest_path_cb[[53548]][,2],rownames(node))
    segments(node$x[a],node$y[a],node$x[b],node$y[b],col = 'red')
    segments(shortest_path_cb[[53548]][,1])
  }
  
  g <- graph_from_data_frame(edge,directed = FALSE)

  #finding shortest time
  weight_time = road$e$length/road$e$freespeed*10
  weight_time = pmax(weight_time,1e-8)
  E(g)$weight = weight_time
  
  #vt_ndx = match(c(1:length(V(g))),V(g)$name)
  vt_ndx = match(rownames(node),V(g)$name)
  
  map_scale = 1e-2   #km
  speed = 100/6      #km/10mins
  
  numbers = length(tower_node)
  shortest_path=as.list(c(1:(numbers^2)))
  
  for (i in c(200:numbers)) {
    print(i)
    for (j in c(1:numbers)) {
      if(lane_transist[tower_dakar[i],tower_dakar[j]]>0) {
        loc1 = tower_node[i]
        loc2 = tower_node[j]
        if (loc1 == loc2) {
          shortest_path[[(i-1)*numbers+j]] = 0
        }
        else {
          b=as.numeric(((shortest_paths(g,vt_ndx[loc1],vt_ndx[loc2],output='both'))$vpath[[1]])$name)
          shortest_path[[(i-1)*numbers+j]] = b
        }
      }
      else
        shortest_path[[(i-1)*numbers+j]] = 0
    }
  }
  save(shortest_path,file="data_prep/shortest_path.RData")
  
  #cbind
  if (FALSE) {
    load('shortest_path_a.RData')
    sa = shortest_path
    load('shortest_path_b.RData')
    sb = shortest_path
    for (i in c(1:200)) {
      print(i)
      for (j in c(1:numbers)) {
        shortest_path[[(i-1)*numbers+j]] = sa[[(i-1)*numbers+j]]
      }
    }
    for (i in c(200:numbers)) {
      print(i)
      for (j in c(1:numbers)) {
        shortest_path[[(i-1)*numbers+j]] = sb[[(i-1)*numbers+j]]
      }
    }
    save(shortest_path,file='data_prep/shortest_path.RData')
  }
  
  #shortest_path_cb
  shortest_path_cb = shortest_path
  for (i in c(1:length(shortest_path_cb))) {
    if (i %% 1000 == 0)
      print(i/1000)
    if(length(shortest_path_cb[[i]])>1) {
      shortest_path_cb[[i]] = cbind(head(shortest_path_cb[[i]],-1),tail(shortest_path_cb[[i]],-1))
    }
  }
  save(shortest_path_cb,file="data_prep/shortest_path_cb.RData")
  
  #dist
  dist = shortest_path_cb
  for (i in c(1:length(shortest_path))) {
    if (i %% 100 == 0)
      print(i/100)
    if(length(shortest_path[[i]])>1) {
      
      ndx = shortest_path_cb[[i]]
      dist_ndx1 = match(ndx[,1],rownames(node))
      dist_ndx2 = match(ndx[,2],rownames(node))
      dist_tmp = sqrt((node$x[dist_ndx1] - node$x[dist_ndx2])^2 + (node$y[dist_ndx1] - node$y[dist_ndx2])^2)/map_scale
      dist[[i]] = dist_tmp
      
      if(FALSE) {
      lane_tmp = {}
      for (j in c(1:nrow(ndx))) {
        lane_step = which(edge$road.e.from == ndx[j,1] & edge$road.e.to == ndx[j,2])
        lane_tmp = c(lane_tmp,lane_step)
      }
      lane[[i]] = lane_tmp
      }
    }
  }
  save(dist,file="data_prep/dist.RData")
  
  #lane
  lane = shortest_path_cb
  edge_matrix = matrix(0,nrow = nrow(edge),ncol = 2)
  edge_matrix[,1] = as.numeric(as.character(edge$road.e.from))
  edge_matrix[,2] = as.numeric(as.character(edge$road.e.to))
  
  load('data_prep/shortest_path.RData')
  load('data_prep/shortest_path_cb.RData')
  sourceCpp('rcpp_try6_road.cpp')
  lane = CPLane(shortest_path_cb,edge_matrix,shortest_path)
  lane=lapply(lane, function(x){x+1666})
  save(lane,file='data_prep/lane.RData')
  
  #lane test
  ndx = 30000
  a = shortest_path_cb[[ndx]]
  b = a[12,]
  which(edge_matrix[,1]==b[1])
  which(edge_matrix[,2]==b[2])
  which(edge$road.e.from==299630486)
  which(edge$road.e.to == 1248333537)
}
























