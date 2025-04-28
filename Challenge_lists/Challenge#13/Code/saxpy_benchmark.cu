#include <stdio.h>
#include <math.h>
#include <cuda_runtime.h> //include CUDA runtime API to use GPU functions

__global__
void saxpy(int n, float a, float *x, float *y)
{
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) y[i] = a * x[i] + y[i];
}// that define a CUDA kernel runs on GPU called saxpy

int main(void)
{
    int start_power = 15;
    int end_power = 25;

    // Print CSV headers
    printf("MatrixSize,TotalTime_ms,KernelTime_ms\n");

    for (int p = start_power; p <= end_power; p++) {
        int N = 1 << p;
        float *x, *y, *d_x, *d_y;

        // Timing
        cudaEvent_t start_total, stop_total, start_kernel, stop_kernel;
        cudaEventCreate(&start_total);
        cudaEventCreate(&stop_total);
        cudaEventCreate(&start_kernel);
        cudaEventCreate(&stop_kernel);

        // Start total timer
        cudaEventRecord(start_total);

        // Allocate host memory
        x = (float*)malloc(N * sizeof(float));
        y = (float*)malloc(N * sizeof(float));

        // Allocate device memory
        cudaMalloc(&d_x, N * sizeof(float));
        cudaMalloc(&d_y, N * sizeof(float));

        // Initialize host arrays
        for (int i = 0; i < N; i++) {
            x[i] = 1.0f;
            y[i] = 2.0f;
        }

        // Copy data from host to device
        cudaMemcpy(d_x, x, N * sizeof(float), cudaMemcpyHostToDevice);
        cudaMemcpy(d_y, y, N * sizeof(float), cudaMemcpyHostToDevice);

        // Start kernel-only timer
        cudaEventRecord(start_kernel);

        // Launch kernel
        saxpy<<<(N + 255) / 256, 256>>>(N, 2.0f, d_x, d_y);

        // Stop kernel-only timer
        cudaEventRecord(stop_kernel);

        // Copy result back to host
        cudaMemcpy(y, d_y, N * sizeof(float), cudaMemcpyDeviceToHost);

        // Stop total timer
        cudaEventRecord(stop_total);

        // Wait for events to complete
        cudaEventSynchronize(stop_total);
        cudaEventSynchronize(stop_kernel);

        // Calculate elapsed time
        float total_time_ms = 0.0f;
        float kernel_time_ms = 0.0f;
        cudaEventElapsedTime(&total_time_ms, start_total, stop_total);
        cudaEventElapsedTime(&kernel_time_ms, start_kernel, stop_kernel);

        // Print results in CSV format
        printf("%d,%.5f,%.5f\n", N, total_time_ms, kernel_time_ms);

        // Free memory
        cudaFree(d_x);
        cudaFree(d_y);
        free(x);
        free(y);

        // Destroy events
        cudaEventDestroy(start_total);
        cudaEventDestroy(stop_total);
        cudaEventDestroy(start_kernel);
        cudaEventDestroy(stop_kernel);
    }

    return 0;
}
