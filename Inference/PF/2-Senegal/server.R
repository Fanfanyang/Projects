library('Matrix')
require('TTR')
require('igraph')
require('survey')
require('grr')
require('graphics')
require('RcppEigen')
require('Rcpp')
require('deldir')

#compute shortest path
if (TRUE) {
  road = readRDS('data_prep/Senegal_roads.RDS')
  load('data_prep/tower_node_dakar.RData')
  load('data_prep/lane_transist_dakar.RData')
  load('data_prep/tower_dakar.RData')
  location = readRDS("data_prep/SITE_ARR_LONLAT.RDS")
  
  node = road$n
  edge = data.frame(road$e$from,road$e$to)
  
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
  
  for (i in c(150:numbers)) {
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
  save(shortest_path,file="shortest_path.RData")
}



















