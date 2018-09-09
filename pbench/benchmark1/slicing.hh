#ifndef SLICING
#define SLICING

#define CPU_ITEMS       3
#define FileIO          0
#define Intersection    1
#define Distance        2
#define BlockEnd        -1

class Slicing{
    
public:
    int miss_curr;
    int intersection_curr;
    int intersection;
    
private:
    int int_tmp;
    int distance1,distance2;
    int group;
    int i,j,k,tmp,point,tp_case,tp_case_test;    // group is 3 point, point is each point
    int not_connect,tmp_pointback;
    
public:
    Slicing():miss_curr(0),intersection_curr(0)
    {}
    
public:
    void intersections(vector<Data>& data_in, int z, vector<Data>& data_out, int *contour_points);
    void contourgene(vector<Data>& data_out,int &iNumberOfContours,vector<int>& iOrientation,vector<int>& iNumberOfPoints, int &locality_distance);
    void contouropt(vector<Data>& data_out,int &iNumberOfContours,vector<int>& Orientations,vector<int>& NumbersOfPoints);
    void contourdire(vector<Data>& data_out,int &iNumberOfContours,vector<int>& iOrientation,vector<int>& iNumberOfPoints);
    template<typename T>
    void quicksort(vector<SILA<T> >& Data_tmp1, int left, int right);
};

#endif
