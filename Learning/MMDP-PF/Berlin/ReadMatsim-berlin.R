require(XML)  
library(data.table)

#should
load('equil_should_be.RData')

#events
data = '../Matsim/ITERS/it.100/100.events.xml'
xml_list = xmlToList(data)
#a = lapply(xml_list, unlist)
a = lapply(xml_list, as.list)
xml_data = rbindlist(a,fill = TRUE)
type = levels(factor(xml_data$type))

#constructing events
xml_data$time = type.convert(xml_data$time,'integer')
xml_data$person = type.convert(xml_data$person,'integer')
xml_data$link = type.convert(xml_data$link,'integer')
xml_data$vehicle = type.convert(xml_data$vehicle,'integer')
xml_data$actType = type.convert(xml_data$actType,'char')

a=xml_data[which(xml_data$type == type[1]),]
activity.end = data.frame(person=a$person,link=a$link,type=a$actType,time=a$time)
b = which(xml_data$type == type[2])
a=xml_data[b,]
activity.start = data.frame(person=a$person,link=a$link,type=a$actType,time=a$time)
b = which(xml_data$type == type[5])
a=xml_data[b,]
link.enter = data.frame(person=a$person,link=a$link,vehicle=a$vehicle,time=a$time)
b = which(xml_data$type == type[6])
a=xml_data[b,]
link.leave = data.frame(person=a$person,link=a$link,vehicle=a$vehicle,time=a$time)

events = list(activity.end=activity.end,activity.start=activity.start,link.enter=link.enter,link.leave=link.leave)
saveRDS(events,'data_prep/100.events.RDS')






#road network
network = '../Matsim/equil/output5/equil/output_network.xml'
xml_list = xmlToList(network)
#a = lapply(xml_list, unlist)
#a = lapply(xml_list, as.list)
#xml_data = rbindlist(a,fill = TRUE)

n = xml_list$nodes
a = lapply(n, as.list)
n = rbindlist(a,fill = TRUE)
n$id = type.convert(n$id,'integer')
n = n[with(n,order(id)),]
n = data.frame(x = n$x,y=n$y)

e = xml_list$links
a = lapply(e, unlist)
a = lapply(a, as.list)
e = rbindlist(a,fill = TRUE)
e$id = type.convert(e$id,'integer')
e = e[with(e,order(id)),]
e = data.frame(from=e$from,to=e$to,length=e$length,lanes=e$permlanes,capacity = e$capacity,freespeed=e$freespeed)
e = e[1:23,]

n$x = as.numeric(as.character(n$x))
n$y = as.numeric(as.character(n$y))
e$from = as.numeric(as.character(e$from))
e$to = as.numeric(as.character(e$to))
e$length = as.numeric(as.character(e$length))
e$lanes = as.numeric(as.character(e$lanes))
e$capacity = as.numeric(as.character(e$capacity))
e$freespeed = as.numeric(as.character(e$freespeed))

n = lapply(n, function(x) as.numeric(as.character(x)))
e = lapply(e, function(x) as.numeric(as.character(x)))

network = list(e=e,n=n)
saveRDS(network,'network.RDS')










#plans

data = '../Matsim/run_160.150.plans_selected.xml'
xml_list = xmlToList(data)
a = lapply(xml_list, unlist)
a = lapply(a, as.list)
xml_data = rbindlist(a,fill = TRUE)

b = lapply(xml_list, function(x) x$person$plan$act)

#total: 5229 work, in excel, replace all
















