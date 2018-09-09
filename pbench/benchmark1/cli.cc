
#include <math.h>
#include <iostream>
#include <fstream>
#include <string>
#include <iomanip>
#include <cstring>

using namespace std;

//--------------------------------------------------------------
// Reading CLI
//--------------------------------------------------------------

bool ReadCLI(const char * CLIFileName)
{
    typedef unsigned short uint16;
    int i, j, k;
    
    const int fillsize = 30;
    char filling[fillsize];
    uint16 uiCommand;
    float fSliceHeight;
    int iIdentifier;
    int iOrientation;
    int iNumberOfPoints;
    int iNumberOfLayers;
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
    cout << filling << endl;
    CLIFile1.read(filling, 9);
    cout << filling << endl;
    CLIFile1.read(filling, 11);
    cout << filling << endl;
    CLIFile1.read(filling, 14);
    cout << filling << endl;
    CLIFile1.read(filling, 16);
    cout << filling << endl;
    CLIFile1.read(filling, 11);
    cout << filling << endl;
    
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
            cout << "iOrientation " << iOrientation << endl;
            //number of points
            CLIFile1.read((char *)&iNumberOfPoints, sizeof(int));
            if (iNumberOfPoints<0)
            {
                cout << "incorrect CLI file, error happens at number of points" << endl;;
                CLIFile1.close();
                return false;
            }
            cout << "iNumberOfPoints " << iNumberOfPoints << endl;
            // read all the coordinates
            float x, y;
            
            for (i=0; i<iNumberOfPoints; i++)
            {
                CLIFile1.read((char *)&x, sizeof(float));
                CLIFile1.read((char *)&y, sizeof(float));
            }
            cout << x << " " << y << endl;
        }
        iNumberOfLayers++;
    }
    cout << "iNumberOfLayers " << iNumberOfLayers << endl;
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
            
            // read all the coordinates
            float x, y;
            
            for (i=0; i<iNumberOfPoints; i++)
            {
                CLIFile2.read((char *)&x, sizeof(float));
                CLIFile2.read((char *)&y, sizeof(float));
            }
            iNumberOfContours[layerindex]++;
        }
        layerindex++;
    }
    CLIFile2.close();
    
    
    // third scan to get all the coordinates and orientations
    // layer index
    // height
    // number of contours
    //		orientation, #points, x, y
    // space
    float* LayerHeights = new float[iNumberOfLayers];
    int** NumbersOfPoints = new int *[iNumberOfLayers];
    int** Orientations = new int*[iNumberOfLayers];
    int totalPoints = 0;
    float*** XCoordinates = new float **[iNumberOfLayers];
    float*** YCoordinates = new float **[iNumberOfLayers];
    for (i=0; i<iNumberOfLayers; i++)
    {
        XCoordinates[i] = new float*[iNumberOfContours[i]];
        YCoordinates[i] = new float*[iNumberOfContours[i]];
        NumbersOfPoints[i] = new int[iNumberOfContours[i]];
        Orientations[i]  = new int[iNumberOfContours[i]];
    }
    
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
    
    for (i=0; i<iNumberOfLayers; i++)
    {
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
            Orientations[i][j] = iOrientation;
            //Orientations[i][j] = 1-iOrientation;
            
            //number of points
            CLIFile3.read((char *)&iNumberOfPoints, sizeof(int));
            if (iNumberOfPoints<0)
            {
                cout << "incorrect SLI file, error happens at number of points" << endl;;
                CLIFile3.close();
                return false;
            }
            XCoordinates[i][j] = new float[iNumberOfPoints];
            YCoordinates[i][j] = new float[iNumberOfPoints];
            NumbersOfPoints[i][j] = iNumberOfPoints;
            totalPoints += iNumberOfPoints;
            
            // read all the coordinates
            float x, y;
            
            for (k=0; k<iNumberOfPoints; k++)
            {
                CLIFile3.read((char *)&x, sizeof(float));
                CLIFile3.read((char *)&y, sizeof(float));
                XCoordinates[i][j][k] = x;
                YCoordinates[i][j][k] = y;
            }
        }
    }
    CLIFile3.close();
    
    // scale and translate the contours for display
    /*
     PartExt[0][0] = PartExt[1][0] = 1e8;
     PartExt[0][1] = PartExt[1][1] = -1e8;
     for (i=0; i<iNumberOfLayers; i++)
     {
     if (i==0)
     {
     PartExt[2][0] = LayerHeights[i];
     PartExt[2][1] = LayerHeights[i];
     }
     else
     {
     if (LayerHeights[i] < PartExt[2][0])
     PartExt[2][0] =  LayerHeights[i];
     if (LayerHeights[i] > PartExt[2][1])
     PartExt[2][1] =  LayerHeights[i];
     }
     for (j=0; j<iNumberOfContours[i]; j++)
     {
     for (k=0; k<NumbersOfPoints[i][j]; k++)
     {
     if (XCoordinates[i][j][k] < PartExt[0][0])
     PartExt[0][0] = XCoordinates[i][j][k];
     if (XCoordinates[i][j][k] > PartExt[0][1])
     PartExt[0][1] = XCoordinates[i][j][k];
     
     if (YCoordinates[i][j][k] < PartExt[1][0])
     PartExt[1][0] = YCoordinates[i][j][k];
     if (YCoordinates[i][j][k] > PartExt[1][1])
     PartExt[1][1] = YCoordinates[i][j][k];
     }
     }
     }
     PartExt[0][2] = PartExt[0][1] - PartExt[0][0];
     PartExt[1][2] = PartExt[1][1] - PartExt[1][0];
     float maxsize;
     if (PartExt[0][2]>PartExt[1][2])
     maxsize = PartExt[0][2];
     else
     maxsize = PartExt[1][2];
     
     // put the contour in the center of the platform
     double offsetx = (PlatformX-PartExt[0][2])/2;
     double offsety = (PlatformY-PartExt[1][2])/2;
     
     for (i=0; i<iNumberOfLayers; i++)
     {
     for (j=0; j<iNumberOfContours[i]; j++)
     {
     for (k=0; k<NumbersOfPoints[i][j]; k++)
     {
     XCoordinates[i][j][k] += (offsetx-PartExt[0][0]);
     YCoordinates[i][j][k] += (offsety-PartExt[1][0]);
     }
     }
     LayerHeights[i] -= PartExt[2][0];
     }
     
     PartExt[0][0] = offsetx;
     PartExt[0][1] = offsetx + PartExt[0][2];
     PartExt[1][0] = offsety;
     PartExt[1][1] = offsety + PartExt[1][2];
     
     double marginx = (PixelCenterPositionX[0][ImageSizeX-1]-PixelCenterPositionX[0][0])*0.01;
     double marginy = (PixelCenterPositionY[ImageSizeY-1][0]-PixelCenterPositionY[0][0])*0.01;
     if (PartExt[0][0]+(offsetx-PartExt[0][0])<PixelCenterPositionX[0][0]+marginx || PartExt[0][1]+(offsetx-PartExt[0][0])>(PixelCenterPositionX[0][ImageSizeX-1]-marginx) ||
     PartExt[1][0]+(offsety-PartExt[1][0])<PixelCenterPositionY[0][0]+marginy || PartExt[1][1]+(offsety-PartExt[1][0])>(PixelCenterPositionY[ImageSizeY-1][0]-marginy))
     {
     cout << "the part is too close to the boundary" << endl;;
     return false;
     }
     */
    return true;
}

bool writeCLI(const char* CLIFileName)
{
    typedef unsigned short uint16;
    int i, j, k;
    
    const int fillsize = 30;
    /*
    char filling1[14] = "$$HEADERSTART";
    char filling2[9] = "$$BINARYTART";
    char filling3[11] = "$$UNITS/1";
    char filling4[14] = "$$VERSION/200";
    char filling5[16] = "$$LABEL/1,part1";
    char filling6[11] = "$$HEADERENDart1";
    */
    char filling1[14] = "$$HEADERSTART";
    char filling2[13] = "$$BINARYTART";
    char filling3[10] = "$$UNITS/1";
    char filling4[14] = "$$VERSION/200";
    char filling5[16] = "$$LABEL/1,part1";
    char filling6[16] = "$$HEADERENDart1";
    
    uint16 uiCommand;
    float fSliceHeight;
    int iIdentifier;
    int iOrientation;
    int iNumberOfPoints;
    int iNumberOfLayers;
    
    //FreeCLI();
    iNumberOfLayers = 10;
    // first scan to get the number of layers
    ofstream CLIFile1;
    CLIFile1.open(CLIFileName, ofstream::out|ofstream::binary);
    if (! CLIFile1.is_open())
    {
        cout << "error " << endl;
        return false;
    }
    
    CLIFile1.write(filling1, 14);
    CLIFile1.write(filling2, 9);
    CLIFile1.write(filling3, 11);
    CLIFile1.write(filling4, 14);
    CLIFile1.write(filling5, 16);
    CLIFile1.write(filling6, 11);
    
    uiCommand = 127;
    CLIFile1.write((char *)&uiCommand, sizeof(uint16));
    
    fSliceHeight = 1;
    CLIFile1.write((char *)&fSliceHeight, sizeof(float));
    
    // Command for Start PolyLine 130
    uiCommand = 130;
    CLIFile1.write((char *)&uiCommand, sizeof(uint16));
    
    // identifier 1
    // identifier to allow more than one model information in one file, here we only have 1
    iIdentifier = 1;
    CLIFile1.write((char *)&iIdentifier, sizeof(int));
    // orientation (0: clockwise, 1: counterclockwise, 2: open contour
    iOrientation = 0;
    CLIFile1.write((char *)&iOrientation, sizeof(int));
    
    //number of points
    iNumberOfPoints = 20;
    CLIFile1.write((char *)&iNumberOfPoints, sizeof(int));
    
    // write all the coordinates
    float x, y;
    x = 1;
    y = 1;
    for (i=0; i<iNumberOfPoints; i++)
    {
        CLIFile1.write((char *)&x, sizeof(float));
        CLIFile1.write((char *)&y, sizeof(float));
    }
    
    CLIFile1.close();
    
    return true;
}

int main(){
    writeCLI("try.cli");
    ReadCLI("cyliners.cli");
    return 0;
}


