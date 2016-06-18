% ===== bmp to memory =====

% clear
clc; clear;

% read img
img = imread('end.bmp');
out = img ./ 32;
n = size(out, 1);
m = size(out, 2);
x = reshape(out, n * m, 3);

% preview
imshow(out .* 32);
pause;

% write header
fid = fopen('3.txt', 'w');

for k=1: n*m
    ss = '';
    for i = 1:3
        t = bin(fi(x(k, i)));
        ss = strcat(ss, t(6:8));
    end
    str = sprintf('%s\n', ss);
    fprintf(fid,str);
end

fclose(fid);