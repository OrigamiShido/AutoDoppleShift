% tic

%% 数值定义
targetTime=[datetime(2025,5,17,15,39,57,698,'TimeZone',hours(8)) datetime(2025,5,17,15,44,29,94,'TimeZone',hours(8))];
k=2;
%% 预报表和多普勒频移
[frequencyRate,azimuth,elevations]=dopplercalc();

%% 预报图
analysisData=process_all_files([pwd,'\data'],'result','stft');

%% 检测和找到多普勒频移量
doppler_rates=hough_detection_precise(analysisData(k).frequency,analysisData(k).time,analysisData(k).Signal);
if isnan(doppler_rates)
    doppler_rates=IntensitySlopeApp(analysisData(k).frequency,analysisData(k).time,analysisData(k).Signal);
end
%% 找到最接近的卫星名称
timeRange=string(targetTime(k):seconds(1):targetTime(k)+seconds(5));
[~,idx]=mink(doppler_rates-frequencyRate{timeRange,:},5,2,'ComparisonMethod','abs');
satelliteResult=frequencyRate(:,unique(idx(:,:),'stable')).Properties.VariableNames;
satelliteResult = satelliteResult(arrayfun(@(c) any(azimuth{timeRange,c{1}} >= 45 & azimuth{timeRange,c{1}} <= 135), satelliteResult));
disp('预测卫星：');
disp(satelliteResult{1});
% toc

% find((azimuth{timeRange,:}>45)&(azimuth{timeRange,:}<135))