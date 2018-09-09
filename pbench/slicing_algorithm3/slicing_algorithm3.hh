#ifndef SLICING
#define SLICING

#include <fstream>
#include <string>
#include <vector>
#include <sstream>

#define CPU_ITEMS       4
#define FileIO          0
#define Traverse        1
#define Intersection    2
#define Sorting         3
#define BlockEnd        -1
#define Gem5            0
#define Gem5SYS         0

#define FACTORWIDTH     80          //80    140
#define FACTORHEIGHT    60          //60    105
#define LAYER           10

#define IMAGESTEP       0.078125
#define IMAGEWIDTH      800         //1024  1792    2048
#define IMAGEHEIGHT     600         //768   1344   1536
#define LAYERSTEP       0.1
#define IMAGEINIT       0           //255
#define SCALE           1
#define CPU_INIT        0

using namespace std;

struct Triangle{
    // x,y,z,normal
    float value[4][3];
};

struct Point{
    float value[4];
};

int Read_STL_File(const char *stl_File_Name, vector<Triangle>& data_in, int scale, float& zmin, float& zmax);
double get_cpu_time();

#endif
