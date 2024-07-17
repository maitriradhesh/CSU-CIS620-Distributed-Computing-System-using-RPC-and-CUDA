cc = nvcc
APPN = ldshr
LIBS= -lpthread
all: ldshr.h reduction.o  $(APPN)_svc $(APPN)

reduction.o : reduction.cu
	$(cc) -c reduction.cu -o reduction.o
	
$(APPN).h: $(APPN).x
	rpcgen $(APPN).x


$(APPN)_svc : $(APPN)_svc_proc.o $(APPN)_svc.o  $(APPN)_xdr.o reduction.o
	$(cc) $(APPN)_svc_proc.o $(APPN)_svc.o  $(APPN)_xdr.o reduction.o -o $(APPN)_svc $(LIBS)
	
	
$(APPN)_svc.o: $(APPN)_svc.c ldshr.h
	$(cc) -c $(APPN)_svc.c -o $(APPN)_svc.o

$(APPN)_xdr.o: $(APPN)_xdr.c ldshr.h
	$(cc) -c $(APPN)_xdr.c -o $(APPN)_xdr.o

$(APPN)_clnt.o: $(APPN)_clnt.c ldshr.h
	$(cc) -c $(APPN)_clnt.c -o $(APPN)_clnt.o

$(APPN) : $(APPN).o $(APPN)_clnt.o  $(APPN)_xdr.o 
	gcc $(APPN).o $(APPN)_clnt.o  $(APPN)_xdr.o -o $(APPN) $(LIBS)

clean:
	$(RM) $(APPN) $(APPN)_svc $(APPN)_svc.c $(APPN)_xdr.c $(APPN)_clnt.c $(APPN).h *.o *.*%

