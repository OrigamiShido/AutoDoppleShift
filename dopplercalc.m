function [frequencyRate,azimuth,elevations]=dopplercalc(targetTime)
%% 定义数值
% tic
disp('begin...')
latitude=30.5288888;
longitude=114.3530555;
altitude=56;
minelevation=0;
durationtimeSeconds=120;
starttime=targetTime;
sampletime=1;

%% 模拟环境
disp('creating satellitescenario object...')
% 创建图窗
sc = satelliteScenario(starttime,starttime+seconds(durationtimeSeconds),sampletime);

%% 地面站
disp('creating groundstation...')
% 创建地面站
gs=groundStation(sc,Name='WHU',Latitude=latitude,Longitude=longitude,Altitude=altitude,MinElevationAngle=minelevation);

%% 导入卫星
disp('importing satellites...')
% 创建和读取卫星，渲染轨道
sat=satellite(sc,[pwd,'\gp2.tle'],OrbitPropagator="sgp4");
%% 预报多普勒频移
disp('Predicting Doppler shift...')
carrierFrequency=11.325e9;
[frequencyShift,timeOut,dopplerInfo] = dopplershift(sat,gs,Frequency=carrierFrequency);
frequencyRate = dopplerInfo.DopplerRate;
relativeVelocity = dopplerInfo.RelativeVelocity;

%% 做表，删除nan行
rowname=string(starttime:seconds(sampletime):starttime+seconds(durationtimeSeconds-1));
frequencyRate=array2table(frequencyRate','RowNames',rowname,'VariableNames',sat.Name);
frequencyRate(:,all(isnan(frequencyRate{:,:})))=[];

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
% 转换为表
rowname=string(starttime:seconds(sampletime):starttime+seconds(durationtimeSeconds));
azimuth=array2table(squeeze(azimuth),"RowNames",rowname,"VariableNames",sat.Name);
elevations=array2table(squeeze(elevations),"RowNames",rowname,"VariableNames",sat.Name);

% %% 设置卫星的可见性(optional)
% 
% disp('computing visibility...')
% ac=access(gs,sat);
% intvls = accessIntervals(ac);
% intvls = sortrows(intvls,"StartTime","ascend");
% % 切换时区
% intvls.StartTime.TimeZone='Asia/Shanghai';
% intvls.EndTime.TimeZone='Asia/Shanghai';

end