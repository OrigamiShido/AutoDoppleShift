function [result] = hough_detection(f,t,s)
%HOUGH_DETECTION 此处显示有关此函数的摘要
%   此处显示详细说明
% 1. STFT幅值谱
S_abs = abs(s);
% S_norm = mat2gray(S_abs); % 归一化

% 2. 对数增强与二值化
S_log = 20*log(S_abs);
bw = imbinarize(S_log, 'adaptive', 'ForegroundPolarity', 'bright', 'Sensitivity', 0.6);

% 3. 去噪和形态学闭运算
bw = bwareaopen(bw, 10);
bw = imclose(bw, strel('line', 7, 0)); % 横向闭运算，可调长度

% 4. 霍夫变换检测直线
[H, theta, rho] = hough(bw);
peaks = houghpeaks(H, 6, 'threshold', ceil(0.2 * max(H(:)))); % 最多6条直线
lines = houghlines(bw, theta, rho, peaks, 'FillGap', 12, 'MinLength', 20);

% 5. 可视化原频谱和所有直线
figure;
imagesc(f, t, S_abs);
axis xy;
xlabel('Frequency (Hz)');
ylabel('Time (s)');
title('Detected Doppler Lines');
colormap jet;
colorbar;
hold on;

rates=zeros(1,length(lines));
for k = 1:length(lines)
    % 图像坐标到物理坐标
    x1 = interp1(1:length(f), f, lines(k).point1(1));
    y1 = interp1(1:length(t), t, lines(k).point1(2));
    x2 = interp1(1:length(f), f, lines(k).point2(1));
    y2 = interp1(1:length(t), t, lines(k).point2(2));
    plot([x1 x2], [y1 y2], '-', 'LineWidth', 2, 'Color', rand(1,3));
    
    % 计算多普勒频移率
    doppler_rate = (x2 - x1) / (y2 - y1); % Hz/s
    fprintf('Line %d: Doppler rate = %.3f Hz/s\n', k, doppler_rate);
    rates(k)=doppler_rate;
end
hold off;
legend('Detected Doppler Lines');
result=mean(rates);
end

