#use fix point strategy
load("benchmark with dakar dataset/inference.RData")
#load("inference.RData")

n.steps=sapply(2:nrow(person.state.d),function(n) sum(person.state.d[n,]!=person.state.d[n-1,]))
n.steps=pmax(20,n.steps)

upd_forward<-function(v1,inc,out,pn,dec,len){
  v2=v1*pn - 0:(len-1)*v1*out
  v2[v2<0]=1e-20
  v2[2:len]=v2[2:len] + v1[1:(len-1)]*inc
  v2[1:(len-1)]=v2[1:(len-1)] + 1:(len-1)*v1[2:len]*dec
  v2
}

transition_forward_fra<-function(la1,lb2,ratein, locin, rateout, locout, pout, pnull){
  m.inc=sapply(1:length(locations),function(n) sum( la1[[n]][1:max.person[n]] * lb2[[n]][2:(max.person[n]+1)] ) )
  m.eq=sapply(1:length(locations),function(n) sum(la1[[n]]*lb2[[n]]))
  m.eq[m.eq==0]=1e-20
  m.dec=sapply(1:length(locations),function(n) sum( 1:max.person[n] * la1[[n]][2:(max.person[n]+1)] * lb2[[n]][1:max.person[n]] ))
  
  fra.inc=m.inc/m.eq
  fra.dec=m.dec/m.eq
  pinc=sapply(1:length(locations),function(n) sum(  ratein[[n]] * fra.dec[locin[[n]] ] )) 
  pdec= sapply(1:length(locations),function(n)  sum(  rateout[[n]] * fra.inc[locout[[n]]  ] ) )
  
  #for each link, calculate the prob of transition at all other links 
  tran=lapply(1:length(locations), function(n)  rateout[[n]] * fra.dec[n] * fra.inc[locout[[n]]  ] )
  alltran=sum(unlist(tran))
  trother=numeric(length = length(locations))
  trother[]=alltran
  trother=trother-sapply(tran,sum) # transition at other links = all transition - transition from local link - transition to local link
  for(n in 1:length(locations)) trother[locout[[n]]]=trother[locout[[n]]]-tran[[n]]
  pn=1-pnull+trother
  
  la2_tilde = lapply(1:length(locations), function(n) upd_forward(la1[[n]],pinc[n],pout[n],pn[n],pdec[n],max.person[n]+1) )
  
  
  lg2=lapply(1:length(locations), function(n) la2_tilde[[n]]*lb2[[n]] )
  K=sapply(lg2, sum )
  la2_tilde=lapply(1:length(locations), function(n) la2_tilde[[n]]/K[n])
  lg2=lapply(1:length(locations), function(n) lg2[[n]]/K[n])
  
  list(la2_tilde=la2_tilde)
}

transition_forward_int<-function(la1,lb2,ratein, locin, rateout, locout, pout, pnull,obs.p2){
  m.inc=numeric(length = length(locations))
  m.eq=numeric(length = length(locations))
  m.dec=numeric(length = length(locations))
  
  m.inc[unobservable]=sapply(unobservable,function(n) sum( la1[[n]][1:max.person[n]] * lb2[[n]][2:(max.person[n]+1)] ) )
  m.eq[unobservable]=sapply(unobservable,function(n) sum(la1[[n]]*lb2[[n]]))
  m.dec[unobservable]=sapply(unobservable,function(n) sum( 1:max.person[n] *la1[[n]][2:(max.person[n]+1)]* lb2[[n]][1:max.person[n]] ))
  
  m.inc[observable]=sapply(observable,function(n) sum( la1[[n]][1:max.person[n]] * lb2[[n]][2:(max.person[n]+1)]  * obs.p2[[as.character(n) ]][2:(max.person[n]+1)] ))
  m.eq[observable]=sapply(observable,function(n) sum(la1[[n]]*lb2[[n]]*  obs.p2[[as.character(n) ]]))
  m.dec[observable]=sapply(observable,function(n) sum( 1:max.person[n] * la1[[n]][2:(max.person[n]+1)] * lb2[[n]][1:max.person[n]]* obs.p2[[as.character(n) ]][1:max.person[n]] ) )
  
  m.eq[m.eq==0]=1e-20
  
  
  fra.inc=m.inc/m.eq
  fra.dec=m.dec/m.eq
  pinc=sapply(1:length(locations),function(n) sum(  ratein[[n]] * fra.dec[locin[[n]] ] )) 
  pdec= sapply(1:length(locations),function(n)  sum(  rateout[[n]] * fra.inc[locout[[n]]  ] ) )
  
  #for each link, calculate the prob of transition at all other links 
  tran=lapply(1:length(locations), function(n)  rateout[[n]] * fra.dec[n] * fra.inc[locout[[n]]  ] )
  alltran=sum(unlist(tran))
  trother=numeric(length = length(locations))
  trother[]=alltran
  trother=trother-sapply(tran,sum) # transition at other links = all transition - transition from local link - transition to local link
  for(n in 1:length(locations)) trother[locout[[n]]]=trother[locout[[n]]]-tran[[n]]
  pn=1-pnull+trother
  
  
  la2_tilde = lapply(1:length(locations), function(n) upd_forward(la1[[n]],pinc[n],pout[n],pn[n],pdec[n],max.person[n]+1) )
  
  la2_tilde[observable]=lapply(observable, function(n) la2_tilde[[n]] * obs.p2[[as.character(n) ]] )
  
  lg2=lapply(1:length(locations), function(n) la2_tilde[[n]]*lb2[[n]] )
  K=sapply(lg2, sum )
  la2_tilde=lapply(1:length(locations), function(n) la2_tilde[[n]]/K[n])
  lg2=lapply(1:length(locations), function(n) lg2[[n]]/K[n])
  
  list(la2_tilde=la2_tilde)
}

forward2 = function(la, lb, obs, rate_in_f, rate_out_f, max.person){
  
  new.t = 1:1200
  length.la = length(la)

  for(i in 1:1199){
    print(i)
    
    ratein=rate_in_f(i) # ratein is a list, each element stores the rate constant of the cars moving from its neighbors to the link 
    rateout=rate_out_f(i) # rateout is a list, each element stores the rate constant of the cars moving from the link to its neighbors
    locin=loc_in_f(i)
    locout=loc_out_f(i)
    
    la1=la[[i]]
    lb2=lb[[i+1]]
    
    m.eq=numeric(length = length(locations))
    m.eq[unobservable]=sapply(unobservable,function(n) sum(la1[[n]]*lb2[[n]]))
    obs.p2=lapply(observable, function(n) obs.matrix[ 1:(max.person[n]+1) ,observation[[as.character(n)]][i+1]+1 ] )
    names(obs.p2)=observable_nominal
    m.eq[observable]=sapply(observable,function(n) sum(la1[[n]]*lb2[[n]]*obs.p2[[as.character(n)]]))
    m.eq[m.eq==0]=1e-20
    
    m.eq.x=numeric(length = length(locations))
    m.eq.x[unobservable]=sapply(unobservable,function(n) sum(0:max.person[n]*la1[[n]]*lb2[[n]]))
    m.eq.x[observable]=sapply(observable,function(n) sum(0:max.person[n]*la1[[n]]*lb2[[n]]*obs.p2[[as.character(n)]]))
    
    pout=sapply(rateout, sum)
    pnull= sum(pout*m.eq.x/m.eq) - pout*m.eq.x/m.eq
    #r_nnn=max.person*pout+pnull
    #nnn = max(ceiling(r_nnn))
    nnn=ceiling(sum(pout*m.eq.x/m.eq))
    
    pout=pout/nnn
    pnull=pnull/nnn
    ratein=lapply(1:length(ratein), function(n) ratein[[n]]/nnn)
    rateout=lapply(1:length(rateout), function(n) rateout[[n]]/nnn)
    
    print("--------------------------------nnn---------")
    print(nnn)

    for (k in 1:nnn){
      t1 = i+(k-1)/nnn; t2 = i+k/nnn;
      lb2=getSlice(lb,t2); 
      if(k!=nnn) {
        new.t = c(new.t, t2)
        tran=transition_forward_fra(la1,lb2,ratein, locin, rateout, locout, pout, pnull)        
      } else {
        tran=transition_forward_int(la1,lb2,ratein, locin, rateout, locout, pout, pnull,obs.p2)
      }
      
      la2=tran$la2_tilde
      la1=la2
      
      if(length(attr(la,'t'))==length.la){la = alloc(la); length.la = length(la)}
      if(min(abs(t2-attr(la,'t')))<1e-6) {
        la[[which.min(abs(t2-attr(la,'t')))]] = la2
      } else {
        attr(la,'t') = c(attr(la,'t'),t2);
        la[[length(attr(la,'t'))]]=la2
      }
      
    } # k
  }
  la = unclass(la)[match(new.t,attr(la,'t'))]; attr(la,'t') = new.t;  attr(la,'c')="a"
  
  list(la = la)
}




upd_backward<-function(v1,inc,out,pn,dec,len){
  v2=v1*pn - 0:(len-1)*v1*out
  v2[v2<0]=1e-20
  v2[1:(len-1)]=v2[1:(len-1)]+v1[2:len]*inc
  v2[2:len]=v2[2:len]+1:(len-1)*v1[1:(len-1)]*dec
  v2
}

transition_backward_fra<-function(la1,lb2,ratein, locin, rateout, locout, pout, pnull){
  m.inc=sapply(1:length(locations),function(n) sum( la1[[n]][1:max.person[n]] * lb2[[n]][2:(max.person[n]+1)] ) )
  m.eq=sapply(1:length(locations),function(n) sum(la1[[n]]*lb2[[n]]))
  m.eq[m.eq==0]=1e-20
  m.dec=sapply(1:length(locations),function(n) sum( 1:max.person[n] * la1[[n]][2:(max.person[n]+1)] * lb2[[n]][1:max.person[n]] ))
  
  #   print("----------------------m.inc----------------------------")
  #   print(m.inc )
  #   print("----------------------m.eq----------------------------")
  #   print(m.eq)
  #   print("----------------------m.dec----------------------------")
  #   print(m.dec)
  
  fra.inc=m.inc/m.eq
  fra.dec=m.dec/m.eq
  pinc=sapply(1:length(locations),function(n) sum(  ratein[[n]] * fra.dec[locin[[n]] ] )) 
  pdec= sapply(1:length(locations),function(n)  sum(  rateout[[n]] * fra.inc[locout[[n]]  ] ) )
  
  #for each link, calculate the prob of transition at all other links 
  tran=lapply(1:length(locations), function(n)  rateout[[n]] * fra.dec[n] * fra.inc[locout[[n]]  ] )
  alltran=sum(unlist(tran))
  trother=numeric(length = length(locations))
  trother[]=alltran
  trother=trother-sapply(tran,sum) # transition at other links = all transition - transition from local link - transition to local link
  for(n in 1:length(locations)) trother[locout[[n]]]=trother[locout[[n]]]-tran[[n]]
  pn=1-pnull+trother
  
  #     print("----------------------pinc----------------------------")
  #     print( pinc )
  #     print("----------------------trother----------------------------")
  #     print(trother)
  #     print("----------------------pdec----------------------------")
  #     print( pdec )
  
  lb1_tilde = lapply(1:length(locations), function(n) upd_backward(lb2[[n]],pinc[n],pout[n],pn[n],pdec[n],max.person[n]+1) )
  
  lg1=lapply(1:length(locations), function(n) la1[[n]]*lb1_tilde[[n]] )
  K=sapply(lg1, sum )
  lb1_tilde=lapply(1:length(locations), function(n) lb1_tilde[[n]]/K[n])
  lg1=lapply(1:length(locations), function(n) lg1[[n]]/K[n])
  
  list(lb1_tilde=lb1_tilde)
}

transition_backward_int<-function(la1,lb2,ratein, locin, rateout, locout, pout, pnull,obs.p2){
  m.inc=numeric(length = length(locations))
  m.eq=numeric(length = length(locations))
  m.dec=numeric(length = length(locations))
  
  m.inc[unobservable]=sapply(unobservable,function(n) sum( la1[[n]][1:max.person[n]] * lb2[[n]][2:(max.person[n]+1)] ) )
  m.eq[unobservable]=sapply(unobservable,function(n) sum(la1[[n]]*lb2[[n]]))
  m.dec[unobservable]=sapply(unobservable,function(n) sum( 1:max.person[n] *la1[[n]][2:(max.person[n]+1)]* lb2[[n]][1:max.person[n]] ))
  
  m.inc[observable]=sapply(observable,function(n) sum( la1[[n]][1:max.person[n]] * lb2[[n]][2:(max.person[n]+1)]  * obs.p2[[as.character(n) ]][2:(max.person[n]+1)] ))
  m.eq[observable]=sapply(observable,function(n) sum(la1[[n]]*lb2[[n]]*  obs.p2[[as.character(n) ]]))
  m.dec[observable]=sapply(observable,function(n) sum( 1:max.person[n] * la1[[n]][2:(max.person[n]+1)] * lb2[[n]][1:max.person[n]]* obs.p2[[as.character(n) ]][1:max.person[n]] ) )
  
  m.eq[m.eq==0]=1e-20
  
  #   print("----------------------m.inc----------------------------")
  #   print(m.inc )
  #   print("----------------------m.eq----------------------------")
  #   print(m.eq)
  #   print("----------------------m.dec----------------------------")
  #   print(m.dec)
  
  fra.inc=m.inc/m.eq
  fra.dec=m.dec/m.eq
  pinc=sapply(1:length(locations),function(n) sum(  ratein[[n]] * fra.dec[locin[[n]] ] )) 
  pdec= sapply(1:length(locations),function(n)  sum(  rateout[[n]] * fra.inc[locout[[n]]  ] ) )
  
  #for each link, calculate the prob of transition at all other links 
  tran=lapply(1:length(locations), function(n)  rateout[[n]] * fra.dec[n] * fra.inc[locout[[n]]  ] )
  alltran=sum(unlist(tran))
  trother=numeric(length = length(locations))
  trother[]=alltran
  trother=trother-sapply(tran,sum) # transition at other links = all transition - transition from local link - transition to local link
  for(n in 1:length(locations)) trother[locout[[n]]]=trother[locout[[n]]]-tran[[n]]
  pn=1-pnull+trother
  
  #     print("----------------------pinc----------------------------")
  #     print( pinc )
  #     print("----------------------trother----------------------------")
  #     print(trother)
  #     print("----------------------pdec----------------------------")
  #     print( pdec )
  
  lb2[observable]=lapply(observable, function(n) lb2[[n]] * obs.p2[[as.character(n) ]] )
  lb1_tilde = lapply(1:length(locations), function(n) upd_backward(lb2[[n]],pinc[n],pout[n],pn[n],pdec[n],max.person[n]+1) )
  
  lg1=lapply(1:length(locations), function(n) la1[[n]]*lb1_tilde[[n]] )
  K=sapply(lg1, sum )
  lb1_tilde=lapply(1:length(locations), function(n) lb1_tilde[[n]]/K[n])
  lg1=lapply(1:length(locations), function(n) lg1[[n]]/K[n])
  
  list(lb1_tilde=lb1_tilde)
}


backward2 = function(la, lb, obs, rate_in_f, rate_out_f, max.person){
  
  new.t = 1:1200
  length.lb = length(lb);

  for(i in 1199:1 ){
    print(i)
    
    ratein=rate_in_f(i) # ratein is a list, each element stores the rate constant of the cars moving from its neighbors to the link 
    rateout=rate_out_f(i) # rateout is a list, each element stores the rate constant of the cars moving from the link to its neighbors
    locin=loc_in_f(i)
    locout=loc_out_f(i)
    
    la1=la[[i]]
    lb2=lb[[i+1]]
    
    m.eq=numeric(length = length(locations))
    m.eq[unobservable]=sapply(unobservable,function(n) sum(la1[[n]]*lb2[[n]]))
    obs.p2=lapply(observable, function(n) obs.matrix[ 1:(max.person[n]+1) ,observation[[as.character(n)]][i+1]+1 ] )
    names(obs.p2)=observable_nominal
    m.eq[observable]=sapply(observable,function(n) sum(la1[[n]]*lb2[[n]]*obs.p2[[as.character(n)]]))
    m.eq[m.eq==0]=1e-20
    
    m.eq.x=numeric(length = length(locations))
    m.eq.x[unobservable]=sapply(unobservable,function(n) sum(0:max.person[n]*la1[[n]]*lb2[[n]]))
    m.eq.x[observable]=sapply(observable,function(n) sum(0:max.person[n]*la1[[n]]*lb2[[n]]*obs.p2[[as.character(n)]]))
    
    pout=sapply(rateout, sum)
    pnull= sum(pout*m.eq.x/m.eq) - pout*m.eq.x/m.eq
    #r_nnn=max.person*pout+pnull
    #nnn = max(ceiling(r_nnn))
    nnn=ceiling(sum(pout*m.eq.x/m.eq))
    
    pout=pout/nnn
    pnull=pnull/nnn
    ratein=lapply(1:length(ratein), function(n) ratein[[n]]/nnn)
    rateout=lapply(1:length(rateout), function(n) rateout[[n]]/nnn)
    
    print("--------------------------------nnn---------")
    print(nnn)

    for (k in nnn:1){
      t1 = i+(k-1)/nnn; t2 = i+k/nnn;
      la1=getSlice(la,t1);
      
      if(k!=nnn) {
        new.t=c(new.t,t2)
        tran=transition_backward_fra(la1,lb2,ratein, locin, rateout, locout, pout, pnull)        
      } else {
        tran=transition_backward_int(la1,lb2,ratein, locin, rateout, locout, pout, pnull,obs.p2)
      }
      
      lb1=tran$lb1_tilde
      lb2 = lb1
      
      if(length(attr(lb,'t'))==length.lb){lb = alloc(lb); length.lb = length(lb)}
      if(min(abs(t1-attr(lb,'t')))<1e-12) {
        lb[[which.min(abs(t1-attr(lb,'t')))]] <- lb1
      } else{
        attr(lb,'t') = c(attr(lb,'t'),t1)
        lb[[length(attr(lb,'t'))]]<-lb1
      }
      
    }
  }
  lb = unclass(lb)[match(new.t,attr(lb,'t'))]; attr(lb,'t') = new.t;  attr(lb,'c')="b"
  list(lb = lb)
}

#######################################################################################################
for(iter in 1:300){
  
  la_old=la
  lb_old=lb
  
  aaa = forward2(la, lb, obs, rate_in_f, rate_out_f, max.person)
  
  la=aaa$la
  
  saveRDS(la,paste("the ", iter,  " forward la.RDS", sep = ""))
  
  print(sprintf('The %d forward completed',iter))
  
  
  
  
  la_old=la
  lb_old=lb
  
  bbb = backward2(la, lb, obs, rate_in_f, rate_out_f, max.person)
  
  lb=bbb$lb
  
  saveRDS(lb,paste("the ", iter,  "backward lb.RDS", sep = ""))
  
  print(sprintf('The %d backward completed',iter))
}