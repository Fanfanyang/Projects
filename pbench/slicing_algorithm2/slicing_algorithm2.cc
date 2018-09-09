//--------------------------------------------------------------
// Slicing Functions
//--------------------------------------------------------------

#include <math.h>
#include <iostream>
#include <fstream>
#include <string>
#include <iomanip>
#include <cstring>
#include "slicing_algorithm2.hh"

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
// Operator Overloading
//--------------------------------------------------------------

bool operator < (const HalfEdge &a, const HalfEdge &b)
{
    if (((a.value[0][2] < b.value[0][2])||((a.value[0][2] == b.value[0][2])&&(a.value[0][1] < b.value[0][1]))||((a.value[0][2] == b.value[0][2])&&(a.value[0][1] == b.value[0][1])&&(a.value[0][0] < b.value[0][0])))||(((a.value[0][2] == b.value[0][2])&&(a.value[0][1] == b.value[0][1])&&(a.value[0][0] == b.value[0][0]))&&
        ((a.value[1][2] < b.value[1][2])||((a.value[1][2] == b.value[1][2])&&(a.value[1][1] < b.value[1][1]))||((a.value[1][2] == b.value[1][2])&&(a.value[1][1] == b.value[1][1])&&(a.value[1][0] < b.value[1][0])))))
        return 1;
    else
        return 0;
}

bool operator > (const HalfEdge &a, const HalfEdge &b)
{
    if (((a.value[0][2] > b.value[0][2])||((a.value[0][2] == b.value[0][2])&&(a.value[0][1] > b.value[0][1]))||((a.value[0][2] == b.value[0][2])&&(a.value[0][1] == b.value[0][1])&&(a.value[0][0] > b.value[0][0])))||(((a.value[0][2] == b.value[0][2])&&(a.value[0][1] == b.value[0][1])&&(a.value[0][0] == b.value[0][0]))&&
        ((a.value[1][2] > b.value[1][2])||((a.value[1][2] == b.value[1][2])&&(a.value[1][1] > b.value[1][1]))||((a.value[1][2] == b.value[1][2])&&(a.value[1][1] == b.value[1][1])&&(a.value[1][0] > b.value[1][0])))))
        return 1;
    else
        return 0;
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
int Read_STL_File(const char *stl_File_Name, vector<HalfEdge>& data_in, int scale, float& zmin, float& zmax)
{
    int counter=0;
    float xmin,xmax,ymin,ymax;
    xmin = 100*scale;
    xmax = 0;
    ymin = 100*scale;
    ymax = 0;
    HalfEdge data_tmp[3];
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
        /*
        if (v1[0] < xmin)
            xmin = v1[0];
        if (v1[0] > xmax)
            xmax = v1[0];
        if (v2[0] < xmin)
            xmin = v2[0];
        if (v2[0] > xmax)
            xmax = v2[0];
        if (v3[0] < xmin)
            xmin = v3[0];
        if (v3[0] > xmax)
            xmax = v3[0];
        
        if (v1[1] < ymin)
            ymin = v1[1];
        if (v1[1] > ymax)
            ymax = v1[1];
        if (v2[1] < ymin)
            ymin = v2[1];
        if (v2[1] > ymax)
            ymax = v2[1];
        if (v3[1] < ymin)
            ymin = v3[1];
        if (v3[1] > ymax)
            ymax = v3[1];
        */
        
        if ((v1[2] < v2[2])||((v1[2] == v2[2])&&(v1[1] < v2[1]))||((v1[2] == v2[2])&&(v1[1] == v2[1])&&(v1[0] < v2[0])))
            for (j=0;j<3;j++)
            {
                data_tmp[0].value[0][j] = v1[j]*scale;
                data_tmp[0].value[1][j] = v2[j]*scale;
            }
        else
            for (j=0;j<3;j++)
            {
                data_tmp[0].value[0][j] = v2[j]*scale;
                data_tmp[0].value[1][j] = v1[j]*scale;
            }
        
        if ((v2[2] < v3[2])||((v2[2] == v3[2])&&(v2[1] < v3[1]))||((v2[2] == v3[2])&&(v2[1] == v3[1])&&(v2[0] < v3[0])))
            for (j=0;j<3;j++)
            {
                data_tmp[1].value[0][j] = v2[j]*scale;
                data_tmp[1].value[1][j] = v3[j]*scale;
            }
        else
            for (j=0;j<3;j++)
            {
                data_tmp[1].value[0][j] = v3[j]*scale;
                data_tmp[1].value[1][j] = v2[j]*scale;
            }
        
        if ((v3[2] < v1[2])||((v3[2] == v1[2])&&(v3[1] < v1[1]))||((v3[2] == v1[2])&&(v3[1] == v1[1])&&(v3[0] < v1[0])))
            for (j=0;j<3;j++)
            {
                data_tmp[2].value[0][j] = v3[j]*scale;
                data_tmp[2].value[1][j] = v1[j]*scale;
            }
        else
            for (j=0;j<3;j++)
            {
                data_tmp[2].value[0][j] = v1[j]*scale;
                data_tmp[2].value[1][j] = v3[j]*scale;
            }
        
        data_tmp[0].prev = 3*i + 2;
        data_tmp[0].next = 3*i + 1;
        data_tmp[1].prev = 3*i;
        data_tmp[1].next = 3*i + 2;
        data_tmp[2].prev = 3*i + 1;
        data_tmp[2].next = 3*i;

        for (j=0;j<3;j++)
        {
            data_tmp[j].flag = 0;
            data_tmp[j].self = j + i*3;
            data_tmp[0].opposite[j] = v3[j]*scale;
            data_tmp[1].opposite[j] = v1[j]*scale;
            data_tmp[2].opposite[j] = v2[j]*scale;
        }
        
        for (j=0;j<3;j++)
            data_in.push_back(data_tmp[j]);
    }
    
    //cout << xmin << " " << xmax << " " << ymin << " " << ymax << " " << zmin << " " << zmax << " " << endl;
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
// Sorting
//--------------------------------------------------------------

void quicksort(vector<HalfEdge>& data_HE,int& left,int& right)
{
    int itl,itr;
    HalfEdge pivot, tmp;
    itl = left;
    itr = right;
    pivot = data_HE[(left+right)/2];
    
    while (itl <= itr)
    {
        while (data_HE[itl] < pivot)
            itl++;
        while (data_HE[itr] > pivot)
            itr--;
        if (itl <= itr)
        {
            tmp = data_HE[itl];
            data_HE[itl] = data_HE[itr];
            data_HE[itr] = tmp;
            itl++;
            itr--;
        }
    }
    
    if (left < itr)
        quicksort(data_HE, left, itr);
    if (itl < right)
        quicksort(data_HE, itl, right);
}

//--------------------------------------------------------------
// Slicing
//--------------------------------------------------------------

void compute_intersection(HalfEdge& data,float& position,vector<Point>& data_out)
{
    Point data_tmp;
    data_tmp.value[0] = (data.value[1][0]-data.value[0][0])*(position-data.value[0][2])/(data.value[1][2]-data.value[0][2])+data.value[0][0];
    data_tmp.value[1] = (data.value[1][1]-data.value[0][1])*(position-data.value[0][2])/(data.value[1][2]-data.value[0][2])+data.value[0][1];
    data_tmp.value[2] = position;
    data_out.push_back(data_tmp);
}

int handle_exception(vector<HalfEdge>& data_HalfEdge, int& index, float& position,vector<Point> data_out, int& k)
{
    HalfEdge data_tmp, data_edge;
    Point point_tmp;
    int index_tmp,i;
    
    index_tmp = data_HalfEdge[index].prev;
    if (data_HalfEdge[index_tmp].opposite[2] == position)
    {
        data_tmp = data_HalfEdge[index_tmp];
        data_edge = data_HalfEdge[data_HalfEdge[index].next];
    }
    else
    {
        index_tmp = data_HalfEdge[index].next;
        data_tmp = data_HalfEdge[index_tmp];
        data_edge = data_HalfEdge[data_HalfEdge[index].prev];
    }
    
    if ((data_tmp.value[0][2] < position)&&(data_tmp.value[1][2] > position))
    {
        compute_intersection(data_HalfEdge[index_tmp],position,data_out);
        data_HalfEdge[index_tmp].flag = 0;
        k = data_HalfEdge[index_tmp].pair;
        return 0;
    }
    
    if (data_edge.value[0][2] == data_edge.value[1][2])
    {
        for (i=0;i<3;i++)
            point_tmp.value[i] = data_HalfEdge[index].opposite[i];
        data_out.push_back(point_tmp);
        data_edge = data_tmp;
    }
    
    handle_exception(data_HalfEdge, data_edge.pair, position,data_out,k);
    return 0;
}

void slicing_proc(vector<HalfEdge>& data_HalfEdge, float& position, int& iNumberOfContours, vector<int>& iOrientation, vector<int>& iNumberOfPoints, vector<Point>& data_out, double cpu_yang[CPU_ITEMS+1])
{
    int i,j,k;
    int before,after;
    int counter[3];
    double cpu_tmp[2];
    int pmubarrier[3];
    pmubarrier[0] = -1;
    pmubarrier[1] = -1;
    pmubarrier[2] = -1;
    Point data_tmp;
    iNumberOfContours = 0;
    iNumberOfPoints.clear();
    iOrientation.clear();
    
#if Gem5
    pmubarrier[0] = Traverse;
    asm __volatile__ (".byte 0x72; .byte 0x25; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r"(pmubarrier[2]) : "r" (pmubarrier[0]), "r" (pmubarrier[0]));
#endif
    cpu_tmp[0] = get_cpu_time();
    for (j=0;j<data_HalfEdge.size();j++)
        if ((data_HalfEdge[j].value[0][2] < position)&&(data_HalfEdge[j].value[1][2] > position))
            data_HalfEdge[j].flag = 1;
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
    for (j=0;j<data_HalfEdge.size();j++)
    {
        counter[0] = data_out.size();
        if (data_HalfEdge[j].flag == 1)
        {
            k = j;
            
            compute_intersection(data_HalfEdge[k],position,data_out);
            
            while (data_HalfEdge[k].flag == 1)
            {
                data_HalfEdge[k].flag = 0;
                before = data_HalfEdge[k].prev;
                after = data_HalfEdge[k].next;
                
                if ((data_HalfEdge[before].value[0][2] < position)&&(data_HalfEdge[before].value[1][2] > position))
                {
                    compute_intersection(data_HalfEdge[before],position,data_out);
                    data_HalfEdge[before].flag = 0;
                    k = data_HalfEdge[before].pair;
                    //cout << "1 " << k << endl;
                    continue;
                }
                if ((data_HalfEdge[after].value[0][2] < position)&&(data_HalfEdge[after].value[1][2] > position))
                {
                    compute_intersection(data_HalfEdge[after],position,data_out);
                    data_HalfEdge[after].flag = 0;
                    k = data_HalfEdge[after].pair;
                    continue;
                }
                
                data_tmp.value[0] = data_HalfEdge[k].opposite[0];
                data_tmp.value[1] = data_HalfEdge[k].opposite[1];
                data_tmp.value[2] = data_HalfEdge[k].opposite[2];
                
                data_out.push_back(data_tmp);
                //cout << "2 " << k << endl;
                //cout << "one1 " << k << " " << data_HalfEdge[k].value[0][2] << " " << data_HalfEdge[k].value[1][2] << " " << data_HalfEdge[k].opposite[2] << " " << position << endl;
                //cout << "one2 " << before << " " << data_HalfEdge[before].value[0][2] << " " << data_HalfEdge[before].value[1][2] << " " << data_HalfEdge[before].opposite[2] << " " << position << endl;
                
                handle_exception(data_HalfEdge, data_HalfEdge[before].pair, position,data_out,k);
                //cout << "four" << endl;
                
            }
            counter[1] = data_out.size();
            counter[2] = counter[1]-counter[0];
            
            iNumberOfContours++;
            iNumberOfPoints.push_back(counter[2]);
            iOrientation.push_back(0);
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
// main
//--------------------------------------------------------------

int main(int argc, char* argv[])
{
    if (argc < 2){ 
        cout << "Please Specify one input STL file" << endl;
        return -1;
    }
    
    ofstream runningtime("result/RunningTime.txt", ofstream::out|ofstream::binary);
    ofstream result("result/SlicingResult.cli");

    vector<HalfEdge> data_HalfEdge;
    typedef unsigned short uint16;
    int scale = SCALE;
    int step;
    float zmin, zmax;
    int i,j,k,l;
    zmin = 100;
    zmax = 0;
    int pmubarrier[3];
    pmubarrier[0] = -1;
    pmubarrier[1] = -1;
    pmubarrier[2] = -1;

    double cpu_yang[CPU_ITEMS+1];
    double cpu_tmp[2];
    string cpu_index[CPU_ITEMS+1] = {"FileIO","Sorting","Traverse","Intersection","Total"};
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
    Read_STL_File(argv[1],data_HalfEdge,scale,zmin,zmax);
    cpu_tmp[1] = get_cpu_time();
    cpu_yang[FileIO] += cpu_tmp[1] - cpu_tmp[0];
    
#if Gem5
    pmubarrier[0] = BlockEnd;
    asm __volatile__ (".byte 0x72; .byte 0x25; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r"(pmubarrier[2]) : "r" (pmubarrier[0]), "r" (pmubarrier[0]));
#endif
    //--------------------------------------------------------------
    // Write CLI
    //--------------------------------------------------------------
    
    char filling1[14] = "$$HEADERSTART";
    char filling2[13] = "$$BINARYTART";
    char filling3[10] = "$$UNITS/1";
    char filling4[14] = "$$VERSION/200";
    char filling5[16] = "$$LABEL/1,part1";
    char filling6[16] = "$$HEADERENDart1";
    result.write(filling1, 14);
    result.write(filling2, 9);
    result.write(filling3, 11);
    result.write(filling4, 14);
    result.write(filling5, 16);
    result.write(filling6, 11);
    
    //--------------------------------------------------------------
    // Sorting and labering
    //--------------------------------------------------------------
    
    int *decode_index = new int[data_HalfEdge.size()];
    int left,right;
    left = 0;
    right = data_HalfEdge.size()-1;
    
#if Gem5
    pmubarrier[0] = Sorting;
    asm __volatile__ (".byte 0x72; .byte 0x25; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r"(pmubarrier[2]) : "r" (pmubarrier[0]), "r" (pmubarrier[0]));
#endif
    
    cpu_tmp[0] = get_cpu_time();
    quicksort(data_HalfEdge,left,right);
    cpu_tmp[1] = get_cpu_time();
    cpu_yang[Sorting] += cpu_tmp[1] - cpu_tmp[0];
    
#if Gem5
    pmubarrier[0] = BlockEnd;
    asm __volatile__ (".byte 0x72; .byte 0x25; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r"(pmubarrier[2]) : "r" (pmubarrier[0]), "r" (pmubarrier[0]));
#endif
    
#if Gem5
    pmubarrier[0] = Traverse;
    asm __volatile__ (".byte 0x72; .byte 0x25; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r"(pmubarrier[2]) : "r" (pmubarrier[0]), "r" (pmubarrier[0]));
#endif
    
    cpu_tmp[0] = get_cpu_time();
    for (i=0;i<data_HalfEdge.size();)
    {
        //data_HalfEdge[data_HalfEdge[i].self].update = i;
        decode_index[data_HalfEdge[i].self] = i;
        decode_index[data_HalfEdge[i+1].self] = i+1;
        data_HalfEdge[i].pair = i+1;
        data_HalfEdge[i+1].pair = i;
        i += 2;
    }
    
    for (i=0;i<data_HalfEdge.size();i++)
    {
        data_HalfEdge[i].next = decode_index[data_HalfEdge[i].next];
        data_HalfEdge[i].prev = decode_index[data_HalfEdge[i].prev];
    }
    cpu_tmp[1] = get_cpu_time();
    cpu_yang[Traverse] += cpu_tmp[1] - cpu_tmp[0];
    
#if Gem5
    pmubarrier[0] = BlockEnd;
    asm __volatile__ (".byte 0x72; .byte 0x25; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r"(pmubarrier[2]) : "r" (pmubarrier[0]), "r" (pmubarrier[0]));
#endif
    
    delete [] decode_index;
    
    //--------------------------------------------------------------
    // slicing
    //--------------------------------------------------------------
    
    //float layer_step = LAYERSTEP;
    //int layer = (zmax-zmin)/layer_step + 1;
    int layer = LAYER;
    float layer_step = (layer-1)/(zmax-zmin);
    float position;
    int iNumberOfContours;
    vector<int> iOrientation, iNumberOfPoints;
    vector<Point> data_out;
    int accumulator, iIdentifier;
    unsigned short uiCommand;
    float fSliceHeight,x,y;
    fSliceHeight = LAYERSTEP;
    
    for (i=0;i<layer;i++)
    {
        position = zmin + layer_step*i;
        data_out.clear();

        slicing_proc(data_HalfEdge,position,iNumberOfContours,iOrientation,iNumberOfPoints,data_out,cpu_yang);

        cout << "layer " << i << " " << iNumberOfContours << endl;
        
        //--------------------------------------------------------------
        // show result and output
        //--------------------------------------------------------------
        
#if Gem5
        pmubarrier[0] = FileIO;
        asm __volatile__ (".byte 0x72; .byte 0x25; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r"(pmubarrier[2]) : "r" (pmubarrier[0]), "r" (pmubarrier[0]));
#endif
        
        cpu_tmp[0] = get_cpu_time();
        uiCommand = 127;
        result.write((char *)&uiCommand, sizeof(uint16));
        result.write((char *)&fSliceHeight, sizeof(float));
        accumulator = 0;
        
        for (l=0;l<iNumberOfContours;l++)
        {
            uiCommand = 130;
            result.write((char *)&uiCommand, sizeof(uint16));
            iIdentifier = 1;
            result.write((char *)&iIdentifier, sizeof(int));
            result.write((char *)&iOrientation[l], sizeof(int));
            result.write((char *)&iNumberOfPoints[l], sizeof(int));
            for (k=accumulator; k<accumulator+iNumberOfPoints[l]; k++)
            {
                x = (float)data_out[k].value[0]/scale;
                y = (float)data_out[k].value[1]/scale;
                result.write((char *)&x, sizeof(float));
                result.write((char *)&y, sizeof(float));
            }
            accumulator += iNumberOfPoints[l];
        }
        cpu_tmp[1] = get_cpu_time();
        cpu_yang[FileIO] += cpu_tmp[1] - cpu_tmp[0];
        
#if Gem5
        pmubarrier[0] = BlockEnd;
        asm __volatile__ (".byte 0x72; .byte 0x25; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r"(pmubarrier[2]) : "r" (pmubarrier[0]), "r" (pmubarrier[0]));
#endif
    }
    
    for (i=0;i<CPU_ITEMS;i++) {
        cpu_yang[CPU_ITEMS] += cpu_yang[i];
    }
    runningtime << "Slicing 2 runningtime" << endl;
    for (i=0;i<CPU_ITEMS+1;i++) {
        runningtime << left << setw(15) << cpu_index[i] << " : " << setw(10) <<  cpu_yang[i] << " " <<  cpu_yang[i]/cpu_yang[CPU_ITEMS]*100 << "%" << endl;
    }
    cout << "time: " << cpu_yang[CPU_ITEMS] << endl;
    
    runningtime.close();
    result.close();
    cout << "memory footprint (kB) " << getValue() << endl;
    return 0;
}





























