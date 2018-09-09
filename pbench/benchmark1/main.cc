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
#include "ofs.hh"
#include "slicing.hh"
#include "pathp.hh"
#include "supportg.hh"

using namespace std;

//--------------------------------------------------------------
// main
//--------------------------------------------------------------

int main()
{
    
    using namespace std;
    int scale = SCALE;
    int step;
    ofstream fp("RunningTime.txt");
    double cpu[5*LAYER];
    float slicing_plane[LAYER];
    int contour_pairs[LAYER];
    int z,a;
    double cpu_tpp, cpu_contour;
    int size, i, j, k, dimension,contour_points;
    i = 0;
    k = 0;
    dimension = 3;
    
    PathPlanning path_planning;
    Slicing slicing;
    //BmpImage bmpimage;
    SupportGeneration supportgeneration;
    
    //--------------------------------------------------------------
    // input data
    //--------------------------------------------------------------
    
    //int a=1;
    //char test[64]="../arm_binary/3d_printing_benchmark/HearingAid.stl";
    //char test[64]= "../stl_files/ringKnots.stl";     //"HearingAid.stl";
    char test[64]= "../stl_files/HearingAid.stl";
    //char test[64] = "STL_Lib/Crocidile_v.stl";
    //char test[64] = "stl_40x40x40_100x100x100_30x30x30_3x3x3_structure_283.stl";
    //char test[64] = "stl_files/HearingAid.stl";
    //char test[64] = "stl_files/bun_zipper.stl";
    //char test[64] = "../stl_files/bun_zipper.stl";
    //size=Read_size(test);
    //size = 3*size;
    //cout << size << endl;
    //size = 398700;
    
    //fp << size << endl;
    //int datatry[18655056];
    vector<Data> data_in, data_out;
    //cout << "one" << endl;
    /*
    for(j=0;j<3999;j++)
    {
        for(k=0;k<dimension;k++)
            data_out[j].value[k] = 0;
    }*/
    
    size=Read_STL_File(test,data_in,scale);
    size = 3*size;
    //for (i=0;i<399999;i++){
    
    /*for (i=0;i<size;i++){
        for (j=0;j<3;j++){
            fp << data_in[i].value[j] << " ";
        }
        fp << endl;
    }*/

    /*
    int **image = new int *[IMAGEHEIGHT];
    for (i=0;i<IMAGEHEIGHT;i++)
        image[i] = new int[IMAGEWIDTH];
     */
    PIXELTYPE image_curr[IMAGEHEIGHT][IMAGEWIDTH], image_prev[IMAGEHEIGHT][IMAGEWIDTH], image_supp[IMAGEHEIGHT][IMAGEWIDTH];

    //--------------------------------------------------------------
    // data processing
    //--------------------------------------------------------------
    
    for (i=0;i<IMAGEHEIGHT;i++)
        for (j=0;j<IMAGEWIDTH;j++){
            image_prev[i][j] = 0;
        }
    step = (ZEND-ZBEGIN)*scale/LAYER;
    k = 0;
    //cout << "z intersection nc out" << endl;
    //for (z=-50;z<40;z+=1)             // bunny
    //for (z=7000;z<13000;z+=500)       // ringknots
    //for (z=0;z/1000<80;z+=1000)       // hearingaid
    for (z=ZBEGIN*scale;z/scale<ZEND;z+=step)
    //for (z=-40000;z<50000;z+=2000)
    {
        //z = z*1000;
        cpu[k*5]  = get_cpu_time();
        slicing_plane[k] = z;
        //fp << "begins!" << endl;
        //cout << size << " " << dimension << endl;
        
        for (i=0;i<IMAGEHEIGHT;i++)
            for (j=0;j<IMAGEWIDTH;j++){
                image_curr[i][j] = 0;
            }
        data_out.clear();
    
        //--------------------------------------------------------------
        // pre-fabrication processes
        //--------------------------------------------------------------
        cpu[k*5+1]  = get_cpu_time();
        slicing.intersections(data_in,dimension,size,z,data_out,&contour_points,scale);
        cpu[k*5+2]  = get_cpu_time();
        path_planning.checkboundary(data_out, scale);
        path_planning.rasterization(data_out,image_curr,scale);
        cpu[k*5+3]  = get_cpu_time();
        supportgeneration.ImageGrow(image_prev,image_supp);
        supportgeneration.ImageDiff(image_curr,image_supp);
        //const char *strFile = "a.bmp";
        //bmpimage.bmp_write(image,strFile);
        
        for (i=0;i<IMAGEHEIGHT;i++)
            for (j=0;j<IMAGEWIDTH;j++)
                image_prev[i][j] = image_curr[i][j];
        
        cpu[k*5+4]  = get_cpu_time();
        
        //--------------------------------------------------------------
        // show result and output
        //--------------------------------------------------------------
        /*
        for (i=0;i<IMAGEHEIGHT;i+=5){
            for (j=0;j<IMAGEWIDTH;j+=10)
                cout << image_supp[i][j];
            cout << endl;
        }
        */
        contour_pairs[k] = contour_points/2;
        k += 1;
    }
    double cpu_tmp[4];
    fp << "slicing_plane" << " | contour pairs" << " | CPU Time"  << " |   Slicing" << " | Path Planning" << " | Support Generation" << " | Overhead" << endl;
    for (i=0;i<k;i+=1){
        fp << setw(8) << slicing_plane[i] << "      | " << setw(10) << contour_pairs[i] << "    | " << setw(8) << cpu[i*5+4]  - cpu[i*5] << " | " << setw(8) << 100*(cpu[i*5+2]-cpu[i*5+1])/(cpu[i*5+4]  - cpu[i*5]) << "% | " << setw(12) << 100*(cpu[i*5+3]-cpu[i*5+2])/(cpu[i*5+4]  - cpu[i*5]) << "% | " << setw(17) << 100*(cpu[i*5+4]-cpu[i*5+3])/(cpu[i*5+4]  - cpu[i*5]) << "% | " << setw(8) << 100*(cpu[i*5+1]-cpu[i*5])/(cpu[i*5+4]  - cpu[i*5]) << "%" << endl;
        //fp << setw(8) << slicing_plane[i] << "      | " << setw(10) << contour_pairs[i] << "    | " << setw(8) << cpu[i*5+4]  - cpu[i*5] << " | " << setw(8) << (cpu[i*5+2]-cpu[i*5+1]) << " | " << setw(12) << (cpu[i*5+3]-cpu[i*5+2]) << " | " << setw(17) << (cpu[i*5+4]-cpu[i*5+3]) << " | " << setw(8) << (cpu[i*5+1]-cpu[i*5]) << " " << endl;
        //cpu_tmp[0] += cpu[i*5+2]-cpu[i*5+1];
        //cpu_tmp[1] += cpu[i*5+3]-cpu[i*5+2];
        //cpu_tmp[2] += cpu[i*5+4]-cpu[i*5+3];
        //cpu_tmp[3] += cpu[i*5+1]-cpu[i*5];
    }
    fp << "Total CPU Time = " << cpu[i*5-1] - cpu[0] << endl;
    //fp << cpu[i*5-1] - cpu[0] << " | " << cpu_tmp[0] << " | " << cpu_tmp[1] << " | " << cpu_tmp[2] << " | " << cpu_tmp[3] << endl;
    
    fp.close();
    return 0;
}

