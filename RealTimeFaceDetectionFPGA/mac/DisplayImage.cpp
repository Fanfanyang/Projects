#include <stdio.h>
#include <opencv2/opencv.hpp>
#include <iostream>

using namespace cv;
using namespace std;

//--------------------------------------------------------------
// image label define
//--------------------------------------------------------------
void image_label(Mat *image, int label_number, int i, int j, int &count)
{
    image->at<Vec3b>(i, j)[1] = label_number;
    if((image->at<Vec3b>(i, j+1)[0] == 250)&(image->at<Vec3b>(i, j+1)[1] == 250))
        image_label(image,label_number,i,j+1,count);
    if((image->at<Vec3b>(i, j-1)[0] == 250)&(image->at<Vec3b>(i, j-1)[1] == 250))
        image_label(image,label_number,i,j-1,count);
    if((image->at<Vec3b>(i+1, j)[0] == 250)&(image->at<Vec3b>(i+1, j)[1] == 250))
        image_label(image,label_number,i+1,j,count);
    count += 1;
    //printf("%d ",count);
}

//--------------------------------------------------------------
// main function
//--------------------------------------------------------------

int main(int argc, char** argv )
{
    if ( argc != 1 )
    {
        printf("NOT usage: DisplayImage <Image_capture> <Image_output>\n");
        return -1;
    }
    
//--------------------------------------------------------------
// input image
//--------------------------------------------------------------
    Mat image, img_out, img_middle, image_final;
    
    VideoCapture cap(0);
    if(!cap.isOpened())
        return -1;
    //Mat frame;

    while(1)
    {
        cap >> image;//frame
        //imshow("frame",frame);
    //imwrite(argv[1], frame);
    
    //image = imread( argv[1], 1 );
    image_final = image.clone();
    if ( !image.data )
    {
        printf("No image data \n");
        return -1;
    }
    if(waitKey(1) == 27)
        break;
//--------------------------------------------------------------
// downsize
//--------------------------------------------------------------
    int x, y, z, c;
    int i,j;
    Mat img_downsize;
    int aa = image.rows/20;
    int bb = image.cols/20;
    img_downsize.create(aa,bb,CV_8UC3);
    for(x=0;x<img_downsize.rows;x++)
        for(y=0;y<img_downsize.cols;y++)
            for(i=0;i<3;i++)
                img_downsize.at<Vec3b>(x,y)[i] = image.at<Vec3b>(x*20,y*20)[i];
    
    img_middle = img_downsize.clone();
    img_out = img_downsize.clone();
    //imwrite("zz_downsize.jpg",img_downsize);
    
//--------------------------------------------------------------
// colour detection
//--------------------------------------------------------------
    float Y, U ,V;
    //float Y, Cr, Cb;
    for(x=0;x<img_downsize.rows;x++)
        for(y=0;y<img_downsize.cols;y++)
        {
            Vec3b intensity = img_out.at<Vec3b>(x, y);
            float blue = intensity.val[0];
            float green = intensity.val[1];
            float red = intensity.val[2];
            U = red - green;
            V = blue - green;
            Y = (red + 2*green + blue)/4;
            /*Y = 0.299*red + 0.587*green + 0.114*blue;
            Cb = -0.169*red - 0.332*green + 0.500*blue;
            Cr = 0.500*red - 0.419*green - 0.081*blue;*/
            //number += 1;
            //cout<<"#"<<number<<": "<<"("<<Y<<", "<<Cb<<", "<<Cr<<")"<<endl;
            //if ((Cb>-22)&(Cb<0)&(0.9*Cr+Cb>0)&(Cr<33))  // skin colour
            if((U>11)&(U<73)&(V>(-39))&(V<10))
            {
                img_out.at<Vec3b>(x, y)[0] = 250;
                img_out.at<Vec3b>(x, y)[1] = 250;
                img_out.at<Vec3b>(x, y)[2] = 250;
            }
            else
            {
                img_out.at<Vec3b>(x, y)[0] = 0;
                img_out.at<Vec3b>(x, y)[1] = 0;
                img_out.at<Vec3b>(x, y)[2] = 0;
            }
        }
    //imwrite("zz_colou_detection.jpg",img_out);
    
//--------------------------------------------------------------
// image fill
//--------------------------------------------------------------
    int wide, length, total, average;
    wide = 10;
    length = 10;
    for(x=wide/2;x<img_downsize.rows-wide/2;x++)
        for(y=length/2;y<img_downsize.cols-length/2;y++)
        {
            total = 0;
            for(i=-wide/2;i<wide/2;i++)
                for(j=-length/2;j<length/2;j++)
                {
                    total += img_out.at<Vec3b>(x+i,y+j)[0];
                }
            average = total/100;
            if (average>187)    //250*0.75=187
            {
                img_middle.at<Vec3b>(x, y)[0] = 250;
                img_middle.at<Vec3b>(x, y)[1] = 250;
                img_middle.at<Vec3b>(x, y)[2] = 250;
            }
            else
            {
                img_middle.at<Vec3b>(x, y)[0] = 0;
                img_middle.at<Vec3b>(x, y)[1] = 0;
                img_middle.at<Vec3b>(x, y)[2] = 0;
            }
        }
    
    for(x=0;x<img_downsize.rows;x++)
        for(y=0;y<img_downsize.cols;y++)
        {
            if (img_middle.at<Vec3b>(x, y)[0] == 250)
            {
                img_out.at<Vec3b>(x, y)[0] = 250;
                img_out.at<Vec3b>(x, y)[1] = 250;
                img_out.at<Vec3b>(x, y)[2] = 250;
            }
            else
            {
                img_out.at<Vec3b>(x, y)[0] = 0;
                img_out.at<Vec3b>(x, y)[1] = 0;
                img_out.at<Vec3b>(x, y)[2] = 0;
            }
        }
    
    //imwrite("zz_image_filter.jpg",img_out);
        imshow("img_fill",img_out);
//--------------------------------------------------------------
// image label use: 0,color; 1,label
//--------------------------------------------------------------
    int label_number,count;
    label_number = 1;
    for(i=0;i<img_downsize.rows;i++)
        for(j=0;j<img_downsize.cols;j++)
        {
            if((img_out.at<Vec3b>(i,j)[0] == 250)&(img_out.at<Vec3b>(i,j)[1] == 250))
            {
                count = 0;
                image_label(&img_out,label_number,i,j,count);
                label_number += 1;
                printf("label_number = %d, (%d, %d), #%d\n",label_number,i,j,count);
            }
        }
    //imwrite("zz_image_label.jpg",img_out);
        imshow("img_label",img_out);
//--------------------------------------------------------------
// image central
//--------------------------------------------------------------
    int left[label_number], right[label_number], top[label_number], bottom[label_number],central_count[label_number];
    for(i=0;i<label_number;i++)
    {
        left[i] = 100;
        right[i] = 0;
        top[i] = 0;
        bottom[i] = 100;
        central_count[i] = 0;
    }
    for(x=0;x<img_downsize.rows;x++)
        for(y=0;y<img_downsize.cols;y++)
        {
            if(img_out.at<Vec3b>(x,y)[0] == 250)
            {
                central_count[img_out.at<Vec3b>(x,y)[1]] += 1;
                if (left[img_out.at<Vec3b>(x,y)[1]] > x)    //left has the min x
                    left[img_out.at<Vec3b>(x,y)[1]] = x;
                if (right[img_out.at<Vec3b>(x,y)[1]] < x)    //right has the max x
                    right[img_out.at<Vec3b>(x,y)[1]] = x;
                if (bottom[img_out.at<Vec3b>(x,y)[1]] > y)    //bottom has the min y
                    bottom[img_out.at<Vec3b>(x,y)[1]] = y;
                if (top[img_out.at<Vec3b>(x,y)[1]] < y)    //top has the max y
                    top[img_out.at<Vec3b>(x,y)[1]] = y;
            }
        }
        
    for(i=0;i<label_number;i++)
    {
        if(central_count[i] > 10)   //filter noise
        {
            printf("count # %d\n",i);
            printf("%d,%d,%d,%d\n",left[i],right[i],bottom[i],top[i]);
            for(y=(bottom[i]-2)*20;y<=(top[i]+2)*20;y++)
            {
                image_final.at<Vec3b>((left[i]-1)*20,y)[0] = 0;
                image_final.at<Vec3b>((left[i]-1)*20,y)[1] = 255;
                image_final.at<Vec3b>((left[i]-1)*20,y)[2] = 255;
                
                image_final.at<Vec3b>((right[i]+1)*20,y)[0] = 0;
                image_final.at<Vec3b>((right[i]+1)*20,y)[1] = 255;
                image_final.at<Vec3b>((right[i]+1)*20,y)[2] = 255;
            }
            for(x=(left[i]-1)*20;x<=(right[i]+1)*20;x++)
            {
                image_final.at<Vec3b>(x,(bottom[i]-2)*20)[0] = 0;
                image_final.at<Vec3b>(x,(bottom[i]-2)*20)[1] = 255;
                image_final.at<Vec3b>(x,(bottom[i]-2)*20)[2] = 255;
                
                image_final.at<Vec3b>(x,(top[i]+2)*20)[0] = 0;
                image_final.at<Vec3b>(x,(top[i]+2)*20)[1] = 255;
                image_final.at<Vec3b>(x,(top[i]+2)*20)[2] = 255;
            }
        }
    }
    
//--------------------------------------------------------------
// show result and output
//--------------------------------------------------------------
        imshow("frame_result",image_final);
    }
    //namedWindow("Display Image", WINDOW_AUTOSIZE );
    //imshow("Display Image", img_out);
    
    //waitKey(0);
    //imwrite(argv[2], img_out);  //image_final
    return 0;
}