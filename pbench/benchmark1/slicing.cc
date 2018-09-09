//--------------------------------------------------------------
// Slicing Functions
//--------------------------------------------------------------

#include <math.h>
#include <iostream>
#include <fstream>
#include <string>
#include <iomanip>
#include <cstring>
#include <math.h>
#include "ofs.hh"
#include "slicing.hh"

using namespace std;

//--------------------------------------------------------------
// Triangle Plane Position
//--------------------------------------------------------------

void Slicing::intersections(vector<Data>& data_in, int z, vector<Data>& data_out, int *contour_points)
{
    intersection = 0;
    group = data_in.size()/DIMENSION;
    //cout << group << endl;
    
    int ind_out = 0;
    Data *data_tmp_1 = new Data[DIMENSION];
    Data *data_tmp_2 = new Data[DIMENSION];
    for (i=0;i<group;i++)
    {
        point = DIMENSION*i;
        //intersection = 2*i;
        
        // decide what triangle plane position it is
        
        if (data_in[point].value[2] > z)
        {
            if (data_in[point+1].value[2] > z)
            {
                if (data_in[point+2].value[2] > z)
                {
                    tp_case = 4;  // all 3 above plane
                }
                else
                {
                    if (data_in[point+2].value[2] == z)
                    {
                        tp_case = 5;
                    }
                    else
                    {
                        tp_case = 3;   // 2 above 1 below
                        data_tmp_1[2] = data_in[point];
                        data_tmp_1[1] = data_in[point+1];
                        data_tmp_1[0] = data_in[point+2];
                    }
                }
            }
            else
            {
                if (data_in[point+1].value[2] == z)
                {
                    if (data_in[point+2].value[2] > z)
                    {
                        tp_case = 5;
                    }
                    else
                    {
                        if (data_in[point+2].value[2] == z)
                        {
                            tp_case = 6;
                            data_tmp_1[1] = data_in[point+1];
                            data_tmp_1[0] = data_in[point+2];
                        }
                        else
                        {
                            tp_case = 2;
                            data_tmp_1[2] = data_in[point+1];
                            data_tmp_1[1] = data_in[point];
                            data_tmp_1[0] = data_in[point+2];
                        }
                    }
                }
                else
                {
                    if (data_in[point+2].value[2] > z)
                    {
                        tp_case = 3;
                        data_tmp_1[1] = data_in[point];
                        data_tmp_1[0] = data_in[point+1];
                        data_tmp_1[2] = data_in[point+2];
                    }
                    else
                    {
                        if (data_in[point+2].value[2] == z)
                        {
                            tp_case = 2;
                            data_tmp_1[2] = data_in[point+2];
                            data_tmp_1[1] = data_in[point+1];
                            data_tmp_1[0] = data_in[point];
                        }
                        else
                        {
                            tp_case = 1;
                            data_tmp_1[0] = data_in[point];
                            data_tmp_1[1] = data_in[point+1];
                            data_tmp_1[2] = data_in[point+2];
                        }
                    }
                }
            }
            
        }
        else
        {
            if (data_in[point].value[2] == z)    // data_in[point].value[2] == z
            {
                {
                    if (data_in[point+1].value[2] > z)
                    {
                        if (data_in[point+2].value[2] > z)
                        {
                            tp_case = 5;
                        }
                        else
                        {
                            if (data_in[point+2].value[2] == z)
                            {
                                tp_case = 6;
                                data_tmp_1[1] = data_in[point];
                                data_tmp_1[0] = data_in[point+2];
                            }
                            else
                            {
                                tp_case = 2;
                                data_tmp_1[2] = data_in[point];
                                data_tmp_1[1] = data_in[point+1];
                                data_tmp_1[0] = data_in[point+2];
                            }
                        }
                    }
                    else
                    {
                        if (data_in[point+1].value[2] == z)
                        {
                            tp_case = 6;
                            data_tmp_1[1] = data_in[point+1];
                            data_tmp_1[0] = data_in[point];
                        }
                        else
                        {
                            if (data_in[point+2].value[2] > z)
                            {
                                tp_case = 2;
                                data_tmp_1[2] = data_in[point];
                                data_tmp_1[1] = data_in[point+1];
                                data_tmp_1[0] = data_in[point+2];
                            }
                            else
                            {
                                if (data_in[point+2].value[2] == z)
                                {
                                    tp_case = 6;
                                    data_tmp_1[1] = data_in[point];
                                    data_tmp_1[0] = data_in[point+2];
                                }
                                else
                                {
                                    tp_case = 5;
                                }
                            }
                        }
                    }
                    
                }
                
            }
            else    // data_in[point].value[2] < z
            {
                if (data_in[point+1].value[2] > z)
                {
                    if (data_in[point+2].value[2] > z)
                    {
                        tp_case = 3;
                        data_tmp_1[0] = data_in[point];
                        data_tmp_1[1] = data_in[point+1];
                        data_tmp_1[2] = data_in[point+2];
                        
                    }
                    else
                    {
                        if (data_in[point+2].value[2] == z)
                        {
                            tp_case = 2;
                            data_tmp_1[2] = data_in[point+2];
                            data_tmp_1[1] = data_in[point+1];
                            data_tmp_1[0] = data_in[point];
                        }
                        else
                        {
                            tp_case = 1;
                            data_tmp_1[2] = data_in[point];
                            data_tmp_1[0] = data_in[point+1];
                            data_tmp_1[1] = data_in[point+2];
                        }
                    }
                }
                else
                {
                    if (data_in[point+1].value[2] == z)
                    {
                        if (data_in[point+2].value[2] > z)
                        {
                            tp_case = 2;
                            data_tmp_1[2] = data_in[point+1];
                            data_tmp_1[1] = data_in[point];
                            data_tmp_1[0] = data_in[point+2];
                        }
                        else
                        {
                            if (data_in[point+2].value[2] == z)
                            {
                                tp_case = 6;
                                data_tmp_1[1] = data_in[point+1];
                                data_tmp_1[0] = data_in[point+2];
                            }
                            else
                            {
                                tp_case = 5;
                            }
                        }
                    }
                    else
                    {
                        if (data_in[point+2].value[2] > z)
                        {
                            tp_case = 1;
                            data_tmp_1[2] = data_in[point];
                            data_tmp_1[1] = data_in[point+1];
                            data_tmp_1[0] = data_in[point+2];
                        }
                        else
                        {
                            if (data_in[point+2].value[2] == z)
                            {
                                tp_case = 5;
                            }
                            else
                            {
                                tp_case = 4;
                            }
                        }
                    }
                }
            }
        }
        
        //cout << i << endl;
        switch (tp_case)
        {
            case 1:
                data_tmp_2[0].value[0] = (z - data_tmp_1[0].value[2])*(data_tmp_1[1].value[0] - data_tmp_1[0].value[0])/(data_tmp_1[1].value[2] - data_tmp_1[0].value[2]) + data_tmp_1[0].value[0];
                // y0
                data_tmp_2[0].value[1] = (z - data_tmp_1[0].value[2])*(data_tmp_1[1].value[1] - data_tmp_1[0].value[1])/(data_tmp_1[1].value[2] - data_tmp_1[0].value[2]) + data_tmp_1[0].value[1];
                // z0
                data_tmp_2[0].value[2] = z;
                // x1
                data_tmp_2[1].value[0] = (z - data_tmp_1[0].value[2])*(data_tmp_1[2].value[0] - data_tmp_1[0].value[0])/(data_tmp_1[2].value[2] - data_tmp_1[0].value[2]) + data_tmp_1[0].value[0];
                // y1
                data_tmp_2[1].value[1] = (z - data_tmp_1[0].value[2])*(data_tmp_1[2].value[1] - data_tmp_1[0].value[1])/(data_tmp_1[2].value[2] - data_tmp_1[0].value[2]) + data_tmp_1[0].value[1];
                // z1
                data_tmp_2[1].value[2] = z;
                intersection += 1;
                data_out.push_back(data_tmp_2[0]);
                data_out.push_back(data_tmp_2[1]);
                break;
            case 2:
                data_tmp_2[0].value[0] = (z - data_tmp_1[0].value[2])*(data_tmp_1[1].value[0] - data_tmp_1[0].value[0])/(data_tmp_1[1].value[2] - data_tmp_1[0].value[2]) + data_tmp_1[0].value[0];
                // y0
                data_tmp_2[0].value[1] = (z - data_tmp_1[0].value[2])*(data_tmp_1[1].value[1] - data_tmp_1[0].value[1])/(data_tmp_1[1].value[2] - data_tmp_1[0].value[2]) + data_tmp_1[0].value[1];
                // z0
                data_tmp_2[0].value[2] = z;
                // x1
                data_tmp_2[1] = data_tmp_1[2];
                intersection += 1;
                data_out.push_back(data_tmp_2[0]);
                data_out.push_back(data_tmp_2[1]);
                break;
            case 3:
                data_tmp_2[0].value[0] = (z - data_tmp_1[0].value[2])*(data_tmp_1[1].value[0] - data_tmp_1[0].value[0])/(data_tmp_1[1].value[2] - data_tmp_1[0].value[2]) + data_tmp_1[0].value[0];
                // y0
                data_tmp_2[0].value[1] = (z - data_tmp_1[0].value[2])*(data_tmp_1[1].value[1] - data_tmp_1[0].value[1])/(data_tmp_1[1].value[2] - data_tmp_1[0].value[2]) + data_tmp_1[0].value[1];
                // z0
                data_tmp_2[0].value[2] = z;
                // x1
                data_tmp_2[1].value[0] = (z - data_tmp_1[0].value[2])*(data_tmp_1[2].value[0] - data_tmp_1[0].value[0])/(data_tmp_1[2].value[2] - data_tmp_1[0].value[2]) + data_tmp_1[0].value[0];
                
                // y1
                data_tmp_2[1].value[1] = (z - data_tmp_1[0].value[2])*(data_tmp_1[2].value[1] - data_tmp_1[0].value[1])/(data_tmp_1[2].value[2] - data_tmp_1[0].value[2]) + data_tmp_1[0].value[1];
                // z1
                data_tmp_2[1].value[2] = z;
                intersection += 1;
                data_out.push_back(data_tmp_2[0]);
                data_out.push_back(data_tmp_2[1]);
                break;
            case 4:
                break;
            case 5:
                break;
            case 6:
                data_tmp_2[0] = data_tmp_1[0];
                data_tmp_2[1] = data_tmp_1[1];
                intersection += 1;
                data_out.push_back(data_tmp_2[0]);
                data_out.push_back(data_tmp_2[1]);
                break;
            default:
                cout << "error: triangle plane position error" << endl;
        }
        
    }
    
    delete[] data_tmp_1;
    delete[] data_tmp_2;
    *contour_points = intersection*2;
}
    
//--------------------------------------------------------------
// Contour Generation
//--------------------------------------------------------------

void Slicing::contourgene(vector<Data>& data_out,int &iNumberOfContours,vector<int>& iOrientation,vector<int>& iNumberOfPoints,int& locality_distance)
{
    //--------------------------------------------------------------
    // Method 1
    //--------------------------------------------------------------
    
    int counter;
    int reserve;
    Data data_tmp_1[2];
    Data data_tmp_2[intersection*2];
    
    for(i=0;i<intersection*2;i++)
    {
        data_tmp_2[i] = data_out[i];
    }
    
    data_out.clear();
    iNumberOfContours = 0;
    iNumberOfPoints.clear();
    iOrientation.clear();
    reserve = 0;
    tmp_pointback = 0;
    counter = 0;
    
    for(j=0;j<intersection;j++)
    {
        distance2 = DISTANCEINIT;
        int_tmp = -1;
        
        for (i=j*2+2;i<intersection*2;i++)
        {
            distance1 = sqrt(pow((data_tmp_2[i].value[0] - data_tmp_2[j*2+1].value[0]),2) + pow((data_tmp_2[i].value[1] - data_tmp_2[j*2+1].value[1]),2));
            if (distance1 < distance2)
            {
                distance2 = distance1;
                int_tmp = i;
            }
        }
        
        distance1 = sqrt(pow((data_tmp_2[reserve*2].value[0] - data_tmp_2[j*2+1].value[0]),2) + pow((data_tmp_2[reserve*2].value[1] - data_tmp_2[j*2+1].value[1]),2));
        if (distance1 < distance2)
        {
            distance2 = distance1;
            int_tmp = reserve*2;
        }
        
        if (int_tmp == reserve*2)     // one closed contour is found
        {
            iOrientation.push_back(0);
            iNumberOfPoints.push_back(j+1-reserve);
            //cout << reserve << " " << j+1 << endl;
            
            for (k=reserve;k<j+1;k++)
                data_out.push_back(data_tmp_2[k*2]);
            reserve = j+1;
            iNumberOfContours++;
            continue;
        }
        
        if (int_tmp%2 == 0) // it's even, means the direction is correct
        {
            data_tmp_1[0] = data_tmp_2[int_tmp];
            data_tmp_1[1] = data_tmp_2[int_tmp+1];
            data_tmp_2[int_tmp] = data_tmp_2[j*2+2];
            data_tmp_2[int_tmp+1] = data_tmp_2[j*2+3];
            data_tmp_2[j*2+2] = data_tmp_1[0];
            data_tmp_2[j*2+3] = data_tmp_1[1];
        }
        else   // we need to exchange the head and tail only for behinds
        {
            data_tmp_1[0] = data_tmp_2[int_tmp-1];
            data_tmp_1[1] = data_tmp_2[int_tmp];
            data_tmp_2[int_tmp-1] = data_tmp_2[j*2+2];
            data_tmp_2[int_tmp] = data_tmp_2[j*2+3];
            data_tmp_2[j*2+2] = data_tmp_1[0];
            data_tmp_2[j*2+3] = data_tmp_1[1];
        }
    }

    //--------------------------------------------------------------
    // Method 2
    //--------------------------------------------------------------
    /*
    int data_use[intersection];
    int counter;
    Data data_tmp_2[intersection*2];
    Data data_tmp_3[intersection];
    for(i=0;i<intersection*2;i++)
    {
        data_tmp_2[i] = data_out[i];
    }
    iNumberOfContours = 0;
    iNumberOfPoints.clear();
    iOrientation.clear();
    for (j=0;j<intersection;j++)
        data_use[j] = 0;
    data_tmp_3[0] = data_tmp_2[0];
    data_tmp_3[1] = data_tmp_2[1];
    data_use[0] = 1;
    tmp_pointback = 0;
    counter = 0;
    locality_distance = 0;
    for(j=2;j<intersection;j++)     // previously: j=0, all other j+2
    {
        point = j*2;
        distance2 = DISTANCEINIT;
        int_tmp = 0;
        for (i=0;i<intersection*2;i++)
        {
            if ((i != tmp_pointback*2+1)&&(i != tmp_pointback*2))
            {
                distance1 = sqrt(pow((data_tmp_2[i].value[0] - data_tmp_3[j-1].value[0]),2) + pow((data_tmp_2[i].value[1] - data_tmp_3[j-1].value[1]),2));
                
                if (distance1 < distance2)
                {
                    distance2 = distance1;
                    int_tmp = i;
                    //if (distance2 <= DIST_TH)
                    //    break;
                }
            }
        }
        counter++;
        locality_distance += abs(int_tmp/2 - tmp_pointback);
        //cout << abs(int_tmp/2 - tmp_pointback) << " ";
        //cout << distance2 << endl;

        if (data_use[int_tmp/2] == 1){
            iNumberOfContours += 1;
            iNumberOfPoints.push_back(counter);
            // orientation (0: clockwise, 1: counterclockwise, 2: open contour
            iOrientation.push_back(0);
            counter = 0;
            
            for (k=0;k<intersection;k++){
                if (data_use[k] == 0)
                    break;
            }
            data_tmp_3[j-1] = data_tmp_2[k*2];
            data_tmp_3[j] = data_tmp_2[k*2+1];
            data_use[k] = 1;
            tmp_pointback = k;
            
            continue;
        }
        //cout << iNumberOfContours << endl;
        
        if (int_tmp%2 == 0) // it's even, means the direction is correct
        {
            data_tmp_3[j] = data_tmp_2[int_tmp+1];
            data_use[int_tmp/2] = 1;
            tmp_pointback = int_tmp/2;
        }
        else   // we need to exchange the head and tail only for behinds
        {
            data_tmp_3[j] = data_tmp_2[int_tmp-1];
            data_use[int_tmp/2] = 1;
            tmp_pointback = int_tmp/2;
        }
        
        if (j==intersection-1){
            iNumberOfContours++;
            iNumberOfPoints.push_back(counter);
            iOrientation.push_back(0);
            counter = 0;
        }
    }
    //cout << endl;
    //cout << "intersection " << intersection << " " << counter << " " << iNumberOfContours << endl;
    
    if (intersection > 0)
        locality_distance = locality_distance/intersection;
    //cout << locality_distance << endl;

    data_out.clear();
    for (i=0;i<intersection;i++)
    {
        data_out.push_back(data_tmp_3[i]);
    }
    */
    //--------------------------------------------------------------
    // Method 3: Distance Queue
    //--------------------------------------------------------------
   
    /* 
    int data_use[intersection];
    int counter;
    Data data_tmp_2[intersection*2];
    Data data_tmp_3[intersection];
    for(i=0;i<intersection*2;i++)
    {
        data_tmp_2[i] = data_out[i];
    }
    
    int index[intersection*6];
    int halfsize = 100;
    int sizetmp;
    int tmp1,tmp2,tmp3,tmp4,tmp_direction,tmp_pointer,tmp_pointback,tmp_connection,not_connect;
    int final = -1;
    int clear = -2;
    int ind_out = 0;
    not_connect = 0;
    int next1[intersection],next2[intersection];
    int connection1[intersection],connection2[intersection];
    int direction1[intersection],direction2[intersection];
    
    for (i=0;i<intersection*6;i++)
        index[i] = i;
    //cout << "intersection " << intersection << endl;
    // carefully schedule input & output
    
    cout << "choosing DQ iteration " << intersection << " " << halfsize*2 << endl;
    asm __volatile__ (".byte 0x72; .byte 0x22; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r" (ind_out) : "r" (index[0]), "r" (clear));
    
    if (intersection < halfsize*2){
        for (j=0;j<intersection;j++)
        {
            tmp1 = data_tmp_2[j*2].value[0];
            tmp2 = data_tmp_2[j*2].value[1];
            tmp3 = data_tmp_2[j*2+1].value[0];
            tmp4 = data_tmp_2[j*2+1].value[1];
            //cout << index[j*4] << " " << data_tmp_2[j*2].value[0] << endl;
     
            asm __volatile__ (".byte 0x72; .byte 0x22; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r" (ind_out) : "r" (index[j*4]), "r" (tmp1));
            asm __volatile__ (".byte 0x72; .byte 0x22; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r" (ind_out) : "r" (index[j*4+1]), "r" (tmp2));
            asm __volatile__ (".byte 0x72; .byte 0x22; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r" (ind_out) : "r" (index[j*4+2]), "r" (tmp3));
            asm __volatile__ (".byte 0x72; .byte 0x22; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r" (ind_out) : "r" (index[j*4+3]), "r" (tmp4));
        }
     
        asm __volatile__ (".byte 0x72; .byte 0x22; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r" (ind_out) : "r" (index[j*4]), "r" (final));
        //cout << "finish input" << endl;
        for (j=0;j<intersection;j++)
        {
            asm __volatile__ (".byte 0x72; .byte 0x24; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r" (next1[j]) : "r" (index[j*6]), "r" (ind_out));
            //cout << "data_index_1[j].pointer" << " " << data_index_1[j].pointer << endl;
            asm __volatile__ (".byte 0x72; .byte 0x24; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r" (next2[j]) : "r" (index[j*6+1]), "r" (ind_out));
            asm __volatile__ (".byte 0x72; .byte 0x24; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r" (connection1[j]) : "r" (index[j*6+2]), "r" (ind_out));
            asm __volatile__ (".byte 0x72; .byte 0x24; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r" (connection2[j]) : "r" (index[j*6+3]), "r" (ind_out));
            asm __volatile__ (".byte 0x72; .byte 0x24; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r" (direction1[j]) : "r" (index[j*6+4]), "r" (ind_out));
            asm __volatile__ (".byte 0x72; .byte 0x24; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r" (direction2[j]) : "r" (index[j*6+5]), "r" (ind_out));
            //cout << "output: " << j << endl;
        }
    }
    else{       // the intersection is larger then the DQ size
        
        // part 1
        sizetmp = intersection/halfsize;
        for (j=0;j<halfsize;j++)
        {
            tmp1 = data_tmp_2[j*2].value[0];
            tmp2 = data_tmp_2[j*2].value[1];
            tmp3 = data_tmp_2[j*2+1].value[0];
            tmp4 = data_tmp_2[j*2+1].value[1];
            asm __volatile__ (".byte 0x72; .byte 0x22; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r" (ind_out) : "r" (index[j*4]), "r" (tmp1));
            //cout << "asm_volatile " << ind_out << " " << index[j*4] << " " << tmp1;
            asm __volatile__ (".byte 0x72; .byte 0x22; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r" (ind_out) : "r" (index[j*4+1]), "r" (tmp2));
            asm __volatile__ (".byte 0x72; .byte 0x22; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r" (ind_out) : "r" (index[j*4+2]), "r" (tmp3));
            asm __volatile__ (".byte 0x72; .byte 0x22; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r" (ind_out) : "r" (index[j*4+3]), "r" (tmp4));
        }
        // part 2
        for (i=0;i<sizetmp-1;i++)
        {
            for (k=0;k<halfsize;k++)
            {
                j = (i+1)*halfsize + k;
                tmp1 = data_tmp_2[j*2].value[0];
                tmp2 = data_tmp_2[j*2].value[1];
                tmp3 = data_tmp_2[j*2+1].value[0];
                tmp4 = data_tmp_2[j*2+1].value[1];
                asm __volatile__ (".byte 0x72; .byte 0x22; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r" (ind_out) : "r" (index[j*4]), "r" (tmp1));
                asm __volatile__ (".byte 0x72; .byte 0x22; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r" (ind_out) : "r" (index[j*4+1]), "r" (tmp2));
                asm __volatile__ (".byte 0x72; .byte 0x22; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r" (ind_out) : "r" (index[j*4+2]), "r" (tmp3));
                asm __volatile__ (".byte 0x72; .byte 0x22; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r" (ind_out) : "r" (index[j*4+3]), "r" (tmp4));
            }
            for (k=0;k<halfsize;k++)
            {
                j = i*halfsize + k;
                //cout << "output: " << j << " " << index[j*6] << endl;
                asm __volatile__ (".byte 0x72; .byte 0x24; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r" (next1[j]) : "r" (index[j*6]), "r" (ind_out));
                asm __volatile__ (".byte 0x72; .byte 0x24; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r" (next2[j]) : "r" (index[j*6+1]), "r" (ind_out));
                asm __volatile__ (".byte 0x72; .byte 0x24; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r" (connection1[j]) : "r" (index[j*6+2]), "r" (ind_out));
                asm __volatile__ (".byte 0x72; .byte 0x24; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r" (connection2[j]) : "r" (index[j*6+3]), "r" (ind_out));
                asm __volatile__ (".byte 0x72; .byte 0x24; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r" (direction1[j]) : "r" (index[j*6+4]), "r" (ind_out));
                asm __volatile__ (".byte 0x72; .byte 0x24; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r" (direction2[j]) : "r" (index[j*6+5]), "r" (ind_out));
            }
        }
        // part 3
        for (j=sizetmp*halfsize;j<intersection;j++)             // overhead after inner loop finished
        {
     
            tmp1 = data_tmp_2[j*2].value[0];
            tmp2 = data_tmp_2[j*2].value[1];
            tmp3 = data_tmp_2[j*2+1].value[0];
            tmp4 = data_tmp_2[j*2+1].value[1];
            //cout << index[j*4] << " " << data_tmp_2[j*2].value[0] << endl;
     
            asm __volatile__ (".byte 0x72; .byte 0x22; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r" (ind_out) : "r" (index[j*4]), "r" (tmp1));
            asm __volatile__ (".byte 0x72; .byte 0x22; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r" (ind_out) : "r" (index[j*4+1]), "r" (tmp2));
            asm __volatile__ (".byte 0x72; .byte 0x22; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r" (ind_out) : "r" (index[j*4+2]), "r" (tmp3));
            asm __volatile__ (".byte 0x72; .byte 0x22; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r" (ind_out) : "r" (index[j*4+3]), "r" (tmp4));
        }
     
        asm __volatile__ (".byte 0x72; .byte 0x22; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r" (ind_out) : "r" (index[j*4]), "r" (final));
        //cout << "finish input" << endl;
        for (j=(sizetmp-1)*halfsize;j<intersection;j++)
        {
            asm __volatile__ (".byte 0x72; .byte 0x24; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r" (next1[j]) : "r" (index[j*6]), "r" (ind_out));
            //cout << "data_index_1[j].pointer" << " " << data_index_1[j].pointer << endl;
            asm __volatile__ (".byte 0x72; .byte 0x24; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r" (next2[j]) : "r" (index[j*6+1]), "r" (ind_out));
            asm __volatile__ (".byte 0x72; .byte 0x24; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r" (connection1[j]) : "r" (index[j*6+2]), "r" (ind_out));
            asm __volatile__ (".byte 0x72; .byte 0x24; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r" (connection2[j]) : "r" (index[j*6+3]), "r" (ind_out));
            asm __volatile__ (".byte 0x72; .byte 0x24; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r" (direction1[j]) : "r" (index[j*6+4]), "r" (ind_out));
            asm __volatile__ (".byte 0x72; .byte 0x24; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r" (direction2[j]) : "r" (index[j*6+5]), "r" (ind_out));
            //cout << "output: " << j << endl;
        }
    }
    
    // testing begin
    int start, end, size, distance1_tmp, distance2_tmp, int_tmp1, int_tmp2;
    size = halfsize*2;
    for(j=0;j<intersection;j++)
    {
        distance1 = DISTANCEINIT;
        distance2 = DISTANCEINIT;
        int_tmp1 = 0;
        int_tmp2 = 0;
        start = 2*j- size;
        if (start < 0)
            start = 0;
        end = 2*j + size;
        if (end > intersection*2)
            end = intersection*2;
        for (i=start;i<end;i++)
        {
            if ((i != j*2+1)&&(i != j*2))
            {
                distance1_tmp = sqrt(pow((data_tmp_2[i].value[0] - data_tmp_2[2*j].value[0]),2) + pow((data_tmp_2[i].value[1] - data_tmp_2[2*j].value[1]),2));
                if (distance1_tmp < distance1)
                {
                    distance1 = distance1_tmp;
                    int_tmp1 = i;
                }
                distance2_tmp = sqrt(pow((data_tmp_2[i].value[0] - data_tmp_2[2*j+1].value[0]),2) + pow((data_tmp_2[i].value[1] - data_tmp_2[2*j+1].value[1]),2));
                if (distance2_tmp < distance2)
                {
                    distance2 = distance2_tmp;
                    int_tmp2 = i;
                }
            }
        }
        next1[j] = int_tmp1/2;
        if (int_tmp1%2 == 0)
            direction1[j] = 0;
        else
            direction1[j] = 1;
        if (distance1 < DQ_threshold)
            connection1[j] = 0;
        else
            connection1[j] = 1;
        next2[j] = int_tmp2/2;
        if (int_tmp2%2 == 0)
            direction2[j] = 0;
        else
            direction2[j] = 1;
        if (distance2 < DQ_threshold)
            connection2[j] = 0;
        else
            connection2[j] = 1;
    }
    // testing finish
    
    
    //for (j=0;j<intersection;j++)
    //    cout << j << " " << data_tmp_2[2*j].value[0] << " " << next1[j] << " " << connection1 [j] << endl;
    //cout << "start connecting " << endl;
    iNumberOfContours = 0;
    iNumberOfPoints.clear();
    iOrientation.clear();
    for (j=0;j<intersection;j++)
        data_use[j] = 0;
    counter = 0;
    data_tmp_3[0] = data_tmp_2[0];
    data_tmp_3[1] = data_tmp_2[1];
    data_use[0] = 1;
    data_use[1] = 1;
    tmp_pointback = 0;
    tmp_pointer = next2[0];
    tmp_direction = direction2[0];
    tmp_connection = connection2[0];
    
    for (j=2;j<intersection;j++){
        counter++;
        if ((tmp_connection == 1)||(data_use[tmp_pointer] == 1)){
            not_connect += 1;
            //cout << not_connect << endl;
            distance2 = DISTANCEINIT;
            for (i=0;i<intersection*2;i++)
            {
                if ((i != tmp_pointback*2+1)&&(i != tmp_pointback*2))       // the value in data_tmp_2
                {
                    distance1 = sqrt(pow((data_tmp_2[i].value[0] - data_tmp_3[j-1].value[0]),2) + pow((data_tmp_2[i].value[1] - data_tmp_3[j-1].value[1]),2));
                
                    if (distance1 < distance2)
                    {
                        distance2 = distance1;
                        int_tmp = i;
                    }
                }
            }
            if (data_use[int_tmp/2] == 1){
                iNumberOfContours += 1;
                iNumberOfPoints.push_back(counter);
                //cout << " contour " << iNumberOfContours << " " << counter << endl;
                // orientation (0: clockwise, 1: counterclockwise, 2: open contour
                iOrientation.push_back(0);
                counter = 0;
                
                for (k=0;k<intersection;k++){
                    if (data_use[k] == 0)
                        break;
                }
                data_tmp_3[j-1] = data_tmp_2[k*2];
                data_tmp_3[j] = data_tmp_2[k*2+1];
                data_use[k] = 1;
                tmp_pointback = k;
                tmp_direction = direction2[k];
                tmp_connection = connection2[k];
                tmp_pointer = next2[k];
                
                continue;
            }
            if (int_tmp%2 == 0) // it's even, means the direction is correct
            {
                data_tmp_3[j] = data_tmp_2[int_tmp+1];
                data_use[int_tmp/2] = 1;
                tmp_pointback = int_tmp/2;
                tmp_direction = direction2[int_tmp/2];
                tmp_connection = connection2[int_tmp/2];
                tmp_pointer = next2[int_tmp/2];
            }
            else   // we need to exchange the head and tail only for behinds
            {
                data_tmp_3[j] = data_tmp_2[int_tmp-1];
                data_use[int_tmp/2] = 1;
                tmp_pointback = int_tmp/2;
                tmp_direction = direction1[int_tmp/2];
                tmp_connection = connection1[int_tmp/2];
                tmp_pointer = next1[int_tmp/2];
            }
            if (j==intersection-1){
                iNumberOfContours++;
                iNumberOfPoints.push_back(counter);
                iOrientation.push_back(0);
                counter = 0;
            }
        }
        else{
            if (tmp_direction == 0){        // correct order
                data_tmp_3[j] = data_tmp_2[tmp_pointer*2+1];
                data_use[tmp_pointer] = 1;
                tmp_direction = direction2[tmp_pointer];
                tmp_connection = connection2[tmp_pointer];
                tmp_pointback = tmp_pointer;
                tmp_pointer = next2[tmp_pointer];
            }
        
            else{                           // exchange head & tail
                data_tmp_3[j] = data_tmp_2[tmp_pointer*2];
                data_use[tmp_pointer] = 1;
                tmp_direction = direction1[tmp_pointer];
                tmp_connection = connection1[tmp_pointer];
                tmp_pointback = tmp_pointer;
                tmp_pointer = next1[tmp_pointer];
            }
            
            if (j==intersection-1){
                iNumberOfContours++;
                iNumberOfPoints.push_back(counter);
                iOrientation.push_back(0);
                //cout << " contour " << iNumberOfContours << " " << counter << endl;
                counter = 0;
            }
        }
        
        //cout << " array " << data_tmp_3[j*2].value[0] << " " << data_tmp_3[j*2+1].value[0] << endl;
    }
    //cout << "not_connect " << not_connect << " " << intersection << " " << iNumberOfContours << " " << counter << endl;
    cout << (float)not_connect<< " ";
    
    miss_curr += not_connect;
    intersection_curr += intersection;
    //for (i=0;i<intersection;i++)
    //    cout << data_tmp_3[i].value[0]/100 << " ";
    data_out.clear();
    for (i=0;i<intersection;i++)
    {
        data_out.push_back(data_tmp_3[i]);
    }
    */ 
    
}

//--------------------------------------------------------------
// Contour Optimization
//--------------------------------------------------------------

void Slicing::contouropt(vector<Data>& data_out,int &iNumberOfContours,vector<int>& Orientations,vector<int>& NumbersOfPoints)
{
    //cout << "one" << endl;
    int iNumberOfContours_prev,points_accu,deleted_index,deleted_points;
    vector<int> Orientations_prev, NumbersOfPoints_prev;
    Orientations_prev = Orientations;
    NumbersOfPoints_prev = NumbersOfPoints;
    iNumberOfContours_prev = iNumberOfContours;
    //Orientations.clear();
    //NumbersOfPoints.clear();
    //iNumberOfContours = 0;
    points_accu=0;
    deleted_index = 0;
    deleted_points = 0;
    for (i=0;i<iNumberOfContours_prev;i++)
    {
        if (NumbersOfPoints_prev[i] < 3)
        {
            data_out.erase(data_out.begin()+points_accu-deleted_points,data_out.begin()+points_accu+NumbersOfPoints_prev[i]-deleted_points);
            NumbersOfPoints.erase(NumbersOfPoints.begin()+i-deleted_index);
            Orientations.erase(Orientations.begin()+i-deleted_index);
            iNumberOfContours--;
            deleted_index++;
            deleted_points += NumbersOfPoints_prev[i];
        }
        points_accu += NumbersOfPoints_prev[i];
    }
}

//--------------------------------------------------------------
// Contour Direction
//--------------------------------------------------------------
template<typename T>
void Slicing::quicksort(vector<SILA<T> >& Data_tmp1, int left, int right)
{
    int itl, itr, pivot;
    itl = left;
    itr = right;
    pivot = Data_tmp1[(left+right)/2].value[1];
    
    while (itl <= itr){
        while (Data_tmp1[itl].value[1] < pivot)
            itl++;
        while (Data_tmp1[itr].value[1] > pivot)
            itr--;
        if (itl <= itr){
            tmp = Data_tmp1[itl].value[1];
            Data_tmp1[itl].value[1] = Data_tmp1[itr].value[1];
            Data_tmp1[itr].value[1] = tmp;
            itl++;
            itr--;
        }
    }
    
    if (left < itr)
        quicksort(Data_tmp1, left, itr);
    if (itl < right)
        quicksort(Data_tmp1, itl, right);
}

void Slicing::contourdire(vector<Data>& data_out,int &iNumberOfContours,vector<int>& Orientations,vector<int>& NumbersOfPoints)
{
    Data data_in[data_out.size()];
    SILA<int> Contour_Queue_tmp;
    vector<SILA<int> > Contour_Queue;
    int points_accu,grid_line,x1,x2,y1,y2,x0,y0,left,right,intersection_x;
    int cmp_value,cmp_idx,SignedArea, in_size;
    int scale = SCALE;
    in_size = data_out.size();
    for(i=0;i<data_out.size();i++)
    {
        data_in[i] = data_out[i];
    }
    data_out.clear();
    
    for(i=0;i<iNumberOfContours;i++)
    {
        points_accu = 0;
        grid_line = 0;
        for (k=0;k<i;k++)
            points_accu += NumbersOfPoints[k];
        for (k=points_accu;k<points_accu+NumbersOfPoints[i];k++){
            grid_line += data_in[k].value[1];
            //cout << data_in[k].value[1] << " ";
        }
        grid_line = grid_line/NumbersOfPoints[i];
        //cout << grid_line << endl;
        points_accu = 0;
        Contour_Queue.clear();
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
                    intersection_x = ((x2 - x1)*(grid_line - y1))/(y2 - y1) + x1;
                    Contour_Queue_tmp.value[0] = k;
                    Contour_Queue_tmp.value[1] = intersection_x;
                    Contour_Queue.push_back(Contour_Queue_tmp);
                }
            }
            points_accu += NumbersOfPoints[k];
        }
        if (Contour_Queue.size() > 0){
            left = 0;
            right = Contour_Queue.size() - 1;
            quicksort(Contour_Queue, left, right);
            
            for (j=0;j<Contour_Queue.size();j+=1){
                if (Contour_Queue[j].value[0] == i){
                    //cout << "one " << i << " " << j << endl;
                    points_accu = 0;
                    for (k=0;k<i;k++)
                        points_accu += NumbersOfPoints[k];
                    cmp_value = data_in[points_accu].value[1];
                    cmp_idx = points_accu;
                    for (k=points_accu;k<points_accu+NumbersOfPoints[i];k++){
                        if(cmp_value > data_in[k].value[1]){
                            cmp_value = data_in[k].value[1];
                            cmp_idx = k;
                        }
                    }
                    //cout << "one " << cmp_idx << " " << in_size << endl;
                    if (cmp_idx == points_accu){
                        x0 = data_in[points_accu+NumbersOfPoints[i]-1].value[0];
                        y0 = data_in[points_accu+NumbersOfPoints[i]-1].value[1];
                        x1 = data_in[cmp_idx].value[0];
                        y1 = data_in[cmp_idx].value[1];
                        x2 = data_in[cmp_idx+1].value[0];
                        y2 = data_in[cmp_idx+1].value[1];
                    }
                    else if (cmp_idx == points_accu+NumbersOfPoints[i]){
                        x0 = data_in[cmp_idx-1].value[0];
                        y0 = data_in[cmp_idx-1].value[1];
                        x1 = data_in[cmp_idx].value[0];
                        y1 = data_in[cmp_idx].value[1];
                        x2 = data_in[points_accu].value[0];
                        y2 = data_in[points_accu].value[1];
                    }
                    else{
                        x0 = data_in[cmp_idx-1].value[0];
                        y0 = data_in[cmp_idx-1].value[1];
                        x1 = data_in[cmp_idx].value[0];
                        y1 = data_in[cmp_idx].value[1];
                        x2 = data_in[cmp_idx+1].value[0];
                        y2 = data_in[cmp_idx+1].value[1];
                    }
                    SignedArea = (x1-x0)*(y2-y0) - (x2-x0)*(y2-y0);
                    if (j%2 == 0){                      // outer contour, clockwise
                        Orientations[i] = 0;
                        if (SignedArea > 0){
                            for (k=points_accu+NumbersOfPoints[i]-1;k>=points_accu;k--){
                                data_out.push_back(data_in[k]);
                            }
                        }
                        else{
                            for (k=points_accu;k<points_accu+NumbersOfPoints[i];k++){
                                data_out.push_back(data_in[k]);
                            }
                        }
                        break;
                    }
                    else{                               // inner contour, counterclockwise
                        Orientations[i] = 1;
                        if (SignedArea < 0){
                            for (k=points_accu+NumbersOfPoints[i]-1;k>=points_accu;k--){
                                data_out.push_back(data_in[k]);
                            }
                        }
                        else{
                            for (k=points_accu;k<points_accu+NumbersOfPoints[i];k++){
                                data_out.push_back(data_in[k]);
                            }
                        }
                        break;
                    }
                }
            }
        }
    }
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
        
    typedef unsigned short uint16;
    int scale = SCALE;
    int step;
    ofstream runningtime("result/RunningTime.txt", ofstream::out|ofstream::binary);
    ofstream result("result/SlicingResult.cli");
    uint16 uiCommand;
    float fSliceHeight;
    int iIdentifier;
    int iNumberOfContours;
    vector<Data> data_in, data_out;
    vector<int> iOrientation,iNumberOfPoints;
    int accumulator;
    int layer;
    int z,a;
    int i, j, k,l,contour_points;
    float zmin,zmax;
    float x,y;
    float miss_rate;
    zmin = 100;
    zmax = 0;
    i = 0;
    k = 0;
  
    double cpu_yang[CPU_ITEMS+1];
    double cpu_tmp[2];
    int pmubarrier[3];
    pmubarrier[0] = -1;
    pmubarrier[1] = -1;
    pmubarrier[2] = -1;
    string cpu_index[CPU_ITEMS+1] = {"FileIO","Intersection","Distance","Total"};
    for (i=0;i<CPU_ITEMS+1;i++)
        cpu_yang[i] = CPU_INIT;
    
    Slicing slicing;
    
    //--------------------------------------------------------------
    // input data
    //--------------------------------------------------------------
    
    cout << "STL file: " << argv[1] << endl;
    
#if Gem5
    pmubarrier[0] = FileIO;
    asm __volatile__ (".byte 0x72; .byte 0x25; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r"(pmubarrier[2]) : "r" (pmubarrier[0]), "r" (pmubarrier[0]));
#endif
    
    cpu_tmp[0] = get_cpu_time();
    Read_STL_File(argv[1],data_in,scale,zmin,zmax);
    cpu_tmp[1] = get_cpu_time();
    cpu_yang[FileIO] += cpu_tmp[1] - cpu_tmp[0];
    
#if Gem5
    pmubarrier[0] = BlockEnd;
    asm __volatile__ (".byte 0x72; .byte 0x25; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r"(pmubarrier[2]) : "r" (pmubarrier[0]), "r" (pmubarrier[0]));
#endif
    
    //zmin += THICKNESS/10;
    layer = LAYER;
    //layer = 10;
    //layer = (zmax-zmin)/THICKNESS;
    float slicing_plane[layer];
    int contour_pairs[layer];
    int searching_distance[layer];
    int number_contours[layer];
    int locality_distance;
    int average_contour, average_distance, average_number, average_CI;
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
    // data processing
    //--------------------------------------------------------------
    cout << "Total Points: " << data_in.size()/3 << endl;
    cout << "z range: "<< zmax << " " << zmin << " " << zmax-zmin << endl;
    cout << "layers: " << layer << endl;
    fSliceHeight = (zmax-zmin)/(layer-1);
    //fSliceHeight = 1;
    k = 0;
    step = (zmax-zmin)*scale/(layer-1);
    //step = 1;
    // slice multiple layers
    for (z=zmin*scale;z<zmax*scale;z+=step)             //this will work. z/scale<zmax will be wrong
    // slice one layer
    //for (z=40*scale;z<=40*scale;z++)
    //for (z=20*scale;z<21*scale;z+=scale)
    {
        data_out.clear();
        //--------------------------------------------------------------
        // Slicing
        //--------------------------------------------------------------
#if Gem5
        pmubarrier[0] = Intersection;
        asm __volatile__ (".byte 0x72; .byte 0x25; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r"(pmubarrier[2]) : "r" (pmubarrier[0]), "r" (pmubarrier[0]));
#endif
        cpu_tmp[0] = get_cpu_time();
        slicing.intersections(data_in,z,data_out,&contour_points);
        cpu_tmp[1] = get_cpu_time();
        cpu_yang[Intersection] += cpu_tmp[1] - cpu_tmp[0];
#if Gem5
        pmubarrier[0] = BlockEnd;
        asm __volatile__ (".byte 0x72; .byte 0x25; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r"(pmubarrier[2]) : "r" (pmubarrier[0]), "r" (pmubarrier[0]));
#endif
        
#if Gem5
        pmubarrier[0] = Distance;
        asm __volatile__ (".byte 0x72; .byte 0x25; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r"(pmubarrier[2]) : "r" (pmubarrier[0]), "r" (pmubarrier[0]));
#endif
        cpu_tmp[0] = get_cpu_time();
        slicing.contourgene(data_out,iNumberOfContours,iOrientation,iNumberOfPoints,locality_distance);
        cpu_tmp[1] = get_cpu_time();
        cpu_yang[Distance] += cpu_tmp[1] - cpu_tmp[0];
#if Gem5
        pmubarrier[0] = BlockEnd;
        asm __volatile__ (".byte 0x72; .byte 0x25; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r"(pmubarrier[2]) : "r" (pmubarrier[0]), "r" (pmubarrier[0]));
#endif
        
        slicing.contouropt(data_out,iNumberOfContours,iOrientation,iNumberOfPoints);
        slicing.contourdire(data_out,iNumberOfContours,iOrientation,iNumberOfPoints);
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

        cout << "layer " << k << " " << z << " " << iNumberOfContours << endl;
        for (l=0;l<iNumberOfContours;l++)
        {
            uiCommand = 130;
            result.write((char *)&uiCommand, sizeof(uint16));
            iIdentifier = 1;
            result.write((char *)&iIdentifier, sizeof(int));
            result.write((char *)&iOrientation[l], sizeof(int));
            result.write((char *)&iNumberOfPoints[l], sizeof(int));
            for (i=accumulator; i<accumulator+iNumberOfPoints[l]; i++)
            {
                x = (float)data_out[i].value[0]/scale;
                y = (float)data_out[i].value[1]/scale;
                result.write((char *)&x, sizeof(float));
                result.write((char *)&y, sizeof(float));
                //cout << data_out[i].value[0]*10/scale << " " << data_out[i].value[1]*10/scale << " ";
            }
            accumulator += iNumberOfPoints[l];
            //cout << endl;
        }
        cpu_tmp[1] = get_cpu_time();
        cpu_yang[FileIO] += cpu_tmp[1] - cpu_tmp[0];
#if Gem5
        pmubarrier[0] = BlockEnd;
        asm __volatile__ (".byte 0x72; .byte 0x25; .byte 0xf3; .byte 0xe6; mov %0, r2;" : "=r"(pmubarrier[2]) : "r" (pmubarrier[0]), "r" (pmubarrier[0]));
#endif
        contour_pairs[k] = contour_points/2;
        searching_distance[k] = locality_distance;
        number_contours[k] = iNumberOfContours;
        slicing_plane[k] = z;
        
        //cout << iNumberOfContours << endl;
        //cout << k << " " << accumulator << " " << z << " " << zmax*scale << endl;
        k++;
        //cout << k << " " << z <<  " " << zmax*scale << endl;
    }
    
    miss_rate = (float)slicing.miss_curr/slicing.intersection_curr;
    //cout << "miss_rate " << miss_rate << " " << slicing.miss_curr << " " << slicing.intersection_curr << endl;
    //cout << "layer " << layer << " " << k << endl;
    average_contour = 0;
    average_distance = 0;
    average_number = 0;
    average_CI = 0;
    for (i=0;i<k;i++){
        //cout << "contour distance: " << contour_pairs[i] << " " << searching_distance[i] << endl;
        average_CI += number_contours[i]*contour_pairs[i];
        average_number += number_contours[i]*number_contours[i];
        average_contour += contour_pairs[i]*contour_pairs[i];
        average_distance += searching_distance[i]*contour_pairs[i];
        //cout << average_number << " ";
    }
    average_CI = sqrt(average_CI/layer);
    average_contour = sqrt(average_contour/layer);
    average_number = sqrt(average_number/layer);
    average_distance = average_distance/average_contour;
    
    cout << endl;
    cout << "average CI per layer " << average_CI << endl;
    cout << "average contours per layer " << average_number << endl;
    cout << "average searching distance per layer " << average_distance << endl;
    cout << "average intersection segments per layer " << average_contour << endl;
    
    for (i=0;i<CPU_ITEMS;i++) {
        cpu_yang[CPU_ITEMS] += cpu_yang[i];
    }
    runningtime << "Slicing 1 runningtime" << endl;
    for (i=0;i<CPU_ITEMS+1;i++) {
        runningtime << left << setw(15) << cpu_index[i] << " : " << setw(10) <<  cpu_yang[i] << " " <<  cpu_yang[i]/cpu_yang[CPU_ITEMS]*100 << "%" << endl;
    }
    cout << "time: " << cpu_yang[CPU_ITEMS] << endl;
    
    runningtime.close();
    result.close();
    cout << "memory footprint (kB) " << getValue() << endl;
    return 0;
}



