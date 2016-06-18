#include<cstdio>
#include<cstdlib>
#include<cstring>
#include<fstream>
#include<bitset>
#include"bmp.h"
#include"color.h"

using namespace std;

const double EPS = 1e-3;

int main(int argc, char* argv[]) {

	if (argc < 3) {
		printf("Usage: img2mem.exe <input> <output>\n");
		return -1;
	}

	Bmp bmp;
	bmp.Input(argv[1]);
	Bmp preview(bmp.GetH(), bmp.GetW());

	ofstream f(argv[2], ofstream::out);

	for (int i = 0; i < bmp.GetW(); ++ i)
		for (int j = bmp.GetH() - 1; j >= 0; -- j) {
			Color t = bmp.GetColor(j, i);
			int r = (int)(t.r * 8), g = (int)(t.g * 8), b = (int)(t.b * 8);
			f << std::bitset<3>(r).to_string() << std::bitset<3>(g).to_string() << std::bitset<3>(b).to_string() << endl;
			preview.SetColor(j, i, Color(float(r) / 8, float(g) / 8, float(b) / 8));
		}

	preview.Output("preview.bmp");
	return 0;
}
