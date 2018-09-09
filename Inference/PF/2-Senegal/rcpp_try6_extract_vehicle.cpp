/*************************************************************************
 > File Name: rcpp_try1.cpp
 > Author: 
 > Mail: 
 > Created Time: Thu Jun 16 20:44:35 2016
 ************************************************************************/

#include<iostream>
#include <Rcpp.h>
// [[Rcpp::depends(RcppEigen)]]

#include <RcppEigen.h>

using namespace std;
using namespace Rcpp;

// [[Rcpp::export]]
NumericMatrix ExtractFast(NumericMatrix Person_State,NumericVector dist_array,NumericVector tower_dakar_rev,List dist, List lane,int numbers, float th){
  int nrow = Person_State.nrow(), ncol = Person_State.ncol();
  NumericMatrix result(nrow,ncol);
  int i,j,k,l,curr,prev,ndx_curr,ndx_prev,count,ndx;
  float dist_tmp,speed,time,accum,tmp_t,off;
  
  for (j=0;j<ncol;j++) {
    count = 0;
    prev = 0;
    curr = 0;
      //Rcout << j << endl;
    for (i=0;i<nrow;i++) {
        //Rcout << i << endl;
      if (Person_State(i,j)!=0) {
        if (prev != 0) {
          curr = Person_State(i,j);
          if (curr != prev) {
            ndx_curr = tower_dakar_rev(curr-1);
            ndx_prev = tower_dakar_rev(prev-1);
            ndx = (ndx_prev-1)*numbers+ndx_curr-1;
              //Rcout << ndx << " " << ndx_curr << " " << ndx_prev << endl;
            dist_tmp = dist_array(ndx);
            speed = (float)dist_tmp/(i-count);
            //Rcout << speed << " " << th << " " << dist_tmp << " " << i << " " << count << " " << j <<endl;
            if (speed > th) {
                NumericVector d = dist[ndx];
                NumericVector e = lane[ndx];
                NumericVector t(d.length());
                time = 0;
                for (k=0;k<d.length();k++) {
                    t(k) = d(k)/speed;
                    time += t(k);
                }
                if (time>1) {
                    ndx = trunc(time);
                    accum = 0;
                    for (k=0;k<t.size();k++) {
                        accum += t(k);
                        t(k) = accum;
                    }
                    NumericVector loc(ndx);
                    off = time-ndx;
                    tmp_t = 0;
                    for (k=0;k<ndx;k++) {
                        tmp_t = k+off;
                        for (l=0;l<t.size();l++) {
                            if (tmp_t < t(l)) break;
                        }
                        loc(k) = e(l);
                    }
                    for(k=0;k<ndx;k++) {
                        result(i-ndx+k,j) = loc(k);
                    }
                    result(i-round(time),j) = prev;
                    result(i,j) = curr;
                }
                else {
                  result(i-1,j) = prev;
                  result(i,j) = curr;
                }
            }
            prev = curr;
            count = i;
          }
        }
        else {
          prev = Person_State(i,j);
          count = i;
        }
      }
      else {
        prev = 0;
        curr = 0;
        count = 0;
      }
    }
    if (j % 1000 == 0)
      Rcout << j/1000 << endl;
  }
  return result;
}

// [[Rcpp::export]]
NumericVector TripDist(NumericMatrix Person_State,NumericVector dist_array,NumericVector tower_dakar_rev,List dist, List lane,int numbers, int th){
  int nrow = Person_State.nrow(), ncol = Person_State.ncol();
  NumericMatrix result(nrow,ncol);
  int i,j,k,curr,prev,ndx_curr,ndx_prev,count,ndx;
  float dist_tmp,speed,time;
  
  for (j=0;j<ncol;j++) {
    count = 0;
    prev = 0;
    curr = 0;
    for (i=1;i<nrow;i++) {
      if (Person_State(i,j)!=0) {
        if (prev != 0) {
          curr = Person_State(i,j);
          if (curr != prev) {
            ndx_curr = tower_dakar_rev(curr-1);
            ndx_prev = tower_dakar_rev(prev-1);
            ndx = (ndx_prev-1)*numbers+ndx_curr-1;
            dist_tmp = dist_array(ndx);
            speed = (float)dist_tmp/(i-count);
            if (speed > th) {
              NumericVector d = dist[ndx];
              NumericVector e = lane[ndx];
              NumericVector t(d.length());
              time = 0;
              for (k=0;k<d.length();k++) {
                t(k) = d(k)/speed;
                time += t(k);
              }
              if (time>1) {
                result(i,j) = dist_tmp;
              }
              else {
                //Rcout << dist_tmp << endl;
                result(i,j) = dist_tmp;
              }
            }
            prev = curr;
            count = i;
          }
        }
        else {
          prev = Person_State(i,j);
          count = i;
        }
      }
      else {
        prev = 0;
        curr = 0;
        count = 0;
      }
    }
    if (j % 100 == 0)
      Rcout << j/100 << endl;
  }
  return result;
}
 
 // [[Rcpp::export]]
 NumericVector SpeedDist(NumericMatrix Person_State,NumericVector dist_array,NumericVector tower_dakar_rev,int numbers){
   int nrow = Person_State.nrow(), ncol = Person_State.ncol();
   NumericMatrix result(nrow,ncol);
   int i,j,curr,prev,ndx_curr,ndx_prev,count,ndx;
   float dist,speed;
   
   for (j=0;j<ncol;j++) {
     count = 0;
     prev = 0;
     curr = 0;
     for (i=1;i<nrow;i++) {
       if (Person_State(i,j)!=0) {
         if (prev != 0) {
           curr = Person_State(i,j);
           if (curr != prev) {
             ndx_curr = tower_dakar_rev(curr-1);
             ndx_prev = tower_dakar_rev(prev-1);
             ndx = (ndx_prev-1)*numbers+ndx_curr-1;
             
             dist = dist_array(ndx);
             speed = (float)dist/(i-count);
             result(i,j) = speed;
             prev = curr;
             count = i;
           }
         }
         else {
           prev = Person_State(i,j);
           count = i;
         }
       }
       else {
         prev = 0;
         curr = 0;
         count = 0;
       }
     }
     if (j % 100 == 0)
       Rcout << j/100 << endl;
   }
   return result;
 }
 

 // [[Rcpp::export]]
 NumericMatrix PersonNdx(NumericMatrix person_state, NumericVector tower_dakar) {
   
   int nrow = person_state.nrow();
   int ncol = person_state.ncol();
   NumericMatrix result(nrow,ncol);
   int i,j,k,curr,prev,ndx1,ndx2;
   
   for(j=0;j<ncol;j++) {
     if (j % 1000 == 0)
       Rcout << j/1000 << endl;
     for (i=1;i<nrow;i++) {
       prev = person_state(i-1,j);
       curr = person_state(i,j);
       if (curr!=prev) {
         ndx1=0;
         ndx2=0;
         for (k=0;k<tower_dakar.size();k++) {
           if (tower_dakar(k)==curr)
             ndx1 = 1;
           if (tower_dakar(k)==prev)
             ndx2 = 1;
         }
         if (ndx1 && ndx2)
           result(i,j)=1;
       }
     }
   }
   return result;
 }
 
 // [[Rcpp::export]]
 NumericMatrix ReName(NumericMatrix person_state, NumericVector lane_ndx, int th) {
   int nrow = person_state.nrow();
   int ncol = person_state.ncol();
   int nlength = lane_ndx.size();
   int i,j,k,target;
   
   for (i=0;i<nrow;i++) {
     Rcout << i << endl;
     for (j=0;j<ncol;j++) {
       if (person_state(i,j)>th) {
         target = person_state(i,j);
         for (k=0;k<nlength;k++) {
           if (target == lane_ndx(k)) {
             person_state(i,j) = k+th+1;
             break;
           }
         }
       }
     }
   }
   return person_state;
 }
 
 // [[Rcpp::export]]
 NumericMatrix Xt_relative_vehicle(NumericMatrix person_extract, int numbers) {
   int nrow = person_extract.nrow();
   int ncol = person_extract.ncol();
   int i,j,curr,prev;
   NumericMatrix result(nrow,numbers);
   
   for (j=0;j<ncol;j++) {
     if (j % 100 == 0)
       Rcout << j/100 << endl;
     for (i=1;i<nrow;i++) {
       prev = person_extract(i-1,j);
       curr = person_extract(i,j);
       if ((curr!=0)&&(prev!=0)) {
         result(i,prev-1) -= 1;
         result(i,curr-1) += 1;
       }
     }
   }
   return result;
 }















