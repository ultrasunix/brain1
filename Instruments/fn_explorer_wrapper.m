function [info, h_fn_connect, h_fn_disconnect, h_fn_reset, h_fn_acquire, h_fn_send_options] = fn_explorer_wrapper(dummy)
info.name = 'TPAC Explorer';
echo_on = 0;

info.options_info.ip_address.label = 'IP address';
info.options_info.ip_address.default = '192.168.1.11';
info.options_info.ip_address.type = 'string';
%
info.options_info.aos_driver_path.label = 'Driver path';
info.options_info.aos_driver_path.default = 'C:\Program Files\AOS\OEMPA 1.2.1.0';
info.options_info.aos_driver_path.type = 'string';

info.options_info.acquire_mode.label = 'Acquisition';
info.options_info.acquire_mode.default = 'FMC'; 
info.options_info.acquire_mode.type = 'constrained';
info.options_info.acquire_mode.constraint = {'FMC'};

info.options_info.sample_freq.label = 'Sample frequency (MHz)';
info.options_info.sample_freq.default = '25'; 
info.options_info.sample_freq.type = 'constrained';
info.options_info.sample_freq.constraint = {'12.5', '25', '50'};

info.options_info.pulse_width.label = 'Pulse width (ns)';
info.options_info.pulse_width.default = 100e-9;
info.options_info.pulse_width.type = 'double';
info.options_info.pulse_width.constraint = [10e-9, 1000e-9];
info.options_info.pulse_width.multiplier = 1e-9;

info.options_info.time_pts.label = 'Time points';
info.options_info.time_pts.default = 1000;
info.options_info.time_pts.type = 'int'; 
info.options_info.time_pts.constraint = [100, 4096];

info.options_info.sample_bits.label = 'Sample bits';
info.options_info.sample_bits.default = '8';
info.options_info.sample_bits.type = 'constrained';
info.options_info.sample_bits.constraint = {'8','14'};

info.options_info.db_gain.label = 'Gain (dB)';
info.options_info.db_gain.default = 20;
info.options_info.db_gain.type = 'int';
info.options_info.db_gain.constraint = [0, 57];

info.options_info.gate_start.label = 'Time start (us)';
info.options_info.gate_start.default = 0;
info.options_info.gate_start.type = 'double';
info.options_info.gate_start.constraint = [0, 1300e-6];
info.options_info.gate_start.multiplier = 1e-6;

info.options_info.instrument_delay.label = 'Instrument delay (ns)';
info.options_info.instrument_delay.default = 0;
info.options_info.instrument_delay.type = 'double';
info.options_info.instrument_delay.constraint = [-1e6, 1e6];
info.options_info.instrument_delay.multiplier = 1e-9;

h_fn_acquire = @fn_acquire;
h_fn_send_options = @fn_send_options;
h_fn_reset = @fn_reset;
h_fn_disconnect = @fn_disconnect;
h_fn_connect = @fn_connect;
% h_fn_get_options = @fn_get_options;

options_sent = 0;
connected = 0;
tx_no = [];
rx_no = [];
time_axis = [];
options_sent = 0;
deviceId = [];
temp_pause = 0;

    function exp_data = fn_acquire(instr_control_data)
        exp_data = [];
        if ~options_sent
            %this should give a warning!
            return;
        end
        if ~connected
            return;
        end
        instr_control_data.play_button_state
        pulser_on = 1;
        if ~temp_pause
            Ascan = fn_acquire_one(deviceId);
        end
        %Put it into exp_data structure
        exp_data.time_data=double(Ascan);
        if str2num(instr_control_data.sample_bits) == 14
            bit_depth = 16;
        else
            bit_depth = str2num(instr_control_data.sample_bits);
        end
        exp_data.time_data=exp_data.time_data * (2 / (2 ^ bit_depth * 0.78));%HARD CODED badness. instrument only seems to use 78% of available bandwidth. This is to account for that.
        exp_data.time_data=exp_data.time_data(1:min([length(time_axis), size(Ascan,1)]), :);
        exp_data.tx = tx_no;
        exp_data.rx = rx_no;
        exp_data.time = time_axis;
        % Disable pulser if only frame was required
        if instr_control_data.play_once
            fn_stop(deviceId);
            pulser_on = 0;
        end
        %Note: there is no way to stop pulser in continuous mode in current
        %version of brain as there is no call to any driver functions when stop is
        %pressed in brain.
    end

    function fn_send_options(options, array, material)
        if ~connected
            return;
        end
        no_channels = length(array.el_xc(:));
        switch options.acquire_mode
            case 'SAFT'
                [options.tx_ch, options.rx_ch] = fn_set_fmc_input_matrices(no_channels, 0);
                options.rx_ch = options.tx_ch;
            case 'FMC'
                [options.tx_ch, options.rx_ch] = fn_set_fmc_input_matrices(no_channels, 0);
            case 'HMC'
                [options.tx_ch, options.rx_ch] = fn_set_fmc_input_matrices(no_channels, 1);
            case 'CSM'
                options.tx_ch = ones(1, no_channels);
                options.rx_ch = ones(1, no_channels);
        end
        
        options.sample_bits = str2double(options.sample_bits);
        fn_write_file_explorer ('test', options.aos_driver_path,no_channels, options.sample_bits, options.gate_start * 1e6, options.time_pts / str2double(options.sample_freq) , options.db_gain, options.pulse_width * 1e6, str2double(options.sample_freq)*1e6);                                                                
        tmp = meshgrid([1:no_channels],[1:no_channels]);
        tx_no = reshape(tmp,[1 no_channels.^2]);
        rx_no = repmat([1:no_channels],1,no_channels);
        time_step = 1 / (str2double(options.sample_freq)*1e6);
        %Global variable temp_pause is used to temporarily pauses
        %acquisition while change happens
        temp_pause = 1;
        time_axis = [options.gate_start:time_step:options.gate_start + time_step*(options.time_pts-1)]' - options.instrument_delay;
        status = mxReadFileWriteHW(deviceId,'test.txt');
        temp_pause = 0;
        if ~status
            error('Cannot load the setup file');
        end
        options_sent = 1;
    end

    function fn_reset(dummy)
%         fn_ag_reset_tcpip(echo_on);
    end

    function res = fn_disconnect(dummy)
        if ~connected
            return
        end
        
        % Disable pulser %
        mxEnableShot(deviceId,0);
        
        % Disconnect %
        mxConnect(deviceId,0);
        
        % Delete device %
        mxDeleteDevice(deviceId);
        
        % free matlab stub dll but makes Matlab crash %
        %utCmdExit
        connected = 0;
        res = connected;
    end

    function res = fn_connect(options)
        % Path to find matlab MEX files %
        addpath(fullfile(options.aos_driver_path, 'matlab'));
        
        % Load matlab stub dll %
        utCmdInit(fullfile(options.aos_driver_path, 'UTKernelMatlab.dll'),'PA1 PA2 PAmini');
        
        % New device (specify IP address) %
        deviceId = utCmdNewDevice(['udp://', options.ip_address],[16384 5000 1],'PAmini');
        
        
        % Connection %;
        status = mxConnect(deviceId,1);
        if ~status
            connected = 0;
            error('Cannot connect to the device');
        else
            connected = 1;
            current_time_pts = options.time_pts;
        end
        res = connected;
    end
end


function Ascan = fn_acquire_one(deviceId)

% get the cycle count (from setting, value in the OEMPAfile).
CycleCount = mxGetSWCycleCount(deviceId);

% Enable pulser %
status = mxEnableShot(deviceId, 1);
if ~status
    error('Cannot enable pulser');
else
    pulser_on = 1;
end

AscanCount = inf; %force it to start while loop
while AscanCount < CycleCount %I think this waits until physical acquisition is complete
    [AscanCount, fifoAscanLost1, total] = mxGetAcquisitionAscanFifoStatus(deviceId) ;
end

[FifoIndex, Cycle, Sequence, xPointCount, ByteSize, Signed] = mxGetAcquisitionAscanFifoIndex(deviceId, [0: CycleCount - 1]);% linspace(0,CycleCount-1,CycleCount));
PointCount = max(xPointCount); % N.B. pointCount = samplingFrequency*rangeTime+1 => here 50*30+1=1501


%-------------------------------------------------------------------------%
Nrow = 0; Ncol = 0;
while Nrow ~= PointCount || Ncol ~= CycleCount %I think this waits while A-scans are transferred to PC
    %Accumulate Ascans %
    FifoIndex = mxGetAcquisitionAscanLifoIndex(deviceId, [0: CycleCount - 1]);% linspace(0,CycleCount-1,CycleCount));
    [Ascan, Cycle, Sequence, encRawVal, lEncoder] = mxGetAcquisitionAscanFifoData(deviceId, FifoIndex);
    [Nrow, Ncol] = size(Ascan);
end
%-------------------------------------------------------------------------%

end

function fn_stop(deviceId)
EnableCall = mxEnableShot(deviceId, 0);
end