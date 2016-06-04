import os,sys
base = [0, 1];

def dec2bin(str_num, length, begin):
	num = int(str_num)
	mid = []
	arr = []
	if begin:
		if num < 0:
			arr.append(1)
		else:
			arr.append(0)
	num = abs(num)
	cnt = length
	while True:
		if num == 0: break
		cnt -= 1
		num, rem = divmod(num, 2)
		mid.append(base[rem])
	while True:
		cnt -= 1
		if cnt == 0 : break
		arr.append(0);
	for i in mid[::-1]:
		arr.append(i)
	return ''.join([str(x) for x in arr])


fin = open("sin_cos");
str_num = fin.read();
fin.close();
arr = str_num.split();
fout = open("sin_cos_bin.mif",'w')
index = 0
fout.write("WIDTH=12;\nDEPTH=722;\n\nADDRESS_RADIX=BIN;\nDATA_RADIX=BIN;\n\nCONTENT BEGIN\n")
for i in arr:
	fout.write("   " + dec2bin(index, 11, False) + " : " + dec2bin(i, 12, True)+";\n")
	index += 1
fout.write("END;")
fout.close()
