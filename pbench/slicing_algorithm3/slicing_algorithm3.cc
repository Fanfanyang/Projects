//--------------------------------------------------------------
// Slicing Functions
//--------------------------------------------------------------

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
//#include "CImg.h"
#include "slicing_algorithm3.hh"

#include "stdlib.h"
#include "stdio.h"
#include "string.h"

using namespace std;
//using namespace cimg_library;

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
int Read_STL_File(const char *stl_File_Name, vector<Triangle>& data_in, int scale, float& zmin, float& zmax)
{
    int counter=0;
    Triangle data_tmp;
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
            data_tmp.value[0][j] = v1[j]*scale;
        for (j=0;j<3;j++)
            data_tmp.value[1][j] = v2[j]*scale;
        for (j=0;j<3;j++)
            data_tmp.value[2][j] = v3[j]*scale;
        for (j=0;j<3;j++)
            data_tmp.value[3][j] = normal[j];
        
        data_in.push_back(data_tmp);
    }
    
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
//--------------------------------------------------------------
// Triangle Point Position
//--------------------------------------------------------------

void triangle_boundary(Triangle& t0, float boundary[4])
{
    int i;
    boundary[0] = t0.value[0][0];
    boundary[1] = t0.value[0][0];
    boundary[2] = t0.value[0][1];
    boundary[3] = t0.value[0][1];
    for (i=0;i<3;i++)
    {
        if (t0.value[i][0] < boundary[0])
            boundary[0] = t0.value[i][0];
        if (t0.value[i][0] > boundary[1])
            boundary[1] = t0.value[i][0];
        if (t0.value[i][1] < boundary[2])
            boundary[2] = t0.value[i][0];
        if (t0.value[i][1] > boundary[3])
            boundary[3] = t0.value[i][0];
    }
}

int triangle_point(Point& p0, Triangle& t0)
{
    float a,b,c;
    
    a = (t0.value[1][0]-t0.value[0][0])*(p0.value[1]-t0.value[0][1]) - (p0.value[0]-t0.value[0][0])*(t0.value[1][1]-t0.value[0][1]);
    b = (t0.value[2][0]-t0.value[1][0])*(p0.value[1]-t0.value[1][1]) - (p0.value[0]-t0.value[1][0])*(t0.value[2][1]-t0.value[1][1]);
    c = (t0.value[0][0]-t0.value[2][0])*(p0.value[1]-t0.value[2][1]) - (p0.value[0]-t0.value[2][0])*(t0.value[0][1]-t0.value[2][1]);

    if (((a > 0)&&(b > 0)&&(c > 0))||((a < 0)&&(b < 0)&&(c < 0)))
        return 1;
    return 0;
}

void triangle_compute(Point& p0, Triangle& t0)
{
    float a,b,c,d;
    a = t0.value[3][0];
    b = t0.value[3][1];
    c = t0.value[3][2];
    d = -(a*t0.value[0][0] + b*t0.value[0][1] + c*t0.value[0][2]);
    p0.value[2] = -(d + a*p0.value[0] + b*p0.value[1])/c;
    if (c > 0)
        p0.value[3] = 1;
    else
        p0.value[3] = -1;
}

//--------------------------------------------------------------
// Sorting
//--------------------------------------------------------------

void quicksort(vector<Point>& data_point,int& left,int& right)
{
    int itl,itr;
    float pivot;
    Point tmp;
    itl = left;
    itr = right;
    pivot = data_point[(left+right)/2].value[2];
    
    while (itl <= itr)
    {
        while (data_point[itl].value[2] < pivot)
            itl++;
        while (data_point[itr].value[2] > pivot)
            itr--;
        if (itl <= itr)
        {
            tmp = data_point[itl];
            data_point[itl] = data_point[itr];
            data_point[itr] = tmp;
            itl++;
            itr--;
        }
    }
    
    if (left < itr)
        quicksort(data_point, left, itr);
    if (itl < right)
        quicksort(data_point, itl, right);
}

//--------------------------------------------------------------
// main
//--------------------------------------------------------------

int main(int argc, char* argv[])
{
    if (argc < 2){
        cout << "Please Specify one input STL file" << endl;
        return -1;
    }
    
    //struct Point xyz[1000][10000];
    
    int scale = SCALE;
    ofstream runningtime("result/RunningTime.txt", ofstream::out|ofstream::binary);
    ofstream layerresult("result/LayerResult.txt", ofstream::out|ofstream::binary);
    vector<Triangle> data_cloud;
    float zmin, zmax;
    float boundary[4];      // xmin,xmax,ymin,ymax
    int image_bound[4];
    int i,j,k,l;
    
    double cpu_yang[CPU_ITEMS+1];
    double cpu_tmp[2];
    int pmubarrier[3];
    pmubarrier[0] = -1;
    pmubarrier[1] = -1;
    pmubarrier[2] = -1;
    string cpu_index[CPU_ITEMS+1] = {"FileIO","Traverse","Intersection","Sorting","Total"};
    for (i=0;i<CPU_ITEMS+1;i++)
        cpu_yang[i] = CPU_INIT;
    
    //--------------------------------------------------------------
    // input data
    //--------------------------------------------------------------
    cout << "STL file: " << argv[1] << endl;
    
#if Gem5
    pmubarrier[0] = FileIO;
    asm __volatile__ (".byte 0x72; .byte 0x25; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r"(pmubarrier[2]) : "r" (pmubarrier[0]), "r" (pmubarrier[0]));
#endif
    
    cpu_tmp[0] = get_cpu_time();
    Read_STL_File(argv[1],data_cloud,scale,zmin,zmax);
    cpu_tmp[1] = get_cpu_time();
    cpu_yang[FileIO] += cpu_tmp[1] - cpu_tmp[0];

#if Gem5
    pmubarrier[0] = BlockEnd;
    asm __volatile__ (".byte 0x72; .byte 0x25; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r"(pmubarrier[2]) : "r" (pmubarrier[0]), "r" (pmubarrier[0]));
#endif
    //--------------------------------------------------------------
    // STL to point cloud
    //--------------------------------------------------------------
    vector<Point> data_point;
    Point tmp_point;
    
    for (i=0;i<data_cloud.size();i++)
    {
#if Gem5
        pmubarrier[0] = Traverse;
        asm __volatile__ (".byte 0x72; .byte 0x25; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r"(pmubarrier[2]) : "r" (pmubarrier[0]), "r" (pmubarrier[0]));
#endif
        
        cpu_tmp[0] = get_cpu_time();
        triangle_boundary(data_cloud[i],boundary);
        for (j=0;j<4;j++)
            image_bound[j] = boundary[j]/IMAGESTEP + 0.5;
        image_bound[1] += 1;
        image_bound[3] += 1;
        cpu_tmp[1] = get_cpu_time();
        cpu_yang[Traverse] += cpu_tmp[1] - cpu_tmp[0];
        
#if Gem5
        pmubarrier[0] = BlockEnd;
        asm __volatile__ (".byte 0x72; .byte 0x25; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r"(pmubarrier[2]) : "r" (pmubarrier[0]), "r" (pmubarrier[0]));
#endif
        
#if Gem5
        pmubarrier[0] = Intersection;
        asm __volatile__ (".byte 0x72; .byte 0x25; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r"(pmubarrier[2]) : "r" (pmubarrier[0]), "r" (pmubarrier[0]));
#endif
        
        cpu_tmp[0] = get_cpu_time();
        for (j=image_bound[0];j<image_bound[1];j++)
            for (k=image_bound[2];k<image_bound[3];k++)
            {
                tmp_point.value[0] = (float)(j-0.5)*IMAGESTEP;
                tmp_point.value[1] = (float)(k-0.5)*IMAGESTEP;
                if (triangle_point(tmp_point,data_cloud[i]) == 1)
                {
                    triangle_compute(tmp_point,data_cloud[i]);
                    data_point.push_back(tmp_point);
                }
            }
        cpu_tmp[1] = get_cpu_time();
        cpu_yang[Intersection] += cpu_tmp[1] - cpu_tmp[0];
        
#if Gem5
        pmubarrier[0] = BlockEnd;
        asm __volatile__ (".byte 0x72; .byte 0x25; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r"(pmubarrier[2]) : "r" (pmubarrier[0]), "r" (pmubarrier[0]));
#endif
    }
    
    //--------------------------------------------------------------
    // Sort point cloud
    //--------------------------------------------------------------
#if Gem5
    pmubarrier[0] = Sorting;
    asm __volatile__ (".byte 0x72; .byte 0x25; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r"(pmubarrier[2]) : "r" (pmubarrier[0]), "r" (pmubarrier[0]));
#endif
    
    cpu_tmp[0] = get_cpu_time();
    int left,right;
    left = 0;
    right = data_point.size()-1;
    quicksort(data_point,left,right);
    cpu_tmp[1] = get_cpu_time();
    cpu_yang[Sorting] += cpu_tmp[1] - cpu_tmp[0];
    
#if Gem5
    pmubarrier[0] = BlockEnd;
    asm __volatile__ (".byte 0x72; .byte 0x25; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r"(pmubarrier[2]) : "r" (pmubarrier[0]), "r" (pmubarrier[0]));
#endif
    //--------------------------------------------------------------
    // Generating Image
    //--------------------------------------------------------------
    //CImg<unsigned int> img_out(IMAGEWIDTH,IMAGEHEIGHT,1,1,0);
    int layer_out[IMAGEHEIGHT][IMAGEWIDTH];
    int layer;
    float layer_step;
    float position;
    float coordinate[2];
    int direction;
    
    //layer_step = LAYERSTEP;
    //layer = (zmax-zmin)/layer_step + 1;
    layer = LAYER;
    layer_step = (layer-1)/(zmax-zmin);
    
    cout << layer << " " << zmax << " " << zmin << " " << data_cloud.size() << " " << data_point.size() << endl;
    
    left = 0;
    right = 0;
    for (i=0;i<layer;i++)
    {
#if Gem5
        pmubarrier[0] = Traverse;
        asm __volatile__ (".byte 0x72; .byte 0x25; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r"(pmubarrier[2]) : "r" (pmubarrier[0]), "r" (pmubarrier[0]));
#endif
        cpu_tmp[0] = get_cpu_time();
        /*
        for (k=0;k<img_out.width();k++)
            for (l=0;l<img_out.height();l++){
                img_out(k,l,0,0) = IMAGEINIT;
            }*/
        cout << "layer " << i << endl;

        for (k=0;k<IMAGEHEIGHT;k++)
            for (l=0;l<IMAGEWIDTH;l++)
                layer_out[k][l] = IMAGEINIT;
        
        position = zmin + layer_step*i;
        for (j=left;j<data_point.size();j++)
        {
            if (data_point[j].value[2] >= position)
            {
                right = j;
                break;
            }
        }
        for (j=left;j<right;j++)
        {
            coordinate[0] = data_point[j].value[0]/IMAGESTEP + 0.5;
            coordinate[1] = data_point[j].value[1]/IMAGESTEP + 0.5;
            direction = data_point[j].value[3];
            if ((coordinate[0] < IMAGEWIDTH)&&(coordinate[0] > 0)&&(coordinate[1] < IMAGEHEIGHT)&&(coordinate[1] > 0))
                layer_out[(int)coordinate[1]][(int)coordinate[0]] += direction*1;
        }
        cpu_tmp[1] = get_cpu_time();
        cpu_yang[Traverse] += cpu_tmp[1] - cpu_tmp[0];
#if Gem5
        pmubarrier[0] = BlockEnd;
        asm __volatile__ (".byte 0x72; .byte 0x25; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r"(pmubarrier[2]) : "r" (pmubarrier[0]), "r" (pmubarrier[0]));
#endif
        
        cpu_tmp[0] = get_cpu_time();
        
        layerresult << "layer: " << i << endl;          // total too much, here sample
        for (k=0;k<IMAGEHEIGHT;k+=1) {
            for (l=0;l<IMAGEWIDTH;l+=1)
                layerresult << layer_out[k][l] << " ";
            layerresult << endl;
        }
        layerresult << endl;
        
        cpu_tmp[1] = get_cpu_time();
        cpu_yang[0] += cpu_tmp[1] - cpu_tmp[0];
        left = right;
    }
    
    for (i=0;i<CPU_ITEMS;i++) {
        cpu_yang[CPU_ITEMS] += cpu_yang[i];
    }
    runningtime << "Slicing 3 runningtime" << endl;
    for (i=0;i<CPU_ITEMS+1;i++) {
        runningtime << left << setw(15) << cpu_index[i] << " : " << setw(10) <<  cpu_yang[i] << " " <<  cpu_yang[i]/cpu_yang[CPU_ITEMS]*100 << "%" << endl;
    }
    cout << "time: " << cpu_yang[CPU_ITEMS] << endl;
    
    layerresult.close();
    runningtime.close();
    cout << "memory footprint (kB) " << getValue() << endl;
    return 0;
}

























