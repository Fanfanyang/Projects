load("benchmark with dakar dataset/inference_2.RData")

lower=0
upper=max.person

normproduct_m<-function(m1,v1,m2,v2){
  (m1*v2+m2*v1)/(v1+v2)
}

normproduct_v<-function(v1,v2){
  v1*v2/(v1+v2)
}

# the m,v of product of two gaussians
normproduct_mv<-function(m1,v1,m2,v2){
  v=v1*v2/(v1+v2)
  m=(m1*v2+m2*v1)/(v1+v2)
  rbind(m,v)
}


# the m,v of "division" of two gaussians
normdivision_mv<-function(m1,v1,m2,v2){
  v=v2*v1/(v2-v1)
  v[is.infinite(v)]=1e20
  m=(m1/v1-m2/v2)*v
  rbind(m,v)
}

# the first order moment of a truncated gaussian
trucfirst<-function(m,v,l,u){
  if(any(v<=0)) print("input truncated normal is invalid")
  s=sqrt(v)
  a=(l-m)/s
  b=(u-m)/s
  
  first=numeric(length = length(m))
  da=dnorm(a)
  db=dnorm(b)
  pa=pnorm(a)
  pb=pnorm(b)
  
  first=m + s*(da-db)/(pb-pa)
  
  ind= which(pb==pa)
  ind2= m[ind]<=l
  
  first[ind][ind2]=l
  first[ind][!ind2]=u[ind][!ind2]
  
  first[first<l]=l
  first[first>u]=u[first>u]
  first
}

# the second order moment of a truncated gaussian
trucsecond<-function(m,v,l,u){
  if(any(v<=0)) print("input truncated normal is invalid in second")
  s=sqrt(v)
  a=(l-m)/s
  b=(u-m)/s
  da=dnorm(a)
  db=dnorm(b)
  pa=pnorm(a)
  pb=pnorm(b)
  
  second=m^2+v-s* ((m+u)*db-(m+l)*da)/(pb-pa)
  
  ind=which(pb==pa)
  ind2=m[ind]<=l
  
  second[ind][ind2]=l^2
  second[ind][!ind2]=u[ind][!ind2]^2
  
  second[second<0]=0
  second
}

# the third order moment of a truncated gaussian
tructhird<-function(m,v,l,u){
  if(any(v<=0)) print("input truncated normal is invalid in third")
  s=sqrt(v)
  a=(l-m)/s
  b=(u-m)/s
  da=dnorm(a)
  db=dnorm(b)
  pa=pnorm(a)
  pb=pnorm(b)
  
  third=m^3+3*m*v-s* ((m^2+2*v+m*u+u^2)*db-(m^2+2*v+m*l+l^2)*da)/(pb-pa)
  
  ind=which(pb==pa)
  ind2=m[ind]<=l
  
  third[ind][ind2]=l^3
  third[ind][!ind2]=u[ind][!ind2]^3
  
  third[third<l^3]=l^3
  third[third>u^3]=(u^3)[third>u^3]
  third
}

# the truncated gaussian is not only a gaussian times with an indicator function, but also with a normlizer: the difference of two cdf values
cdfdifference<-function(m,v,l,u){
  s=sqrt(v)
  a=(l-m)/s
  b=(u-m)/s
  pnorm(b)-pnorm(a)
}


transition_forward_fra<-function(la1,lb2,ratein, locin, rateout, locout,pout,pnull ){
  
  inc_lower=lower-1
  inc_upper=upper-1
  eq_lower=lower
  eq_upper=upper
  dec_lower=lower+1
  dec_upper=upper+1
  
  # inc means alpha(x)*beta(x+1)*obs(x+1). If beta(x) is N(m,v), the beta(x+1)=N(m-1,v), dec is alpha(x)*beta(x-1)*obs(x-1)
  product_inc_m=normproduct_m(la1[1,],la1[2,],lb2[1,]-1,lb2[2,])
  product_eq_m=normproduct_m(la1[1,],la1[2,],lb2[1,],lb2[2,])
  product_dec_m=normproduct_m(la1[1,],la1[2,],lb2[1,]+1,lb2[2,])
  product_v=normproduct_v(la1[2,],lb2[2,])
  
  product_inc_k_exp=-(2*(la1[1,]-lb2[1,])+1)/(la1[2,]+lb2[2,])/2.0
  product_dec_k_exp=(2*(la1[1,]-lb2[1,])-1)/(la1[2,]+lb2[2,])/2.0
  
  product_inc_k_fac=exp(product_inc_k_exp )
  product_dec_k_fac=exp(product_dec_k_exp )
  
  product_inc_k_fac[product_inc_k_fac>1e150]=1e150
  product_dec_k_fac[product_dec_k_fac>1e150]=1e150
  
  # I_inc=\sum_{x} alpha(x)*beta(x+1)*obs(x+1) =\sum_{x} constant factor *gaussian(x)*Indicator = constant factor* cdfdiffernce
  m.inc =product_inc_k_fac*
    cdfdifference(product_inc_m,product_v,inc_lower,inc_upper)
  
  # I_eq=\sum_{x} alpha(x)*beta(x)*obs(x) =\sum_{x} constant factor *gaussian(x)*Indicator = constant factor* cdfdiffernce
  m.eq =
    cdfdifference(product_eq_m,product_v,eq_lower,eq_upper)
  m.eq[m.eq==0]=1e-20
  
  # I_dec=\sum_{x} alpha(x)*beta(x-1)*obs(x-1)*x =\sum_{x} constant factor *gaussian(x)*Indicator*x = constant factor* cdfdiffernce * trucfirst  
  m.dec=product_dec_k_fac*
    cdfdifference(product_dec_m,product_v,dec_lower,dec_upper)*
    trucfirst(product_dec_m,product_v,dec_lower,dec_upper)
  
  fra.inc=m.inc/m.eq
  fra.dec=m.dec/m.eq
  fra.inc[fra.inc>1e150]=1e150
  fra.dec[fra.dec>1e150]=1e150
  
  pinc=sapply(1:length(locations),function(n) sum(  ratein[[n]] * fra.dec[locin[[n]] ] )) 
  pdec= sapply(1:length(locations),function(n)  sum(  rateout[[n]] * fra.inc[locout[[n]]  ] ) )
  
  #for each link, calculate the prob of transition at all other links 
  tran=lapply(1:length(locations), function(n)  rateout[[n]] *  fra.dec[n] * fra.inc[ locout[[n]] ] )
  alltran=sum(unlist(tran))
  
  trother=numeric(length = length(locations))
  trother[]=alltran
  trother=trother-sapply(tran,sum) # transition at other links = all transition - transition from local link - transition to local link
  
  for(n in 1:length(locations)) trother[locout[[n]]]=trother[locout[[n]]]-tran[[n]]
  
  pn=1-pnull+trother
  
  inc_lower=lower
  inc_upper=upper
  eq_lower=lower
  eq_upper=upper
  dec_lower=lower
  dec_upper=upper
  
  
  #moment matching versus gamma(x) \propto la1(x-1)*lb2(x)*obs(x)*pinc + la1(x)*lb2(x)*obs(x)*(1-pout*x-pn)+ la1(x+1)*lb2(x)*obs(x)*pdec*(x+1)
  inc_m=normproduct_m(la1[1,]+1,la1[2,],lb2[1,],lb2[2,])
  eq_m=normproduct_m(la1[1,],la1[2,],lb2[1,],lb2[2,])
  dec_m=normproduct_m(la1[1,]-1,la1[2,],lb2[1,],lb2[2,])
  tran_v=normproduct_v(la1[2,],lb2[2,])
  
  inc_k_exp=product_inc_k_exp
  dec_k_exp=product_dec_k_exp
  
  inc_k_fac=exp(inc_k_exp )
  dec_k_fac=exp(dec_k_exp )
  
  inc_k_fac[inc_k_fac>1e150]=1e150
  dec_k_fac[dec_k_fac>1e150]=1e150
  
  inc_const=inc_k_fac*cdfdifference(inc_m,tran_v,inc_lower,inc_upper)
  eq_const=cdfdifference(eq_m,tran_v,eq_lower,eq_upper)
  eq_const[eq_const==0]=1e-300
  dec_const=dec_k_fac*cdfdifference(dec_m,tran_v,dec_lower,dec_upper)
  
  inc_first=trucfirst(inc_m,tran_v,inc_lower,inc_upper)
  inc_second=trucsecond(inc_m,tran_v,inc_lower,inc_upper)
  eq_first=trucfirst(eq_m,tran_v,eq_lower,eq_upper)
  eq_second=trucsecond(eq_m,tran_v,eq_lower,eq_upper)
  eq_third=tructhird(eq_m,tran_v,eq_lower,eq_upper)
  dec_first=trucfirst(dec_m,tran_v,dec_lower,dec_upper)
  dec_second=trucsecond(dec_m,tran_v,dec_lower,dec_upper)
  dec_third=tructhird(dec_m,tran_v,dec_lower,dec_upper)
  
  # k= \sum_{x} gamma(x)
  inc.k=inc_const*pinc
  eq.k=eq_const*( pn -pout*eq_first )
  dec.k=dec_const*pdec*(dec_first+1)
  sum_k=inc.k+eq.k+dec.k
  
  # m= \sum_{x} gamma(x)*x
  inc.m=inc_const*pinc*inc_first
  eq.m=eq_const*( pn*eq_first-pout*eq_second)
  dec.m=dec_const*pdec*(dec_second+dec_first)
  sum_m=inc.m+eq.m+dec.m
  lg2_m=sum_m/sum_k
  
  # v= \sum_{x} gamma(x)*(x-mean)^2
  inc.v=inc_const*pinc*(inc_second-2*lg2_m*inc_first+lg2_m^2)
  eq.v= eq_const*( pn*(eq_second-2*lg2_m*eq_first+lg2_m^2) - pout*(eq_third-2*lg2_m*eq_second+lg2_m^2*eq_first) )
  dec.v=dec_const*pdec*((dec_third-2*lg2_m*dec_second+lg2_m^2*dec_first)+(dec_second-2*lg2_m*dec_first+lg2_m^2) )
  sum_v=inc.v+eq.v+dec.v
  lg2_v=sum_v/sum_k
  
  #   lg2_m[lg2_m<0]=0
  #   lg2_m[lg2_m>upper]=upper[lg2_m>upper]
  lg2_v[lg2_v<=0]=1e8
  
  lg2_tilde=rbind(lg2_m,lg2_v)
  
  la2_tilde=normdivision_mv(lg2_m,lg2_v,lb2[1,],lb2[2,])
  la2_tilde[2,la2_tilde[2,]<=0]=1e10
  list(la2_tilde=la2_tilde,lg2_tilde=lg2_tilde ) 
}


transition_forward_int<-function(la1,lb2,ratein, locin, rateout, locout,pout,pnull,obs.p2 ){
  
  inc_lower=lower-1
  inc_upper=upper-1
  eq_lower=lower
  eq_upper=upper
  dec_lower=lower+1
  dec_upper=upper+1
  
  # inc means alpha(x)*beta(x+1)*obs(x+1). If beta(x) is N(m,v), then beta(x+1)=N(m-1,v); dec is alpha(x)*beta(x-1)*obs(x-1)
  product_inc_m=normproduct_m(la1[1,],la1[2,],lb2[1,]-1,lb2[2,])
  product_eq_m=normproduct_m(la1[1,],la1[2,],lb2[1,],lb2[2,])
  product_dec_m=normproduct_m(la1[1,],la1[2,],lb2[1,]+1,lb2[2,])
  product_v=normproduct_v(la1[2,],lb2[2,])
  
  product_inc_k_exp=-(2*(la1[1,]-lb2[1,])+1)/(la1[2,]+lb2[2,])/2.0
  product_dec_k_exp=(2*(la1[1,]-lb2[1,])-1)/(la1[2,]+lb2[2,])/2.0
  
  product_inc_k_exp_obs=((product_eq_m[observable]-obs.p2[1,])^2 - (product_inc_m[observable]-obs.p2[1,]+1)^2)/(product_v[observable]+obs.p2[2,])/2.0
  product_dec_k_exp_obs=((product_eq_m[observable]-obs.p2[1,])^2 - (product_dec_m[observable]-obs.p2[1,]-1)^2)/(product_v[observable]+obs.p2[2,])/2.0
  
  product_inc_k_exp[observable]=product_inc_k_exp[observable] + product_inc_k_exp_obs
  product_dec_k_exp[observable]=product_dec_k_exp[observable] + product_dec_k_exp_obs
  
  product_inc_k_fac=exp(product_inc_k_exp )
  product_dec_k_fac=exp(product_dec_k_exp )
  
  product_inc_k_fac[product_inc_k_fac>1e150]=1e150
  product_dec_k_fac[product_dec_k_fac>1e150]=1e150
  
  product_inc_m[observable]=normproduct_m(product_inc_m[observable],product_v[observable],obs.p2[1,]-1,obs.p2[2,])
  product_eq_m[observable]=normproduct_m(product_eq_m[observable],product_v[observable],obs.p2[1,],obs.p2[2,])
  product_dec_m[observable]=normproduct_m(product_dec_m[observable],product_v[observable],obs.p2[1,]+1,obs.p2[2,])
  product_v[observable]=normproduct_v(product_v[observable],obs.p2[2,])
  
  # I_inc=\sum_{x} alpha(x)*beta(x+1)*obs(x+1) =\sum_{x} constant factor *gaussian(x)*Indicator = constant factor* cdfdiffernce
  m.inc =product_inc_k_fac*
    cdfdifference(product_inc_m,product_v,inc_lower,inc_upper)
  
  # I_eq=\sum_{x} alpha(x)*beta(x)*obs(x) =\sum_{x} constant factor *gaussian(x)*Indicator = constant factor* cdfdiffernce
  m.eq =
    cdfdifference(product_eq_m,product_v,eq_lower,eq_upper)
  m.eq[m.eq==0]=1e-20
  
  # I_dec=\sum_{x} alpha(x)*beta(x-1)*obs(x-1)*x =\sum_{x} constant factor *gaussian(x)*Indicator*x = constant factor* cdfdiffernce * trucfirst  
  m.dec=product_dec_k_fac*
    cdfdifference(product_dec_m,product_v,dec_lower,dec_upper)*
    trucfirst(product_dec_m,product_v,dec_lower,dec_upper)
  
  
  fra.inc=m.inc/m.eq
  fra.dec=m.dec/m.eq
  
  fra.inc[fra.inc>1e150]=1e150
  fra.dec[fra.dec>1e150]=1e150
  pinc=sapply(1:length(locations),function(n) sum(  ratein[[n]] * fra.dec[locin[[n]] ] )) 
  pdec= sapply(1:length(locations),function(n)  sum(  rateout[[n]] * fra.inc[locout[[n]]  ] ) )
  
  #for each link, calculate the prob of transition at all other links 
  tran=lapply(1:length(locations), function(n) rateout[[n]] *  fra.dec[n] * fra.inc[locout[[n]] ] )
  alltran=sum(unlist(tran))
  trother=numeric(length = length(locations))
  trother[]=alltran
  trother=trother-sapply(tran,sum) # transition at other links = all transition - transition from local link - transition to local link
  for(n in 1:length(locations)) trother[locout[[n]]]=trother[locout[[n]]]-tran[[n]]
  pn=1-pnull+trother
  
  
  inc_lower=lower
  inc_upper=upper
  eq_lower=lower
  eq_upper=upper
  dec_lower=lower
  dec_upper=upper
  
  #moment matching versus gamma(x) \propto la1(x-1)*lb2(x)*obs(x)*pinc + la1(x)*lb2(x)*obs(x)*(1-pout*x-pn)+ la1(x+1)*lb2(x)*obs(x)*pdec*(x+1)
  
  inc_m=normproduct_m(la1[1,]+1,la1[2,],lb2[1,],lb2[2,])
  eq_m=normproduct_m(la1[1,],la1[2,],lb2[1,],lb2[2,])
  dec_m=normproduct_m(la1[1,]-1,la1[2,],lb2[1,],lb2[2,])
  tran_v=normproduct_v(la1[2,],lb2[2,])
  
  inc_k_exp=-(2*(la1[1,]-lb2[1,])+1)/(la1[2,]+lb2[2,])/2.0
  dec_k_exp=(2*(la1[1,]-lb2[1,])-1)/(la1[2,]+lb2[2,])/2.0
  
  inc_k_exp_obs=((eq_m[observable]-obs.p2[1,])^2 - (inc_m[observable]-obs.p2[1,])^2)/(tran_v[observable]+obs.p2[2,])/2.0
  dec_k_exp_obs=((eq_m[observable]-obs.p2[1,])^2 - (dec_m[observable]-obs.p2[1,])^2)/(tran_v[observable]+obs.p2[2,])/2.0
  
  inc_k_exp[observable]=inc_k_exp[observable] + inc_k_exp_obs
  dec_k_exp[observable]=dec_k_exp[observable] + dec_k_exp_obs
  
  inc_k_fac=exp(inc_k_exp)
  dec_k_fac=exp(dec_k_exp)
  
  inc_k_fac[inc_k_fac>1e150]=1e150
  dec_k_fac[dec_k_fac>1e150]=1e150
  
  inc_m[observable]=normproduct_m(inc_m[observable],tran_v[observable],obs.p2[1,],obs.p2[2,])
  eq_m[observable]=normproduct_m(eq_m[observable],tran_v[observable],obs.p2[1,],obs.p2[2,])
  dec_m[observable]=normproduct_m(dec_m[observable],tran_v[observable],obs.p2[1,],obs.p2[2,])
  tran_v[observable]=normproduct_v(tran_v[observable],obs.p2[2,])
  
  inc_const=inc_k_fac*cdfdifference(inc_m,tran_v,inc_lower,inc_upper)
  eq_const=cdfdifference(eq_m,tran_v,eq_lower,eq_upper)
  eq_const[eq_const==0]=1e-300
  dec_const=dec_k_fac*cdfdifference(dec_m,tran_v,dec_lower,dec_upper)
  
  inc_first=trucfirst(inc_m,tran_v,inc_lower,inc_upper)
  inc_second=trucsecond(inc_m,tran_v,inc_lower,inc_upper)
  eq_first=trucfirst(eq_m,tran_v,eq_lower,eq_upper)
  eq_second=trucsecond(eq_m,tran_v,eq_lower,eq_upper)
  eq_third=tructhird(eq_m,tran_v,eq_lower,eq_upper)
  dec_first=trucfirst(dec_m,tran_v,dec_lower,dec_upper)
  dec_second=trucsecond(dec_m,tran_v,dec_lower,dec_upper)
  dec_third=tructhird(dec_m,tran_v,dec_lower,dec_upper)
  
  # k= \sum_{x} gamma(x)
  inc.k=inc_const*pinc
  eq.k=eq_const*( pn -pout*eq_first )
  dec.k=dec_const*pdec*(dec_first+1)
  sum_k=inc.k+eq.k+dec.k
  
  # m= \sum_{x} gamma(x)*x
  inc.m=inc_const*pinc*inc_first
  eq.m=eq_const*( pn*eq_first-pout*eq_second)
  dec.m=dec_const*pdec*(dec_second+dec_first)
  sum_m=inc.m+eq.m+dec.m
  lg2_m=sum_m/sum_k
  
  # v= \sum_{x} gamma(x)*(x-mean)^2
  inc.v=inc_const*pinc*(inc_second-2*lg2_m*inc_first+lg2_m^2)
  eq.v= eq_const*( pn*(eq_second-2*lg2_m*eq_first+lg2_m^2) - pout*(eq_third-2*lg2_m*eq_second+lg2_m^2*eq_first) )
  dec.v=dec_const*pdec*((dec_third-2*lg2_m*dec_second+lg2_m^2*dec_first)+(dec_second-2*lg2_m*dec_first+lg2_m^2) )
  sum_v=inc.v+eq.v+dec.v
  lg2_v=sum_v/sum_k
  
  #   lg2_m[lg2_m<0]=0
  #   lg2_m[lg2_m>upper]=upper[lg2_m>upper]
  lg2_v[lg2_v<=0]=1e8
  
  lg2_tilde=rbind(lg2_m,lg2_v)
  
  la2_tilde=normdivision_mv(lg2_m,lg2_v,lb2[1,],lb2[2,])
  la2_tilde[2,la2_tilde[2,]<=0]=1e10
  list(la2_tilde=la2_tilde,lg2_tilde=lg2_tilde ) 
}



forward2 = function(la,  lb, lg, obs, rate_in_f, rate_out_f, max.person){
  
  lower=0
  upper=max.person
  
  new.t = c()
  length.la = length(la) 
  length.lg = length(lg)
  
  for(i in 1:1199 ){#(length(obs.p)-1)
    print(i)
    ratein=rate_in_f(i) # ratein is a list, each element stores the rate constant of the cars moving from its neighbors to the link 
    rateout=rate_out_f(i) # rateout is a list, each element stores the rate constant of the cars moving from the link to its neighbors
    locin=loc_in_f(i)
    locout=loc_out_f(i)
    
    la1=la[[i]]
    lb2=lb[[i+1]]
    
    m.eq=numeric(length = length(locations))
    product_eq=normproduct_mv(la1[1,],la1[2,],lb2[1,],lb2[2,])
    m.eq[unobservable]=trucfirst(product_eq[1,unobservable],product_eq[2,unobservable],lower,upper[unobservable])
    
    obs.p2=sapply(observable, function(n) obs.prob[,observation[[as.character(n)]][i+1]+1 ] )
    product_eq[,observable]=normproduct_mv(product_eq[1,observable],product_eq[2,observable],obs.p2[1,],obs.p2[2,])
    m.eq[observable]=trucfirst(product_eq[1,observable],product_eq[2,observable],lower,upper[observable])
    
    pout=sapply(rateout, sum)
    pnull= sum(pout*m.eq) - pout*m.eq
    r_nnn=max.person*pout+pnull
    nnn = max(ceiling(r_nnn))
    
    pout=pout/nnn
    pnull=pnull/nnn
    ratein=lapply(1:length(ratein), function(n) ratein[[n]]/nnn)
    rateout=lapply(1:length(rateout), function(n) rateout[[n]]/nnn)
    
    print("--------------------------------nnn---------")
    print(nnn)
    
    if(nnn>1) new.t=c(new.t,i+1:(nnn-1)/nnn)
    
    for (k in 1:nnn){
      #print(k)
      t1 = i+(k-1)/nnn; t2 = i+k/nnn;
      lb2=getSlice(lb,t2); 
      if(k!=nnn) {
        tran=transition_forward_fra(la1,lb2,ratein, locin, rateout, locout, pout, pnull )
        la2=tran$la2_tilde
        la1=la2
        lg2=tran$lg2_tilde
        
        if(length(attr(la,'t'))==length.la){la = alloc(la); length.la = length(la)}
        if(min(abs(t2-attr(la,'t')))<1e-6) {
          la[[which.min(abs(t2-attr(la,'t')))]] = la2
        } else {
          attr(la,'t') = c(attr(la,'t'),t2);
          la[[length(attr(la,'t'))]]=la2
        }
        
        if(length(attr(lg,'t'))==length.lg){lg = alloc(lg); length.lg = length(lg)}
        if(min(abs(t2-attr(lg,'t')))<1e-6) {
          lg[[which.min(abs(t2-attr(lg,'t')))]] = lg2
        } else {
          attr(lg,'t') = c(attr(lg,'t'),t2);
          lg[[length(attr(lg,'t'))]]=lg2
        }
        
      } else {
        tran=transition_forward_int(la1,lb2,ratein, locin, rateout, locout, pout, pnull,obs.p2 )
        la2=tran$la2_tilde
        la1=la2
        lg2=tran$lg2_tilde
        la[[i+1]]=la2
        lg[[i+1]]=lg2
      }
      
      #print(lg2)
      
    } # k
  } # (length(obs.p)-1)
  
  new.t=c(1:1200,new.t)
  la = unclass(la)[match(new.t,attr(la,'t'))]; attr(la,'t') = new.t;  attr(la,'c')="a"
  lg = unclass(lg)[match(new.t,attr(lg,'t'))]; attr(lg,'t') = new.t;  attr(lg,'c')="a"
  
  list(la = la,lg=lg)
}



transition_backward_fra<-function(la1,lb2,ratein, locin, rateout, locout,pout,pnull ){  
  
  inc_lower=lower-1
  inc_upper=upper-1
  eq_lower=lower
  eq_upper=upper
  dec_lower=lower+1
  dec_upper=upper+1
  
  # inc means alpha(x)*beta(x+1)*obs(x+1). If beta(x) is N(m,v), the beta(x+1)=N(m-1,v), dec is alpha(x)*beta(x-1)*obs(x-1)
  product_inc_m=normproduct_m(la1[1,],la1[2,],lb2[1,]-1,lb2[2,])
  product_eq_m=normproduct_m(la1[1,],la1[2,],lb2[1,],lb2[2,])
  product_dec_m=normproduct_m(la1[1,],la1[2,],lb2[1,]+1,lb2[2,])
  product_v=normproduct_v(la1[2,],lb2[2,])
  
  product_inc_k_exp=-(2*(la1[1,]-lb2[1,])+1)/(la1[2,]+lb2[2,])/2.0
  product_dec_k_exp=(2*(la1[1,]-lb2[1,])-1)/(la1[2,]+lb2[2,])/2.0
  
  product_inc_k_fac=exp(product_inc_k_exp )
  product_dec_k_fac=exp(product_dec_k_exp )
  
  product_inc_k_fac[product_inc_k_fac>1e150]=1e150
  product_dec_k_fac[product_dec_k_fac>1e150]=1e150
  
  # I_inc=\sum_{x} alpha(x)*beta(x+1)*obs(x+1) =\sum_{x} constant factor *gaussian(x)*Indicator = constant factor* cdfdiffernce
  m.inc =product_inc_k_fac*
    cdfdifference(product_inc_m,product_v,inc_lower,inc_upper)
  
  # I_eq=\sum_{x} alpha(x)*beta(x)*obs(x) =\sum_{x} constant factor *gaussian(x)*Indicator = constant factor* cdfdiffernce
  m.eq =
    cdfdifference(product_eq_m,product_v,eq_lower,eq_upper)
  m.eq[m.eq==0]=1e-20
  
  # I_dec=\sum_{x} alpha(x)*beta(x-1)*obs(x-1)*x =\sum_{x} constant factor *gaussian(x)*Indicator*x = constant factor* cdfdiffernce * trucfirst  
  m.dec=product_dec_k_fac*
    cdfdifference(product_dec_m,product_v,dec_lower,dec_upper)*
    trucfirst(product_dec_m,product_v,dec_lower,dec_upper)
  
  fra.inc=m.inc/m.eq
  fra.dec=m.dec/m.eq
  
  fra.inc[fra.inc>1e150]=1e150
  fra.dec[fra.dec>1e150]=1e150
  pinc=sapply(1:length(locations),function(n) sum(  ratein[[n]] * fra.dec[locin[[n]] ] )) 
  pdec= sapply(1:length(locations),function(n)  sum(  rateout[[n]] * fra.inc[locout[[n]]  ] ) )
  
  #for each link, calculate the prob of transition at all other links
  tran=lapply(1:length(locations), function(n) rateout[[n]] *  fra.dec[n] * fra.inc[locout[[n]] ] )
  alltran=sum(unlist(tran))
  trother=numeric(length = length(locations))
  trother[]=alltran
  trother=trother-sapply(tran,sum) # transition at other links = all transition - transition from local link - transition to local link
  for(n in 1:length(locations)) trother[locout[[n]]]=trother[locout[[n]]]-tran[[n]]
  pn=1-pnull+trother
  
  inc_lower=lower-1
  inc_upper=upper-1
  eq_lower=lower
  eq_upper=upper
  dec_lower=lower+1
  dec_upper=upper+1
  
  #moment matching versus gamma(x) \propto la1(x)*lb2(x+1)*obs(x+1)*pinc + la1(x)*lb2(x)*obs(x)*(1-pout*x-pn)+ la1(x)*lb2(x-1)*obs(x-1)*pdec*x
  
  inc_m=normproduct_m(la1[1,],la1[2,],lb2[1,]-1,lb2[2,])
  eq_m=normproduct_m(la1[1,],la1[2,],lb2[1,],lb2[2,])
  dec_m=normproduct_m(la1[1,],la1[2,],lb2[1,]+1,lb2[2,])
  tran_v=normproduct_v(la1[2,],lb2[2,])
  
  inc_k_exp=product_inc_k_exp
  dec_k_exp=product_dec_k_exp
  
  inc_k_fac=exp(inc_k_exp )
  dec_k_fac=exp(dec_k_exp )
  
  inc_k_fac[inc_k_fac>1e150]=1e150
  dec_k_fac[dec_k_fac>1e150]=1e150
  
  inc_const=inc_k_fac*cdfdifference(inc_m,tran_v,inc_lower,inc_upper)
  eq_const=cdfdifference(eq_m,tran_v,eq_lower,eq_upper)
  eq_const[eq_const==0]=1e-300
  dec_const=dec_k_fac*cdfdifference(dec_m,tran_v,dec_lower,dec_upper)
  
  
  inc_first=trucfirst(inc_m,tran_v,inc_lower,inc_upper)
  inc_second=trucsecond(inc_m,tran_v,inc_lower,inc_upper)
  eq_first=trucfirst(eq_m,tran_v,eq_lower,eq_upper)
  eq_second=trucsecond(eq_m,tran_v,eq_lower,eq_upper)
  eq_third=tructhird(eq_m,tran_v,eq_lower,eq_upper)
  dec_first=trucfirst(dec_m,tran_v,dec_lower,dec_upper)
  dec_second=trucsecond(dec_m,tran_v,dec_lower,dec_upper)
  dec_third=tructhird(dec_m,tran_v,dec_lower,dec_upper)
  
  # k= \sum_{x} gamma(x)
  inc.k=inc_const*pinc
  eq.k=eq_const*( pn-pout*eq_first )
  dec.k=dec_const*pdec*dec_first
  sum_k=inc.k+eq.k+dec.k
  
  # m= \sum_{x} gamma(x)*x
  inc.m=inc_const*pinc*inc_first
  eq.m=eq_const*( pn*eq_first-pout*eq_second)
  dec.m=dec_const*pdec*dec_second
  sum_m=inc.m+eq.m+dec.m
  lg1_m=sum_m/sum_k
  
  # v= \sum_{x} gamma(x)*(x-mean)^2
  inc.v=inc_const*pinc*(inc_second-2*lg1_m*inc_first+lg1_m^2)
  eq.v= eq_const*( pn*(eq_second-2*lg1_m*eq_first+lg1_m^2) - pout*(eq_third-2*lg1_m*eq_second+lg1_m^2*eq_first) )
  dec.v=dec_const*pdec*(dec_third-2*lg1_m*dec_second+lg1_m^2*dec_first)
  sum_v=inc.v+eq.v+dec.v
  lg1_v=sum_v/sum_k
  
  #   lg1_m[lg1_m<0]=0
  #   lg1_m[lg1_m>upper]=upper[lg1_m>upper]
  lg1_v[lg1_v<=0]=1e8
  
  lg1_tilde=rbind(lg1_m,lg1_v)
  
  lb1_tilde=normdivision_mv(lg1_m,lg1_v,la1[1,],la1[2,])
  lb1_tilde[2,lb1_tilde[2,]<=0]=1e10
  
  list(lb1_tilde=lb1_tilde,lg1_tilde=lg1_tilde)
}


transition_backward_int<-function(la1,lb2,ratein, locin, rateout, locout,pout,pnull,obs.p2 ){  
  
  inc_lower=lower-1
  inc_upper=upper-1
  eq_lower=lower
  eq_upper=upper
  dec_lower=lower+1
  dec_upper=upper+1
  
  # inc means alpha(x)*beta(x+1)*obs(x+1). If beta(x) is N(m,v), the beta(x+1)=N(m-1,v), dec is alpha(x)*beta(x-1)*obs(x-1)
  product_inc_m=normproduct_m(la1[1,],la1[2,],lb2[1,]-1,lb2[2,])
  product_eq_m=normproduct_m(la1[1,],la1[2,],lb2[1,],lb2[2,])
  product_dec_m=normproduct_m(la1[1,],la1[2,],lb2[1,]+1,lb2[2,])
  product_v=normproduct_v(la1[2,],lb2[2,])
  
  product_inc_k_exp=-(2*(la1[1,]-lb2[1,])+1)/(la1[2,]+lb2[2,])/2.0
  product_dec_k_exp=(2*(la1[1,]-lb2[1,])-1)/(la1[2,]+lb2[2,])/2.0
  
  product_inc_k_exp_obs=((product_eq_m[observable]-obs.p2[1,])^2 - (product_inc_m[observable]-obs.p2[1,]+1)^2)/(product_v[observable]+obs.p2[2,])/2.0
  product_dec_k_exp_obs=((product_eq_m[observable]-obs.p2[1,])^2 - (product_dec_m[observable]-obs.p2[1,]-1)^2)/(product_v[observable]+obs.p2[2,])/2.0
  
  product_inc_k_exp[observable]=product_inc_k_exp[observable] + product_inc_k_exp_obs
  product_dec_k_exp[observable]=product_dec_k_exp[observable] + product_dec_k_exp_obs
  
  product_inc_k_fac=exp(product_inc_k_exp )
  product_dec_k_fac=exp(product_dec_k_exp )
  
  product_inc_k_fac[product_inc_k_fac>1e150]=1e150
  product_dec_k_fac[product_dec_k_fac>1e150]=1e150
  
  product_inc_m[observable]=normproduct_m(product_inc_m[observable],product_v[observable],obs.p2[1,]-1,obs.p2[2,])
  product_eq_m[observable]=normproduct_m(product_eq_m[observable],product_v[observable],obs.p2[1,],obs.p2[2,])
  product_dec_m[observable]=normproduct_m(product_dec_m[observable],product_v[observable],obs.p2[1,]+1,obs.p2[2,])
  product_v[observable]=normproduct_v(product_v[observable],obs.p2[2,])
  
  # I_inc=\sum_{x} alpha(x)*beta(x+1)*obs(x+1) =\sum_{x} constant factor *gaussian(x)*Indicator = constant factor* cdfdiffernce
  m.inc =product_inc_k_fac*
    cdfdifference(product_inc_m,product_v,inc_lower,inc_upper)
  
  # I_eq=\sum_{x} alpha(x)*beta(x)*obs(x) =\sum_{x} constant factor *gaussian(x)*Indicator = constant factor* cdfdiffernce
  m.eq =
    cdfdifference(product_eq_m,product_v,eq_lower,eq_upper)
  m.eq[m.eq==0]=1e-20
  
  # I_dec=\sum_{x} alpha(x)*beta(x-1)*obs(x-1)*x =\sum_{x} constant factor *gaussian(x)*Indicator*x = constant factor* cdfdiffernce * trucfirst  
  m.dec=product_dec_k_fac*
    cdfdifference(product_dec_m,product_v,dec_lower,dec_upper)*
    trucfirst(product_dec_m,product_v,dec_lower,dec_upper)
  
  fra.inc=m.inc/m.eq
  fra.dec=m.dec/m.eq
  
  fra.inc[fra.inc>1e150]=1e150
  fra.dec[fra.dec>1e150]=1e150
  
  pinc=sapply(1:length(locations),function(n) sum(  ratein[[n]] * fra.dec[locin[[n]] ] )) 
  pdec= sapply(1:length(locations),function(n)  sum(  rateout[[n]] * fra.inc[locout[[n]]  ] ) )
  
  #for each link, calculate the prob of transition at all other links
  tran=lapply(1:length(locations), function(n)  rateout[[n]] *  fra.dec[n] * fra.inc[locout[[n]]  ] )
  alltran=sum(unlist(tran))
  trother=numeric(length = length(locations))
  trother[]=alltran
  trother=trother-sapply(tran,sum) # transition at other links = all transition - transition from local link - transition to local link
  for(n in 1:length(locations)) trother[locout[[n]]]=trother[locout[[n]]]-tran[[n]]
  pn=1-pnull+trother
  
  inc_lower=lower-1
  inc_upper=upper-1
  eq_lower=lower
  eq_upper=upper
  dec_lower=lower+1
  dec_upper=upper+1
  
  #moment matching versus gamma(x) \propto la1(x)*lb2(x+1)*obs(x+1)*pinc + la1(x)*lb2(x)*obs(x)*(1-pout*x-pn)+ la1(x)*lb2(x-1)*obs(x-1)*pdec*x
  
  inc_m=normproduct_m(la1[1,],la1[2,],lb2[1,]-1,lb2[2,])
  eq_m=normproduct_m(la1[1,],la1[2,],lb2[1,],lb2[2,])
  dec_m=normproduct_m(la1[1,],la1[2,],lb2[1,]+1,lb2[2,])
  tran_v=normproduct_v(la1[2,],lb2[2,])
  
  inc_k_exp=-(2*(la1[1,]-lb2[1,])+1)/(la1[2,]+lb2[2,])/2.0
  dec_k_exp=(2*(la1[1,]-lb2[1,])-1)/(la1[2,]+lb2[2,])/2.0
  
  inc_k_exp_obs=((eq_m[observable]-obs.p2[1,])^2 - (inc_m[observable]-obs.p2[1,]+1)^2)/(tran_v[observable]+obs.p2[2,])/2.0
  dec_k_exp_obs=((eq_m[observable]-obs.p2[1,])^2 - (dec_m[observable]-obs.p2[1,]-1)^2)/(tran_v[observable]+obs.p2[2,])/2.0
  
  inc_k_exp[observable]=inc_k_exp[observable] + inc_k_exp_obs
  dec_k_exp[observable]=dec_k_exp[observable] + dec_k_exp_obs
  
  inc_k_fac=exp(inc_k_exp)
  dec_k_fac=exp(dec_k_exp)
  
  inc_k_fac[inc_k_fac>1e150]=1e150
  dec_k_fac[dec_k_fac>1e150]=1e150
  
  inc_m[observable]=normproduct_m(inc_m[observable],tran_v[observable],obs.p2[1,]-1,obs.p2[2,])
  eq_m[observable]=normproduct_m(eq_m[observable],tran_v[observable],obs.p2[1,],obs.p2[2,])
  dec_m[observable]=normproduct_m(dec_m[observable],tran_v[observable],obs.p2[1,]+1,obs.p2[2,])
  tran_v[observable]=normproduct_v(tran_v[observable],obs.p2[2,])
  
  
  inc_const=inc_k_fac*cdfdifference(inc_m,tran_v,inc_lower,inc_upper)
  eq_const=cdfdifference(eq_m,tran_v,eq_lower,eq_upper)
  eq_const[eq_const==0]=1e-300
  dec_const=dec_k_fac*cdfdifference(dec_m,tran_v,dec_lower,dec_upper)
  
  inc_first=trucfirst(inc_m,tran_v,inc_lower,inc_upper)
  inc_second=trucsecond(inc_m,tran_v,inc_lower,inc_upper)
  eq_first=trucfirst(eq_m,tran_v,eq_lower,eq_upper)
  eq_second=trucsecond(eq_m,tran_v,eq_lower,eq_upper)
  eq_third=tructhird(eq_m,tran_v,eq_lower,eq_upper)
  dec_first=trucfirst(dec_m,tran_v,dec_lower,dec_upper)
  dec_second=trucsecond(dec_m,tran_v,dec_lower,dec_upper)
  dec_third=tructhird(dec_m,tran_v,dec_lower,dec_upper)
  
  # k= \sum_{x} gamma(x)
  inc.k=inc_const*pinc
  eq.k=eq_const*( pn-pout*eq_first )
  dec.k=dec_const*pdec*dec_first
  sum_k=inc.k+eq.k+dec.k
  
  # m= \sum_{x} gamma(x)*x
  inc.m=inc_const*pinc*inc_first
  eq.m=eq_const*( pn*eq_first-pout*eq_second)
  dec.m=dec_const*pdec*dec_second
  sum_m=inc.m+eq.m+dec.m
  lg1_m=sum_m/sum_k
  
  # v= \sum_{x} gamma(x)*(x-mean)^2
  inc.v=inc_const*pinc*(inc_second-2*lg1_m*inc_first+lg1_m^2)
  eq.v= eq_const*( pn*(eq_second-2*lg1_m*eq_first+lg1_m^2) - pout*(eq_third-2*lg1_m*eq_second+lg1_m^2*eq_first) )
  dec.v=dec_const*pdec*(dec_third-2*lg1_m*dec_second+lg1_m^2*dec_first)
  sum_v=inc.v+eq.v+dec.v
  lg1_v=sum_v/sum_k
  
  #   lg1_m[lg1_m<0]=0
  #   lg1_m[lg1_m>upper]=upper[lg1_m>upper]
  lg1_v[lg1_v<=0]=1e8
  
  lg1_tilde=rbind(lg1_m,lg1_v)
  
  lb1_tilde=normdivision_mv(lg1_m,lg1_v,la1[1,],la1[2,])
  lb1_tilde[2,lb1_tilde[2,]<=0]=1e10
  
  list(lb1_tilde=lb1_tilde,lg1_tilde=lg1_tilde)
}



backward2 = function(la,  lb, lg , obs, prate_in_f, rate_out_f, max.person){
  
  lower=0
  upper=max.person
  
  new.t = c()
  length.lb = length(lb) 
  length.lg = length(lg)
  
  for(i in 1199:1 ){
    print(i)
    ratein=rate_in_f(i)
    rateout=rate_out_f(i)
    locin=loc_in_f(i)
    locout=loc_out_f(i)
    
    la1=la[[i]]
    lb2=lb[[i+1]]
    
    m.eq=numeric(length = length(locations))
    product_eq=normproduct_mv(la1[1,],la1[2,],lb2[1,],lb2[2,])
    m.eq[unobservable]=trucfirst(product_eq[1,unobservable],product_eq[2,unobservable],lower,upper[unobservable])
    
    obs.p2=sapply(observable, function(n) obs.prob[,observation[[as.character(n)]][i+1]+1 ] )
    product_eq[,observable]=normproduct_mv(product_eq[1,observable],product_eq[2,observable],obs.p2[1,],obs.p2[2,])
    m.eq[observable]=trucfirst(product_eq[1,observable],product_eq[2,observable],lower,upper[observable])
    
    pout=sapply(rateout, sum)
    pnull= sum(pout*m.eq) - pout*m.eq
    r_nnn=max.person*pout+pnull
    nnn = max(ceiling(r_nnn))
    
    pout=pout/nnn
    pnull=pnull/nnn
    ratein=lapply(1:length(ratein), function(n) ratein[[n]]/nnn)
    rateout=lapply(1:length(rateout), function(n) rateout[[n]]/nnn)
    
    print("--------------------------------nnn---------")
    print(nnn)
    
    if(nnn>1) new.t=c(new.t,i+(nnn-1):1/nnn)
    
    for (k in nnn:1){
      #print(k)
      t1 = i+(k-1)/nnn; t2 = i+k/nnn;
      la1=getSlice(la,t1);
      
      if(k!=nnn) {
        tran=transition_backward_fra(la1,lb2,ratein, locin, rateout, locout, pout, pnull )        
      } else {
        tran=transition_backward_int(la1,lb2,ratein, locin, rateout, locout, pout, pnull,obs.p2 )
      }
      
      lb1=tran$lb1_tilde
      lb2 = lb1
      lg1=tran$lg1_tilde
      
      if(k==1){
        lb[[i]]=lb1
        lg[[i]]=lg1
      } else {
        if(length(attr(lb,'t'))==length.lb){lb = alloc(lb); length.lb = length(lb)}
        if(min(abs(t1-attr(lb,'t')))<1e-12) {
          lb[[which.min(abs(t1-attr(lb,'t')))]] <- lb1
        } else{
          attr(lb,'t') = c(attr(lb,'t'),t1)
          lb[[length(attr(lb,'t'))]]<-lb1
        }
        
        if(length(attr(lg,'t'))==length.lg){lg = alloc(lg); length.lg = length(lg)}
        if(min(abs(t1-attr(lg,'t')))<1e-6) {
          lg[[which.min(abs(t1-attr(lg,'t')))]] = lg1
        } else {
          attr(lg,'t') = c(attr(lg,'t'),t1);
          lg[[length(attr(lg,'t'))]]=lg1
        }
      }
      
    } # k
  } # i
  
  new.t=c(1:1200,rev(new.t) )
  
  lb = unclass(lb)[match(new.t,attr(lb,'t'))]; attr(lb,'t') = new.t;  attr(lb,'c')="b"
  lg = unclass(lg)[match(new.t,attr(lg,'t'))]; attr(lg,'t') = new.t;  attr(lg,'c')="a"
  
  list(lb = lb,lg=lg)
}


#######################################################################################################

for(iter in 1:300){
  
  la_old=la
  lb_old=lb
  
  aaa = forward2(la,  lb, lg, obs, rate_in_f, rate_out_f, max.person)
  
  la=aaa$la
  
  saveRDS(la,paste("the ", iter,  " forward la.RDS", sep = ""))
  
  print(sprintf('The %d forward completed',iter))
  
  
  
  
  la_old=la
  lb_old=lb
  
  bbb = backward2(la,  lb, lg, obs, rate_in_f, rate_out_f, max.person)
  
  lb=bbb$lb
  
  saveRDS(lb,paste("the ", iter,  "backward lb.RDS", sep = ""))
  
  print(sprintf('The %d backward completed',iter))
}