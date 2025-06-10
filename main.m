% tic

%% 数值定义
targetTime=[datetime(2025,5,17,15,39,57,698,'TimeZone',hours(8)) datetime(2025,5,17,15,44,29,94,'TimeZone',hours(8))];
k=2;
%% 预报表和多普勒频移
frequencyRate=dopplercalc();

%% 预报图
analysisData=process_all_files([pwd,'\data'],'result','stft');

%% 检测和找到多普勒频移量
doppler_rates=hough_detection(analysisData(k).frequency,analysisData(k).time,analysisData(k).Signal);
% doppler_rates2=hough_detection_precise(analysisData(k).frequency,analysisData(k).time,analysisData(k).Signal);

%% 找到最接近的卫星名称
[~,idx]=min(abs(doppler_rates-frequencyRate(string(targetTime(k):seconds(1):targetTime(k)+seconds(5)),:)),[],2);
satelliteResult=frequencyRate(:,unique(idx{:,:},'stable')).Properties.VariableNames;
disp('预测卫星：');
disp(satelliteResult);
% toc