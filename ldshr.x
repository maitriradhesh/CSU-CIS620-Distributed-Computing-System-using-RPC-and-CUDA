struct input {
	int N; 
	int M;
	int S1;
	int S2;
};
/*array size
mean 
seed value
*/

struct Node {
    double F;
    struct Node* next;
};



struct LinkedList {
   struct Node* head;
};


program LDSHRPROG {
	version LDSHRVERS{
	double getload(string) = 1;
	double sumqroot_gpu(input) = 2;
	double sumqroot_lst(LinkedList) = 3;
	} = 1;
} = 0x22200001;
/* 1 is the version number
program number ranges established by ONC*/
