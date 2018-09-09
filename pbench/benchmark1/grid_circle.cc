//--------------------------------------------------------------
// Grid Circle
//--------------------------------------------------------------

#include <math.h>
#include <iostream>
#include <fstream>
#include <string>
#include <iomanip>
#include "ofs.hh"
#include "pathp.hh"

using namespace std;

int main(){
    int i,j;
    int matrix[21][21];
    int distance;
    for (i=0;i<21;i++)
        for (j=0;j<21;j++)
        {
            distance = pow(i-10,2)+pow(j-10,2);
            if (distance <= 100)
                matrix[i][j] = 1;
            else
                matrix[i][j] = 0;
        }
    for (i=0;i<21;i++){
        cout << "{";
        for (j=0;j<21;j++){
            cout << matrix[i][j] << ",";
        }
        cout << "};" << endl;
    }
}


















