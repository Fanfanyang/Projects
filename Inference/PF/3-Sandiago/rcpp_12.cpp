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
NumericVector ExtractFast(NumericMatrix Person_State, NumericVector length){
  int nrow = Person_State.nrow(), ncol = Person_State.ncol();
  NumericVector result(ncol);
  int i,j,curr,prev,count,tot_time;
  float dist,tot_dist,ave_speed;
  
  for (j=0;j<ncol;j++) {
    result(j) = 0;
    count = 0;
    prev = 0;
    curr = 0;
    tot_dist = 0;
    tot_time = 0;
    for (i=1;i<nrow;i++) {
      if (Person_State(i,j)!=0) {
        if (prev != 0) {
          curr = Person_State(i,j);
          if (curr != prev) {
            dist = length(prev-1);
            //speed = dist/(i-count);
            /*if (speed>th) {
              result(j) = 1;
              break;
            }*/
            tot_dist += dist;
            tot_time += (i-count);
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
    ave_speed = (float)tot_dist/tot_time;
    result(j) = ave_speed;
    
    if (j % 100 == 0)
      Rcout << j/100 << " " << ave_speed << " " << tot_dist << " " << tot_time << endl;
  }

  return result;
}


// [[Rcpp::export]]
NumericVector SpeedDist(NumericMatrix Person_State, NumericVector length){
  int nrow = Person_State.nrow(), ncol = Person_State.ncol();
  NumericMatrix result(nrow,ncol);
  int i,j,curr,prev,count;
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
            dist = length(prev-1);
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



















