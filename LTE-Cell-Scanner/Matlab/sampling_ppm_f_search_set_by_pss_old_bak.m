% Jiao Xianjun (putaoshu@msn.com; putaoshu@gmail.com)
% Find out LTE PSS in the signal stream and correct sampling&carrier error.
% A script of project: https://github.com/JiaoXianjun/rtl-sdr-LTE

function [ppm, f_set, xc, fo_idx_set, pss_idx_set, fo_pss_idx_set, fo_with_all_pss_idx, extra_info] = sampling_ppm_f_search_set_by_pss(s, fo_search_set, pss_fo_set, sampling_carrier_twist, max_reserve, num_pss_period_try, combined_pss_peak_range, par_th, num_peak_th)
% sampling period PPM! not sampling frequency PPM!

% fo_search_set = -100e3 : 5e3 : 100e3; % -100kHz ~ 100 kHz with 5kHz step size
% pss_fo_set = pss_fo_set_gen(td_pss, fo_search_set);

combined_pss_peak_range_half = floor(combined_pss_peak_range/2);
extra_info = [];

len_pss = size(pss_fo_set, 1);
num_fo_pss = size(pss_fo_set, 2);

len = length(s);
len_short = len - (len_pss-1);

corr_store = zeros(len_short, num_fo_pss);

for i=1:num_fo_pss
    tmp_corr = abs( filter(pss_fo_set(end:-1:1, i), 1, s) ).^2;
    tmp_corr = tmp_corr(len_pss:end);
    corr_store(:,i) = tmp_corr;
end

if sampling_carrier_twist==1
    ppm = inf;
    f_set = fo_search_set;
    
    fo_idx_set = 1:length(f_set);
    n_f = length(f_set);
    xc=zeros(3,len_short,n_f);
    for foi=1:n_f
      for t=1:3
        col_idx = (t-1)*length(fo_search_set) + fo_idx_set(foi);
        xc(t,:,foi)=corr_store(:,col_idx);
      end
    end

    pss_idx_set = inf;
    fo_pss_idx_set = inf;
    fo_with_all_pss_idx = inf;
    disp('Corr done.');
    return;
end

if num_pss_period_try == 1
    pss_period = 19200/2;
    shift_len = ceil( len_short./pss_period );
elseif num_pss_period_try == 3
    pss_period = [(19200/2)-1, (19200/2), (19200/2)+1];
    shift_len = 1;
else
    disp('sampling_ppm_f_search_set_by_pss: num_pss_period_try must be 1 or 3 currently!');
    return;
end
num_half_radioframe = floor( len_short./pss_period );
max_peak_all = zeros(1, num_pss_period_try*num_fo_pss);
max_idx_all = zeros(1, num_pss_period_try*num_fo_pss);
peak_to_avg = zeros(1, num_pss_period_try*num_fo_pss);
for i=1:num_pss_period_try
    corr_store_tmp = corr_store(1:pss_period(i), : );
    for j=2:num_half_radioframe(i)
        sp = (j-1)*pss_period(i) + 1;
        ep = j*pss_period(i);
        corr_store_tmp = corr_store_tmp + corr_store(sp:ep, : );
    end
    
    % % ---------shift add------------------------------------
    corr_store_tmp_tmp = corr_store_tmp;
    corr_store_tmp = zeros(pss_period(i), num_fo_pss);
    for k = -shift_len : shift_len
        corr_store_tmp = corr_store_tmp + circshift(corr_store_tmp_tmp, [k,0]);
    end
    % % ----------------end of shift add------------------------
    
    sp = (i-1)*num_fo_pss + 1;
    ep = i*num_fo_pss;
    [max_peak_all(sp:ep), max_idx_all(sp:ep)] = max(corr_store_tmp, [], 1);
    for j=sp:ep
        tmp_peak = max_peak_all(j);
        tmp_max_idx = max_idx_all(j);
        peak_area_range = (tmp_max_idx-combined_pss_peak_range_half) : (tmp_max_idx+combined_pss_peak_range_half);
        peak_area_range = mod(peak_area_range-1, pss_period(i)) + 1;
        tmp_avg = corr_store_tmp(:, j-sp+1);
        tmp_avg(peak_area_range) = [];
        tmp_avg = mean(tmp_avg);
        peak_to_avg(j) = 10*log10(tmp_peak/tmp_avg);
    end
end

[~, sort_idx] = sort(max_peak_all, 'descend');

% max_reserve = 1;
above_par_idx = (peak_to_avg(sort_idx(1:max_reserve)) > par_th);
disp(['Hit        PAR ' num2str(peak_to_avg(sort_idx(1:max_reserve))) 'dB']);
extra_info.par = peak_to_avg(sort_idx(1:max_reserve));
extra_info.sort_idx = sort_idx(1:max_reserve);
a_tmp = kron( ones(1, num_pss_period_try), [fo_search_set fo_search_set fo_search_set] );
extra_info.fo_raw = a_tmp(sort_idx(1:max_reserve));

if sum(above_par_idx)==0
    xc = 0;
    ppm = inf;
    f_set = inf;
    fo_idx_set = inf;
    pss_idx_set = inf;
    fo_pss_idx_set = inf;
    fo_with_all_pss_idx = inf;
    disp('No strong enough PSS correlation peak.');
    return;
end

sort_idx = sort_idx(above_par_idx);
max_idx = max_idx_all(sort_idx);

ppm = inf(1, length(sort_idx));
f_set = inf(1, length(sort_idx));
pss_idx_set = inf(1, length(sort_idx));
fo_pss_idx_set = inf(1, length(sort_idx));
fo_idx_set = inf(1, length(sort_idx));

real_count = 0;
extra_info.num_forPPM = zeros(1, length(sort_idx));
for i=1:length(sort_idx)
    shift_idx = floor( ( sort_idx(i)-1 )/num_fo_pss ) + 1; % 1 -- -1; 2 -- 0; 3 -- 1
    fo_pss_idx = sort_idx(i) - (shift_idx-1)*num_fo_pss;
    
    % calculate pss idx
    pss_idx = floor( (fo_pss_idx-1)/length(fo_search_set) ) + 1;
    
    % calculate frequency offset
    fo_idx = mod(fo_pss_idx-1, length(fo_search_set)) + 1;
    f_tmp = fo_search_set(fo_idx);
    
    % calculate PPM
    corr_seq = corr_store(:, fo_pss_idx);
    tmp_max_idx = max_idx(i);
    tmp_pss_period = pss_period(shift_idx);
    if tmp_max_idx-3 < 1
        tmp_max_idx = tmp_max_idx + tmp_pss_period;
    end
    
    num_peak = num_half_radioframe(shift_idx) + 1;
    peak_val = zeros(1, num_peak);
    peak_idx = zeros(1, num_peak);
    peak_count = 1;
    for j=tmp_max_idx : tmp_pss_period : len_short
        if j+3 <= len_short
            [tmp_val, tmp_idx] = max(corr_seq(j-3:j+3));
            if tmp_idx ~=1 && tmp_idx ~=7
                peak_val(peak_count) = tmp_val;
                
%                 tmp_seq = corr_seq(j-3:j+3);
%                 tmp_seq(tmp_idx-1:tmp_idx+1) = tmp_seq(tmp_idx-1:tmp_idx+1) - min(tmp_seq(tmp_idx-1:tmp_idx+1));
% %                 tmp_seq(tmp_idx-1:tmp_idx+1) = tmp_seq(tmp_idx-1:tmp_idx+1) - ( (sum(tmp_seq)-sum(tmp_seq(tmp_idx-1:tmp_idx+1)))/4 );
%                 sum_peak = sum(tmp_seq(tmp_idx-1:tmp_idx+1));
%                 tmp_idx = (tmp_idx-1)*(tmp_seq(tmp_idx-1)/sum_peak) + tmp_idx*(tmp_seq(tmp_idx)/sum_peak) + (tmp_idx+1)*(tmp_seq(tmp_idx+1)/sum_peak);
% 
                tmp_seq = corr_seq(j-3:j+3);
                tmp_seq = tmp_seq(tmp_idx-1:tmp_idx+1);
                tmp_seq = tmp_seq - min(tmp_seq);
                sum_peak = sum(tmp_seq);
                tmp_idx = (tmp_idx-1)*(tmp_seq(1)/sum_peak) + tmp_idx*(tmp_seq(2)/sum_peak) + (tmp_idx+1)*(tmp_seq(3)/sum_peak);

%                 tmp_seq = corr_seq(j-3:j+3);
%                 tmp_seq = tmp_seq((tmp_idx-1):(tmp_idx+1));
%                 if tmp_seq(1) > tmp_seq(3)*1.4
%                     tmp_seq = tmp_seq - tmp_seq(3);
%                     sum_peak = sum(tmp_seq(1:2));
%                     tmp_idx = (tmp_idx-1)*(tmp_seq(1)/sum_peak) + tmp_idx*(tmp_seq(2)/sum_peak);
%                 elseif tmp_seq(3) > tmp_seq(1)*1.4
%                     tmp_seq = tmp_seq - tmp_seq(1);
%                     sum_peak = sum(tmp_seq(2:3));
%                     tmp_idx = tmp_idx*(tmp_seq(2)/sum_peak) + (tmp_idx+1)*(tmp_seq(3)/sum_peak);
%                 else
%                     tmp_seq = tmp_seq - (sum(corr_seq(j-3:j+3)) - sum(tmp_seq))/4;
%                     sum_peak = sum(tmp_seq);
%                     tmp_idx = (tmp_idx-1)*(tmp_seq(1)/sum_peak) + tmp_idx*(tmp_seq(2)/sum_peak) + (tmp_idx+1)*(tmp_seq(3)/sum_peak);
%                 end
            else
                peak_val(peak_count) = 0;
                disp(['Seems not a peak ' num2str(corr_seq(j-3:j+3).') ' at i=' num2str(i) ' j=' num2str(j)]);
            end
            peak_idx(peak_count) = j-3+tmp_idx-1;
            peak_count = peak_count + 1;
        else
            break;
        end
    end
    peak_val = peak_val(1: peak_count-1);
    peak_idx = peak_idx(1: peak_count-1);
    
    peak_val_th = max(peak_val)/2;
    first_idx = find(peak_val>peak_val_th, 1, 'first');
    last_idx = find(peak_val>peak_val_th, 1, 'last');
    
    if last_idx-first_idx < (num_peak*num_peak_th)
        disp(['Too few peak at i=' num2str(i) ' of total ' num2str(length(sort_idx))]);
        continue;
    else
        disp(['Hit num forPPM ' num2str(last_idx-first_idx)]);
    end
    extra_info.num_forPPM(i) = last_idx-first_idx;
    
    real_dist = peak_idx(last_idx) - peak_idx(first_idx);
    ideal_dist = round( real_dist/9600 )*9600;
    
    ppm_tmp = 1e6*(real_dist-ideal_dist)/ideal_dist;
    
    exist_flag = false;
    for j=1:real_count
        if abs(f_tmp - f_set(j))<7500 && abs(ppm_tmp - ppm(j))<6
            exist_flag = true;
            disp(['duplicated fo and ppm ' num2str(f_tmp/1e3) 'kHz ' num2str(ppm_tmp) 'PPM at i=' num2str(i) ' j=' num2str(j)]);
            break;
        end
    end
    
    if ~exist_flag
        real_count = real_count + 1;
        f_set(real_count) = f_tmp;
        ppm(real_count) = ppm_tmp;
        fo_pss_idx_set(real_count) = fo_pss_idx;
        pss_idx_set(real_count) = pss_idx;
        fo_idx_set(real_count) = fo_idx;
    end
end

if real_count==0
    xc = 0;
    ppm = inf;
    f_set = inf;
    fo_idx_set = inf;
    pss_idx_set = inf;
    fo_pss_idx_set = inf;
    fo_with_all_pss_idx = inf;
    disp('No valid PSS hit sequence.');
    return;
end

f_set = f_set(1:real_count);
ppm = ppm(1:real_count);
fo_pss_idx_set = fo_pss_idx_set(1:real_count);
pss_idx_set = pss_idx_set(1:real_count);
fo_idx_set = fo_idx_set(1:real_count);

fo_with_all_pss_idx = [fo_idx_set, length(fo_search_set) + fo_idx_set, length(fo_search_set)*2 + fo_idx_set];

n_f = length(f_set);
xc=zeros(3,len_short,n_f);
for foi=1:n_f
  for t=1:3
    col_idx = (t-1)*length(fo_search_set) + fo_idx_set(foi);
    xc(t,:,foi)=corr_store(:,col_idx);
  end
end

disp(['Hit         FO ' num2str(f_set./1e3) 'kHz']);
disp(['Hit        PPM ' num2str(ppm)]);
disp(['Hit    PSS idx ' num2str(pss_idx_set)]);
disp(['Hit     FO idx ' num2str(fo_idx_set)]);
disp(['Hit FO_PSS idx ' num2str(fo_pss_idx_set)]);
disp(['Hit FO_ALL_PSS ' num2str(fo_with_all_pss_idx)]);

extra_info.fo = f_set./1e3;
extra_info.ppm = ppm;
extra_info.pss_idx = pss_idx_set;
extra_info.fo_idx = fo_idx_set;
extra_info.fo_pss_idx = fo_pss_idx_set;
extra_info.fo_all_pss = fo_with_all_pss_idx;
