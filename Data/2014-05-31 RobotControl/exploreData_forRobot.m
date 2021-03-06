
%given_amp_counts = 4.5/2.4e-3;

f_lim = [0 22];
t_lim=[];
pname = 'SavedData\';
truth=[];intended=[];
switch 5
    case 2
        fname = 'openBCI_raw_2014-05-31_20-48-01_Robot02.txt'; chans=[2];
    case 3
        fname = 'openBCI_raw_2014-05-31_20-51-30_Robot03.txt'; chans=[2];
    case 4
        fname = 'openBCI_raw_2014-05-31_20-55-29_Robot04.txt'; chans=[2];
    case 5
        fname = 'openBCI_raw_2014-05-31_20-57-51_Robot05.txt'; chans=2;  t_lim=[0 135];%this might be the one from the movie
        truth = [12	19	2
            31	34	3
            39	40	1
            48	51	1
            57	59	3
            60	62	2
            66	69	3
            81	84	1
            90	94	3
            101	105	3
            106	109	1
            114	119	3
            121	122	2];  %start time, end time, action code...1 = left, 2  = right, 3 = fwd
        truth_start_sec = 16.22;
        intended = [27 34 1
            36  51  1
            56  62  2
            65  69  3
            74  83  1
            87  94  3
            100 109 1
            112 119 3];
         intended(:,1:2) = intended(:,1:2)+1;
    case 9
        fname = 'openBCI_raw_2014-05-31_21-07-40_Robot09.txt'; chans=2;
    case 11
        fname = 'openBCI_raw_2014-05-31_21-15-57_Robot11.txt'; chans = 2;  %alpha, then 7.5 Hz sustained
    case 12
        fname = 'openBCI_raw_2014-05-31_21-17-28_Robot12.txt'; chans = 2;
end
scale_fac_volts_count=2.23e-8;

%% process truth data
time_offset_sec = truth_start_sec - truth(1,1);
if (1)
    %use "intended" instead of truth
    disp(['Using "intended" commands instead of actual robot actions...']);
    truth = intended;
end

if ~isempty(truth)
    truth_sec = truth(:,1:2);
    truth_sec = truth_sec + time_offset_sec;
    truth_code = truth(:,3);
else
    truth_sec = [];
    truth_code=[];
end

%% load data
data_uV = load([pname fname]);  %loads data as microvolts
data_uV = data_uV(:,[1 chans+1 size(data_uV,2)]);  %get aux, too
%fs = data2.fs_Hz;
fs = 250;
count = data_uV(:,1);  %first column is a packet counter (though it's broken)
data_V = data_uV(:,2:end) * 1e-6; %other columns are data
clear data_uV;

%% filter data
data_V = data_V - ones(size(data_V,1),1)*mean(data_V);
%[b,a]=butter(2,[0.2 50]/(fs/2));
[b,a]=butter(2,0.2/(fs/2),'high');
data_V = filter(b,a,data_V);
[b,a]=butter(3,[55 65]/(fs/2),'stop');
data_V = filter(b,a,data_V);
% [b,a]=butter(3,[65 75]/(fs/2),'stop');
% data_V = filter(b,a,data_V);

%% write to WAV
% fs_dec = fs;foo_V = data_V;
% %foo_V = resample(data_V,1,2); fs_dec = fs / 2;  %decimate
% outfname = ['WAVs\' fname(1:end-4) '.wav'];
% disp(['writing to ' outfname]);
% wavwrite(foo_V(:,1:min([size(data_V,2) 2]))*1e6/500,fs_dec,16,outfname);


%% analyze data
% mean_data_V = mean(data_V);
% median_data_V = median(data_V);
% std_data_V = std(data_V);
% spread_data_V = diff(xpercentile(data_V,0.5+(0.68-0.5)*[-1 1]))/2;
% spread_data_V = median(spread_data_V)*ones(size(spread_data_V));

%% plot data
t_sec = ([1:size(data_V,1)]-1)/fs;
nrow = 3; ncol=1;
ax=[];
figure;setFigureTallestWide;
for Ichan=1:1
    
    %     %time-domain plot
    %     subplotTightBorder(nrow,ncol,(Ichan-1)*2+1);
    %     plot(t_sec,data_V(:,Ichan)*1e6);
    %     xlim(t_sec([1 end]));
    %     %ylim(1e6*(median_data_V(Ichan)+3*[-1 1]*spread_data_V(Ichan)));
    %     ylim([-200 200]);
    %     weaText({['Mean = ' num2str(mean(data_V(:,Ichan))*1e6,3) ' uV'];
    %         ['Std = ' num2str(std(data_V(:,Ichan))*1e6,3) ' uV']},2);
    %     title(['Channel ' num2str(Ichan)]);
    %     xlabel(['Time (sec)']);
    %     ylabel(['Signal (uV)']);
    %     ax(end+1)=gca;
    
    %spectrogram
    subplot(nrow,ncol,Ichan);
    %N=1024;
    %N=1200;overlap = 1-1/32;plots=0;
    %N = 2400;overlap = 1-1/64;plots=0; yl=[0 15];
    %N=512;overlap = 1-1/16;plots=0;
    N=512;overlap = 1-50/N;plots=0;  %this is the overlap in the processing GUI
    [pD,wT,f]=windowedFFTPlot_spectragram(data_V(:,Ichan)*1e6,N,overlap,fs,plots);
    wT = wT + (N/2)/fs;
    
    %FFT Averaging (in dB space)
    smooth_txt=[];
    if (1)
        pD_dB = 10*log10(pD);
        smooth_fac = 0.9;
        smooth_txt = ['Smooth Fac: ' num2str(smooth_fac)];
        b = 1-smooth_fac; a = [1 -smooth_fac];
        pD_dB = filter(b,a,pD_dB')';  %transpose to smooth across columns
        pD = 10.^(0.1*pD_dB);
    end
    
    %continue plotting
    imagesc(wT,f,10*log10(pD));
    set(gca,'Ydir','normal');
    xlabel('Time (sec)');
    ylabel('Frequency (Hz)');
    title([fname ', Channel ' num2str(chans(Ichan))],'interpreter','none');
    %set(gca,'Clim',+25+[-40 0]+10*log10(256)-10*log10(N));
    set(gca,'Clim',[-15 15]);
    if ~isempty(t_lim)
        xlim(t_lim);
    else
        xlim(t_sec([1 end]));
    end
    xl=xlim;
    ylim(f_lim);
    cl=get(gca,'Clim');
    txt = {['fs: ' num2str(fs) ' Hz, N: ' num2str(N) ', Step: ' num2str(round(N*(1-overlap)))];['Clim = [' num2str(round(cl(1))) ' ' num2str(round(cl(2))) '] dB']};
    if ~isempty(smooth_txt); txt{end+1}=smooth_txt;end
    h=weaText(txt,2);
    set(h,'BackgroundColor','white');
    colorbar;
    clabel(['uV/sqrt(Hz) (dB)']);
    
%     hold on;
%     plot(xlim,inband_Hz(1)*[1 1],'w--','linewidth',2);
%     plot(xlim,inband_Hz(2)*[1 1],'w--','linewidth',2);
%     hold off
    
    ax(end+1)=gca;
    
    %    %compute SNR
    inband_Hz = [4 15];
    Ifreq=find((f >= inband_Hz(1)) & (f <= inband_Hz(2)));
    [peak_pD,Ipeak]=max(pD(Ifreq,:));
    ave_noise_pD = zeros(size(peak_pD));
    %loop and get noise (excluding peak) for each time
    for Itime=1:length(ave_noise_pD)
        foo_pD = pD(Ifreq,Itime);
        foo_pD(Ipeak(Itime)) = NaN;
        if (Ipeak(Itime) > 1);foo_pD(Ipeak(Itime)-1) = NaN;end;
        if (Ipeak(Itime) < length(foo_pD)); foo_pD(Ipeak(Itime)+1) = NaN;end;
        ave_noise_pD(Itime) = nanmean(foo_pD);
    end
    peak_freq_Hz = f(Ifreq(Ipeak));
    snr_dB = 10*log10(pD ./ (ones(size(pD,1),1)*ave_noise_pD));
    peak_SNR_dB = zeros(size(peak_freq_Hz));
    for Itime=1:length(peak_SNR_dB);
        peak_SNR_dB(Itime) = snr_dB(Ifreq(Ipeak(Itime)),Itime);
    end
    t_snr_sec = wT;
    
    %continue plotting
    for Iplot=1:2
        subplot(nrow,ncol,Ichan+Iplot);
%         if Iplot==1
            foo_dB = snr_dB;
%         else
%             foo_dB = snr_dB;
%             I = find(foo_dB<det_thresh_dB);
%             foo_dB(I) = -10;
%             I = find((f < inband_Hz(1)) | (f > inband_Hz(2)));
%             foo_dB(I,:) = -10;
%             %I = find(foo>=det_thresh_dB)
%             %foo(I)
%         end
        imagesc(wT,f,foo_dB);
        set(gca,'Ydir','normal');
        xlabel('Time (sec)');
        ylabel('Frequency (Hz)');
        title([fname ', Channel ' num2str(chans(Ichan))],'interpreter','none');
        set(gca,'Clim',[-10 10]);
        set(gca,'Clim',[-5 10]);
        xlim(xl);
        ylim(f_lim);
        cl=get(gca,'Clim');
        %h=weaText({['Nfft = ' num2str(N) ', fs = ' num2str(fs) ' Hz'];['Clim = [' num2str(round(cl(1))) ' ' num2str(round(cl(2))) '] dB']},1);
        h = weaText(txt,2);
        set(h,'BackgroundColor','white');
        clabel(['SNR (dB)']);

        
        det_thresh_dB = 6;
        I=find(peak_SNR_dB > det_thresh_dB);
        if (Iplot==2)
            hold on; plot(t_snr_sec(I),peak_freq_Hz(I),'wo','linewidth',2); hold off;
           
            %freq_bounds = [4 6.5 9 12 15];
            freq_bounds = [4 6.5 9 12];
            for Ibound=1:length(freq_bounds);
                hold on;
                plot(xlim,freq_bounds(Ibound)*[1 1],'w--','linewidth',2);
                hold off;
            end
 
            %add truth bounds
            truth_to_freq_code = [2 1 3];
            for Itruth=1:size(truth_sec,1)
                hold on;
                y = freq_bounds(truth_to_freq_code(truth_code(Itruth))+[0 1]);
                plot(truth_sec(Itruth,1)*[1 1],y,'k:','linewidth',2);
                plot(truth_sec(Itruth,2)*[1 1],y,'k:','linewidth',2);
                hold off;
            end
 
            
        end
        ax(end+1)=gca;
    end
end    
linkaxes(ax);

