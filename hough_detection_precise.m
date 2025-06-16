function [dopplerResult] = hough_detection_precise(f,t,s)
% Doppler Line Detection and Slope Fitting for Noisy STFT Spectrograms
% 适用于 analysisData 结构体，包含 frequency, time, Signal 字段

% 1. STFT幅值谱，并归一化
S_abs = abs(s);

% 2. 对数变换增强对比度
S_log = 20*log(S_abs);
% S_log=mat2gray(S_log);
% figure;
% imagesc(S_log);
bw = imbinarize(S_log, 'adaptive', 'ForegroundPolarity', 'bright', 'Sensitivity', 0.6);
% bw = imbinarize(S_log, 'global');
% figure;
% imagesc(bw);

% 4. 去除小噪点和形态学闭运算补全断点
bw = bwareaopen(bw, 10);  % 去除小于10像素的连通域
bw = imclose(bw, strel('line', 7, 0)); % 横向闭运算

% 5. 霍夫变换检测直线
[H, theta, rho] = hough(bw);
peaks = houghpeaks(H, 6, 'Threshold', ceil(0.2 * max(H(:)))); % 最多检测6条直线
lines = houghlines(bw, theta, rho, peaks, 'FillGap', 12, 'MinLength', 20);

% 6. 在原始频谱图上可视化所有检测直线及其点
figure;
imagesc(f, t, S_abs);
axis xy;
xlabel('Frequency (Hz)');
ylabel('Time (s)');
title('Detected Doppler Lines');
colormap jet;
colorbar;
hold on;

result=zeros(1,length(lines));

for k = 1:length(lines)
    % 端点像素坐标
    x1_px = lines(k).point1(1);
    y1_px = lines(k).point1(2);
    x2_px = lines(k).point2(1);
    y2_px = lines(k).point2(2);

    % 用 improfile 采样直线上的所有点
    npts = max(abs([x2_px-x1_px, y2_px-y1_px]))+1; % 确保采样足够密
    xline = linspace(x1_px, x2_px, npts);
    yline = linspace(y1_px, y2_px, npts);

    % 映射到物理坐标
    freq_pts = interp1(1:length(f), f, xline, 'linear', 'extrap');
    time_pts = interp1(1:length(t), t, yline, 'linear', 'extrap');

    % 只保留在有效范围内的点
    valid = ~isnan(freq_pts) & ~isnan(time_pts) & ...
            (freq_pts >= min(f)) & (freq_pts <= max(f)) & ...
            (time_pts >= min(t)) & (time_pts <= max(t));
    freq_pts = freq_pts(valid);
    time_pts = time_pts(valid);

    % 对所有点做一次线性拟合
    if numel(time_pts) > 2
        p = polyfit(time_pts, freq_pts, 1);
        doppler_rate = p(1); % Hz/s

        % 可视化直线点和拟合结果
        plot(freq_pts, time_pts, 'o', 'MarkerSize', 4, 'Color', [0.8 0.8 0.8]); % 采样点
        plot(polyval(p, t), t, '--', 'LineWidth', 2, 'Color', rand(1,3)); % 拟合线
        % 端点连线
        plot([freq_pts(1), freq_pts(end)], [time_pts(1), time_pts(end)], '-', 'LineWidth', 2, 'Color', rand(1,3));

        % 显示频移率
        fprintf('Line %d: Doppler rate (polyfit all points) = %.3f Hz/s, points used: %d\n', ...
                k, doppler_rate, numel(time_pts));
    else
        % 点数太少时只用端点
        doppler_rate = (freq_pts(end) - freq_pts(1)) / (time_pts(end) - time_pts(1));
        plot([freq_pts(1), freq_pts(end)], [time_pts(1), time_pts(end)], '-', 'LineWidth', 2, 'Color', rand(1,3));
        fprintf('Line %d: Doppler rate (endpoint only) = %.3f Hz/s, points used: %d\n', ...
                k, doppler_rate, numel(time_pts));
    end
    result(k)=doppler_rate;
end

hold off;
legend('Detected Points', 'Fitted Line', 'Location', 'best');
dopplerResult=mean(result);
end

