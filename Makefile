
pan.c:
		spin -DNSHEPHERD=1 -DNWORKER=126 -a hello_world_multi.pml
pan: pan.c
	gcc 
all: pan
