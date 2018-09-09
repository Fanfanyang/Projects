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
NumericMatrix TransitionMTime(NumericMatrix person_state, int size, int sep) {
  int nrow = person_state.nrow();
  int ncol = person_state.ncol();
  NumericMatrix result(size,size);
  int i,j;
  
  for (i=1;i<nrow;i++) {
    if (i % sep == 0) continue;
    for (j=0;j<ncol;j++) {
      result(person_state(i-1,j)-1,person_state(i,j)-1) += 1;
    }
  }
  return result;
}

// [[Rcpp::export]]
NumericMatrix TransitionM(NumericMatrix person_state, int size) {
  
  int nrow = person_state.nrow();
  int ncol = person_state.ncol();
  NumericMatrix result(size,size);
  int i,j;
  
  for (i=1;i<nrow;i++) {
    Rcout << i << endl;
    for (j=0;j<ncol;j++) {
      result(person_state(i-1,j)-1,person_state(i,j)-1) += 1;
    }
  }

  return result;
}

// [[Rcpp::export]]
NumericMatrix PersonState(NumericVector time, NumericVector tower, NumericVector person, int nrow, int ncol, int min_time) {
  
  int it = time.length();
  NumericMatrix result(nrow,ncol);
  int i,j,tmp_ndx,tmp_tower,tmp_person,last;
  last = 0;
  
  for(i=0;i<it;i++) {
    tmp_ndx = time(i) - min_time;
    if (tmp_ndx > last) {
      //Rcout << tmp_ndx << endl;
      for (j=last+1;j<=tmp_ndx;j++) {
        result(j,_) = result(last,_);
      }
    }
    tmp_tower = tower(i);
    tmp_person = person(i);
    result(tmp_ndx,tmp_person-1) = tmp_tower;
    last = tmp_ndx;
  }
  return result;
}
/*
// [[Rcpp::export]]
NumericMatrix Transition(NumericVector tower, NumericVector person, int nrow) {
  
  int it = tower.length();
  NumericMatrix result(nrow,nrow);
  int i,last;
  last = 1;
  
  for(i=1;i<it;i++) {
    if (person(i) != last) {
      last = person(i);
      continue;
    }
    result(tower(i-1)-1,tower(i)-1) += 1; 
  }
  return result;
}
*/
// [[Rcpp::export]]
NumericMatrix InitLoc(NumericMatrix person_state) {
  
  int nrow = person_state.nrow();
  int ncol = person_state.ncol();
  int i,j,val,ndx;
  
  for(j=0;j<ncol;j++) {
    ndx=0;
    val=0;
    for(i=0;i<nrow;i++)
      if (person_state(i,j)>0) {
        val = person_state(i,j);
        ndx = i;
        break;
      }
    for(i=0;i<ndx;i++)
      person_state(i,j) = val;
  }
  
  return person_state;
}










// [[Rcpp::export]]
NumericMatrix trytry(NumericMatrix a) {
  NumericMatrix result(3,4);
  result(1,_) = a(1,_);
  print(a);
  Rcout << a << endl;
  return result;
}


// [[Rcpp::export]]
NumericMatrix StateXt(NumericVector time, NumericVector tower, int nrow, int ncol, int min_time) {
    
  int it = time.length();
  NumericMatrix Xt_real(nrow,ncol);
  int i,tmp_ndx,tmp_tower;
  
  for(i=0;i<it;i++) {
    tmp_ndx = time(i) - min_time;
    tmp_tower = tower(i);
    Xt_real(tmp_ndx,tmp_tower-1) = Xt_real(tmp_ndx,tmp_tower-1) + 1;
  }

  return Xt_real;
}

















