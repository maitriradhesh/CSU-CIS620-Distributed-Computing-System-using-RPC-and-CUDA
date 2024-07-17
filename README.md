The purpose of this project was to write a distributed application using the Remote Procedure Call (RPC) protocol, the threads library, and the CUDA toolkit. In this project we were expected to use the ONC RPC Protocol to distribute computation via threads from a Linux workstation to two Linux workstations with the lowest two loads.

This project has the following files:
	ldshr.x 
	ldshr.c
	ldshr_svc_proc.c
	reduction.cu
	makefile
	datafile

This project is divided into two parts. The client program running on a workstation provides the interface to the users, and that can be any workstation from our “LINUX Lab”. The servers running on the pre-selected five Linux workstations provide the machine load reporting service and another two computational services.  We are instructed to use these workstations as the server workstations: "\"arthur\",\"bach\",\"brahms\"","\"chopin\"," and "\"degas\" " . 

Let’s begin with the 1st file, ldshr.x.

The code is a definition file for an RPC (Remote Procedure Call) interface, typically used with the ONC (Open Network Computing) RPC protocol. This is often described using a language specific to defining interfaces for RPC which likely uses the syntax for Sun Microsystems' RPC language, which can be compiled by rpcgen on Unix-like systems.

Here’s a breakdown of the components of the code:

Struct Definitions:

input Struct: This structure is designed to hold parameters needed by one of the RPC functions. It includes:
	"N" : Likely the size of the array or some numeric parameter indicating the scale or number of elements.
	"M" : Could represent a mean value used for calculations, possibly related to initializing values or determining behaviour of computation.
	"S" : These are seed values, probably used for generating random numbers in a controlled way to ensure reproducibility.

 Node Struct: Represents a node in a linked list, which includes:
	"F" : This could be a floating-point number representing data stored in each node.
	"next" : A pointer to the next node in the linked list, establishing the linked list structure.

LinkedList Struct: Represents a simple linked list structure that holds:
	"head" : A pointer to the first node of the list.

RPC Program Definition:

The RPC program is defined with a unique identifier and a version number. This definition specifies the procedures that can be remotely invoked, their signatures, and the types of data they accept and return.

program LDSHRPROG :Declares an RPC program with a specific program number (0X22200001). This hexadecimal number uniquely identifies this particular set of RPC services on the network.

vesrion LDSHRVERS:
	double "'getload(string)'"   : This function likely retrieves and returns the load average of a system identified by a string (probably a hostname or an identifier). The load average could relate to CPU or other system resource metrics.
	double "'sumqroot_gpu(input)'" : Computes and returns a double precision result, taking an input struct that contains parameters possibly configuring how the computation should be done on a GPU, like handling arrays using seeds for random number generation.
	double "'sumqroot_lst(LinkedList)'"  Similar to "'sumqroot_gpu()'" , but it operates on a linked list, possibly performing some aggregation or transformation (like summing quadruple roots) on list elements.

1: This line indicates the version of the program is 1. It is crucial as different versions of an RPC program can have different APIs or behaviours.

Use and Context:

This file is used to generate client and server stubs for RPC communication. The stubs handle data serialization and communication tasks, allowing developers to focus on implementing business logic rather than dealing with the complexities of network programming.

Client-side: The client application uses these stubs to call functions as if they were local, but the calls are transparently sent over the network.

Server-side: The server implements these functions, and the server stubs handle incoming network calls, execute the server's implementations, and send back the results.

These stubs and skeleton codes are generated using a tool like rpcgen by providing this .x file as input. This tool facilitates building distributed applications where servers can offer specific services that remote clients can invoke over a network.

Now , the next file, ldshr.c:

The client program keeps a list of five available Linux workstations in our lab. It firstly invokes a remote procedure "'getload()'"   to collect the load average (over the last 5 minute) from each workstation in the list and selects two workstations with the lowest load averages. Then, based on the command line option ("'-gpu' " or "'-lst'" ), the client creates two threads to invoke the computation function "'sumqroot_gpu()'"   or "'sumqroot_lst()'"  on the selected two workstations. Each workstation will get equal amount of data size. Finally, the client joins with the threads, adds the results from the two servers and prints it out.

Example 1:
"haydn % Idshr -gpu 20 5 17 23" 
"arthur: 2.30 bach: 3.3 brahms: 3.8 chopin: 0.50 degas: 1.27" 
"(executed on chopin and degas)" 
"result: 1421129.93" 
The first example, with the command line arguments "'-gpu N M S1 S2'"  , computes the sum of the quadruple root of an array. The whole array has 〖'2〗^N' (i.e. 〖'2〗^20') elements. Each of the selected servers will initialize half of the array elements using the exponential distribution with the mean value '"M'"  (i.e. "5" ). The two servers will use the values "'S1'"  and" 'S2'" , respectively (i.e. "17"  and "23" ), as the initial seed. The computation is executed on the machines chopin and degas with their GPUs. The client combines the results from the two servers and prints it out.

Example 2:
"haydn % Idshr -lst datafile" 
"arthur: 1.30 bach: 5.5 brahms: 2.8 chopin: 2.27 degas: 0.9" 
"(executed on arthur and degas)" 
"result: 7.40" 
The second example calculates the sum of the quadruple root of the doubles 5.0, 7.0, 19.0, and 23.0 stored in the file datafile. The task is distributed to the machines "arthur" and "degas". Each server gets a linked list of doubles from the client.

The C code is the main client implementation for an RPC-based distributed computing system. It uses threads to offload computation to remote servers using different data inputs, either from an array or a linked list structure. The program is structured to handle different commands specified via command-line arguments.

Breakdown of the Code:

Included Headers:
	"stdio.h" - Standard input/output library for functions like printf, fscanf, etc.
	"ctype.h"  - Character type library, not directly used in the visible part of the code but could be included for character testing and conversion utilities.
	"rpc/rpc.h"  - Contains functions and definitions for RPC programming, crucial for creating clients and making remote procedure calls.
	"string.h"  - Provides string handling functions, likely used for operations like strcmp.
	"pthread.h"  - Provides access to the POSIX threading API, enabling the program to create and manage threads.
	"ldshr.h"  - Presumably a custom header related to the specific RPC service, defining data structures like LinkedList, Node, and input, as well as function prototypes.
	"float.h"  - Provides limits for float types, used here to initialize minimum comparison values using DBL_MAX.

Struct Definitions:
	"ThreadParams" 
	Holds parameters for threads performing GPU computations.
	Contains pointers to input structures and CLIENT for RPC.
	"ListThreadParams" 
	Used for threads processing linked lists.
	Holds pointers to a LinkedList and an associated CLIENT for RPC operations.

Function Descriptions:
	"thread_function" 
	Purpose: Acts as a wrapper to call the "'sumqroot_gpu_1()'"  RPC function, handling GPU computations on remote servers.
	Parameters: Takes a generic pointer, casts it to "ThreadParams", and uses it to perform an RPC call.
	Return: Returns the result from the RPC call, or NULL if the call fails.

"readDataAndCreateLists" 
	Purpose: Reads double values from a file and alternately populates two linked lists.
	Parameters: Filename and pointers to two linked lists.
	Operations: Opens the file, reads doubles, and allocates Node structures filled with read values, appending them alternately to the two lists.
	Error Handling: Checks for file opening errors and memory allocation failures, exiting on failure.

"processListfunction" 
	Purpose: Processes a linked list using the "'sumqroot_lst_1()'"  RPC function.
	Parameters: Takes "ListThreadParams"  to access a linked list and its associated RPC client.
	Return: Returns a pointer to a double holding the RPC call result or NULL if the call or memory allocation fails.

"main" 
	Initialization
	Parses command-line arguments to configure the computation.
	Initializes RPC clients for pre-defined servers.
	Load Calculation
	Calls "'getload_1()'"  for each server to determine their loads and selects the two with the lowest loads for computation tasks.
	Command Handling
	"'-lst'"  option: Initializes linked lists, reads data into them, creates threads for processing these lists on the selected servers, and aggregates results.
	"'-gpu' " option: Prepares input structures, creates threads for GPU computations on selected servers using the provided seed values, and aggregates results.
	Cleanup
	Frees allocated resources, destroys RPC clients, and handles potential thread-related results.
Error Handling:
Throughout the program, extensive error handling ensures robust operation, including checking for:
	Successful memory allocations.
	Successful file operations.
	Valid RPC client creations.
	Correct execution of RPC calls.

This code is a sophisticated example of how multi-threading, remote procedure calls, and file I/O can be integrated in a C program to distribute computation tasks across multiple servers, making efficient use of networked resources and parallel processing.

Now , the next file, ldshr_svc_proc.c:

The server provides three services (i.e. functions). To get the load average (over the last 5 minute) on Linux, you can call the system function "'getloadavg()'" . The function "'sumqroot_gpu()'"   firstly initializes the very large array using the values "N,M", and "S1"  (or "S2"  ) passed from the client. It then launches a kernel function on GPU to calculate the quadruple root of each element in the array. Next, it invokes the reduction kernel function on GPU to get the summation of the quadruple roots and returns the value back to the client. Similarly, the function "'sumqroot_lst()'"   gets a linked list of doubles from the client. It then utilizes higher-order functions, namely the "'map()'"   function along with a formula function and the "'reduce()'"   function along with a summation function, to compute the summation of the quadruple roots in the list.

The code implements a set of server-side RPC functions that perform computations on data structures and system information, using the RPC mechanism for distributed computing. Each function is designed to be called remotely by clients. Here’s an explanation of each part:

Included Headers:
	"stdio.h"- Used for input/output functions such as printf and fprintf.
	"string.h"  -  Provides string manipulation capabilities, though its specific use isn't shown directly in the provided snippets.
	"rpc/rpc.h"  - Necessary for functions and types used in RPC programming.
	"ldshr.h"  - Presumably a custom header related to the specific RPC service, defining data structures like LinkedList, Node, and input, as well as function prototypes.
	"unistd.h"  - Typically includes various constants, type definitions, and functions for performing system calls.
	"math.h"  - Provides mathematical functions, in this case, sqrt, used for computing the quadruple root.
Function Descriptions:
	"'getload_1_svc()'"  
	Purpose: Fetches and returns the system's 5-minute load average.
	Parameters: char**server for the server identifier (unused here) and struct svc_req*rqp for additional RPC request handling information.
	Process: Uses "'getloadavg()'"  to fetch load averages and returns the 5-minute average. It handles potential errors like a failed call or memory allocation issues.
	Return: Pointer to a double containing the load average, or NULL on failure.

"'sumqroot_gpu_1_svc()'"  
	Purpose: Calculates a custom "sum root" computation, which could simulate a complex GPU-based operation.
	Parameters: input*NMS, containing parameters like array size, mean, and seeds; struct svc_req*rqp for the request.
	Process: Chooses a seed based on the parity of N and performs a computation by calling "'sumqroot()'" , a function likely designed to simulate a computation-intensive task.
	Return: Pointer to a double containing the computed value, or NULL if memory allocation fails.

"'sumqroot_lst_1_svc()'"  
	Purpose: Computes the sum of quadruple roots of all numbers in a linked list.
	Parameters: LinkedList *list which is the data to process, and struct svc_req*rqp for the request context.
	Process: Iterates over the linked list, applying the map function to each node and accumulating results.
	Return: Pointer to a static double containing the result. Static to ensure it remains valid post-function execution.

"'map'"  
	Purpose: Computes the quadruple root of a number.
	Parameters: Node *node containing a double.
	Return: The quadruple root of the node's value.

"'reduce'"  
	Purpose: Accumulates the quadruple roots of all numbers in a linked list.
	Parameters: LinkedList *list containing the data.
	Process: Iterates through the list, applying map to each element and summing the results.
	Return: Sum of the mapped values.

Server-Side Implementation Details:
These functions are typical of server-side RPC implementations where heavy lifting is done on the server, possibly to leverage more powerful computing resources or centralized data handling.
	The use of malloc in RPC service functions for returning data is crucial since RPC uses C's pass-by-value semantics, and returning local stack data would lead to undefined behaviour.
	Error handling is essential in such environments to ensure the server remains robust against failures caused by external factors like memory allocation failures or invalid inputs.

Summary:
This server-side code effectively showcases how complex data operations can be abstracted behind RPC calls, allowing clients to perform potentially computationally intensive operations remotely. This pattern is beneficial in distributed systems where tasks can be offloaded to specialized or more powerful servers. The use of linked data structures and conditional logic based on input parameters demonstrates a flexible handling approach tailored to the needs of diverse client requests.

Next, the file reduction.cu:

The CUDA C++ program demonstrates a distributed computation approach using GPU acceleration to compute the sum of the quadruple roots of an array of numbers, structured in a template fashion with kernel functions for map and reduce phases. Here's a detailed explanation of each part of the code:

Included Headers:
	"stdio.h" - Standard C library for input and output functions.
	"stdlib.h"- Standard C library for memory allocation, process control, conversions, and others.
	"cuda_runtime.h" - CUDA runtime API, essential for using CUDA functionalities like memory allocation, data transfer, and kernel execution.

Struct Definition: 
	"SharedMemory": 
This template struct provides a type-safe way to access shared memory within CUDA kernels. It uses the extern keyword to declare shared memory arrays (__smem[]) that are scoped to individual blocks of threads.
	operator*T and operator const T* - These operator overloads allow instances of SharedMemory<T>  to be used directly as pointers to type T, providing access to shared memory as if it were an array of type T.
CUDA Kernels:
	"'map'"   Kernel: 
Computes the quadruple root (fourth root) of each element in the input array if the element is non-negative.
	Parameters:
	double '*g_idata' : Input data array.
	double '*g_odata' : Output data array where results are stored.
	unsigned int 'n': Number of elements in the input and output arrays.

"'reduce'"  Kernel:
	Performs a parallel reduction to sum all elements in the array.
	Uses shared memory for efficient intra-block summation.
	Each block computes a partial sum of its elements, and the results are written to the output array.
	Shared Memory Usage: Efficient for reduction as it minimizes global memory access.

Helper Function: gpuAsert
A utility function for error checking CUDA operations. It prints out errors and optionally aborts the program.

Parameters:
	cudaError_t code: The CUDA error code.
	const char*file: The file in which the error occurred.
	int line: The line number at which the error is checked.
	bool abort: If true, the function exits the program on an error.

Extern "C" Function: sumqroot
The main computational function that sets up GPU memory, initiates kernel launches, and handles data transfer between host and device.

Parameters:
	int 'N': Power of two that determines the number of elements in the computation.
	int 'M': Mean value used to generate the input data using an exponential distribution.
	int 'S': Seed for random number generation.

Process:
	Allocates host and device memory.
	Initializes input data using an exponential distribution.
	Calls the map kernel to compute quadruple roots.
	Uses the reduce kernel in a loop to sum all elements, handling intermediate results with dynamic kernel launches as the number of elements reduces.

CUDA Memory Management:
	Uses cudaMalloc to allocate memory on the GPU.
	Transfers data between host and device using cudaMemcpy.
	Frees GPU memory resources with cudaFree.

Loop for Reduction:
The reduction process may require multiple stages depending on the number of threads and blocks. The loop continues reducing the size of the data (s) until only one value remains, which is the sum of all quadruple roots.

Error Handling:
Every critical CUDA operation is checked using checkCudaErrors, which uses gpuAsert to validate the operation's success.

Summary
This program exemplifies a typical use case for CUDA in performing high-performance parallel computations, combining memory management, error handling, and parallel programming patterns to efficiently process large data sets on the GPU.

Let’s deal with the datafile:

This datafile is used as input for some kind of processing, likely a computation based on the context of previous messages. In the context of your distributed computing system, this file could be read by the ldshr.c client application. 

In the ldshr.c file, when the program is run with the "'-lst'"  command-line option, the main function will invoke the "readDataAndCreateLists" function to read numbers from the datafile and populate two linked lists with its contents. 
Here’s a brief rundown of how that part of the program works:
	Command-Line Argument Check: The program first checks the provided arguments to see if the "'-lst'"  option is specified.
if (strcmp(argv[1],"-lst" )==0 && argc==3){ }

Opening the Data File: If the "'-lst'"  condition is met, "readDataAndCreateLists" is called with the filename provided as the second argument (here, it would be argv[2], which is expected to be " datafile ").

Reading Data and Filling Lists: The "readDataAndCreateLists" function then opens the datafile and reads its contents. For each number read from the file, a new Node is created, and the number is stored in this node. The nodes are alternately added to two linked lists (list1 and list2), effectively splitting the data between them.

Processing Lists: After the lists are populated, two threads are created, each responsible for processing one of the lists. The "processListfunction" function is used as the entry point for each thread, which in turn calls the "'sumqroot_lst_1_svc()'"  RPC function to calculate the sum of quadruple roots of the numbers in each list.

Result Aggregation: Once both threads have finished processing, the results (sum of quadruple roots from each list) are combined to produce a final result, which is then outputted by the program.

In summary, when the ldshr.c program is invoked with the "'-lst'"  option followed by a filename, it reads from that file to create two linked lists of numbers. These lists are then processed in parallel using remote procedure calls, and the results are aggregated and printed out. The datafile in this case provides the raw data for this distributed computing operation.

Lastly, the file, makefile:

The makefile is a script used by the make utility to build and compile a distributed application that utilizes both CPU and GPU for processing. It defines a series of rules and dependencies to automate the compilation of a program named ldshr. 
Let's go through it section by section:
Variables:
	cc: The compiler used for CUDA files (.cu), typically nvcc (NVIDIA CUDA Compiler). 
	APPN : The base name of the application, ldshr in this case.
	LIBS : Libraries to link with during compilation, here -lpthread for linking with the POSIX threading library. 
Targets and Dependencies:
	all: The default target. It depends on "ldshr.h", "reduction.o", $(APPN)_svc, and $(APPN). Running make without arguments will build all these dependencies.

"reduction.o": This target compiles the reduction.cu file into an object file "reduction.o" using the CUDA compiler. This object file is likely to contain the GPU-accelerated functions.

$(APPN).h : Generates header files from an RPC interface definition file ($(APPN).x) using rpcgen, a tool for generating C code to implement an RPC protocol.

$(APPN)_svc : Compiles the server component of the RPC application. It links together several object files, including those for the server procedures, the server stub, the XDR routines (for data serialization), and the "reduction.o"file.

$(APPN)_svc.o, $(APPN)_xdr.o, $(APPN)_clnt.o: These targets compile individual source files $(APPN)_svc.c, $(APPN)_xdr.c, $(APPN)_clnt.c) into object files. Each source file is generated by rpcgen and handles different parts of the RPC protocol:
	_svc.c : Server stubs for handling RPC requests.
	_xdr.c : XDR routines for data serialization and deserialization.
	_clnt.c : Client stubs for making RPC calls to the server.

$(APPN)  : Compiles the client executable. It depends on the client object files and XDR routines, and it uses gcc for linking because the client part is likely not containing any CUDA code, thus not requiring nvcc.

Phony Target: clean
	clean: A phony target that doesn't correspond to a file name; it's a command for cleaning up the build environment. It removes the application executables, intermediate object files (*.o), and files generated by rpcgen (with extensions .c and .h).
Special Characters:
	$@ : Represents the target name.
	$^ : Represents all of the target's dependency names.
	$(RM)  : The command to remove files, typically rm-f.
In essence, this makefile provides a sequence of instructions for building a distributed application that includes both a client and a server. The server uses CUDA for computations, while the client and server communicate over RPC. The makefile ensures that any changes to the source files trigger a rebuild of the affected components, facilitating a smooth development workflow.

Project status: COMPLETELY WORKING.
Testing and debugging:
We got issues with the client computing the sum to 0.00. The issue was with the sum the results in the client program( ldshr.c). The thread's result was incorrect and we fixed it by freeing the allocated memory and then correctly summing them up and printing out the total.

Outputs:
Step-1:
	To begin to run the code, we need to open 6 terminals in total.
	5 server terminals
	1 client terminal.
 
Step 2:
	Make all the necessary files to compile the program. To do that, we make you of the make command. Inside our makefile, we also rpcgen here which is used to create the 4 RPC connected files. From these generated files, we import "ldshr.h" file into the ldshr.c and ldshr_svc_proc.c files as we want to make use of the "ldshr.x" file.
	Open five terminals in the specified hostnames specified in ldshr.c. 
	The hardcoded hostnames are "\"arthur\",\"bach\",\"brahms\"","\"chopin\"," and "\"degas\"" .

Step 3: 
	The servers are setup in all the specified host servers and run. The servers are run, and they are listening to incoming requests.
	We need to 1st run the ldshr_svc_proc.c file making use of the ./ldshr_svc command so that the servers are wanting to connect to the client workstation, ldshr.c.
	If you do not run the server file 1st, the client workstation will throw an error that in could not connect to the servers to get the load. 
 
CASE 1: 
./ldshr -gpu 20 5 17 23
 
The output on each server window is showing the load averages for each server (the 2 servers with the least loads), and the "GPU sum"  is being computed  in the same two servers which is being picked by the ("'getloadavg()'" ) which represents the computed result from the GPU calculation for each server. Each server is computing its own part of the workload.
	The results from each server (the 2 servers with the least loads) where the GPU computations happen are being received  by the client (ldshr.c) after the pthread_join calls.
	The final summation is aggregating the results from each thread to produce the final output.
	The wrapper function is used from the client side and the function is used to go to the server side to get calculated by the GPU (reduction.cu).

CASE 2:
./ldshr -lst datafile
 
The "-lst'"  option is provided, it triggers the following:
	Reading a data file and dividing its contents into two linked lists (by alternating between them for each data point).
	Two separate threads are created for processing these lists on the two selected servers.
	Each thread uses the "'sumqroot_lst_1()'"   RPC call to process its respective list and compute a sum of quadruple roots.
	After both threads finish, their results are combined to produce a final sum.
	The quadruple root is calculated in map function in ldshr_svc_proc.c. The reduce function in the same file is used to add the quadruple roots.

