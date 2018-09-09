//--------------------------------------------------------------
// Path Planning
//--------------------------------------------------------------

#include <math.h>
#include <iostream>
#include <fstream>
#include <string>
#include <iomanip>
#include "clipper.hpp"
#include "pathp_algorithm2.hh"

#include "stdlib.h"
#include "stdio.h"
#include "string.h"

using namespace std;
using namespace ClipperLib;

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
// main
//--------------------------------------------------------------

int main(int argc, char* argv[])
{
    
    if (argc < 2){
        cout << "Usage: pathp slicingresult " << endl;
        return -1;
    }
    cout << "Input file: " << argv[1] << endl;
    
    float radius = 0.1;
    //radius = (float)(*argv[2] - '0');
    //radius = radius * (-0.01);
    
    typedef unsigned short uint16;
    int scale = SCALE;
    int step;
    radius *= scale;
    
    ofstream result("result/SlicingResultAlgorithm2.cli");
    const char *CLIFileName = argv[1];
    //const char *CLIFileName = "result/SlicingResult.cli"
    //const char *CLIFileName = "../arm_binary/3d_printing_benchmark/SlicingResult.cli";
    //const char *CLIFileName = "SlicingResult.cli";
    
    ofstream runningtime;
    runningtime.open("result/RunningTime.txt", ofstream::out|ofstream::binary);
    //int layer;
    //layer = LAYER;

    Path OriginalContour;
    cInt a,b;
    ClipperOffset contourOffset;
    Paths offsetContour;

    int i, j, k,l;
    i = 0;
    k = 0;

#define CPU_ITEMS 3
    double cpu_yang[CPU_ITEMS+1];
    double cpu_tmp[2];
    string cpu_index[CPU_ITEMS+1] = {"Read CLI","CtourOffset","Write CLI","Total"};
    for (i=0;i<CPU_ITEMS+1;i++)
        cpu_yang[i] = CPU_INIT;
    
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
    int accumulator;
    //int *iNumberOfContours;
    
    iNumberOfLayers = 0;
    // first scan to get the number of layers
    ifstream CLIFile1;
    CLIFile1.open(CLIFileName, ifstream::in|ifstream::binary);
    if (! CLIFile1.is_open())
    {
        cout << "Error opening file" << endl;;
        return false;
    }
    memset(filling, 0, fillsize);
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
    memset(filling, 0, fillsize);
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
    
    memset(filling, 0, fillsize);
    CLIFile3.seekg(0, ios::beg);
    CLIFile3.read(filling, 14);
    CLIFile3.read(filling, 9);
    CLIFile3.read(filling, 11);
    CLIFile3.read(filling, 14);
    CLIFile3.read(filling, 16);
    CLIFile3.read(filling, 11);
  
    cpu_tmp[1] = get_cpu_time();
    cpu_yang[0] += cpu_tmp[1] - cpu_tmp[0];
    
    for (i=0; i<iNumberOfLayers; i++)
    {
        // yang debug
        //cout << "iNumberOfContours " << i << " " << iNumberOfContours[i] << endl;

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
            cpu_tmp[0] = get_cpu_time();
            
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
                
                a = x*scale;
                b = y*scale;
                OriginalContour << IntPoint(a,b);
            }
            cpu_tmp[1] = get_cpu_time();
            cpu_yang[0] += cpu_tmp[1] - cpu_tmp[0];
            
            cpu_tmp[0] = get_cpu_time();
            if (OriginalContour.size())
                contourOffset.AddPath(OriginalContour, jtRound, etClosedPolygon);
            cpu_tmp[1] = get_cpu_time();
            cpu_yang[1] += cpu_tmp[1] - cpu_tmp[0];
            
            OriginalContour.clear();
        }
        
        //--------------------------------------------------------------
        // Path Planning
        //--------------------------------------------------------------

        cout << "Layer: " << i << " " << iNumberOfContours[i] << endl;
        
        cpu_tmp[0] = get_cpu_time();
        offsetContour.clear();
        contourOffset.Execute(offsetContour, radius);
	//cout << offsetContour.size() << endl;
        cpu_tmp[1] = get_cpu_time();
        cpu_yang[1] += cpu_tmp[1] - cpu_tmp[0];
        
        //cout << "one " << NumbersOfPoints.size() << " " << iNumberOfContours[i] << endl;
        //--------------------------------------------------------------
        // show result and output
        //--------------------------------------------------------------
        cpu_tmp[0] = get_cpu_time();
        uiCommand = 127;
        result.write((char *)&uiCommand, sizeof(uint16));
        result.write((char *)&fSliceHeight, sizeof(float));
        accumulator = 0;
        float x,y;
        /*
        for (l=0;l<iNumberOfContours[i];l++)
        {
            //cout << endl;
            //cout << " contours: " << l << " " << NumbersOfPoints[l] << " " << offsetContour[l].size() << " " << endl;
            uiCommand = 130;
            result.write((char *)&uiCommand, sizeof(uint16));
            iIdentifier = 1;
            result.write((char *)&iIdentifier, sizeof(int));
            result.write((char *)&Orientations[l], sizeof(int));
            result.write((char *)&NumbersOfPoints[l], sizeof(int));
            //cout << " please " << endl;
            for (k=accumulator; k<accumulator+NumbersOfPoints[l]; k++)
            {
                //cout << k << " ";
                x = (float)offsetContour[l][k-accumulator].X/scale;
                y = (float)offsetContour[l][k-accumulator].Y/scale;
                result.write((char *)&x, sizeof(float));
                result.write((char *)&y, sizeof(float));
            }
            accumulator += NumbersOfPoints[l];
            //cout << endl;
            //cout << " accumulator " << accumulator << endl;
        }
        */
        cpu_tmp[1] = get_cpu_time();
        cpu_yang[2] += cpu_tmp[1] - cpu_tmp[0];

        contourOffset.Clear();
        //cout << "two" << endl;
    }
    CLIFile3.close();
    result.close();
    
    for (i=0;i<CPU_ITEMS;i++) {
        cpu_yang[CPU_ITEMS] += cpu_yang[i];
    }
    runningtime << "PathPlanning 2 runningtime" << endl;
    for (i=0;i<CPU_ITEMS+1;i++) {
        runningtime << left << setw(15) << cpu_index[i] << " : " << setw(10) <<  cpu_yang[i] << " " <<  cpu_yang[i]/cpu_yang[CPU_ITEMS]*100 << "%" << endl;
    }
    cout << "time: " << cpu_yang[CPU_ITEMS] << endl;
    
    runningtime.close();
    cout << "memory footprint (kB) " << getValue() << endl;
    return 0;
}














