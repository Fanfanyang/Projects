//--------------------------------------------------------------
// Path Planning
//--------------------------------------------------------------

#include <math.h>
#include <iostream>
#include <fstream>
#include <string>
#include <iomanip>
//#include "CImg.h"
#include "ofs.hh"
#include "pathp.hh"

using namespace std;
//using namespace cimg_library;

void PathPlanning::quicksort(vector<int>& Data_tmp1, int left, int right)
{
    itl = left;
    itr = right;
    pivot = Data_tmp1.at((left+right)/2);
    
    while (itl <= itr){
        while (Data_tmp1.at(itl) < pivot)
            itl++;
        while (Data_tmp1.at(itr) > pivot)
            itr--;
        if (itl <= itr){
            tmp = Data_tmp1.at(itl);
            Data_tmp1.at(itl) = Data_tmp1.at(itr);
            Data_tmp1.at(itr) = tmp;
            itl++;
            itr--;
        }
    }
    
    if (left < itr)
        quicksort(Data_tmp1, left, itr);
    if (itl < right)
        quicksort(Data_tmp1, itl, right);
}

bool PathPlanning::rasterization(vector<Data>& data_in, vector<Data>& data_out, int scale, int& layer, int& NumberOfContours, vector<int>& NumbersOfPoints, vector<int>& Orientations, double cpu_yang[CPU_INIT])
{
    double cpu_tmp[2];
    Data data_tmp;
    int direction = 1;      // 1: go right, -1: go left
    int pmubarrier[3];
    pmubarrier[0] = -1;
    pmubarrier[1] = -1;
    pmubarrier[2] = -1;
    
    for (i=0;i<IMAGEHEIGHT;i++){
        
#if Gem5
        pmubarrier[0] = Intersection;
        asm __volatile__ (".byte 0x72; .byte 0x25; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r"(pmubarrier[2]) : "r" (pmubarrier[0]), "r" (pmubarrier[0]));
#endif
        
        cpu_tmp[0] = get_cpu_time();
        Binary_Queue.clear();
        grid_line = i*grid*scale;
        points_accu = 0;
        for (k=0;k<NumbersOfPoints.size();k++){
            for (j=points_accu;j<NumbersOfPoints[k]+points_accu;j++){
                if (j == NumbersOfPoints[k]+points_accu-1)
                {
                    if (Orientations[k] == 2)       // open contour
                    {
                        continue;
                    }
                    else
                    {
                        x1 = data_in[j].value[0];
                        y1 = data_in[j].value[1];
                        x2 = data_in[points_accu].value[0];
                        y2 = data_in[points_accu].value[1];
                    }
                }
                else
                {
                    x1 = data_in[j].value[0];
                    y1 = data_in[j].value[1];
                    x2 = data_in[j+1].value[0];
                    y2 = data_in[j+1].value[1];
                }
                if(((y1 < grid_line)&&(y2 > grid_line))||((y2 < grid_line)&&(y1 > grid_line))){
                    intersection_x = (float)(x2 - x1)*(grid_line - y1)/(y2 - y1) + x1;
                    Binary_Queue.push_back(intersection_x);
                }
            }
            points_accu += NumbersOfPoints[k];
        }
        cpu_tmp[1] = get_cpu_time();
        cpu_yang[Intersection] += cpu_tmp[1] - cpu_tmp[0];
        
#if Gem5
        pmubarrier[0] = BlockEnd;
        asm __volatile__ (".byte 0x72; .byte 0x25; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r"(pmubarrier[2]) : "r" (pmubarrier[0]), "r" (pmubarrier[0]));
#endif
        
        if (Binary_Queue.size() > 0){
            
#if Gem5
            pmubarrier[0] = Sorting;
            asm __volatile__ (".byte 0x72; .byte 0x25; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r"(pmubarrier[2]) : "r" (pmubarrier[0]), "r" (pmubarrier[0]));
#endif
            
            cpu_tmp[0] = get_cpu_time();
            left = 0;
            right = Binary_Queue.size() - 1;
            quicksort(Binary_Queue, left, right);
            
            switch (direction) {
                case 1:
                    for (j=0;j<Binary_Queue.size()/2;j+=1){                      // total must be even numbers.
                        
                        data_tmp.value[0] = Binary_Queue[j*2];
                        data_tmp.value[1] = i*grid*scale;
                        //data_tmp.value[2] = layer*fSliceHeight*scale;
                        data_out.push_back(data_tmp);
                        
                        data_tmp.value[0] = Binary_Queue[j*2+1];
                        data_tmp.value[1] = i*grid*scale;
                        data_out.push_back(data_tmp);
                        NumberOfContours++;
                    }
                    direction = -direction;
                    break;
                case -1:
                    for (j=Binary_Queue.size()/2-1;j>=0;j-=1){                      // total must be even numbers.
                        
                        data_tmp.value[0] = Binary_Queue[j*2+1];
                        data_tmp.value[1] = i*grid*scale;
                        data_out.push_back(data_tmp);
                        
                        data_tmp.value[0] = Binary_Queue[j*2];
                        data_tmp.value[1] = i*grid*scale;
                        data_out.push_back(data_tmp);
                        NumberOfContours++;
                    }
                    direction = -direction;
                    break;
                default:
                    break;
            }
            //cout << i << " " << Binary_Queue.size() << endl;
            
            cpu_tmp[1] = get_cpu_time();
            cpu_yang[Sorting] += cpu_tmp[1] - cpu_tmp[0];
            
#if Gem5
            pmubarrier[0] = BlockEnd;
            asm __volatile__ (".byte 0x72; .byte 0x25; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r"(pmubarrier[2]) : "r" (pmubarrier[0]), "r" (pmubarrier[0]));
#endif
        }
    }
    return 0;
}

//--------------------------------------------------------------
// main
//--------------------------------------------------------------

int main(int argc, char* argv[])
{
    if (argc < 2){
        cout << "Specify input file" << endl;
        return -1;
    }
    cout << "Input file: " << argv[1] << endl;

    typedef unsigned short uint16;
    int scale = SCALE;
    int step;
    //ifstream inputdata;
    ofstream runningtime;

    const char *CLIFileName = argv[1];
    runningtime.open("result/RunningTime.txt", ios_base::app);
    ofstream result("result/PathPResult.cli");
    int layer;
    layer = LAYER;
    vector<Data> data_in;
    vector<Data> data_out;
    Data data_tmp;
    int buffer;
    int z,a;
    int i, j, k,l;
    i = 0;
    k = 0;
    
    double cpu_yang[CPU_ITEMS+1];
    double cpu_tmp[2];
    int pmubarrier[3];
    pmubarrier[0] = -1;
    pmubarrier[1] = -1;
    pmubarrier[2] = -1;
    string cpu_index[CPU_ITEMS+1] = {"FileIO","Intersection","Sorting","Total"};
    for (i=0;i<CPU_ITEMS+1;i++)
        cpu_yang[i] = CPU_INIT;
    
    PathPlanning path_planning;
    //bool image_curr[IMAGEHEIGHT][IMAGEWIDTH];
    
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
    // input data
    //--------------------------------------------------------------
#if Gem5
    pmubarrier[0] = FileIO;
    asm __volatile__ (".byte 0x72; .byte 0x25; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r"(pmubarrier[2]) : "r" (pmubarrier[0]), "r" (pmubarrier[0]));
#endif
    cpu_tmp[0] = get_cpu_time();
    
    l = 0;
    const int fillsize = 30;
    char filling[fillsize];
    uint16 uiCommand;
    float fSliceHeight;
    int iIdentifier;
    int iOrientation;
    int iNumberOfPoints;
    int iNumberOfLayers;
    int NumberOfContours;
    
    iNumberOfLayers = 0;
    // first scan to get the number of layers
    ifstream CLIFile1;
    CLIFile1.open(CLIFileName, ifstream::in|ifstream::binary);
    if (! CLIFile1.is_open())
    {
        cout << "Error opening file" << endl;;
        return false;
    }
    //memset(filling, 0, fillsize);
    CLIFile1.read(filling, 14);
    CLIFile1.read(filling, 9);
    CLIFile1.read(filling, 11);
    CLIFile1.read(filling, 14);
    CLIFile1.read(filling, 16);
    CLIFile1.read(filling, 11);
    
    while (!CLIFile1.eof())
    {
        // Command for Start Layer (127)
        if (iNumberOfLayers==0)	//if not the first layer, this number is read in layer loop
        {
            CLIFile1.read((char *)&uiCommand, sizeof(uint16));
            if (uiCommand!=127)
            {
                cout << "incorrect CLI file, error happens at command for start layer" << endl;;
                CLIFile1.close();
                return false;
            }
        }
        
        
        CLIFile1.read((char *)&fSliceHeight, sizeof(float));
        if (fSliceHeight < 0)
        {
            cout << "incorrect CLI file, error happens at CLIce height" << endl;;
            CLIFile1.close();
            return false;
        }
        
        // for each layer
        while (!CLIFile1.eof())
        {
            // Command for Start PolyLine 130
            CLIFile1.read((char *)&uiCommand, sizeof(uint16));
            
            //we finished this layer
            if (uiCommand==127)
            {
                break;
            }
            if (uiCommand!=130)
            {
                cout << "incorrect CLI file, error happens at command for start poly line" << endl;;
                CLIFile1.close();
                return false;
            }
            
            // identifier 1
            // identifier to allow more than one model information in one file, here we only have 1
            CLIFile1.read((char *)&iIdentifier, sizeof(int));
            if (iIdentifier!=1)
            {
                cout << "incorrect CLI file, error happens at identifier" << endl;;
                CLIFile1.close();
                return false;
            }
            
            // orientation (0: clockwise, 1: counterclockwise, 2: open contour
            CLIFile1.read((char *)&iOrientation, sizeof(int));
            if (iOrientation!=0 && iOrientation!=1 && iOrientation!=2)
            {
                cout << "incorrect CLI file, error happens at orientation" << endl;;
                CLIFile1.close();
                return false;
            }
            //cout << "iOrientation " << iOrientation << endl;
            //number of points
            CLIFile1.read((char *)&iNumberOfPoints, sizeof(int));
            if (iNumberOfPoints<0)
            {
                cout << "incorrect CLI file, error happens at number of points" << endl;;
                CLIFile1.close();
                return false;
            }
            //cout << "iNumberOfPoints " << iNumberOfPoints << endl;
            // read all the coordinates
            float x, y;
            
            for (i=0; i<iNumberOfPoints; i++)
            {
                CLIFile1.read((char *)&x, sizeof(float));
                CLIFile1.read((char *)&y, sizeof(float));
            }
            //cout << x << " " << y << endl;
        }
        iNumberOfLayers++;
    }
    CLIFile1.close();
    
    
    // second scan to get the number of contours for each layer
    int* iNumberOfContours = new int[iNumberOfLayers];
    for (i=0; i<iNumberOfLayers; i++)
    {
        iNumberOfContours[i] = 0;
    }
    
    ifstream CLIFile2;
    CLIFile2.open(CLIFileName, ifstream::in|ifstream::binary);
    if (! CLIFile2.is_open())
    {
        cout << "Error opening file" << endl;;
        return false;
    }
    //memset(filling, 0, fillsize);
    CLIFile2.read(filling, 14);
    CLIFile2.read(filling, 9);
    CLIFile2.read(filling, 11);
    CLIFile2.read(filling, 14);
    CLIFile2.read(filling, 16);
    CLIFile2.read(filling, 11);
    int layerindex = 0;
    while (!CLIFile2.eof())
    {
        // Command for Start Layer (127)
        if (layerindex==0)	//if not the first layer, this number is read in layer loop
        {
            CLIFile2.read((char *)&uiCommand, sizeof(uint16));
            if (uiCommand!=127)
            {
                cout << "incorrect CLI file, error happens at command for start layer" << endl;;
                CLIFile2.close();
                return false;
            }
        }
        
        CLIFile2.read((char *)&fSliceHeight, sizeof(float));
        if (fSliceHeight < 0)
        {
            cout << "incorrect CLI file, error happens at CLIce height" << endl;;
            CLIFile2.close();
            return false;
        }
        
        // for each layer
        while (!CLIFile2.eof())
        {
            // Command for Start PolyLine 130
            CLIFile2.read((char *)&uiCommand, sizeof(uint16));
            //cout << "uiCommand " << uiCommand << " done " << endl;
            //we finished this layer
            if (uiCommand==127)
            {
                break;
            }
            if (uiCommand!=130)
            {
                cout << "incorrect CLI file, error happens at command for start poly line" << endl;;
                CLIFile2.close();
                return false;
            }
            
            // identifier 1
            // identifier to allow more than one model information in one file, here we only have 1
            CLIFile2.read((char *)&iIdentifier, sizeof(int));
            if (iIdentifier!=1)
            {
                cout << "incorrect CLI file, error happens at identifier" << endl;;
                CLIFile2.close();
                return false;
            }
            
            // orientation (0: clockwise, 1: counterclockwise, 2: open contour
            CLIFile2.read((char *)&iOrientation, sizeof(int));
            if (iOrientation!=0 && iOrientation!=1 && iOrientation!=2)
            {
                cout << "incorrect CLI file, error happens at orientation" << endl;;
                CLIFile2.close();
                return false;
            }
            
            //number of points
            CLIFile2.read((char *)&iNumberOfPoints, sizeof(int));
            if (iNumberOfPoints<0)
            {
                cout << "incorrect CLI file, error happens at number of points" << endl;;
                CLIFile2.close();
                return false;
            }
            //cout << "iNumberOfPoints " << iNumberOfPoints << endl;
            
            // read all the coordinates
            float x, y;
            
            for (i=0; i<iNumberOfPoints; i++)
            {
                CLIFile2.read((char *)&x, sizeof(float));
                CLIFile2.read((char *)&y, sizeof(float));
            }
            iNumberOfContours[layerindex]++;
            //cout << layerindex << " " << iNumberOfContours[layerindex] << endl;
            //cout << x << " " << y << endl;
        }
        layerindex++;
    }
    CLIFile2.close();
    
    iNumberOfContours[iNumberOfLayers-1]--;
    
    // third scan to get all the coordinates and orientations
    // layer index
    // height
    // number of contours
    //		orientation, #points, x, y
    // space
    float* LayerHeights = new float[iNumberOfLayers];
    
    vector<int> NumbersOfPoints;
    vector<int> Orientations;
    int totalPoints = 0;

    // yang debug
    //cout << "iNumberOfLayers " << iNumberOfLayers << endl;
    
    ifstream CLIFile3;
    CLIFile3.open(CLIFileName, ios::in|ios::binary);
    if (! CLIFile3.is_open())
    {
        cout << "Error opening file" << endl;;
        return false;
    }
    
    //memset(filling, 0, fillsize);
    CLIFile3.seekg(0, ios::beg);
    CLIFile3.read(filling, 14);
    CLIFile3.read(filling, 9);
    CLIFile3.read(filling, 11);
    CLIFile3.read(filling, 14);
    CLIFile3.read(filling, 16);
    CLIFile3.read(filling, 11);
    
    cpu_tmp[1] = get_cpu_time();
    cpu_yang[FileIO] += cpu_tmp[1] - cpu_tmp[0];
    
#if Gem5
    pmubarrier[0] = BlockEnd;
    asm __volatile__ (".byte 0x72; .byte 0x25; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r"(pmubarrier[2]) : "r" (pmubarrier[0]), "r" (pmubarrier[0]));
#endif
    
    for (i=0; i<iNumberOfLayers; i++)
    {
#if Gem5
        pmubarrier[0] = FileIO;
        asm __volatile__ (".byte 0x72; .byte 0x25; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r"(pmubarrier[2]) : "r" (pmubarrier[0]), "r" (pmubarrier[0]));
#endif
        cpu_tmp[0] = get_cpu_time();

        // Command for Start Layer (127)
        CLIFile3.read((char *)&uiCommand, sizeof(uint16));
        if (uiCommand!=127)
        {
            cout << "incorrect SLI file, error happens at command for start layer" << endl;;
            CLIFile3.close();
            return false;
        }
        
        
        CLIFile3.read((char *)&fSliceHeight, sizeof(float));
        if (fSliceHeight < 0)
        {
            cout << "incorrect SLI file, error happens at slice height" << endl;;
            CLIFile3.close();
            return false;
        }
        LayerHeights[i] = fSliceHeight;
        
        // for each layer
        NumbersOfPoints.clear();
        Orientations.clear();
        for (j=0; j<iNumberOfContours[i]; j++)
        {
            // Command for Start PolyLine 130
            CLIFile3.read((char *)&uiCommand, sizeof(uint16));
            
            if (uiCommand!=130)
            {
                cout << "incorrect SLI file, error happens at command for start poly line" << endl;;
                CLIFile3.close();
                return false;
            }
            
            // identifier 1
            // identifier to allow more than one model information in one file, here we only have 1
            CLIFile3.read((char *)&iIdentifier, sizeof(int));
            if (iIdentifier!=1)
            {
                cout << "incorrect SLI file, error happens at identifier" << endl;;
                CLIFile3.close();
                return false;
            }
            
            // orientation (0: clockwise, 1: counterclockwise, 2: open contour
            CLIFile3.read((char *)&iOrientation, sizeof(int));
            if (iOrientation!=0 && iOrientation!=1 && iOrientation!=2)
            {
                cout << "incorrect SLI file, error happens at orientation" << endl;;
                CLIFile3.close();
                return false;
            }
            Orientations.push_back(iOrientation);
            //Orientations[i][j] = 1-iOrientation;
            
            //number of points
            CLIFile3.read((char *)&iNumberOfPoints, sizeof(int));
            if (iNumberOfPoints<0)
            {
                cout << "incorrect SLI file, error happens at number of points" << endl;;
                CLIFile3.close();
                return false;
            }
            NumbersOfPoints.push_back(iNumberOfPoints);
            totalPoints += iNumberOfPoints;
            
            // read all the coordinates
            float x, y;
            
            for (k=0; k<iNumberOfPoints; k++)
            {
                CLIFile3.read((char *)&x, sizeof(float));
                CLIFile3.read((char *)&y, sizeof(float));
                data_tmp.value[0] = x*scale;
                data_tmp.value[1] = y*scale;
                data_tmp.value[2] = i*fSliceHeight*scale;
                data_in.push_back(data_tmp);
                //cout << data_tmp.value[0] << " " << data_tmp.value[1] << endl;
            }
            //cout << iNumberOfPoints << " ";
        }
        
        cpu_tmp[1] = get_cpu_time();
        cpu_yang[FileIO] += cpu_tmp[1] - cpu_tmp[0];
        
#if Gem5
        pmubarrier[0] = BlockEnd;
        asm __volatile__ (".byte 0x72; .byte 0x25; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r"(pmubarrier[2]) : "r" (pmubarrier[0]), "r" (pmubarrier[0]));
#endif
        //--------------------------------------------------------------
        // Path Planning
        //--------------------------------------------------------------
        /*for (k=0;k<img_out.width();k++)
            for (l=0;l<img_out.height();l++){
                img_out(k,l,0,0) = IMAGEINIT;
            }*/
        NumberOfContours = 0;
        data_out.clear();
        
        cout << "0Layer: " << i << " " << iNumberOfContours[i] << " " << data_in.size() << endl;
        
        path_planning.rasterization(data_in,data_out,scale,i,NumberOfContours,NumbersOfPoints,Orientations,cpu_yang);

        //cout << "1Layer: " << i << " " << NumberOfContours << " " << data_out.size() << endl;
        
        //--------------------------------------------------------------
        // show result and output
        //--------------------------------------------------------------
#if Gem5
        pmubarrier[0] = FileIO;
        asm __volatile__ (".byte 0x72; .byte 0x25; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r"(pmubarrier[2]) : "r" (pmubarrier[0]), "r" (pmubarrier[0]));
#endif
        cpu_tmp[0] = get_cpu_time();
        float x,y;
        int accumulator;
        
        Orientations.clear();
        NumbersOfPoints.clear();
        for (l=0;l<NumberOfContours;l++) {
            Orientations.push_back(0);
            NumbersOfPoints.push_back(2);
        }
        
        uiCommand = 127;
        result.write((char *)&uiCommand, sizeof(uint16));
        result.write((char *)&fSliceHeight, sizeof(float));
        accumulator = 0;
        
        for (l=0;l<NumberOfContours;l++)
        {
            uiCommand = 130;
            result.write((char *)&uiCommand, sizeof(uint16));
            iIdentifier = 1;
            result.write((char *)&iIdentifier, sizeof(int));
            result.write((char *)&Orientations[l], sizeof(int));
            result.write((char *)&NumbersOfPoints[l], sizeof(int));
            for (k=accumulator; k<accumulator+NumbersOfPoints[l]; k++)
            {
                x = (float)data_out[k].value[0]/scale;
                y = (float)data_out[k].value[1]/scale;
                result.write((char *)&x, sizeof(float));
                result.write((char *)&y, sizeof(float));
                //cout << data_out[i].value[0]*10/scale << " " << data_out[i].value[1]*10/scale << " ";
            }
            accumulator += NumbersOfPoints[l];
            //cout << y << " " << data_out[k].value[1] << endl;
        }
        
        cpu_tmp[1] = get_cpu_time();
        cpu_yang[FileIO] += cpu_tmp[1] - cpu_tmp[0];
        
#if Gem5
        pmubarrier[0] = BlockEnd;
        asm __volatile__ (".byte 0x72; .byte 0x25; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r"(pmubarrier[2]) : "r" (pmubarrier[0]), "r" (pmubarrier[0]));
#endif
        
        data_in.clear();
        //cout << z << " " << iNumberOfContours[i] << endl;
    }
    CLIFile3.close();
    
    for (i=0;i<CPU_ITEMS;i++) {
        cpu_yang[CPU_ITEMS] += cpu_yang[i];
    }
    runningtime << "PathPlanning 1 runningtime" << endl;
    for (i=0;i<CPU_ITEMS+1;i++) {
        runningtime << left << setw(15) << cpu_index[i] << " : " << setw(10) <<  cpu_yang[i] << " " <<  cpu_yang[i]/cpu_yang[CPU_ITEMS]*100 << "%" << endl;
    }
    cout << "time: " << cpu_yang[CPU_ITEMS] << endl;
    
    result.close();
    runningtime.close();
    cout << "memory footprint (kB) " << getValue() << endl;
    return 0;
}

















