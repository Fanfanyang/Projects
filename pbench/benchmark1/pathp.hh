#ifndef PATHPLANNING
#define PATHPLANNING

#include <vector>
using namespace std;

template <typename T>
struct coordinate{
    T value[3];     //x,y
};

#define CPU_ITEMS       3
#define FileIO          0
#define Intersection    1
#define Sorting         2
#define BlockEnd        -1

#define ISGRID          0
#define ONHORIZONTAL    1
#define ONVERTICAL      2
#define ISPOINT         3

class PathPlanning{
private:
    int i,j,k,l;
    int intersection_x,intersection_y, pivot, tmp;
    int x1,y1,x2,y2,x0,y0,x3,y3,z,xmin,xmax,ymin,ymax;
    float grid,area,area_extra;
    int grid_line,boundx,boundy;
    int points_accu;
    bool contourstart;
    vector<int> Binary_Queue;
    vector<coordinate<int> > Intersection_Queue;
    int left,right,itl,itr;
    coordinate<int> tmp_coordinate,boundary_start;
    coordinate<int> boundary[2];    //0 for left, 1 for right
    coordinate<int> corners[4];
    coordinate<int> corner_index;
    int corner_counter;
    Data pivot_coordinate,tmp_start,tmp_c;
    
public:
    void quicksort(vector<int> &Data_tmp1, int left, int right);
    bool checkboundary(vector<Data>& data_in, int scale);
    bool rasterization(vector<Data>& data_in, vector<Data>& data_out, int scale, int& layer, int& NumberOfContours, vector<int>& NumbersOfPoints, vector<int>& Orientations, double cpu_yang[CPU_INIT]);
    
public:
    PathPlanning():grid((float)FACTORWIDTH/IMAGEWIDTH),y1(0),y2(0)
    {}
};

#endif
