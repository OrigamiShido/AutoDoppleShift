function [azimuth,elevations,resultTable,varargout]=satellite(varargin)
% SGP4 tracker
% 输出：预报表resultTable，intvls；雷达图
%% 解析输入
p=inputParser;
addParameter(p,'isSave',false);
addParameter(p,'isIntvls',false);
addParameter(p,'isDoppler',false);
addParameter(p,'isRadargraph',false);
addParameter(p,'isViewer',false);
parse(p,varargin{:});

isSave=p.Results.isSave;
isIntvls=p.Results.isIntvls;
isDoppler=p.Results.isDoppler;
isRadargraph=p.Results.isRadargraph;
isViewer=p.Results.isViewer;

%% 定义数值
% tic
disp('begin...')
latitude=30.5288888;
longitude=114.3530555;
altitude=56;
minelevation=60;
durationtime=1;
starttime=datetime(2025,5,31,14,0,0,'TimeZone',hours(8));
sampletime=60;

%% 模拟环境
disp('creating satellitescenario object...')
% 创建图窗
sc = satelliteScenario(starttime,starttime+hours(durationtime),sampletime);

%% 地面站
disp('creating groundstation...')
% 创建地面站
gs=groundStation(sc,Name='WHU',Latitude=latitude,Longitude=longitude,Altitude=altitude,MinElevationAngle=minelevation);

%% 导入卫星
disp('importing satellites...')
% 创建和读取卫星，渲染轨道
sat=satellite(sc,[pwd,'\gp.tle'],OrbitPropagator="sgp4");

%% 获取位置
disp('getting positions and predicting...')

[position,~]=states(sat,CoordinateFrame='ecef');
% [position_lla,velocity_lla]=states(sat,CoordinateFrame='geographic');
%% 预报

% 获取地面站 ECEF 坐标
gsLLA = [latitude, longitude, altitude];
gsECEF = lla2ecef(gsLLA);
% 转换卫星坐标为ENU
[xn,ye,zup]=ecef2enu(position(1,:,:),position(2,:,:),position(3,:,:),gsLLA(1),gsLLA(2),gsLLA(3),wgs84Ellipsoid);
% 转换ENU坐标为AER
[azimuth,elevations]=enu2aer(xn,ye,zup);
% 数组降维
azimuth=squeeze(azimuth);
elevations=squeeze(elevations);
% 获取可见卫星索引和值
[rowIdx, colIdx] = find(elevations > 60);
theta=deg2rad(azimuth(elevations>60));
rho=elevations(elevations>60);
% 转换为表
rowname=string(starttime:seconds(sampletime):starttime+hours(durationtime));
azimuth=array2table(squeeze(azimuth),"RowNames",rowname,"VariableNames",sat.Name);
elevations=array2table(squeeze(elevations),"RowNames",rowname,"VariableNames",sat.Name);

%% 时间表
Time = elevations.Properties.RowNames(rowIdx);
Satellite = elevations.Properties.VariableNames(colIdx)';
resultTable = table(Time, Satellite,theta,rho);
resultTable = sortrows(resultTable,"Time","ascend");
if isSave
    writetable(resultTable,'predict_local.csv');
end
%% 预报多普勒频移
if isDoppler
    carrierFrequency=11.325e9;
    [frequencyShift,timeOut,dopplerInfo] = dopplershift(sat(1),gs,Frequency=carrierFrequency);
    frequencyRate = dopplerInfo.DopplerRate;
    relativeVelocity = dopplerInfo.RelativeVelocity;

    plot(timeOut,frequencyShift(1,:)/1e3)       % Doppler shift in kilohertz (kHz)
    xlim([timeOut(1) timeOut(end)])
    title("Doppler Shift vs. Time")
    xlabel("Simulation Time")
    ylabel("Doppler Shift (kHz)")
    grid on
    varargout{1}=dopplerInfo;
end

%% 雷达图
if isRadargraph
    disp('plotting radar figure...');

    fig=figure();
    set(fig, 'Renderer', 'painters'); % 设置矢量图渲染器
    set(fig, 'Units', 'normalized', 'Position', [0 0 1 1]); % 最大化
    pax = polaraxes;
    hold on;
    polarscatter(theta, rho, 5, 'filled');
    title('卫星可见性雷达图（elevation > 60°）');

    % 设置r轴为90为中心，0在外圈
    set(pax, 'RTick', 0:5:90, 'RLim', [60 90], 'ThetaZeroLocation', 'top', 'ThetaDir', 'clockwise');
    pax.RDir = 'reverse'; % 让90在中心，0在外圈
    pax.RAxis.Label.String = '天顶角 (°)';
    pax.ThetaAxis.Label.String = '方位角 (°)';
    if isSave
        saveas(fig, 'radar_figure.svg', 'svg');
    end
    % toc
end

%% 设置卫星的可见性(optional)
if isIntvls
    disp('computing visibility...')
    ac=access(gs,sat);
    intvls = accessIntervals(ac);
    intvls = sortrows(intvls,"StartTime","ascend");
    % 切换时区
    intvls.StartTime.TimeZone='Asia/Shanghai';
    intvls.EndTime.TimeZone='Asia/Shanghai';
    if isSave
        writetable(intvls,'predict_matlab.csv');
    end
    varargout{2}=intvls;
end
% toc

%% 创建Viewer
if isViewer
    v=satelliteScenarioViewer(sc,Name='Starlink Scenario Viewer',Basemap='satellite',Dimension='2D');
    campos(v,latitude,longitude);
    play(sc);
end

end