#!/bin/bash

for i in 1 2 4 8 16; do
        echo nworker $i
	srun spin -DNSHEPHERD=$i -DNWORKER=1 -c100  -run -O2 -bitstate -DVECTORSZ=10000000  -m100000000  hello_world_multi.pml
done

echo nworker 24
srun -t240 spin -DNSHEPHERD=24 -DNWORKER=1 -c100 -run -O2 -bitstate -DVECTORSZ=10000000  -m100000000  hello_world_multi.pml
echo nworker 28
srun -t240 spin -DNSHEPHERD=28 -DNWORKER=1 -c100 -run -O2 -bitstate -DVECTORSZ=10000000  -m100000000  hello_world_multi.pml
