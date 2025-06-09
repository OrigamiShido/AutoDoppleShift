function result=process_all_files(directory,result_dir_name,analysis_method)
% 扫描目录内所有的iq和xml配对文件，调用processingxx函数，并将结果图片保存到子目录result内
result=[];
% 创建result子目录
disp(['Current directory is:',directory]);
result_dir = fullfile(directory, result_dir_name);
if ~exist(result_dir, 'dir')
    mkdir(result_dir);
end
disp('Result directory created.');

% 获取目录内所有iq和xml文件
disp('iq and xml files getting...')
iq_files = dir(fullfile(directory, '*.iq'));
disp('done.');

% 遍历所有iq文件
for i = 1:length(iq_files)
    iq_file = fullfile(directory, iq_files(i).name);
    xml_file = fullfile(directory, strrep(iq_files(i).name, '.iq', '.xml'));

    % 检查是否存在对应的xml文件
    if exist(xml_file, 'file')
        % 从文件名中提取日期时间部分
        [~, name, ~] = fileparts(iq_files(i).name);
        timestamp = extractAfter(name, '-'); % 提取第一个 '-' 后的部分
        switch analysis_method
            case 'stft'
                disp(['Trying to preccessing files of ',timestamp,'...']);
                % 调用processingxx函数
                try
                    [returnfig,returndata]=processingstft(iq_file, xml_file);
                    set(returnfig, 'Renderer', 'painters'); % 设置矢量图渲染器
                    disp('done. Saving...')
                    % 保存结果图片为矢量图格式
                    result=[result returndata];
                    saveas(returnfig, fullfile(result_dir, append(timestamp, '-1s','.svg')), 'svg');
                    clear returnfig;
                    disp('done.')
                catch ME
                    fprintf('Error processing %s and %s: %s\n', iq_file, xml_file, ME.message);
                end
            case 'wvd'
                disp(['Trying to preccessing files of ',timestamp,'...']);
                % 调用processingxx函数
                try
                    returnfig=processingwvd(iq_file, xml_file,pace=0.01);
                    set(returnfig, 'Renderer', 'painters'); % 设置矢量图渲染器
                    disp('done. Saving...')
                    % 保存结果图片为矢量图格式
                    saveas(returnfig, fullfile(result_dir, append(timestamp, '-0.01s','.svg')), 'svg');
                    clear returnfig;
                    disp('done.')
                catch ME
                    fprintf('Error processing %s and %s: %s\n', iq_file, xml_file, ME.message);
                end
        end

    else
        fprintf('No matching XML file for %s\n', iq_files(i).name);
    end
end
end