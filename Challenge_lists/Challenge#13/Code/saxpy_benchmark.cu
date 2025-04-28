#include <stdio.h>
#include <math.h>
#include <cuda_runtime.h> // include CUDA runtime API
#include <chrono>         // include chrono for CPU timing

// GPU Kernel
__global__
void saxpy(int n, float a, float *x, float *y)
{
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) y[i] = a * x[i] + y[i];
}

// CPU Function
void saxpy_cpu(int n, float a, float *x, float *y)
{
    for (int i = 0; i < n; i++) {
        y[i] = a * x[i] + y[i];
    }
}

int main(void)
{
    int start_power = 15;
    int end_power = 25;

    printf("MatrixSize,HostMalloc_ms,DeviceMalloc_ms,MemcpyHtoD_ms,Kernel_ms,MemcpyDtoH_ms,FreeHost_ms,FreeDevice_ms,TotalMeasured_ms\n");

    for (int p = start_power; p <= end_power; p++) {
        int N = 1 << p;
        float *x, *y, *d_x, *d_y;

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
        x = (float*)malloc(N * sizeof(float));
        y = (float*)malloc(N * sizeof(float));
        cudaEventRecord(stop);
        cudaEventSynchronize(stop);
        cudaEventElapsedTime(&host_malloc_time, start, stop);

        // Device malloc timing
        cudaEventRecord(start);
        cudaMalloc(&d_x, N * sizeof(float));
        cudaMalloc(&d_y, N * sizeof(float));
        cudaEventRecord(stop);
        cudaEventSynchronize(stop);
        cudaEventElapsedTime(&device_malloc_time, start, stop);

        // Initialize host arrays (does not time it separately)
        for (int i = 0; i < N; i++) {
            x[i] = 1.0f;
            y[i] = 2.0f;
        }

        // Host to device memcpy timing
        cudaEventRecord(start);
        cudaMemcpy(d_x, x, N * sizeof(float), cudaMemcpyHostToDevice);
        cudaMemcpy(d_y, y, N * sizeof(float), cudaMemcpyHostToDevice);
        cudaEventRecord(stop);
        cudaEventSynchronize(stop);
        cudaEventElapsedTime(&memcpy_h2d_time, start, stop);

        // Kernel execution timing
        cudaEventRecord(start);
        saxpy<<<(N + 255) / 256, 256>>>(N, 2.0f, d_x, d_y);
        cudaEventRecord(stop);
        cudaEventSynchronize(stop);
        cudaEventElapsedTime(&kernel_time, start, stop);

        // Device to host memcpy timing
        cudaEventRecord(start);
        cudaMemcpy(y, d_y, N * sizeof(float), cudaMemcpyDeviceToHost);
        cudaEventRecord(stop);
        cudaEventSynchronize(stop);
        cudaEventElapsedTime(&memcpy_d2h_time, start, stop);

        // Host free timing
        cudaEventRecord(start);
        free(x);
        free(y);
        cudaEventRecord(stop);
        cudaEventSynchronize(stop);
        cudaEventElapsedTime(&host_free_time, start, stop);

        // Device free timing
        cudaEventRecord(start);
        cudaFree(d_x);
        cudaFree(d_y);
        cudaEventRecord(stop);
        cudaEventSynchronize(stop);
        cudaEventElapsedTime(&device_free_time, start, stop);

        // Total
        float total_measured_time = host_malloc_time + device_malloc_time + memcpy_h2d_time + kernel_time + memcpy_d2h_time + host_free_time + device_free_time;

        // Print results
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

        // Destroy events
        cudaEventDestroy(start);
        cudaEventDestroy(stop);

        // === Now benchmark CPU ===
        float *x_cpu, *y_cpu;

        double host_malloc_time_cpu = 0.0;
        double computation_time_cpu = 0.0;
        double host_free_time_cpu = 0.0;

        auto cpu_start = std::chrono::high_resolution_clock::now();
        x_cpu = (float*)malloc(N * sizeof(float));
        y_cpu = (float*)malloc(N * sizeof(float));
        auto cpu_stop = std::chrono::high_resolution_clock::now();
        host_malloc_time_cpu = std::chrono::duration<double, std::milli>(cpu_stop - cpu_start).count();

        for (int i = 0; i < N; i++) {
            x_cpu[i] = 1.0f;
            y_cpu[i] = 2.0f;
        }

        cpu_start = std::chrono::high_resolution_clock::now();
        saxpy_cpu(N, 2.0f, x_cpu, y_cpu);
        cpu_stop = std::chrono::high_resolution_clock::now();
        computation_time_cpu = std::chrono::duration<double, std::milli>(cpu_stop - cpu_start).count();

        cpu_start = std::chrono::high_resolution_clock::now();
        free(x_cpu);
        free(y_cpu);
        cpu_stop = std::chrono::high_resolution_clock::now();
        host_free_time_cpu = std::chrono::duration<double, std::milli>(cpu_stop - cpu_start).count();

        double total_cpu_time = host_malloc_time_cpu + computation_time_cpu + host_free_time_cpu;

        printf("[CPU] %d, %.5f, %.5f, %.5f, %.5f\n", 
            N, host_malloc_time_cpu, computation_time_cpu, host_free_time_cpu, total_cpu_time);
    }

    return 0;
}
