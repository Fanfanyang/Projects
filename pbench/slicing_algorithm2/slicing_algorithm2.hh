#ifndef SLICING
#define SLICING

#include <fstream>
#include <string>
#include <vector>
#include <sstream>

#define LAYERSTEP       0.1
#define LAYER           10
#define SCALE           1
#define CPU_INIT        0
#define CPU_ITEMS       4
#define Gem5            0
#define Gem5SYS         0

#define FileIO          0
#define Sorting         1
#define Traverse        2
#define Intersection    3
#define BlockEnd        -1

using namespace std;

struct Point{
    // x,y,z
    float value[3];
};

struct HalfEdge{
    float value[2][3];
    float opposite[3];
    int self;
    //int update;
    int prev;
    int next;
    int pair;
    int flag;
};

int Read_STL_File(const char *stl_File_Name, vector<HalfEdge>& data_in, int scale, float& zmin, float& zmax);
double get_cpu_time();

#endif
