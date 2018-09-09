//--------------------------------------------------------------
// Support Generation
//--------------------------------------------------------------

#include <math.h>
#include <iostream>
#include <fstream>
#include <string>
#include <iomanip>
#include <sstream>
#include <string>
#include "CImg.h"
#include "ofs.hh"

using namespace std;
using namespace cimg_library;

int main()
{

    typedef unsigned short uint16;
    int scale = SCALE;
    float grid = (float)FACTORWIDTH/IMAGEWIDTH;
    int step;
    ofstream runningtime;
    const char *CLIFileName = "result/PathPResult.cli";
    runningtime.open("result/RunningTime.txt", ios_base::app);
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
    string cpu_index[CPU_ITEMS+1] = {"Read CLI","Intersection","Sort","Img_line","Save Img","Total"};
    for (i=0;i<CPU_ITEMS+1;i++)
        cpu_yang[i] = CPU_INIT;
    
    //bool image_curr[IMAGEHEIGHT][IMAGEWIDTH];
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
        cpu_yang[0] += cpu_tmp[1] - cpu_tmp[0];
        
        //--------------------------------------------------------------
        // Path Planning
        //--------------------------------------------------------------
        CImg<unsigned int> img_out(IMAGEWIDTH,IMAGEHEIGHT,1,1,0);
        for (k=0;k<img_out.width();k++)
         for (l=0;l<img_out.height();l++){
             img_out(k,l,0,0) = 255;
         }
        NumberOfContours = 0;
        data_out.clear();
        
        cout << "Layer: " << i << " " << iNumberOfContours[i] << " " << data_in.size() << endl;
        
        
        //--------------------------------------------------------------
        // show result and output
        //--------------------------------------------------------------
        cpu_tmp[0] = get_cpu_time();

        int coordinate_y;
        int coordinate_x[2];
        for (k=0;k<data_in.size()/2;k++) {
            coordinate_y = (data_in[k*2].value[1]/grid)/scale;
            //cout << coordinate_y << " " << data_in[k*2].value[1] << endl;
            
            if (data_in[k*2].value[0] < data_in[k*2+1].value[0]) {
                coordinate_x[0] = (data_in[k*2].value[0]/grid)/scale;
                coordinate_x[1] = (data_in[k*2+1].value[0]/grid)/scale;
            }
            else {
                coordinate_x[0] = (data_in[k*2+1].value[0]/grid)/scale;
                coordinate_x[1] = (data_in[k*2].value[0]/grid)/scale;
            }
            
            for (l=coordinate_x[0];l<coordinate_x[1];l++) {
                img_out(l,coordinate_y,0,0) = 0;
            }
        }
        img_out.save("result/int_image.bmp",i);
        
        cpu_tmp[1] = get_cpu_time();
        cpu_yang[4] += cpu_tmp[1] - cpu_tmp[0];
        
        data_in.clear();
        
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
    
    runningtime.close();
    
    return 0;
}
















