function fn_write_file_explorer(name,driver_path,cycles,sample_bit,Start,Range,gain,Width,sample_frequency)
% filedir = cd;
fid = fopen([name,'.txt'],'w+t');
%% inputs
% cycles = no_element;
% sample_bit = bit;
% Start=start;
% Range=range;
% gain=amplify;
% Width=width;
%%
if sample_bit ==14
    sample_bit = 12;
end
element_start = 0;
element_stop = cycles-1;
element = [element_start:element_stop];
FMC = 1;
no_usb3 = 1;
GainDigital=10.000000;
BeamCorrection=0.0;
TimeSlot=cycles*Range*sample_frequency/1e6*sample_bit/500;%check
PointFactor=100e6/sample_frequency;%check
CompressionType='Decimation';   
Rectification='Signed';
FilterIndex=1;
GateCount =0;

WedgeDelay=0.00;
Elementcount=1;
Element=0;
Delaycount='1;1';
Delay=0.00;
Widthcount=1;
Focusing='Standard';

Gaincount=1;
Gain=0;
FocalTimeOfFlightcount=1;
FocalTimeOfFlight=0.0;

i = findstr(driver_path, ' '); 
i = i(end);
driver_version = driver_path(i+1:end);

%% Write text
fprintf(fid,'[Root]\n');
fprintf(fid,['VersionDriverOEMPA=',driver_version,'\n']);
fprintf(fid,['CycleCount=%2.0f\n','FMCElementStart=%1.0f\n'...
    'FMCElementStop=%2.0f\n','EnableFMC=%1.0f\n',...
    'DisableUSB3=%1.0f\n','AscanBitSize=%1.0fBits\n\n'],cycles,element_start,element_stop...
    ,FMC,no_usb3,sample_bit);
for i=0:element_stop
    if i < 10
        fprintf(fid,['[Cycle:%1.0f]\n','GainDigital=%2.6f dB\n','BeamCorrection=%1.1f dB\n'...
    'Start=%1.6f us\n','Range=%2.6f us\n','TimeSlot=%5.1f us\n','PointFactor=%1.0f\n'...
    'CompressionType=%s\n','Rectification=%s\n','FilterIndex=%1.0f\n','GainAnalog=%2.6f dB\n'...
    'GateCount=%1.0f\n\n'],i,GainDigital,BeamCorrection,Start,Range,TimeSlot,PointFactor,...
    CompressionType,Rectification,FilterIndex,gain,GateCount);
fprintf(fid,['[Cycle:%1.0f\\Pulser]\n','WedgeDelay=%1.2f us\n','Element.count=%1.0f\n',...
    'Element=%1.0f\n','Delay.count=%s\n','Delay=%1.2f us\n','Width.count=%1.0f\n',...
    'Width=%1.2f us\n\n'],i,WedgeDelay,Elementcount,i,Delaycount,Delay,Widthcount,Width);
fprintf(fid,['[Cycle:%1.0f\\Receiver]\n','WedgeDelay=%1.2f us\n','Element.count=%1.0f\n',...
    'Element=%1.0f\n','Focusing=%s\n','Delay.count=%s\n','Delay=%1.2f us\n',...
    'Gain.count=%1.0f\n','Gain=%1.1f dB\n','FocalTimeOfFlight.count=%1.0f\n',...
    'FocalTimeOfFlight=%1.1f us\n\n'],i,WedgeDelay,Elementcount,i,...
    Focusing,Delaycount,Delay,Gaincount,Gain,FocalTimeOfFlightcount,FocalTimeOfFlight);
    else
fprintf(fid,['[Cycle:%2.0f]\n','GainDigital=%2.6f dB\n','BeamCorrection=%1.1f dB\n'...
    'Start=%1.6f us\n','Range=%2.6f us\n','TimeSlot=%5.1f us\n','PointFactor=%1.0f\n'...
    'CompressionType=%s\n','Rectification=%s\n','FilterIndex=%1.0f\n','GainAnalog=%2.6f dB\n'...
    'GateCount=%1.0f\n\n'],i,GainDigital,BeamCorrection,Start,Range,TimeSlot,PointFactor,...
    CompressionType,Rectification,FilterIndex,gain,GateCount);
fprintf(fid,['[Cycle:%2.0f\\Pulser]\n','WedgeDelay=%1.2f us\n','Element.count=%1.0f\n',...
    'Element=%2.0f\n','Delay.count=%s\n','Delay=%1.2f us\n','Width.count=%1.0f\n',...
    'Width=%1.2f us\n\n'],i,WedgeDelay,Elementcount,i,Delaycount,Delay,Widthcount,Width);
fprintf(fid,['[Cycle:%2.0f\\Receiver]\n','WedgeDelay=%1.2f us\n','Element.count=%1.0f\n',...
    'Element=%2.0f\n','Focusing=%s\n','Delay.count=%s\n','Delay=%1.2f us\n',...
    'Gain.count=%1.0f\n','Gain=%1.1f dB\n','FocalTimeOfFlight.count=%1.0f\n',...
    'FocalTimeOfFlight=%1.1f us\n\n'],i,WedgeDelay,Elementcount,i,...
    Focusing,Delaycount,Delay,Gaincount,Gain,FocalTimeOfFlightcount,FocalTimeOfFlight);
    end
end
fclose(fid);