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
int CPInx(NumericVector e_from, NumericVector e_to) {
    int inx = 0;
    int length = e_from.size();
    int i,j;
    
    for (i=0;i<length;i++) {
        if (i % 100 == 0) 
          Rcout << i/100 << " " << inx << endl;
        for (j=0;j<length;j++) {
            if (e_to[i] == e_from[j])
              inx++;
        }
    }
    return inx;
}

// [[Rcpp::export]]
NumericMatrix CPS1(NumericVector e_from, NumericVector e_to, int events) {
  int length = e_from.size();
  int i,j;
  int idx=0;
  NumericMatrix result(length,events);
  
  for (i=0;i<length;i++) {
    if (i % 100 == 0) 
      Rcout << i/100 << " " << idx << endl;
    for (j=0;j<length;j++) {
      if (e_to[i] == e_from[j]) {
        result(i,idx) = -1;
        result(j,idx) = 1;
        idx++; 
      }
    }
  }
  return result;
}

// [[Rcpp::export]]
NumericMatrix CPS2(NumericMatrix m_total, int events) {
  int length = m_total.cols();
  int i,j;
  int idx=0;
  NumericMatrix result(length,events);
  
  for (i=0;i<length;i++) {
    if (i % 100 == 0) 
      Rcout << i/100 << " " << idx << endl;
    for (j=0;j<length;j++) {
      if ((i!=j)&&(m_total(i,j)>0)) {
        result(i,idx) = -1;
        result(j,idx) = 1;
        idx++; 
      }
    }
  }
  Rcout << idx << endl;
  return result;
}

















