clear; clc; close all;

%% 1.Load the Encrypted Image
[file,path] = uigetfile({'*.png;*.jpg;*.bmp', 'Image Files'}, 'Select the Encrypted Image to Decrypt');
if isequal(file,0), return; end
cipherImg = imread(fullfile(path, file));
[P, ~, ~] = size(cipherImg);

%% 2.Generate the Same Chaotic Keys
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
    R_seq(i) = mod(round(x*P), P);
end

%% 3.Inverse Diffusion
E1 = cipherImg(:,:,1);
E2 = cipherImg(:,:,2);
E3 = cipherImg(:,:,3);
E = double([E1, E2, E3]);
Ks = hex2dec_blocks(keyHex);
decoded_confused = zeros(size(E));

S = sum(E(:));
for i = numel(E):-1:2
    idx = mod(i-1, 24) + 1;
    V = mod(E(i-1) + Ks(idx), 256);
    decoded_confused(i) = bitxor(uint8(E(i)), bitxor(uint8(V), uint8(Ks(idx))));
end
w = bitxor(uint8(mod(floor(S), 256)), uint8(Ks(1)));
decoded_confused(1) = bitxor(uint8(E(1)), uint8(w));

%% 5.Inverse Confusion
for i = 1:P
    decoded_confused(i, :) = circshift(decoded_confused(i, :), [0, -R_seq(i)]);
end

%% 6.De-concatenation
R_rec = uint8(decoded_confused(:, 1:P));
G_rec = uint8(decoded_confused(:, P+1:2*P)');
B_rec = uint8(flipud(decoded_confused(:, 2*P+1:3*P))');

decryptedImg = cat(3, R_rec, G_rec, B_rec);

%% 7.Output Saving
outputFolder = 'C:\Repositories\Image Encryption\outputFolder_decryption';
timeStamp = char(datetime('now', 'Format', 'yyyy-MM-dd_HH-mm-ss'));

inputFileName = fullfile(outputFolder, ['Input_', timeStamp, '.png']);
decryptedFileName = fullfile(outputFolder, ['Decrypted_', timeStamp, '.png']);

imwrite(decryptedImg, decryptedFileName);
imwrite(cipherImg, inputFileName);

%% 8.Plotting
figure('Name', 'Input');
imshow(cipherImg);
title('Input');

figure('Name', 'Decrypted Output');
imshow(decryptedImg);
title('Decrypted Output');

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