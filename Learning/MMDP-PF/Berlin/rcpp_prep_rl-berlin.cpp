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
NumericMatrix PossibleAction(NumericVector sinto, NumericVector sinfrom, int facility_length) {
  int size1 = sinto.size();
  int size2 = sinfrom.size();
  int i,j;
  int inx = 0;
  NumericMatrix result(156430,2);
  for(i=0;i<size1;i++) {
    if (i < facility_length) {
      result(inx,0) = i+1;
      result(inx,1) = i+1;
      inx++;
      for(j=facility_length;j<size2;j++) {
        if (sinto(i)==sinfrom(j)) {
          result(inx,0) = i+1;
          result(inx,1) = j+1;
          inx++;
        }
      }
    } else {
      for(j=0;j<size2;j++) {
        if (sinto(i)==sinfrom(j)) {
          result(inx,0) = i+1;
          result(inx,1) = j+1;
          inx++;
        }
      }
    }
  }
  Rcout << "total actions: " << inx << endl;
  return result;
}

// [[Rcpp::export]]
List PolicyList(NumericVector person_state_d, NumericVector person_state_d_1, List policy_template, List action_list, float SmallProb) {
  
  int size = person_state_d.size(), listsize = policy_template.size();
  NumericVector tmp1,tmp2;
  int i,j;
  List result(listsize);
  //result = policy_template;
  for(i=0;i<listsize;i++) {
    tmp1 = policy_template[i];
    NumericVector tmp3(tmp1.size());
    for(j=0;j<tmp3.size();j++) {
      tmp3(j) = SmallProb; 
    }
    result[i] = tmp3;
  }
  //Rcout << "begin" << endl;
  for(i=0;i<size;i++) {
    tmp1 = action_list[person_state_d(i)-1];
    tmp2 = result[person_state_d(i)-1];
    //Rcout << "i: " << i << " " << person_state_d_1(i) << " tmp1: " << tmp1 << endl;
    for (j=0;j<tmp1.size();j++) {
      //Rcout << "j " << j << " tmp2 " << tmp2 << endl;
      if (tmp1(j)==person_state_d_1(i)) {
        tmp2(j)++;
        result[person_state_d(i)-1] = tmp2;
        //Rcout << "this run end" << endl;
        break;
      }
    }
  }
  
  return result;
}






















