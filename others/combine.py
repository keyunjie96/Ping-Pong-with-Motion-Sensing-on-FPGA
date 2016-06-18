src1 = '1.txt'
src2 = '2.txt'

lines1 = open(src1).readlines()
lines2 = open(src2).readlines()

out = 'test.txt'
f = open(out, 'w')
for i in xrange(len(lines1)):
	if (len(lines1[i]) > 0):
		f.write('00000000000000' + lines1[i].replace('\n','') + lines2[i].replace('\n','') + '\n')
f.close()
