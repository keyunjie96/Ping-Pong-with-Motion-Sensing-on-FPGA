#include <iostream>
#include <iomanip>
#include <fstream>
#include <cmath>
using namespace std;
#define PI 3.1415926
int k(double a)
{
	return a*1000;
}
int main()
{
	ofstream fout("sin_cos");
	for(double i = -180; i <= 180; ++i)
	{
		fout << setw(3) << k(sin(i/180*PI)) << endl << k(cos(i/180*PI)) << endl;
	}
	return 0;
}