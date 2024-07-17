#include <stdio.h>
#include <ctype.h>
#include <rpc/rpc.h>
#include <string.h>
#include "ldshr.h"
#include <pthread.h>
#include <float.h>

struct ThreadParams{
	input *nms;
	CLIENT *server;
};//traverse the pthread

typedef struct {
	LinkedList *list;
    	CLIENT *server;
} ListThreadParams;
// Linked list into the pthread

void *thread_function(void *arg) {
	struct ThreadParams *thread_params = (struct ThreadParams *)arg;
	double *result = malloc(sizeof(double));
	if (result == NULL){
		fprintf(stderr, "Failed to get result from sumqroot_gpu_1\n");
		return NULL;
	}	
	*result = (*sumqroot_gpu_1(thread_params->nms, thread_params->server));
	return result;
}

void readDataAndCreateLists(const char* filename, LinkedList* list1, LinkedList* list2) {
    FILE* file = fopen(filename, "r");
    if (file == NULL) {
        perror("Failed to open file");
        exit(EXIT_FAILURE);
    }
    double number;
    int count = 0;
    Node* currentNode;
    while (fscanf(file, "%lf", &number) == 1) {
        currentNode = malloc(sizeof(Node));
        if (currentNode == NULL) {
            fprintf(stderr, "Memory allocation failed\n");
            exit(EXIT_FAILURE);
        }
        currentNode->F = number;
        currentNode->next = NULL;

        if (count % 2 == 0) {
            currentNode->next = list1->head;
            list1->head = currentNode;
        } else {
            currentNode->next = list2->head;
            list2->head = currentNode;
        }
        count++;
    }
    fclose(file);
}

void *processListFunction(void *arg) {
    ListThreadParams *params = (ListThreadParams *)arg;
    double *result = sumqroot_lst_1(params->list, params->server);
    if (result == NULL) {
        fprintf(stderr, "Failed to get result from sumqroot_lst\n");
        return NULL;
    }

    double *localResult = malloc(sizeof(double));
    if (localResult == NULL) {
        fprintf(stderr, "Failed to allocate memory for result\n");
        return NULL;
    }
    *localResult = *result;  // Copy the result to locally allocated memory to return
    return localResult;
}

int main(argc, argv) int argc; char *argv[]; {
	if (argc < 2) {
	        fprintf(stderr, "Usage: %s -option [additional args]\n", argv[0]);
	        exit(EXIT_FAILURE);
	}

	CLIENT *cl[5];
	double *load[5];
	char *server[5] = {"arthur", "bach", "brahms", "chopin", "degas"};
	// create client handles
	int i = 0;
	while (i < 5) {
		if (!(cl[i] = clnt_create(server[i], LDSHRPROG, LDSHRVERS, "tcp"))) {
			fprintf(stderr, "Error creating client for server[%d]\n", i);
			exit(1);
		}
		i++;
	}
	i = 0;
	while (i < 5) {
		load[i] = (double *)malloc(sizeof(double));
		if (load[i] == NULL) {
			fprintf(stderr, "Error allocating memory for load[%d]\n", i);
			exit(1);
		}
		i++;
	}
	
	double min = DBL_MAX;
	double second_min = DBL_MAX;
	int min_index = -1; 
	int second_min_index = -1;

	i = 0;
	while (i < 5){
		*load[i] = *getload_1(&server[i], cl[i]);
		if (*load[i] < min) {
			second_min = min;
			second_min_index = min_index;
			min = *load[i];
			min_index = i;
		}
		else if (*load[i] < second_min) {
			second_min = *load[i];
			second_min_index = i;
		}
		i++;
	}

	printf("arthur: %lf bach: %lf,brahms: %lf chopin: %lf degas: %lf\n", *load[0], *load[1], *load[2], *load[3], *load[4]);

	printf("(executed on %s and %s)\n", server[min_index], server[second_min_index]);

	if (strcmp(argv[1], "-lst") == 0 && argc == 3) {
    		LinkedList *list1 = malloc(sizeof(LinkedList));
    		LinkedList *list2 = malloc(sizeof(LinkedList));
    		if (!list1 || !list2) {
        		fprintf(stderr, "Failed to allocate memory for linked lists\n");
        		exit(EXIT_FAILURE);
    		}
    		list1->head = list2->head = NULL;
    		readDataAndCreateLists(argv[2], list1, list2);

    		CLIENT *server1 = cl[min_index];  // More accurately reflects that this is a server connection
			CLIENT *server2 = cl[second_min_index];

    		pthread_t threads[2];
    		ListThreadParams thread_params1 = {list1, server1};
    		ListThreadParams thread_params2 = {list2, server2};

    		pthread_create(&threads[0], NULL, processListFunction, &thread_params1);
    		pthread_create(&threads[1], NULL, processListFunction, &thread_params2);

			double finalSum = 0.0;
    		void *status;
			double *result = (double *)status;
    		
    		for (int i = 0; i < 2; i++) {
        		pthread_join(threads[i], &status);
        		if (status != NULL) {
            			finalSum += *(double *)status;
						free(status);
        		}
    		}

    		printf("Final sum of results: %.2f\n", finalSum);

    		// Cleanup
    		clnt_destroy(server1);
    		clnt_destroy(server2);
    		// Free linked lists here
	}


	// else if (strcmp(argv[1], "-gpu") == 0) {
	// 	printf("HELLO/n");
	// 	input nms[2];
	// 	double finalSum = 0.0;
	// 	void *status; 
	// 	double *result = (double *)status;
	// 	pthread_t thread[2];
		
	// 	nms[0].N = atoi(argv[2]) - 1;
	//     nms[0].M = atoi(argv[3]);
	//     nms[0].S1 = atoi(argv[4]);
	// 	nms[1].N = atoi(argv[2]) - 1;
	//     nms[1].M = atoi(argv[3]);
	//     nms[1].S2 = atoi(argv[5]);  // Assuming a different 'S' for the second instance

	//     printf("HELLO/n");
	// 	struct ThreadParams thread_params[2];
    // 	thread_params[0].nms = &nms[0];
	//     thread_params[0].server = cl[min_index];
	//     thread_params[1].nms = &nms[1];
	//     thread_params[1].server = cl[second_min_index];

	// 	pthread_create(&thread[0], NULL, thread_function, &thread_params[0]);
	// 	pthread_create(&thread[1], NULL, thread_function, &thread_params[1]);

	// 	for (int i = 0; i < 2; i++) { 
	// 				printf("Result from thread %d: %f\n", i, *result);
	// 		}
	// 	for (i = 0; i < 2; i++) {
	// 		pthread_join(thread[i], &status);
	// 		//printf("Result from thread %d: %f\n", i, *result);
	// 		if (status != NULL){
	// 			finalSum += *(double *)status;
	// 			//free(status);
	// 		}
	// 		else {
	// 			fprintf(stderr, "Thread %d did not return a result\n", i);
	// 		}
	// 	}
	// 	printf("Result: %.2f\n", finalSum);
	// }
	else if (strcmp(argv[1], "-gpu") == 0) {
    input nms[2];
    double finalSum = 0.0;
    void *status;
    pthread_t thread[2];

    nms[0].N = atoi(argv[2]) - 1;
    nms[0].M = atoi(argv[3]);
    nms[0].S1 = atoi(argv[4]);
    nms[1].N = atoi(argv[2]) - 1;
    nms[1].M = atoi(argv[3]);
    nms[1].S2 = atoi(argv[5]);  // Assuming a different 'S' for the second instance

    struct ThreadParams thread_params[2];
    thread_params[0].nms = &nms[0];
    thread_params[0].server = cl[min_index];
    thread_params[1].nms = &nms[1];
    thread_params[1].server = cl[second_min_index];

    pthread_create(&thread[0], NULL, thread_function, &thread_params[0]);
    pthread_create(&thread[1], NULL, thread_function, &thread_params[1]);

    for (int i = 0; i < 2; i++) {
        pthread_join(thread[i], &status);
        if (status != NULL) {
            double result = *(double *)status;
            //printf("Result from thread %d: %f\n", i, result);
            finalSum += result;
            //free(status);  // Make sure to free the memory allocated in thread_function
        } else {
            fprintf(stderr, "Thread %d did not return a result\n", i);
        }
    }
    printf("Result: %.2f\n", finalSum);
}

	else {
		fprintf(stderr, "Invalid option provided\n");
        	exit(EXIT_FAILURE);
	}

	return 0;
}
