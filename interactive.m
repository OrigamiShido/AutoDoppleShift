function [] = interactive(f,t,s)
%INTERACTIVE 此处显示有关此函数的摘要
%   此处显示详细说明

% 绘制强度图像
figure;
imagesc(f,t,abs(s));
axis xy;
xlabel('X');
ylabel('Y');
title('二维数组强度图像');
colorbar;

% 用户点击两点
disp('请用鼠标点击两个点...');
[clicked_x, clicked_y] = ginput(2); % 获取两个点的坐标

% 显示点击的点
hold on;
plot(clicked_x, clicked_y, 'ro-', 'MarkerSize', 10, 'LineWidth', 2);

% 计算斜率
dx = clicked_x(2) - clicked_x(1);
dy = clicked_y(2) - clicked_y(1);

if dx ~= 0
    slope = dy / dx;
    disp(['两点间斜率为: ', num2str(slope)]);
else
    disp('两点横坐标相同，斜率不存在（垂直线）');
end

% 可选：在图像上注释斜率
mid_x = mean(clicked_x);
mid_y = mean(clicked_y);
text(mid_x, mid_y, ['Slope=', num2str(slope, '%.2f')], ...
    'FontSize', 12, 'Color', 'w', 'BackgroundColor', 'k');
end

