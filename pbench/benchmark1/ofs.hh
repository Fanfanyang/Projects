#ifndef OTHER_FUNCTIONS
#define OTHER_FUNCTIONS

#include <fstream>
#include <string>
#include <vector>
#include <sstream>

#define THICKNESS       0.1
#define FACTORWIDTH     80          //80    140
#define FACTORHEIGHT    60          //60    105
#define IMAGEWIDTH      800        //1024  1792    2048
#define IMAGEHEIGHT     600         //768   1344   1536
#define IMAGESTEP       0.078125

#define LAYERSTEP       0.1
#define LAYER           10
#define GROWCIRCLE      21
#define SCALE           10000
#define DISTANCEINIT    FACTORWIDTH*SCALE
#define DISTANCETH      SCALE
#define DIMENSION       3
#define IMAGETH         1           //175
#define IMAGEINIT       0           //255
#define GROWVALUE       255
#define PIXELTYPE       bool
#define DQ_threshold    10
#define DIST_TH         1
#define CPU_INIT        0
#define Gem5            0
#define Gem5SYS         0

using namespace std;

struct Data{
    // x,y,z
    int value[3];
};

template <typename T>
struct SILA{
    //one, another
    T value[2];
};

int parseLine(char* line);
int getValue();

int Read_size(const char *stl_File_Name);
int Read_STL_File(const char *stl_File_Name, vector<Data>& data_in, int scale, float& zmin, float& zmax);
double get_wall_time();
double get_cpu_time();
string getfilename(int k, int mode);
/*
class BmpImage{
private:
    unsigned char info[54];
    int width,height,size,tmp,i,j;
    FILE *fpi, *fpw;
    int data[786432];
    
public:
    void bmp_read(string strFile);
    void bmp_write(int (&data_in)[768][1024], const char* strFile);
};
*/
#endif
