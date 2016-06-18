# _*_ enc:gbk _*_

src = 'test.txt'
lines = open(src).readlines();

out = 'bg.bin'
f = open(out, 'wb')
for line in lines:
	if (len(line) > 0):
		a = [int(line[8 * x: 8 * (x+1)], 2) for x in [3, 2, 1, 0]]
		f.write(bytearray(a))
f.close()
