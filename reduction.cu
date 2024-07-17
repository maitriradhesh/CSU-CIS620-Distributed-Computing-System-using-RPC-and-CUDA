// #include <stdio.h>
// #include <stdlib.h>
// #include <cuda_runtime.h>

// template<class T>
// struct SharedMemory {
//     __device__ inline operator T *() {
//         extern __shared__ int __smem[];
//         return (T *)__smem;
//     }

//     __device__ inline operator const T *() const {
//         extern __shared__ int __smem[];
//         return (T *)__smem;
//     }
// };

// __global__ void map(double *g_idata, double *g_odata, unsigned int n) {
//     unsigned int i = blockIdx.x * blockDim.x + threadIdx.x;
//     if (i < n) {
//         double value = g_idata[i];
//         g_odata[i] = (value > 0) ? sqrt(sqrt(value)) : 0;  // Compute quadruple root
//     }
// }

// __global__ void reduce(double *g_idata, double *g_odata, unsigned int n) {
//     double *sdata = SharedMemory<double>(); 
//     //extern __shared__ double sdata[];
//     unsigned int tid = threadIdx.x;
//     unsigned int i = blockIdx.x * blockDim.x + threadIdx.x;

//    /* if (idx < n) {
//         sdata[tid] = g_idata[idx];
//     } else {
//         sdata[tid] = 0;
//     }*/
//      sdata[tid] = (i < n) ? g_idata[i] : 0;

//     __syncthreads();

//     for (unsigned int s = blockDim.x / 2; s > 0; s >>= 1) {
//         if (tid < s) {
//             sdata[tid] += sdata[tid + s];
//         }
//         __syncthreads();
//     }

//     if (tid == 0) {
//         g_odata[blockIdx.x] = sdata[0];
//     }
// }

// #define checkCudaErrors(ans) { gpuAssert((ans), __FILE__, __LINE__); }
// void gpuAssert(cudaError_t code, const char *file, int line, bool abort = true) {
//     if (code != cudaSuccess) {
//         fprintf(stderr, "GPUassert: %s %s %d\n", cudaGetErrorString(code), file, line);
//         if (abort) exit(code);
//     }
// }
// //int main(int argc, char **argv) {
// extern "C" double sumqroot(int N, int M, int S) {
//     /*if (argc < 4) {
//         fprintf(stderr, "Usage: %s <power_of_two> <mean> <seed>\n", argv[0]);
//         return 1;
//     }

//     int n = 1 << atoi(argv[1]); // assuming at least 8
//    // int n = atoi(argv[1]);
//     int mean = atoi(argv[2]);
//     int seed = atoi(argv[3]);*/

//     int n = 1 << N; // assuming at least 8
//     int mean = M;
//     int seed = S;

//     //int size = 1 << n;
//    // int numThreads = size;
//     int numThreads = n;
//     int maxThreads = 256;  // number of threads per block
//     int numBlocks = n / maxThreads;
//     unsigned int  bytes = n * sizeof(double);
//     int smemSize = maxThreads * sizeof(double);

//     double *h_idata = (double *)malloc(bytes);
//     double *h_odata = (double *)malloc(numBlocks * sizeof(double));
//     double *d_idata, *d_odata, *d_intermediate;

//     checkCudaErrors(cudaMalloc((void **)&d_idata, bytes));
//     checkCudaErrors(cudaMalloc((void **)&d_odata, numBlocks * sizeof(double)));
//     checkCudaErrors(cudaMalloc((void **)&d_intermediate, bytes)); // Ensure it's large enough

//     srand48(seed);
//     for (int i = 0; i < n; i++) {
//         h_idata[i] = -mean * log(drand48());
//     }

//     checkCudaErrors(cudaMemcpy(d_idata, h_idata, bytes, cudaMemcpyHostToDevice));

//     map<<<numBlocks, maxThreads>>>(d_idata, d_intermediate, numThreads);
//     reduce<<<numBlocks, maxThreads, smemSize>>>(d_intermediate, d_odata, numThreads);

//     int s = numBlocks;
//     while (s > 1) {
//        // int nextNumBlocks = (s + maxThreads - 1) / maxThreads;
        
//         reduce<<<(s + maxThreads - 1) / maxThreads, maxThreads, smemSize>>>(d_odata, d_intermediate, s);
//         checkCudaErrors(cudaMemcpy(d_odata, d_intermediate, (s + maxThreads - 1) / maxThreads * sizeof(double), cudaMemcpyDeviceToDevice)); //this line error checks and is IMPORTANT
//         s = (s + maxThreads - 1) / maxThreads;
//         //s = nextNumBlocks;
//     }

//     checkCudaErrors(cudaMemcpy(h_odata, d_odata, sizeof(double), cudaMemcpyDeviceToHost));

//     printf("GPU sum : %f\n\n", h_odata[0]);

//     checkCudaErrors(cudaFree(d_idata));
//     checkCudaErrors(cudaFree(d_odata));
//     checkCudaErrors(cudaFree(d_intermediate));
//     free(h_idata);
//     free(h_odata);

//     return h_odata[0];
// }
#include <stdio.h>
#include <stdlib.h>
//#include <math.h>
//#include <cuda_runtime.h>

template<class T>
struct SharedMemory {
    __device__ inline operator T *() {
        extern __shared__ int __smem[];
        return (T *)__smem;
    }

    __device__ inline operator const T *() const {
        extern __shared__ int __smem[];
        return (T *)__smem;
    }
};

__global__ void map(double *g_idata, double *g_odata, unsigned int n) {
    unsigned int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) {
        double value = g_idata[i];
        g_odata[i] = (value > 0) ? sqrt(sqrt(value)) : 0;  // Compute quadruple root
    }
}

__global__ void reduce(double *g_idata, double *g_odata, unsigned int n) {
    extern __shared__ double sdata[];
    unsigned int tid = threadIdx.x;
    unsigned int i = blockIdx.x * blockDim.x + threadIdx.x;

   /* if (idx < n) {
        sdata[tid] = g_idata[idx];
    } else {
        sdata[tid] = 0;
    }*/
     sdata[tid] = (i < n) ? g_idata[i] : 0;

    __syncthreads();

    for (unsigned int s = blockDim.x / 2; s > 0; s >>= 1) {
        if (tid < s) {
            sdata[tid] += sdata[tid + s];
        }
        __syncthreads();
    }

    if (tid == 0) {
        g_odata[blockIdx.x] = sdata[0];
    }
}

#define checkCudaErrors(ans) { gpuAssert((ans), __FILE__, __LINE__); }
void gpuAssert(cudaError_t code, const char *file, int line, bool abort = true) {
    if (code != cudaSuccess) {
        fprintf(stderr, "GPUassert: %s %s %d\n", cudaGetErrorString(code), file, line);
        if (abort) exit(code);
    }
}

//int main(int argc, char **argv) {
extern "C" double sumqroot(int N, int M, int S) {
    // if (argc < 4) {
    //     fprintf(stderr, "Usage: %s <power_of_two> <mean> <seed>\n", argv[0]);
    //     return 1;
    // }

//     int n = 1 << atoi(argv[1]); // assuming at least 8
//    // int n = atoi(argv[1]);
//     int mean = atoi(argv[2]);
//     int seed = atoi(argv[3]);

    int n = 1 << N; // assuming at least 8
    int mean = M;
    int seed = S;

    //int size = 1 << n;
   // int numThreads = size;
    int numThreads = n;
    int maxThreads = 256;  // number of threads per block
    int numBlocks = n / maxThreads;
    unsigned int  bytes = n * sizeof(double);
    int smemSize = maxThreads * sizeof(double);

    double *h_idata = (double *)malloc(bytes);
    double *h_odata = (double *)malloc(numBlocks * sizeof(double));
    double *d_idata, *d_odata, *d_intermediate;

    checkCudaErrors(cudaMalloc((void **)&d_idata, bytes));
    checkCudaErrors(cudaMalloc((void **)&d_odata, numBlocks * sizeof(double)));
    checkCudaErrors(cudaMalloc((void **)&d_intermediate, bytes)); // Ensure it's large enough

    srand48(seed);
    for (int i = 0; i < n; i++) {
        h_idata[i] = -mean * log(drand48());
    }

    checkCudaErrors(cudaMemcpy(d_idata, h_idata, bytes, cudaMemcpyHostToDevice));

    map<<<numBlocks, maxThreads>>>(d_idata, d_intermediate, numThreads);
    reduce<<<numBlocks, maxThreads, smemSize>>>(d_intermediate, d_odata, numThreads);

    int s = numBlocks;
    while (s > 1) {
       // int nextNumBlocks = (s + maxThreads - 1) / maxThreads;
        reduce<<<(s + maxThreads - 1) / maxThreads, maxThreads, smemSize>>>(d_odata, d_intermediate, s);
        checkCudaErrors(cudaMemcpy(d_odata, d_intermediate, (s + maxThreads - 1) / maxThreads * sizeof(double), cudaMemcpyDeviceToDevice));
        //s = nextNumBlocks;
        s = (s + maxThreads - 1) / maxThreads;
    }

    checkCudaErrors(cudaMemcpy(h_odata, d_odata, sizeof(double), cudaMemcpyDeviceToHost));

    printf("GPU sum : %f\n\n", h_odata[0]);

    checkCudaErrors(cudaFree(d_idata));
    checkCudaErrors(cudaFree(d_odata));
    checkCudaErrors(cudaFree(d_intermediate));
    //free(h_idata);
    //free(h_odata);

    return h_odata[0];
}

