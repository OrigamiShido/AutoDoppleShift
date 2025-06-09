%% 预报表和多普勒频移
frequencyRate=dopplercalc();
%% 预报图
analysisData=process_all_files([pwd,'\data'],'result','stft');

% 假设 analysisData 已在工作区，含 frequency, time, Signal 字段
%% 
hough_detection(analysisData(2).frequency,analysisData(2).time,analysisData(2).Signal)