#include <float.h>

__global__ void maxpooling_kernel(float *output, float *input,
	int batch, int channel, int height, int width,
	int kernel_height, int kernel_width, int pad_height, int pad_width, int stride_height, int stride_width, int total_size)
{
	int C = channel;
	int H = height;
	int W = width;
	int kH = kernel_height;
	int kW = kernel_width;
	int pH = pad_height;
	int pW = pad_width;
	int sH = stride_height;
	int sW = stride_width;

	int P = ((H + 2 * pH - kH) / sH) + 1;
	int Q = ((W + 2 * pW - kW) / sW) + 1;

	//tid : thread id
	int tid = blockIdx.x * blockDim.x + threadIdx.x;

	if (tid >= total_size)
		return;

	//q_idx : output w-index
	int q_idx = tid % Q;
	int idx = tid / Q;

	//p_idx : output h-index
	int p_idx = idx % P;
	idx /= P;

	//k_idx : output channel-index
	int k_idx = idx % C;

	//n_idx : output batch-index
	int n_idx = idx / C;

	//output(n_idx, k_idx, p_idx, q_idx)

	float max = -FLT_MAX;
	for (int kh = 0; kh < kH; kh++) {
		int h_idx = p_idx * sH + kh - pH;
		if (h_idx >= 0 && h_idx < H) {
			for (int kw = 0; kw < kW; kw++) {
				int w_idx = q_idx * sW + kw - pW;
				if (w_idx >= 0 && w_idx < W) {
					int input_index = n_idx * C * H * W + k_idx * H * W + h_idx * W + w_idx;
					if (input[input_index] > max) {
						max = input[input_index];
					}
				}
			}
		}
	}
	output[tid] = max;

}


void maxpooling(float *output, float *input,
	int batch, int channel, int height, int width,
	int kernel_height, int kernel_width, int pad_height, int pad_width, int stride_height, int stride_width)
{
	int N = batch;
	int C = channel;
	int H = height;
	int W = width;
	int kH = kernel_height;
	int kW = kernel_width;
	int pH = pad_height;
	int pW = pad_width;
	int sH = stride_height;
	int sW = stride_width;

	int P = (H + 2 * pH - kH) / sH + 1;
	int Q = (W + 2 * pW - kW) / sW + 1;

	int THREADS_PER_BLOCK = 256;
	int TOTAL_SIZE = N * C * P * Q;
	int NUMBER_OF_BLOCKS = (TOTAL_SIZE + THREADS_PER_BLOCK - 1) / THREADS_PER_BLOCK;

	maxpooling_kernel << < NUMBER_OF_BLOCKS, THREADS_PER_BLOCK >> > (output, input, N, C, H, W, kH, kW, pH, pW, sH, sW, TOTAL_SIZE);

}
