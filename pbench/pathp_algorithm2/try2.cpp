


Path originalContour;
Paths offsetContour;
ClipperOffset contourOffset;
ifstream contourFile;
contourFile.open("contourCoordinate\\" + inputFileName + ".txt", ios::in);
int numOfPath;
contourFile >> numOfPath;
for (int j = 0; j < numOfPath; j++)
{
    originalContour.clear();
    int numOfVertex;
    contourFile >> numOfVertex;
    for (int k = 0; k < numOfVertex; k++)
    {
        double x, y, z;
        contourFile >> x >> y >> z;
        cInt a = x*10e6;
        cInt b = y*10e6;
        layerHeight = z;
        originalContour << IntPoint(a, b);
    }
    contourOffset.AddPath(originalContour, jtRound, etClosedPolygon);
}
        for (int l = 1; l < 5; l++)
        {
            offsetContour.clear();
            contourOffset.Execute(offsetContour, l*pixelSize);
            CString str;
            str.Format(outputFileName + "%d.txt", l);
            SaveToFile("offsetCoordinate\\" + str, offsetContour, layerHeight);
        }
        contourFile.close();