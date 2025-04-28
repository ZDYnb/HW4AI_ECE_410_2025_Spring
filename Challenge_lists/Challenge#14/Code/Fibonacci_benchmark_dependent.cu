#include <stdio.h>
#include <cuda_runtime.h>
#include <chrono>

// GPU device function: iterative Fibonacci
__device__ unsigned long long fibonacci_device(int n)
{
    if (n <= 1) return n;
    unsigned long long a = 0, b = 1, c;
    for (int i = 2; i <= n; ++i) {
        c = a + b;
        a = b;
        b = c;
    }
    return b;
}

// GPU Kernel
__global__
void fibonacci_kernel(int *input, unsigned long long *output, int n)
{
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx < n) {
        output[idx] = fibonacci_device(input[idx]);
    }
}

// CPU Fibonacci function
unsigned long long fibonacci_cpu(int n)
{
    if (n <= 1) return n;
    unsigned long long a = 0, b = 1, c;
    for (int i = 2; i <= n; ++i) {
        c = a + b;
        a = b;
        b = c;
    }
    return b;
}

int main(void)
{
    int start_power = 10;  // Start smaller to avoid huge Fibonacci numbers
    int end_power = 20;

    printf("MatrixSize,HostMalloc_ms,DeviceMalloc_ms,MemcpyHtoD_ms,Kernel_ms,MemcpyDtoH_ms,FreeHost_ms,FreeDevice_ms,TotalMeasured_ms\n");

    for (int p = start_power; p <= end_power; p++) {
        int N = 1 << p;
        int *input, *d_input;
        unsigned long long *output, *d_output;

        // Create CUDA events
        cudaEvent_t start, stop;
        cudaEventCreate(&start);
        cudaEventCreate(&stop);

        float host_malloc_time = 0.0f;
        float device_malloc_time = 0.0f;
        float memcpy_h2d_time = 0.0f;
        float kernel_time = 0.0f;
        float memcpy_d2h_time = 0.0f;
        float host_free_time = 0.0f;
        float device_free_time = 0.0f;

        // Host malloc timing
        cudaEventRecord(start);
        input = (int*)malloc(N * sizeof(int));
        output = (unsigned long long*)malloc(N * sizeof(unsigned long long));
        cudaEventRecord(stop);
        cudaEventSynchronize(stop);
        cudaEventElapsedTime(&host_malloc_time, start, stop);

        // Device malloc timing
        cudaEventRecord(start);
        cudaMalloc(&d_input, N * sizeof(int));
        cudaMalloc(&d_output, N * sizeof(unsigned long long));
        cudaEventRecord(stop);
        cudaEventSynchronize(stop);
        cudaEventElapsedTime(&device_malloc_time, start, stop);

        // Initialize host arrays
        for (int i = 0; i < N; i++) {
            input[i] = i % 40;  // Limit Fibonacci input size to avoid overflow
        }

        // Host to device memcpy timing
        cudaEventRecord(start);
        cudaMemcpy(d_input, input, N * sizeof(int), cudaMemcpyHostToDevice);
        cudaEventRecord(stop);
        cudaEventSynchronize(stop);
        cudaEventElapsedTime(&memcpy_h2d_time, start, stop);

        // Kernel execution timing
        cudaEventRecord(start);
        fibonacci_kernel<<<(N + 255) / 256, 256>>>(d_input, d_output, N);
        cudaEventRecord(stop);
        cudaEventSynchronize(stop);
        cudaEventElapsedTime(&kernel_time, start, stop);

        // Device to host memcpy timing
        cudaEventRecord(start);
        cudaMemcpy(output, d_output, N * sizeof(unsigned long long), cudaMemcpyDeviceToHost);
        cudaEventRecord(stop);
        cudaEventSynchronize(stop);
        cudaEventElapsedTime(&memcpy_d2h_time, start, stop);

        // Host free timing
        cudaEventRecord(start);
        free(input);
        free(output);
        cudaEventRecord(stop);
        cudaEventSynchronize(stop);
        cudaEventElapsedTime(&host_free_time, start, stop);

        // Device free timing
        cudaEventRecord(start);
        cudaFree(d_input);
        cudaFree(d_output);
        cudaEventRecord(stop);
        cudaEventSynchronize(stop);
        cudaEventElapsedTime(&device_free_time, start, stop);

        // Total
        float total_measured_time = host_malloc_time + device_malloc_time + memcpy_h2d_time + kernel_time + memcpy_d2h_time + host_free_time + device_free_time;

        // Print GPU results
        printf("[GPU] %d,%.5f,%.5f,%.5f,%.5f,%.5f,%.5f,%.5f,%.5f\n", 
            N,
            host_malloc_time,
            device_malloc_time,
            memcpy_h2d_time,
            kernel_time,
            memcpy_d2h_time,
            host_free_time,
            device_free_time,
            total_measured_time
        );

        // Destroy CUDA events
        cudaEventDestroy(start);
        cudaEventDestroy(stop);

        // === Now benchmark CPU ===
        int *input_cpu;
        unsigned long long *output_cpu;

        double host_malloc_time_cpu = 0.0;
        double computation_time_cpu = 0.0;
        double host_free_time_cpu = 0.0;

        auto cpu_start = std::chrono::high_resolution_clock::now();
        input_cpu = (int*)malloc(N * sizeof(int));
        output_cpu = (unsigned long long*)malloc(N * sizeof(unsigned long long));
        auto cpu_stop = std::chrono::high_resolution_clock::now();
        host_malloc_time_cpu = std::chrono::duration<double, std::milli>(cpu_stop - cpu_start).count();

        for (int i = 0; i < N; i++) {
            input_cpu[i] = i
