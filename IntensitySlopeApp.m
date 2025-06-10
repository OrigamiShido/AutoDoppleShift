function IntensitySlopeApp(f,t,s)
    % 示例数据
    % GUI
    fig = uifigure('Name', '强度图像点击选点与斜率', 'Position', [100,100,700,600]);
    ax = uiaxes(fig, 'Position', [60, 110, 500, 450]);
    hold(ax, 'on');
    imagesc(ax, f,t,abs(s));
    axis(ax, 'xy'); % y正向向上
    xlabel(ax, 'X'); ylabel(ax, 'Y'); colorbar(ax);
    title(ax, '点击选两点，自动计算斜率');
    
    ptHandles = gobjects(2,1);
    clickPos_pix = zeros(2,2);  % 存像素坐标
    clickPos_xy  = zeros(2,2);  % 存实际坐标
    clickCnt = 0;
    
    % 信息显示
    lbl = uilabel(fig, 'Position', [580, 250, 110, 100], ...
        'Text', '', 'FontSize', 13, 'HorizontalAlignment', 'left');
    
    % 确定按钮
    btn = uibutton(fig, 'Position', [300, 30, 100, 40], ...
        'Text', '确定', 'ButtonPushedFcn', @(btn, event) confirmPoint());
    
    % 设置缩放和拖动
    hzoom = zoom(fig);
    setAllowAxesZoom(hzoom, ax, true);
    hpan = pan(fig);
    setAllowAxesPan(hpan, ax, true);

    % 设置点击事件（注意：imagesc创建的对象需用ax的ButtonDownFcn）
    ax.ButtonDownFcn = @imgClicked;
    h = findobj(ax, 'Type', 'Image');
    h.PickableParts = 'all';
    h.HitTest = 'off'; % 让axes接收点击

    function imgClicked(src, event)
        cp = src.CurrentPoint(1,1:2); % cp = [x, y]坐标
        if clickCnt < 2
            clickCnt = clickCnt + 1;
        else
            clearPoints();
            clickCnt = 1;
        end
        clickPos_xy(clickCnt, :) = cp; % 记录实际坐标
        % 画点
        if isgraphics(ptHandles(clickCnt)), delete(ptHandles(clickCnt)); end
        ptHandles(clickCnt) = plot(ax, cp(1), cp(2), 'ro', 'MarkerSize', 10, 'LineWidth',2);
        % 显示信息
        if clickCnt == 2
            slope = calcSlope(clickPos_xy(2,:),clickPos_xy(1,:));
            msg = sprintf('点1: (%.3f, %.3f)\n点2: (%.3f, %.3f)\n斜率: %s', ...
                clickPos_xy(1,1), clickPos_xy(1,2), clickPos_xy(2,1), clickPos_xy(2,2), slope);
            lbl.Text = msg;
        else
            lbl.Text = sprintf('点1: (%.3f, %.3f)', clickPos_xy(1,1), clickPos_xy(1,2));
        end
    end

    function s = calcSlope(p1, p2)
        dx = p2(1) - p1(1);
        dy = p2(2) - p1(2);
        if dx == 0
            s = '无穷大';
        else
            s = num2str(dy/dx, '%.4f');
        end
    end

    function confirmPoint()
        if clickCnt == 0
            uialert(fig, '请先点击选择点', '提示');
        elseif clickCnt == 1
            uialert(fig, sprintf('你选择的点为: (%.3f, %.3f)', clickPos_xy(1,1), clickPos_xy(1,2)), '选择结果');
        else
            slope = calcSlope(clickPos_xy(2,:),clickPos_xy(1,:));
            msg = sprintf(['你选择的点为:\n点1: (%.3f, %.3f)\n点2: (%.3f, %.3f)\n斜率: %s'], ...
                clickPos_xy(1,1), clickPos_xy(1,2), clickPos_xy(2,1), clickPos_xy(2,2), slope);
            uialert(fig, msg, '选择结果');
        end
    end

    function clearPoints()
        for k = 1:2
            if isgraphics(ptHandles(k)), delete(ptHandles(k)); end
        end
        clickPos_pix(:) = 0;
        clickPos_xy(:) = 0;
        clickCnt = 0;
        lbl.Text = '';
    end
end