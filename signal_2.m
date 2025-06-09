function data_dec = signal_2(data,M)
%UNTITLED 此处显示有关此函数的摘要
%   此处显示详细说明
data_dec=zeros(1,length(data));
for n=1:length(data)

    if data(n)>32767   %8位宽的数据有符号数据取值范围[-128,127],(2^8/2-1=127),根据实际位宽修改
       data_dec(n)=double(data(n))-65536;
    else
        data_dec(n) = data(n);
    end

end

end

