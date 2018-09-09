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
List CPLane(List shortest_path_cb, NumericMatrix edge_matrix, List shortest_path){

  int nrow1 = shortest_path_cb.size();
  int nrow2 = edge_matrix.nrow();
  List result(nrow1);
  int i,j,k,ndx;
  
  for (i=0;i<nrow1;i++) {
    if (i % 100 == 0)
      Rcout << i/100 << endl;
    NumericVector idx = shortest_path[i];
    //Rcout << idx.size() << endl;
    if (idx.size()>1) {
      NumericMatrix c = shortest_path_cb[i];
      ndx = c.nrow();
      NumericVector a(ndx);
      for (j=0;j<ndx;j++) {
        for (k=0;k<nrow2;k++) {
          if (((edge_matrix(k,1)==c(j,0)) && (edge_matrix(k,0)==c(j,1))) || ((edge_matrix(k,0)==c(j,0)) && (edge_matrix(k,1)==c(j,1)))) {
            a(j) = k+1;
            break;
          }
        }
      }
      result[i] = a;
    }
    else
      result[i] = 0;
  }

  return result;
}
 

 // [[Rcpp::export]]
 NumericMatrix AddTransit6(NumericMatrix person_state, NumericMatrix person_ndx, NumericMatrix same_node, NumericVector tower_dakar_rev, List shortest_path_cb, int numbers, List dist, List lane, float speed) {
   
   int nrow = person_state.nrow();
   int ncol = person_state.ncol();
   int i,j,curr,prev;
   int ndx,k,l,flag;
   float time,accum,tmp_t,off;
   //NumericVector d;
   //NumericMatrix c;
   
   for(j=0;j<ncol;j++) {
     if (j % 1000 == 0)
       Rcout << j/1000 << endl;
     for(i=1;i<nrow;i++){
       // tower location
       curr = person_state(i,j);
       prev = person_state(i-1,j);
       flag=0;
       for(k=0;k<same_node.nrow();k++) {
         if ((prev == same_node(k,0)) && (curr == same_node(k,1)) )
           flag = 1;
       }
       //Rcout << i << " " << j << endl;
       //if ((curr != prev) && (!flag)) {
       if ((curr != prev) && (person_ndx(i,j)==1) && (!flag)) {
         // location -> number 1-289
         curr = tower_dakar_rev(curr-1);
         prev = tower_dakar_rev(prev-1);
         ndx = (prev-1)*numbers+curr-1;
         
         //Rcout << i << " " << j << " " << ndx << endl;
         NumericMatrix c = shortest_path_cb[ndx];
         NumericVector d = dist[ndx];
         NumericVector e = lane[ndx];
         NumericVector t(c.rows());
         time = 0;
         
         for (k=0;k<c.rows();k++) {
           //Rcout << d(k) << " " << e(k) << endl;
           t(k) = d(k)/speed;
           time += t(k);
         }
         //Rcout << t << endl;
         //Rcout << time << endl;
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
             //Rcout << " loc " << l << " " << e(l) << endl;
           }
           
           for(k=0;k<ndx;k++) {
             person_state(i-ndx+k,j) = loc(k);
             if (person_state(i-ndx+k,j)  == 1495)
               Rcout << i << ' ' << j <<  ' ' << ((prev-1)*numbers+curr-1) << ' ' << e(l) << endl;
           }
         }
       }
     }
   }
   return person_state;
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
  




















