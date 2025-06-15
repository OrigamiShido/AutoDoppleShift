function [slope]=IntensitySlopeApp(f,t,s)
% GUI
fig = uifigure('Name', '强度图像多点拟合直线', 'Position', [100,100,700,600]);
ax = uiaxes(fig, 'Position', [60, 110, 500, 450]);
hold(ax, 'on');
imagesc(ax, f,t,abs(s));
axis(ax, 'xy'); % y正向向上
xlabel(ax, 'X'); ylabel(ax, 'Y'); colorbar(ax);
title(ax, '多次点击选点，拟合直线');

ptHandles = gobjects(0);        % 存图形句柄
clickPos_xy  = [];              % 存实际坐标

% 信息显示
lbl = uilabel(fig, 'Position', [580, 250, 110, 150], ...
    'Text', '', 'FontSize', 13, 'HorizontalAlignment', 'left');

% 拟合直线句柄
fitLineHandle = gobjects(1);

% 拟合按钮
btn = uibutton(fig, 'Position', [260, 30, 100, 40], ...
    'Text', '拟合直线', 'ButtonPushedFcn', @(btn, event) fitLine());
% 清除按钮
clearBtn = uibutton(fig, 'Position', [380, 30, 100, 40], ...
    'Text', '清除', 'ButtonPushedFcn', @(btn, event) clearPoints());
% 完成按钮
finishBtn = uibutton(fig, 'Position', [500, 30, 100, 40], ...
    'Text', '完成', 'ButtonPushedFcn', @(btn, event) finishAndReturn());

% 缩放和拖动
hzoom = zoom(fig);
setAllowAxesZoom(hzoom, ax, true);
hpan = pan(fig);
setAllowAxesPan(hpan, ax, true);

% 设置点击事件
ax.ButtonDownFcn = @imgClicked;
h = findobj(ax, 'Type', 'Image');
h.PickableParts = 'all';
h.HitTest = 'off'; % 让axes接收点击

    function imgClicked(src, event)
        cp = src.CurrentPoint(1,1:2); % cp = [x, y]坐标
        clickPos_xy = [clickPos_xy; cp];
        ptHandles(end+1) = plot(ax, cp(1), cp(2), 'ro', 'MarkerSize', 10, 'LineWidth',2);
        lbl.Text = sprintf('%d 个点已选择', size(clickPos_xy,1));
        % 拟合线若存在则清除
        if isgraphics(fitLineHandle)
            delete(fitLineHandle);
            fitLineHandle = gobjects(1);
        end
    end

    function fitLine()
        if size(clickPos_xy,1)<2
            uialert(fig, '至少需要两个点进行拟合', '提示');
            return;
        end
        xfit = clickPos_xy(:,1);
        yfit = clickPos_xy(:,2);
        p = polyfit(yfit, xfit, 1);
        slope = p(1);
        intercept = p(2);
        % 绘制拟合直线
        xlim_now = get(ax, 'XLim');
        xLine = linspace(xlim_now(1), xlim_now(2), 100);
        yLine = polyval(p, xLine);
        if isgraphics(fitLineHandle)
            delete(fitLineHandle);
        end
        fitLineHandle = plot(ax, xLine, yLine, 'b-', 'LineWidth', 2);
        % 信息显示
        eqStr = sprintf('y = %.4fx + %.4f', slope, intercept);
        lbl.Text = sprintf('%d 个点已选择\n拟合直线:\n%s\n斜率: %.4f', size(clickPos_xy,1), eqStr, slope);
    end

    function clearPoints()
        % 删除点和直线
        for k = 1:numel(ptHandles)
            if isgraphics(ptHandles(k)), delete(ptHandles(k)); end
        end
        if isgraphics(fitLineHandle)
            delete(fitLineHandle);
        end
        clickPos_xy = [];
        ptHandles = gobjects(0);
        fitLineHandle = gobjects(1);
        lbl.Text = '';
        slope = [];
    end

    function finishAndReturn()
        % 若没有拟合则尝试自动拟合
        if isempty(slope)
            fitLine();
        end
        % 若拟合依然无效则返回空
        if isempty(slope)
            slope = [];
        end
        close(fig);
    end

% 等待窗口关闭
uiwait(fig);

% 若用户直接关闭窗口
if isvalid(fig)
    close(fig);
end
end