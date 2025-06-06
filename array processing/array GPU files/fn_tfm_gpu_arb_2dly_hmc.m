function result=fn_tfm_gpu_arb_2dly_hmc(exp_data,TFM_focal_law)
global SYSTEM_TYPES

if ~isfield(SYSTEM_TYPES,'mat_ver')
    a=ver('matlab');
    SYSTEM_TYPES.mat_ver=str2num(a.Version);
end

%define the area of the image field
img_size=size(TFM_focal_law.lookup_time_tx);
ndims=length(img_size);
img_size=img_size(1:end-1);
%result=zeros(img_size);

%convert data to required gpuarray data
%result=parallel.gpu.GPUArray.ones(size(result),'single');
n=gpuArray( int32(size(exp_data.time_data,1)));
combs=gpuArray( int32(size(exp_data.time_data,2)));
tx=gpuArray( int32(exp_data.tx));
rx=gpuArray( int32(exp_data.rx));
lookup_ind_tx= gpuArray(int32(TFM_focal_law.lookup_ind_tx));
lookup_ind_rx= gpuArray(int32(TFM_focal_law.lookup_ind_rx));
tt_weight = gpuArray(single(TFM_focal_law.tt_weight));
%filter_weight = parallel.gpu.GPUArray.ones(size(TFM_focal_law.tt_weight),'single');
filter=gpuArray(single(TFM_focal_law.filter));
time_data=gpuArray(single(exp_data.time_data));

if SYSTEM_TYPES.mat_ver>=8
    result=gpuArray.zeros(img_size,'single');
    filter_weight = gpuArray.ones(size(TFM_focal_law.tt_weight),'single');
    first_half_filt=gpuArray.ones(floor(single(n)/2),1,'single');
    scnd_half_filt=gpuArray.zeros(ceil(single(n)/2),1,'single');
else
    result=parallel.gpu.GPUArray.ones(img_size,'single');
    filter_weight = parallel.gpu.GPUArray.ones(size(TFM_focal_law.tt_weight),'single');
    first_half_filt=parallel.gpu.GPUArray.ones(floor(single(n)/2),1,'single');
    scnd_half_filt=parallel.gpu.GPUArray.zeros(ceil(single(n)/2),1,'single');
end

if TFM_focal_law.filter_on
    time_data=ifft((filter*tt_weight.*fft(time_data)))*2;
    else
    if TFM_focal_law.hilbert_on
        %first_half_filt=parallel.gpu.GPUArray.ones(floor(single(n)/2),1,'single');
        %scnd_half_filt=parallel.gpu.GPUArray.zeros(ceil(single(n)/2),1,'single');
        filter=[first_half_filt; scnd_half_filt];
        time_data=ifft((filter*filter_weight.*fft(time_data)))*2;
    end
end
lookup_amp_tx=gpuArray(single(TFM_focal_law.lookup_amp_tx));
lookup_amp_rx=gpuArray(single(TFM_focal_law.lookup_amp_rx));

%split analytic data into real and imaginary parts
real_exp=single(real(time_data));
img_exp=single(imag(time_data));
pixs=prod(img_size);

%specify total number of pixels and the image dimensions
pixels=gpuArray(int32(pixs));
grid_x=gpuArray(int32(size(result,1)));
grid_y=gpuArray(int32(size(result,2)));
grid_z=gpuArray(int32(size(result,3)));

bit_ver=mexext;
ptx_file=['gpu_tfm_arb_2dly_hmc_' bit_ver([end-1:end]) '.ptx'];

k = parallel.gpu.CUDAKernel(ptx_file, 'gpu_tfm_arb_2dly_hmc.cu');
k.ThreadBlockSize = TFM_focal_law.thread_size;%gpu_han.MaxThreadsPerBlock;
k.GridSize = ceil(pixs./k.ThreadBlockSize(1));

real_result=result;
imag_result=result;

[real_result imag_result]=feval(k,real_result,imag_result,n,combs,real_exp,img_exp,tx, rx, lookup_ind_tx, lookup_ind_rx, pixels, grid_x, grid_y, grid_z, lookup_amp_tx,lookup_amp_rx, tt_weight);
%
result=real_result+imag_result.*i;
result=gather(result);
result=double(result);
