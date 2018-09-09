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
List ListAdd(List list1, List list2, float alpha) {
  //list1+list2*alpha
  NumericVector tmp1,tmp2;
  int size = list1.size();
  int i,j;
  for(i = 0; i < size; i++) {
    tmp1 = list1[i];
    tmp2 = list2[i];
    //Rcout << i << ' ' << tmp1.size() << endl;
    for(j=0;j<tmp1.size();j++)
      tmp1(j) = tmp1(j) + tmp2(j) * alpha;
    list1[i] = tmp1;
    //Rcout << i << ' ' << tmp1(0) << endl;
  }
  return list1;
}

// [[Rcpp::export]]
NumericMatrix SamplingAction(NumericMatrix Xi_1, NumericMatrix xyz, List transition, List action_list) {
  int nrow = Xi_1.nrow(), ncol = Xi_1.ncol(), mcol = transition.size();
  NumericMatrix result(nrow,ncol);
  NumericVector tmp, var;
  int i,j,k;
  for(i = 0; i < nrow; i++) {
    for(j=0; j<ncol; j++) {
      for (k=0; k<mcol; k++) {
        tmp = transition[Xi_1(i,j)-1];
        var = action_list[Xi_1(i,j)-1];
        if (tmp(k) >= xyz(i,j)) break;
      }
      //if(k==25)
      //  Rcout << i << " " << j << " " << k << " " << transition(Xi_1(i,j)-1,k-1) << " " << xyz(i,j) << endl;
      result(i,j) = var(k);
    }
  }
  return result;
}

// [[Rcpp::export]]
NumericMatrix SamplingState(NumericMatrix Xi_1, NumericMatrix Xi_2, NumericMatrix xyz, NumericMatrix transition) {
  int nrow = Xi_1.nrow(), ncol = Xi_1.ncol();
  NumericMatrix result(nrow,ncol);
  int i,j;
  for(i = 0; i < nrow; i++) {
    for(j=0; j<ncol; j++) {
      if (transition(i,Xi_1(i,j)-1) >= xyz(i,j))
        result(i,j) = Xi_2(i,j);
      else
        result(i,j) = Xi_1(i,j);
    }
  }
  return result;
}

// [[Rcpp::export]]
NumericVector CWeight(NumericMatrix Xi_obs, NumericVector Yt_1, NumericMatrix obs_matrix) {
  int nrow = Xi_obs.nrow(), ncol = Xi_obs.ncol();
  NumericVector result(nrow);
  int i,j;
  for (i=0;i<nrow;i++) {
    result(i) = 0;
    for (j=0;j<ncol;j++) {
      result(i) += obs_matrix(Xi_obs(i,j),Yt_1(j));
    }
  }

  return result;
}

// [[Rcpp::export]]
NumericMatrix CountAction1(NumericMatrix x_sample, NumericMatrix u_sample, NumericVector w, int size, NumericVector T, int k) {
  int nrow = x_sample.nrow(), ncol = x_sample.ncol();
  NumericMatrix result(size,size);
  int i,j;
  for (i=0;i<nrow;i++) {
    if (k <= T(i)) {
      for (j=0;j<ncol;j++) {
        result(x_sample(i,j)-1,u_sample(i,j)-1) += w(i)*(1/(T(i)+1));
      } 
    }
  }
  return result;
}

// [[Rcpp::export]]
NumericMatrix CountAction3(NumericMatrix x_sample, NumericMatrix u_sample, NumericMatrix w, int size) {
  int nrow = x_sample.nrow(), ncol = x_sample.ncol();
  NumericMatrix result(size,size);
  int i,j;
  for (i=0;i<nrow;i++) {
    for (j=0;j<ncol;j++) {
      result(x_sample(i,j)-1,u_sample(i,j)-1) += w(i,j);
    }
  }
  return result;
}

/*
 * // [[Rcpp::export]]
 NumericMatrix StateProb(NumericMatrix Xi_1, NumericMatrix Xi_2, NumericMatrix Xi_3, NumericMatrix transition) {
int nrow = Xi_1.nrow(), ncol = Xi_1.ncol();
NumericMatrix result(nrow,ncol);
int i,j;
for(i = 0; i < nrow; i++) {
for(j=0; j<ncol; j++) {
if (Xi_1(i,j)==Xi_2(i,j))
result(i,j) = 1;
else if (Xi_3(i,j)==Xi_1(i,j))
result(i,j) = 1-transition(i,Xi_1(i,j)-1);
else
result(i,j) = transition(i,Xi_1(i,j)-1);
}
}
return result;
}
 */

/*
 * // [[Rcpp::export]]
 NumericMatrix Sampling(NumericMatrix Xi_1, NumericMatrix xyz, NumericMatrix m_time_m, NumericMatrix m_time_ndx) {
int nrow = Xi_1.nrow(), ncol = Xi_1.ncol(), mcol = m_time_m.ncol();
NumericMatrix result(nrow,ncol);
int i,j,k;
for(i = 0; i < nrow; i++) {
for(j=0; j<ncol; j++) {
for (k=0; k<mcol; k++) {
if (m_time_m(Xi_1(i,j)-1,k) >= xyz(i,j)) break;
}
result(i,j) = m_time_ndx(Xi_1(i,j)-1,k);
}
}
return result;
}
 */


















