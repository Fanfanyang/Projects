#include <stdlib.h>
#include <math.h>
#include <iostream>
#include <fstream>
#include <string>
#include <iomanip>
#include <time.h>
#include <sys/time.h>
#include <fstream>
#include <string>
#include <vector>
#include <sstream>
#include <cstring>
#include "ofs.hh"

#include "stdlib.h"
#include "stdio.h"
#include "string.h"

using namespace std;

//--------------------------------------------------------------
// Memory footprint
//--------------------------------------------------------------

    int parseLine(char* line){ 
        int i = strlen(line);
        while (*line < '0' || *line > '9') line++;
        line[i-3] = '\0';
        i = atoi(line);
        return i;
    }
    

    int getValue(){ //Note: this value is in KB!
#if Gem5SYS
        FILE* file = fopen("/proc/self/status", "r");
        int result = -1;
        char line[128];
    

        while (fgets(line, 128, file) != NULL){
            if (strncmp(line, "VmSize:", 7) == 0){
                result = parseLine(line);
                break;
            }
        }
        fclose(file);
        return result;
#else
        return 0;
#endif
    }


//--------------------------------------------------------------
// Reading STL
//--------------------------------------------------------------

bool _isnan(double var)
{
    volatile double d = var;
    return d != d;
}

// return number of triangles
int Read_STL_File(const char *stl_File_Name, vector<Data>& data_in, int scale, float& zmin, float& zmax)
{
    int counter=0;
    Data *data_tmp;
    data_tmp = new Data[3];
    FILE *fptr = NULL;
    //fptr = fopen(stl_File_Name, "rb");
    fptr = fopen(stl_File_Name, "rb");
    if(fptr == NULL)
        return -1;
    //if (ftell(fp) == 0)   Read_stl_Binary(fp);
    //else Read_stl_Text(fp);
    
    // read the header
    char Header[80];
    fread(Header, 1, 80, fptr);
    // read Triangle number
    int TriNum = 0;
    fread((char *)&TriNum, sizeof(int), 1, fptr);
    if(TriNum <= 0) return 0;
    //triangle_array.clear();
    //triangle_array.reserve(TriNum);
    int j;
    // read each triangle
    //cout << "three " << TriNum << endl;
    for(int i=0;i<TriNum;i++)
    {
        //CVertex normal, v1, v2, v3;
        float normal[3], v1[3], v2[3], v3[3];
        float temf[3];
        // read normal
        fread((char *)temf, sizeof(float), 3, fptr);
        normal[0] = temf[0];    normal[1] = temf[1];    normal[2] = temf[2];
#ifdef _DEBUG
        assert(_isnan(normal[0])==0 && _isnan(normal[1])==0 && _isnan(normal[2])==0);
#endif
        // read vertices
        fread((char *)temf, sizeof(float), 3, fptr);
        v1[0] = temf[0];        v1[1] = temf[1];        v1[2] = temf[2];
#ifdef _DEBUG
        assert(_isnan(v1[0])==0 && _isnan(v1[1])==0 && _isnan(v1[2])==0);
#endif
        fread((char *)temf, sizeof(float), 3, fptr);
        v2[0] = temf[0];        v2[1] = temf[1];        v2[2] = temf[2];
#ifdef _DEBUG
        assert(_isnan(v2[0])==0 && _isnan(v2[1])==0 && _isnan(v2[2])==0);
#endif
        fread((char *)temf, sizeof(float), 3, fptr);
        v3[0] = temf[0];        v3[1] = temf[1];        v3[2] = temf[2];
#ifdef _DEBUG
        assert(_isnan(v3[0])==0 && _isnan(v3[1])==0 && _isnan(v3[2])==0);
#endif
        // read attribute
        short attrib = 0;
        fread((char *)&attrib, sizeof(short), 1, fptr);
        
        if (v1[2] < zmin)
            zmin = v1[2];
        if (v1[2] > zmax)
            zmax = v1[2];
        if (v2[2] < zmin)
            zmin = v2[2];
        if (v2[2] > zmax)
            zmax = v2[2];
        if (v3[2] < zmin)
            zmin = v3[2];
        if (v3[2] > zmax)
            zmax = v3[2];
        
        for (j=0;j<3;j++)
            data_tmp[0].value[j] = v1[j]*scale;
        for (j=0;j<3;j++)
            data_tmp[1].value[j] = v2[j]*scale;
        for (j=0;j<3;j++)
            data_tmp[2].value[j] = v3[j]*scale;
        for (j=0;j<3;j++)
        {
            data_in.push_back(data_tmp[j]);
        }
        
        if ((v1[2] > THICKNESS/10)||(v2[2] > THICKNESS/10)||(v3[2] > THICKNESS/10))
            counter++;
        //cout << i << " " << v1[2] << endl;
        //if ( i == 132900)
        //if (i == 15073)
        //break;
        //cout << i << " ";
    }
    delete[] data_tmp;
    //cout << counter*3 << endl;
    fclose(fptr);
    return TriNum;
}

//--------------------------------------------------------------
// Timer
//--------------------------------------------------------------

#include <time.h>
#include <sys/time.h>

double get_wall_time(){
    struct timeval time;
    if (gettimeofday(&time,NULL)){
        //  Handle error
        return 0;
    }
    return (double)time.tv_sec + (double)time.tv_usec * .000001;
}

double get_cpu_time(){
#if Gem5SYS
    return (double)clock() / CLOCKS_PER_SEC;
#else
    return 1;
#endif
}

