#ifndef NSHEPHERD
#define NSHEPHERD 2
#endif

#ifndef NWORKER
#define NWORKER 2
#endif

#ifndef NTHREAD
#define NTHREAD 5
#endif

/* shut promela up if timeout is not defined, models premature timeout */
/*
#ifndef timeout
#define timeout true
#endif
*/
int rets[NSHEPHERD*NWORKER*2+1];

mtype = {Greeter};
inline function(n, arg, ret) {
  if
    :: n == Greeter ->
       byte tmp1, tmp2, tmp3, tmp4;
       qthread_id(tmp1);
       qthread_shep(tmp2);
       qthread_worker(tmp4, tmp3);
       printf("Hello World! This is thread %d, running on shepherd %d, worker %d\n", tmp1, tmp2, tmp3);
    /*   ret = 1 */ /* Success */
    :: else ->
       printf("trying to execute invalid function %d\n", n);
       assert(0)
  fi
}

#include "model.pml"


/* we need to do this by how many to spawn. */


/* the other thing is that all the shepherds and workers are operating concurrently */

/* need to put the function table before the module */

init {
  byte status;
  byte nshepherds;
  byte nworkers;
  byte return_value;
  qthread_initialize(status);
  assert(status == Success);
  printf("status %d\n", status);
  byte spawn = 0;
  byte tmp;
  /* byte rets[NWORKER*2]; */
  tmp = 1;
  qthread_num_shepherds(nshepherds);
  qthread_num_workers(tmp);
  spawn = tmp * nshepherds;


  printf("%d shepherds...\n", nshepherds);

  /* qthread_num_workers(nworkers); */ 
  printf("\t%d threads total\n", nworkers);
  byte i;
  i = 0;
  printf("enqueue spawn %d\n", spawn);
  do :: i < spawn ->
        printf("enqueue main %d\n", i);
        qthread_fork(Greeter, 0, /*rets*/i);
        /* assert(rets[i] == Success); */
        i++;
     :: else -> break 
  od
  printf("done spawning\n");
  i = 0;
  printf("spawn %d\n", spawn);
  do :: i < spawn ->
        printf("reading ff on %d\n", i);
        rets[i] == 1;
        /* qthread_readFF(0, rets[i]); */
        /* assert(rets[i] == Success); */
        i++;
     :: else -> break
  od
  qthread_finalize();
}