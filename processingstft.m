function [fig,data]=processingstft(file_iq,file_xml,varargin)
% 处理函数
% input:file_iq:iq file
% file_xml:xml file
% pace:读取秒步长：默认0.1
% analyze_time: 分析时间，输入大于0值以指定，否则默认为全部时长
% style:绘图风格：mesh/surf/waterfall

%% 解析输入
p=inputParser;

default_analyze=0;
default_pace=0.1;

addRequired(p,'file_iq');
addRequired(p,'file_xml');
addParameter(p,'analyze_time',default_analyze);
addParameter(p,'pace',default_pace);

parse(p,file_iq,file_xml,varargin{:});

file_iq=p.Results.file_iq;
file_xml=p.Results.file_xml;
pace=p.Results.pace;
analyze_time=p.Results.analyze_time;

clear checkstyle default_style default_analyze default_pace p validstyle varargin;

%% 提取文件名中的日期时间部分
[~, name, ~] = fileparts(file_iq);
timestamp_raw = extractAfter(name, '-'); % 提取第一个 '-' 后的部分
timestamp = regexprep(timestamp_raw, '(\d{2})h(\d{2})m(\d{2})s(\d+)', '$1:$2:$3:$4'); % 格式化时间


%% 读文件
params=xmlread(file_xml);
fid=fopen(file_iq,'r');

clear file_xml;

f0=str2double(params.getElementsByTagName('CenterFrequency').item(0).getTextContent());
fs=str2double(params.getElementsByTagName('SampleRate').item(0).getTextContent());
center_frequency=str2double(params.getElementsByTagName('CenterFrequency').item(0).getTextContent());
% decimation=str2double(params.getElementsByTagName('Decimation').item(0).getTextContent());
sample_count=str2double(params.getElementsByTagName('SampleCount').item(0).getTextContent());
% ScaleFactor=str2double(params.getElementsByTagName('ScaleFactor').item(0).getTextContent());
% fs=40000000/decimation
time=sample_count/fs;%%按1秒10M的采样率（复数，真实数据是20M），采样了5秒--获取采集时间；

fseek(fid,(1-1)*10^6, 'bof'); % 将文件位置设置为文件开头之后的字节数

sample_read_count=fs*pace;
if(analyze_time>0)
    loop=length(0:pace:(analyze_time-pace));
else
    loop=length(0:pace:(time-pace));
end
clear analyze_time sample_count

% 参数定义
window_length = 4096; % 窗口长度
overlap = 2048;        % 窗口重叠长度
nfft = 4096;          % FFT 点数

S_all = [];
T_all = [];
F = [];

%% 计算
for cnt=1:loop

    Data_all = fread(fid,sample_read_count,'*ubit16');%每次读1M复数数据，即0.1秒，指针到达数据尾巴处，但不是文件尾巴处
    Data_IQ=Data_all;%后面在循环中不要关闭文件

    N=length(Data_IQ);%N为10^6

    %% 读取IQ数据
    Data_I=Data_IQ(1:2:N-1);
    Data_Q=Data_IQ(2:2:N);

    % if (cnt==1)
    %     figure();
    %     plot(Data_I,'-ro');
    %     hold on;
    %     plot(Data_Q,'-bo');
    %     hold on;
    % end

    %% 符号位处理
    % Data_IQ_10= bin2dec(Data_IQ);
    data_dec_I = signal_2(Data_I,16);
    data_dec_Q = signal_2(Data_Q,16);%%5*10^6个

    % if (cnt==1)
    %     figure();
    %     plot(data_dec_I,'-ro');
    %     hold on;
    %     plot(data_dec_Q,'-bo');
    %     hold on;
    % end
    %% 转换为满量程数值到 -1.0---1.0范围内电压值 （MV）
    data_dec_I=data_dec_I/2^15;
    data_dec_Q=data_dec_Q/2^15;

    signal=data_dec_I+1i*data_dec_Q;%signal=data_dec_I-i*data_dec_Q;这也是引起频谱翻转的一个地方.数据

    % --------------------------------------------------
    %% 信号处理部分
    [S, F_tmp, T] = stft(signal, fs, 'Window', blackman(window_length), ...
        'OverlapLength', overlap, 'FFTLength', nfft);

    if isempty(F)
        F = F_tmp; % 只取一次频率轴
    end

    % 时间轴需要加上当前段的起始时间
    T = T + (cnt-1)*pace;

    % 拼接
    S_all = [S_all, S];
    T_all = [T_all, T];
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end
fclose(fid);

% % 计算 STFT
% [S, F, T] = stft(wave, fs, 'Window', hamming(window_length), ...
%     'OverlapLength', overlap, 'FFTLength', nfft);

% 保证 F 和 T_all 为列向量
F = F(:);
T_all = T_all(:).';

% 检查 S_all 尺寸是否匹配
if size(S_all,1) ~= length(F) || size(S_all,2) ~= length(T_all)
    error('S_all 的尺寸与 F 或 T_all 不匹配');
end

% 绘制时频图（不显示图窗，最大化）
fig = figure('Visible', 'off');
set(fig, 'Units', 'normalized', 'Position', [0 0 1 1]); % 最大化
% imagesc(F+center_frequency, T_all, 20*log10(abs(S_all.')),[-12,-6]); axis xy;% 小天线对数坐标窗blackman
imagesc(F+center_frequency, T_all, 20*log10(abs(S_all.')),[-10,-4]); axis xy;% 锅天线对数坐标窗blackman
xlabel(sprintf('频率 (Hz)\nSample rate: %.2f Hz, Time: %.2f s', fs, time));
ylabel('时间 (s)');
title(['STFT时频图 ',timestamp]);
colorbar;

data=struct('frequency',F+center_frequency,'time',T_all,'Signal',S_all.');
end