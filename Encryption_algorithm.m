clear; clc; close all;

%% 1.Load the images
[file,path] = uigetfile({'*.jpg;*.png;*.bmp', 'Image Files'}, 'Select an Image to Encrypt');
if isequal(file,0), return; end
img = imread(fullfile(path, file));
img = imresize(img, [256,256]);
[P, ~, ~] = size(img);

%% 2.Converting to RGB planes and concatenating the planes
R = img(:,:,1);
G = img(:,:,2)';
B = flipud(img(:,:,3)');
concatenatedImg = [R, G, B];

%% 3.Generating the chaotic number using Keys
keyHex = '8127812AB5DBD629DB287628DE2387FC45BC47AA6504ACBF';

K1 = hex2num_custom(keyHex(1:12));
K2 = hex2num_custom(keyHex(13:24));
K3 = hex2num_custom(keyHex(25:36));
K4 = hex2num_custom(keyHex(37:48));
PBP = 14160.01;
a = PBP + 0.001*mod((K1 + K2), 1);
x = mod((K3+K4),1);

R_seq = zeros(1, P);
for i = 1:P
    x = mod(a*x*(1-x),1);
    R_seq(i) = mod(round(x*P),P);
end

%% 4.Confusion algorithm
confusedImg = concatenatedImg;
for i = 1:P
    confusedImg(i,:) = circshift(confusedImg(i, :), R_seq(i));
end

%% 5.Diffusion
E = double(confusedImg);
S = sum(E(:));
Ks = hex2dec_blocks(keyHex);

w = bitxor(mod(floor(S), 256), Ks(1));
E(1) = bitxor(uint8(confusedImg(1)), uint8(w));

for i = 2:numel(E)
    idx = mod(i-1, 24) + 1;
    V = mod(E(i-1)+Ks(idx), 256);
    E(i) = bitxor(uint8(confusedImg(i)), bitxor(uint8(V), uint8(Ks(idx))));
end

cipherPart1 = E(:, 1:P);
cipherPart2 = E(:, P+1:2*P);
cipherPart3 = E(:, 2*P+1:3*P);
cipherImg = uint8(cat(3, cipherPart1, cipherPart2, cipherPart3));

%% 6.Output saving
outputFolder = 'C:\Repositories\Image Encryption\outputFolder_encryption';

timeStamp = char(datetime('now','Format', 'yyyy-mm-dd_HH-MM-SS'));

origFileName = fullfile(outputFolder, ['Original_', timeStamp, '.png']);
cipherFileName = fullfile(outputFolder, ['Encrypted_', timeStamp, '.png']);

imwrite(img, origFileName);
imwrite(cipherImg, cipherFileName);

fprintf('Images saved successfully in: %s\n', outputFolder);
figure('Name', 'Original Image Output');
imshow(img);
title('Original Photo');

%% 7.Plotting
figure('Name', 'Encrypted Image Output');
imshow(cipherImg);
title('Encrypted Cipher Image');

%% Conversion functions
function val = hex2num_custom(hexStr)
decVal = 0;
for i = 1:length(hexStr)
    decVal = decVal*16 + hexdec_single(hexStr(i));
end
val = decVal/(2^48 + 1);
end

function d = hexdec_single(c)
d = find('0123456789ABCDEF' == upper(c)) - 1;
end

function blocks = hex2dec_blocks(hexStr)
blocks = zeros(1, 24);
for i = 1:24
    blocks(i) = hex2dec(hexStr(2*i-1 : 2*i));
end
end
