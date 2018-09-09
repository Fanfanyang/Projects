
library(ggplot2)
require(Hmisc)

#use fix point strategy
load("inference_1_synthtown.RData")
#load("inference_1_pro.RData")

upd_forward<-function(v1,inc,out,pn,dec,len){
  v2=v1*pn - 0:(len-1)*v1*out
  v2[2:len]=v2[2:len] + v1[1:(len-1)]*inc
  v2[1:(len-1)]=v2[1:(len-1)] + 1:(len-1)*v1[2:len]*dec
  v2
}

upd_forward_test<-function(v1,inc,out,pn,dec,len){
  v2 = v2_0 = v2_1 = v2_2 = array(0,dim=length(v1))
  
  v2=v1*pn - 0:(len-1)*v1*out
  v2[2:len]=v2[2:len] + v1[1:(len-1)]*inc
  v2[1:(len-1)]=v2[1:(len-1)] + 1:(len-1)*v1[2:len]*dec
  
  v2_0=v1*pn - 0:(len-1)*v1*out
  v2_1[2:len]=v1[1:(len-1)]*inc
  v2_2[1:(len-1)]=1:(len-1)*v1[2:len]*dec
  list(v2_0=v2_0,v2_1=v2_1,v2_2=v2_2,v2=v2)
}

LaToState <- function(xa) {
  unlist(lapply(xa,function(x) {
    gamma=x/sum(x)
    sum(gamma* (0:(length(gamma)-1)))
  } ))
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
  
  #test
  if (FALSE) {
    #should equal, tmp not consider beta
    n=24
    sum(la1[[n]][2:(max.person[n]+1)]*pdec[n]*c(1:max.person[n]))
    n=25
    sum(la1[[n]][1:max.person[n]]*pinc[n])
    
    n=1
    sum(la1[[n]][2:(max.person[n]+1)]*pdec[n]*c(1:max.person[n]))
    sum(unlist(sapply(locout[[n]],function(m) sum(la1[[m]][1:max.person[m]]*pinc[m]))))
    
    v1=la1[[n]]
    inc=pinc[n]
    out=pout[n]
    pn=pn[n]
    dec=pdec[[n]]
    len=max.person[n]+1
    
    #post test
    prev = LaToState(la1)
    post = LaToState(la2_tilde)
    diff = post - prev
    
    #upd_fowrad_test
    tmpl1=tmpl2=list()
    for(n in c(1:25)) {
      tmpl1[[n]] = upd_forward_test(la1[[n]],pinc[n],pout[n],pn[n],pdec[n],max.person[n]+1) 
      tmpl2[[n]] = unlist(lapply(tmpl1[[n]],sum)) 
    }
    tmpm = matrix(unlist(tmpl2),nrow = 25, byrow = T)
    colnames(tmpm) = names(tmpl2[[1]])
    
    tmpl1_n = lapply(tmpl1,function(n) lapply(n,function(m) {
      m/sum(n$v2)
    }))
    
    tmp_xt = t(sapply(c(1:25),function(n) unlist(lapply(tmpl1_n[[n]], function(m) {
      sum(m*c(0:max.person[n]))
    }))))
    tmp_tot = colSums(tmp_xt)
    tmp_tot[1]+tmp_tot[2]+tmp_tot[3]
    
    #forward test xt
    tmp_diff = t(sapply(c(1:25),function(n) unlist(lapply(tmpl1_n[[n]], function(m) {
      sum( (m-la1[[n]])*c(0:max.person[n]))
    }))))
    
    
  }
  la2_tilde = lapply(1:length(locations), function(n) upd_forward(la1[[n]],pinc[n],pout[n],pn[n],pdec[n],max.person[n]+1) )
  
  lg2=lapply(1:length(locations), function(n) la2_tilde[[n]]*lb2[[n]] )
  K=sapply(lg2, sum )
  la2_tilde=lapply(1:length(locations), function(n) la2_tilde[[n]]/K[n])
  
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
  pdec= sapply(1:length(locations),function(n)  sum(  rateout[[n]] * fra.inc[locout[[n]] ] ) )
  
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
  
  list(la2_tilde=la2_tilde)
}

forward2 = function(la, lb, obs, rate_in_f, rate_out_f, max.person, step){
  
  new.t = c()
  length.la = length(la)
  
  for(i in 1:1440){
    #print(i)
    
    ratein=rate_in_f(i) # ratein is a list, each element stores the rate constant of the cars moving from its neighbors to the link 
    rateout=rate_out_f(i) # rateout is a list, each element stores the rate constant of the cars moving from the link to its neighbors
    locin=loc_in_f(i)
    locout=loc_out_f(i)
    
    la1=la[[i]]
    lb2=lb[[i+1]]
    
    m.eq=numeric(length = length(locations))
    m.eq[unobservable]=sapply(unobservable,function(n) sum(la1[[n]]*lb2[[n]]))
    obs.p2=lapply(observable, function(n) obs.matrix[ 1:(max.person[n]+1) ,observation[[as.character(n)]][i+1]+1 ] )
    if ((i %% step)!=0) {
      obs.p2[[1]][]=1
      obs.p2[[2]][]=1
    }
    names(obs.p2)=observable_nominal
    m.eq[observable]=sapply(observable,function(n) sum(la1[[n]]*lb2[[n]]*obs.p2[[as.character(n)]]))
    m.eq[m.eq==0]=1e-20
    
    m.eq.x=numeric(length = length(locations))
    m.eq.x[unobservable]=sapply(unobservable,function(n) sum(0:max.person[n]*la1[[n]]*lb2[[n]]))
    m.eq.x[observable]=sapply(observable,function(n) sum(0:max.person[n]*la1[[n]]*lb2[[n]]*obs.p2[[as.character(n)]]))
    
    pout=sapply(rateout, sum)
    pnull= sum(pout*m.eq.x/m.eq) - pout*m.eq.x/m.eq
    r_nnn=max.person*pout+pnull
    nnn = max(ceiling(r_nnn))
    
    pout=pout/nnn
    pnull=pnull/nnn
    ratein=lapply(1:length(ratein), function(n) ratein[[n]]/nnn)
    rateout=lapply(1:length(rateout), function(n) rateout[[n]]/nnn)
    
    #print("--------------------------------nnn---------")
    #print(nnn)
    
    if(nnn>1) new.t=c(new.t,i+1:(nnn-1)/nnn)
    
    for (k in 1:nnn){
      t1 = i+(k-1)/nnn; t2 = i+k/nnn;
      lb2=getSlice(lb,t2);
      
      if(k!=nnn) {
        tran=transition_forward_fra(la1,lb2,ratein, locin, rateout, locout, pout, pnull)
        la2=tran$la2_tilde
        
        if(length(attr(la,'t'))==length.la){la = alloc(la); length.la = length(la)}
        if(min(abs(t2-attr(la,'t')))<1e-6) {
          la[[which.min(abs(t2-attr(la,'t')))]] = la2
        } else {
          attr(la,'t') = c(attr(la,'t'),t2);
          la[[length(attr(la,'t'))]]=la2
        }
        
      } else {
        tran=transition_forward_int(la1,lb2,ratein, locin, rateout, locout, pout, pnull,obs.p2)
        la2=tran$la2_tilde
        la[[i+1]]=la2
      }
      
      la1=la2
      
    } # k
  }
  
  new.t=c(1:1441,new.t)
  la = unclass(la)[match(new.t,attr(la,'t'))]; attr(la,'t') = new.t;  attr(la,'c')="a"
  
  list(la = la)
}




upd_backward<-function(v1,inc,out,pn,dec,len){
  v2=v1*pn - 0:(len-1)*v1*out
  v2[1:(len-1)]=v2[1:(len-1)]+v1[2:len]*inc
  v2[2:len]=v2[2:len]+1:(len-1)*v1[1:(len-1)]*dec
  v2
}

transition_backward_fra<-function(la1,lb2,ratein, locin, rateout, locout, pout, pnull){
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
  
  lb1_tilde = lapply(1:length(locations), function(n) upd_backward(lb2[[n]],pinc[n],pout[n],pn[n],pdec[n],max.person[n]+1) )
  
  lg1=lapply(1:length(locations), function(n) la1[[n]]*lb1_tilde[[n]] )
  K=sapply(lg1, sum )
  lb1_tilde=lapply(1:length(locations), function(n) lb1_tilde[[n]]/K[n])
  
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
  
  lb2[observable]=lapply(observable, function(n) lb2[[n]] * obs.p2[[as.character(n) ]] )
  lb1_tilde = lapply(1:length(locations), function(n) upd_backward(lb2[[n]],pinc[n],pout[n],pn[n],pdec[n],max.person[n]+1) )
  
  lg1=lapply(1:length(locations), function(n) la1[[n]]*lb1_tilde[[n]] )
  K=sapply(lg1, sum )
  lb1_tilde=lapply(1:length(locations), function(n) lb1_tilde[[n]]/K[n])
  
  list(lb1_tilde=lb1_tilde)
}


backward2 = function(la, lb, obs, rate_in_f, rate_out_f, max.person, step){
  
  new.t = c()
  length.lb = length(lb);
  
  for(i in 1440:1 ){
    #print(i)
    
    ratein=rate_in_f(i) # ratein is a list, each element stores the rate constant of the cars moving from its neighbors to the link 
    rateout=rate_out_f(i) # rateout is a list, each element stores the rate constant of the cars moving from the link to its neighbors
    locin=loc_in_f(i)
    locout=loc_out_f(i)
    
    la1=la[[i]]
    lb2=lb[[i+1]]
    
    m.eq=numeric(length = length(locations))
    m.eq[unobservable]=sapply(unobservable,function(n) sum(la1[[n]]*lb2[[n]]))
    obs.p2=lapply(observable, function(n) obs.matrix[ 1:(max.person[n]+1) ,observation[[as.character(n)]][i+1]+1 ] )
    if ((i %% step)!=0) {
      obs.p2[[1]][]=1
      obs.p2[[2]][]=1
    }
    
    names(obs.p2)=observable_nominal
    m.eq[observable]=sapply(observable,function(n) sum(la1[[n]]*lb2[[n]]*obs.p2[[as.character(n)]]))
    m.eq[m.eq==0]=1e-20
    
    m.eq.x=numeric(length = length(locations))
    m.eq.x[unobservable]=sapply(unobservable,function(n) sum(0:max.person[n]*la1[[n]]*lb2[[n]]))
    m.eq.x[observable]=sapply(observable,function(n) sum(0:max.person[n]*la1[[n]]*lb2[[n]]*obs.p2[[as.character(n)]]))
    
    pout=sapply(rateout, sum)
    pnull= sum(pout*m.eq.x/m.eq) - pout*m.eq.x/m.eq
    r_nnn=max.person*pout+pnull
    nnn = max(ceiling(r_nnn))
    
    pout=pout/nnn
    pnull=pnull/nnn
    ratein=lapply(1:length(ratein), function(n) ratein[[n]]/nnn)
    rateout=lapply(1:length(rateout), function(n) rateout[[n]]/nnn)
    
    #print("--------------------------------nnn---------")
    #print(nnn)
    
    if(nnn>1) new.t=c(new.t,i+(nnn-1):1/nnn)
    
    for (k in nnn:1){
      t1 = i+(k-1)/nnn; t2 = i+k/nnn;
      la1=getSlice(la,t1)
      
      if(k!=nnn) {
        tran=transition_backward_fra(la1,lb2,ratein, locin, rateout, locout, pout, pnull)        
      } else {
        tran=transition_backward_int(la1,lb2,ratein, locin, rateout, locout, pout, pnull,obs.p2)
      }
      
      lb1=tran$lb1_tilde
      lb2 = lb1
      
      if(k==1){
        lb[[i]]=lb1
      } else{
        if(length(attr(lb,'t'))==length.lb){lb = alloc(lb); length.lb = length(lb)}
        if(min(abs(t1-attr(lb,'t')))<1e-12) {
          lb[[which.min(abs(t1-attr(lb,'t')))]] <- lb1
        } else{
          attr(lb,'t') = c(attr(lb,'t'),t1)
          lb[[length(attr(lb,'t'))]]<-lb1
        }
      }
      
    }
  }
  
  new.t=c(1:1441,rev(new.t) )
  lb = unclass(lb)[match(new.t,attr(lb,'t'))]; attr(lb,'t') = new.t;  attr(lb,'c')="b"
  list(lb = lb)
}


#######################################################################################################









































