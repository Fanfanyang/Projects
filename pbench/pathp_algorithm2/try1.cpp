#include "clipper.hpp"
#include <iostream>
#include <fstream>


using namespace ClipperLib;
using namespace std;

int main()
{
    Path subj;
    Paths try1;
    Paths solution;
    ClipperOffset co;
    double layerHeight = 0.1;
    
    subj <<
    IntPoint(348,257) << IntPoint(364,148) << IntPoint(362,148) <<
    IntPoint(326,241) << IntPoint(295,219) << IntPoint(258,88) <<
    IntPoint(440,129) << IntPoint(370,196) << IntPoint(372,275);

    co.AddPath(subj, jtRound, etClosedPolygon);
    co.Execute(solution, -1.0);

    ofstream result("result_try.txt");
    
    cout << subj << endl;
    cout << solution[0][2].X << endl;
    result.close();
}