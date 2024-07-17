#include <stdio.h>
#include <string.h>
#include <rpc/rpc.h>
#include "ldshr.h"
#include <unistd.h>
#include <math.h>

double sumqroot(int N, int M, int S);
double map(Node *node);
double reduce(LinkedList *list);

// double *getload_1_svc(char **server, struct svc_req *rqp) {
// 	double load[3];
// 	int ret = getloadavg(load, 3);
// 	double *result = load + 2;
// 	return (double *)result;
// }

double *getload_1_svc(char **server, struct svc_req *rqp) {
    double load[3];
    int ret = getloadavg(load, 3);  // load[0], load[1], load[2] are 1, 5, and 15 minute load averages
    if (ret == -1) {
        fprintf(stderr, "getloadavg call failed\n");
        return NULL;  // You should handle the error appropriately
    }
    double *result = malloc(sizeof(double));  // Allocate memory for the result
    if (result == NULL) {
        fprintf(stderr, "Memory allocation failed\n");
        return NULL;
    }
    *result = load[1];  // return the 5-minute load average, or choose another
    return result;
}


// double *sumqroot_gpu_1_svc(input *NMS, struct svc_req *rqp) {
// 	//fprintf(stderr, "Error allocating memory for max in sumqroot_gpu_1_svc\n");
// 	double *max = (double *)malloc(sizeof(double));
// 	*max = sumqroot(NMS->N, NMS->M, NMS->S);//goes to cuda file
// 	return max;
// }

double *sumqroot_gpu_1_svc(input *NMS, struct svc_req *rqp) {
    double *max = (double *)malloc(sizeof(double));
    if (max == NULL) {
        fprintf(stderr, "Error allocating memory for max in sumqroot_gpu_1_svc\n");
        return NULL;
    }
    
    // Example condition: choose seed based on a modulus operation or any other condition
    int seed = (NMS->N % 2 == 0) ? NMS->S1 : NMS->S2;
    *max = sumqroot(NMS->N, NMS->M, seed);  // Using dynamic seed based on N
    return max;
}


double *sumqroot_lst_1_svc(LinkedList *list, struct svc_req *rqp) {
    static double result;  // Make static to ensure it persists after function return
    result = reduce(list);
    return &result;
}

double map(Node *node) {
    return sqrt(sqrt(node->F));  // Quadruple root
}

double reduce(LinkedList *list) {
    double sum = 0;
    Node *current = list->head;
    while (current != NULL) {
        sum += map(current);
        current = current->next;
    }
    return sum;
}

// LinkedList * upd_lst_1_svc(LinkedList *inputlist , struct svc_req *rqp)
// {
// 	struct Node *node;
// 	node = inputlist->head;
// 	do{
// 		node->F = pow(node->F,1.0/4.0)* 20.0;
// 		node = node->next;
// 	}while(node->next != NULL);
// 	node->F =  pow(node->F,1.0/4.0)* 20.0;
// 	return (LinkedList *) inputlist;
// }
