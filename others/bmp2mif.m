% ===== bmp to mif =====

% clear
clc; clear;

% read img
img = imread('test.bmp');
out = img ./ 64;
n = size(out, 1);
m = size(out, 2);
x = reshape(out, n * m, 3);

% preview
imshow(out .* 64);
pause;

% write header
fid = fopen('test.mif', 'w');
str = strcat('WIDTH=9;\nDEPTH=',num2str(n * m),';\n\nADDRESS_RADIX=BIN;\nDATA_RADIX=BIN;\n\n');
fprintf(fid,str);

% write content
str = 'CONTENT BEGIN\n';
fprintf(fid,str);

for k=1: n*m
    ss = '';
    for i = 1:3
        t = bin(fi(x(k, i)));
        ss = strcat(ss, t(6:8));
    end
    addr = bin(fi(int32(k - 1)));
    str = sprintf('   %s : %s;\n', addr(12: 32), ss);
    fprintf(fid,str);
end

% write footer
fprintf(fid,'END;\n');
fclose(fid);