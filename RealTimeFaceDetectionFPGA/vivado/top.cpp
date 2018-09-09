////////////////////////////////////////////////////////////////////////////
// Canny Edge Detection Algorithm - HLS HW Implementation
// Created by: Fan Yang
// Fall 2014
//
// This file contains all of the subroutines which perform the
// face detection
//
// This file is modified off a tutorial created by Xilinx, and as such
// we retain the below copyright notice and disclaimer.
////////////////////////////////////////////////////////////////////////////
/***************************************************************************
 
 *   © Copyright 2013 Xilinx, Inc. All rights reserved.
 
 *   This file contains confidential and proprietary information of Xilinx,
 *   Inc. and is protected under U.S. and international copyright and other
 *   intellectual property laws.
 
 *   DISCLAIMER
 *   This disclaimer is not a license and does not grant any rights to the
 *   materials distributed herewith. Except as otherwise provided in a valid
 *   license issued to you by Xilinx, and to the maximum extent permitted by
 *   applicable law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND WITH
 *   ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES AND CONDITIONS,
 *   EXPRESS, IMPLIED, OR STATUTORY, INCLUDING BUT NOT LIMITED TO WARRANTIES
 *   OF MERCHANTABILITY, NON-INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR
 *   PURPOSE; and (2) Xilinx shall not be liable (whether in contract or
 *   tort, including negligence, or under any other theory of liability)
 *   for any loss or damage of any kind or nature related to, arising under
 *   or in connection with these materials, including for any direct, or any
 *   indirect, special, incidental, or consequential loss or damage (including
 *   loss of data, profits, goodwill, or any type of loss or damage suffered
 *   as a result of any action brought by a third party) even if such damage
 *   or loss was reasonably foreseeable or Xilinx had been advised of the
 *   possibility of the same.
 
 *   CRITICAL APPLICATIONS
 *   Xilinx products are not designed or intended to be fail-safe, or for use
 *   in any application requiring fail-safe performance, such as life-support
 *   or safety devices or systems, Class III medical devices, nuclear facilities,
 *   applications related to the deployment of airbags, or any other applications
 *   that could lead to death, personal injury, or severe property or environmental
 *   damage (individually and collectively, "Critical Applications"). Customer
 *   assumes the sole risk and liability of any use of Xilinx products in Critical
 *   Applications, subject only to applicable laws and regulations governing
 *   limitations on product liability.
 
 *   THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS PART OF THIS FILE AT
 *   ALL TIMES.
 
 ***************************************************************************/
#include "top.h"
#include <iostream>
using namespace std;
//--------------------------------------------------------------------------------------------------
//start face detection
//--------------------------------------------------------------------------------------------------

void image_label(hls::Window<10,10,unsigned char> *win)
{
    cout<<"good"<<endl;
}

void downsize( RGB_IMAGE& src, RGB_IMAGE& dst) {
    
    HLS_SIZE_T rows = src.rows;
    HLS_SIZE_T cols = src.cols;
    hls::Scalar<3, unsigned char> pixel_1;
    
    for( HLS_SIZE_T i = 0; i < rows; i++ )
        for( HLS_SIZE_T j = 0; j < cols; j++ ){
            src >> pixel_1;
            if((i%20 == 0)&&(j%20 == 0))
                dst << pixel_1;
        }
}

void color_detection(RGB_IMAGE& src, RGB_IMAGE& dst){
    
    HLS_SIZE_T rows = src.rows;
    HLS_SIZE_T cols = src.cols;
    hls::Scalar<3, unsigned char> pixel_1;
    //unsigned char red,green,blue,Y,U,V;
    int red,green,blue;
    //int Y,U,V;
    float Y,Cb,Cr;
    for( HLS_SIZE_T i = 0; i < rows; i++ )
        for( HLS_SIZE_T j = 0; j < cols; j++ ){
            src >> pixel_1;
            blue = pixel_1.val[0];
            green = pixel_1.val[1];
            red = pixel_1.val[2];
           /* U = red - green;
            V = blue - green;
            Y = (red + 2*green + blue)/4;*/
            Y = 0.299*red + 0.587*green + 0.114*blue;
            Cb = -0.169*red - 0.332*green + 0.500*blue;
            Cr = 0.500*red - 0.419*green - 0.081*blue;

            //cout<<red<<endl;
            //if((U>11)&(U<73)&(V>(-39))&(V<10))  //250
            if ((Cb>-22)&(Cb<0)&(0.9*Cr+Cb>0)&(Cr<33))
            {
                pixel_1.val[0] = 250;
                pixel_1.val[1] = 250;
                pixel_1.val[2] = 250;
                //cout<<pixel_1.val[2]<<endl;
            }
            else
            {
                pixel_1.val[0] = 0;
                pixel_1.val[1] = 0;
                pixel_1.val[2] = 0;
            }
            dst << pixel_1;
        }
}

void image_fill1(RGB_IMAGE& src, RGB_IMAGE& dst){

    hls::Window<9, 9, float> 	kernel;
    hls::Point_<int> 		anchor;
    
    for (int i = 0; i < 9; i++)
        for (int j = 0; j < 9; j++)
            kernel.val[i][j] = 1/81.0;
    //cout<<kernel.val[3][5]<<endl;
    
    anchor.x = -1;
    anchor.y = -1;
    
    hls::Filter2D(src, dst, kernel, anchor);
}

void image_fill2(RGB_IMAGE& src, RGB_IMAGE& dst){
    
    HLS_SIZE_T rows = src.rows;
    HLS_SIZE_T cols = src.cols;
    hls::Scalar<3, unsigned char> pixel_1;
    hls::Scalar<3, unsigned char> pixel_2;
    int color1,color2;
    int tmp[9];
    hls::LineBuffer<9,100,unsigned char> linebuff;
    hls::Window<10,10,unsigned char> win;
    int x,y,z,total,average;
    
    for( HLS_SIZE_T i = 0; i < rows; i++ )
        for( HLS_SIZE_T j = 0; j < cols; j++ ){
            src >> pixel_1;
            if(pixel_1.val[0] > 100)
            {
                pixel_1.val[0] = 250;
                pixel_1.val[1] = 250;
                pixel_1.val[2] = 250;
            }
            else{
                pixel_1.val[0] = 0;
                pixel_1.val[1] = 0;
                pixel_1.val[2] = 0;
            }
            dst << pixel_1;
        }
}

void image_fill3( RGB_IMAGE& src, RGB_IMAGE& dst) {
    
    HLS_SIZE_T rows = src.rows;
    HLS_SIZE_T cols = src.cols;
    hls::Scalar<3, unsigned char> pixel_1;
    hls::Scalar<3, unsigned char> pixel_2;
    int color1,color2;
    int tmp[9];
    hls::LineBuffer<9,100,unsigned char> linebuff;
    hls::Window<10,10,unsigned char> win;
    int x,y,z,total,average;

    for( HLS_SIZE_T i = 0; i < rows; i++ )
        for( HLS_SIZE_T j = 0; j < cols; j++ ){
            
            if(i < rows && i < cols){
                src >> pixel_1;
                color1 = pixel_1.val[0];
                //cout<<color1<<endl;
            }
            
            if(j < cols){
                for(x=0;x<9;x++)
                    tmp[x] = linebuff.getval(x,j);
                for(x=0;x<8;x++)
                    linebuff.val[x+1][j] = tmp[x];
            }
            
            if(j<cols && i<rows){
                linebuff.insert_bottom(color1,j);
            }
            
            win.shift_right();
            
            if(j<cols){
                win.insert(color1,0,0);
                for(x=0;x<9;x++)
                win.insert(tmp[x],x+1,0);
            }
            
            if(i<=4 || j<=4 || i>rows-4 || j>cols-4)
            color2 = 0;
            else{
                total = 0;
                for(x=0;x<10;x++)
                for(y=0;y<10;y++){
                    total += win.getval(x,y);
                }
                
                //cout<<total<<endl;
                average = total/100;
                //cout<<average<<endl;
                if(average > 187)   //250*0.75 = 187
                {
                    color2 = 250;
                }
                else
                {
                    color2 = 0;
                }
            }
            
            pixel_2.val[0] = color2;
            pixel_2.val[1] = color2;
            pixel_2.val[2] = color2;
            dst << pixel_2;
        }
}

void image_label( RGB_IMAGE& src, RGB_IMAGE& dst) {
    
    HLS_SIZE_T rows = src.rows;
    HLS_SIZE_T cols = src.cols;
    hls::Scalar<3, unsigned char> pixel_1;
    hls::Scalar<3, unsigned char> pixel_2;
    int color1,color2;
    int tmp[9];
    hls::LineBuffer<9,100,unsigned char> linebuff;
    hls::Window<10,10,unsigned char> win;
    int x,y,z,label_number;
    cout<<"good here"<<endl;
    for( HLS_SIZE_T i = 0; i < rows; i++ )
        for( HLS_SIZE_T j = 0; j < cols; j++ ){
                src >> pixel_1;
                color1 = pixel_1.val[0];
                win.insert(color1,i,j);
        }
    cout<<"good again"<<endl;
    label_number = 0;
    for(x=0;x<rows;x++)
        for(y=0;y<cols;y++){
            if(win.getval(x,y) == 250)
            {
                image_label(&win);
                label_number += 1;
            }
        }
    cout<<"that's all"<<endl;

            dst << pixel_1;
    
}

void draw_rectangle( RGB_IMAGE& src1, RGB_IMAGE& src2, RGB_IMAGE& dst) {

    hls::Scalar<3, unsigned char> pixel_1;
    hls::Scalar<3, unsigned char> pixel_2;
    int left,right,top,bottom;
    left = 100;
    right = 0;
    top = 0;
    bottom = 100;
    for( HLS_SIZE_T i = 0; i < src1.rows; i++ )
    for( HLS_SIZE_T j = 0; j < src1.cols; j++ ){
        src1 >> pixel_1;
        if(pixel_1.val[0] == 250){
            if(left > j)
            left = j;
            if(right < j)
            right = j;
            if(bottom > i)
            bottom = i;
            if(top < i)
            top = i;
        }
    }
    cout<<left<<" "<<right<<" "<<top<<" "<<bottom<<endl;
    left = left*20;
    right = right*20;
    top = top*20;
    bottom = bottom*20;
    cout<<src2.rows<<" "<<src2.cols<<endl;
    cout<<left<<" "<<right<<" "<<top<<" "<<bottom<<endl;
    
    for( HLS_SIZE_T i = 0; i < src2.rows; i++ )
    for( HLS_SIZE_T j = 0; j < src2.cols; j++ ){
        src2 >> pixel_2;
        if((i == bottom)||(i == top)){
            if((j < right)&&(j > left)){
                pixel_2.val[0] = 0;
                pixel_2.val[1] = 255;
                pixel_2.val[2] = 255;
            }
        }
        if((j == left)||(j == right)){
            if((i < top)&&(i > bottom)){
                pixel_2.val[0] = 0;
                pixel_2.val[1] = 255;
                pixel_2.val[2] = 255;
            }
        }
        dst << pixel_2;
    }
}

void face_detection(AXI_STREAM& input, AXI_STREAM& output, int rows, int cols) {
    //Create AXI streaming interfaces for the core
#pragma HLS RESOURCE variable=input core=AXIS metadata="-bus_bundle INPUT_STREAM"
#pragma HLS RESOURCE variable=output core=AXIS metadata="-bus_bundle OUTPUT_STREAM"
    
#pragma HLS RESOURCE core=AXI_SLAVE variable=rows metadata="-bus_bundle CONTROL_BUS"
#pragma HLS RESOURCE core=AXI_SLAVE variable=cols metadata="-bus_bundle CONTROL_BUS"
#pragma HLS RESOURCE core=AXI_SLAVE variable=return metadata="-bus_bundle CONTROL_BUS"
    
#pragma HLS INTERFACE ap_stable port=rows
#pragma HLS INTERFACE ap_stable port=cols
    
    RGB_IMAGE src1(rows, cols);
    RGB_IMAGE try1_out(rows, cols);
    RGB_IMAGE try1_final(rows, cols);
    RGB_IMAGE try1(rows, cols);
    
    RGB_IMAGE try2(rows/20, cols/20);
    RGB_IMAGE try3(rows/20, cols/20);
    RGB_IMAGE try4(rows/20, cols/20);
    RGB_IMAGE try5(rows/20, cols/20);

#pragma HLS dataflow
    // AXI to RGB_IMAGE stream
    hls::AXIvideo2Mat( input, src1 );
    hls::Duplicate( src1, try1, try1_out );
    downsize( try1, try2);
    color_detection(try2,try3);
    image_fill1(try3,try4);
    image_fill2(try4,try5);
    //image_label(try4,try5);
    draw_rectangle(try5,try1_out,try1_final);
    
    hls::Mat2AXIvideo( try1_final, output );
}
