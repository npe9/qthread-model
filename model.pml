/* the other thing is that qthreads are programs and the programs.
catch a simple error.

 So you model your program as well.

 You also model the modules :)

 impractical to do this.

Certain parts of the system require modeling because they don't correspond to C.

machine context switches. How are they modeled in promela? model with a channel.

 make an inline.

 That will be interesting to move to a coq abstract semantics.

So environment variables with be defined as pound defines.
 That is nice.

array of channels for scheduling.

 Also interesting because it allows you to debug cooperative threads.

It's also nice because it can be developed incrementally.

 And changes to the main module can be tested against all other modules.

The idea is to add a test in travis CI.

*/


mtype:state = {
  Migrating,
  YieldedNear,
  Yielded,
  Queue,
  FebBlocked,
  ParentYield,
  ParentBlocked,
  ParentUnblocked,
  Syscall,
  Assassinated,
  Terminated,
  Running,
  New,
  TermShep,
  Nascent,
  RealMccoy,
  Unstealable,
  NoShepherd,
  Simple,
  TaskId
}

/* move this out eventually */
inline  qthread_writeEF_const(ret, retval) {
  ret = retval
}

/* need to be separate */
inline qthread_readFF(val, ret) {
  ret == 1
}

inline QTHREAD_CASLOCK_READ_UI(ptr, ret) {
  /* simple setting is atomic in promela, no need for anything special here */
  ret = ptr
}

inline QT_CAS(ptr, oldv, newv, ret) {
  atomic {
    ret = ptr;
    if :: ptr == oldv ->
          ptr = newv
       :: else
    fi
  }
}

/* inline QTHREAD_FASTLOCK_SETUP() { */
/*   /\* do nothing, just placeholder *\/ */
/*   assert(1) */
/* } */

/* inline QTHREAD_FASTLOCK_UNLOCK(l) { */
/*   assert(l); */
/*   l = 0; */
/*   assert(1) */
/* } */

inline QTHREAD_TRYLOCK_TRY(l, m) {
  /* a trylock is pthread_spin_trylock */
  atomic {
    if :: !l ->
          l = 1;
          m = 1
       :: else ->
          m = 0
    fi
  }
  assert(1)
}

inline QTHREAD_TRYLOCK_LOCK(l) {
  /* a trylock is pthread_spin_lock */
  atomic {
    !l;
    l = 1
  }
}

inline QTHREAD_TRYLOCK_UNLOCK(l) {
  assert(l);
  l = 0
}

typedef pthread_cond_t {
  byte waiters = 0;
  chan cont = [0] of {bit};
}

inline QTHREAD_COND_LOCK(l) {
  /* this is just regular pthreads with */
  assert(1)
}

inline QTHREAD_COND_UNLOCK(l) {
  /*   */
  assert(1)
}

inline QTHREAD_COND_BCAST(l) {
  /* pthread_cond_broadcast  */
  atomic {
    do
      :: l.waiters > 0 ->
         l.waiters--;
         l.cont?_
      :: else ->
         break
    od;
  }
}

inline QTHREAD_COND_SIGNAL(l) {
  /* pthread_cond_signal*/
  atomic {
    if :: l.waiters > 0 ->
          l.waiters--;
          l.cont!1
       :: else
    fi
  }
}

inline QTHREAD_COND_WAIT(l) {
  /* actually implemented as pthread_cond_timedwait */
  atomic {
    l.waiters++;
    QTHREAD_COND_UNLOCK(l);
    do :: l.cont?_ -> break
       /* :: (timeout) -> break  */
    od
  }
}

inline SPINLOCK_BODY() {
  /* no concept of process scheduling, so don't do anything here. */
  assert(1)
}

typedef Node {
  int next;
  int prev;
  byte value;
  bool allocated;
}

typedef Threadqueue {
  byte qid;
  int qlength;
  byte threads[NTHREAD];
  Node nodes[NWORKER*NSHEPHERD*2+1];
  int head;
  int tail;
  byte qlock;
  byte w_inds[NTHREAD];
  int t;
  byte type;
  pthread_cond_t cond;
  byte numwaiters;
};

typedef Worker {
  /* int threadqueue; */
  byte worker_id;
  bool tactive;
  byte shepherd;
  byte current
};

/* I can establish a ready queue by making an array with max tasks, we're still doing */
typedef Shepherd {
  byte workers[NWORKER];
  byte ready;
  byte sorted_sheplist[NSHEPHERD];
  byte shep_dists[NSHEPHERD];
  byte sched_shepherd;
  byte shepherd_id;
  /* PAPER: active is a reserved word in promela */
  bool tactive
};

typedef Blocked {
  byte queue;
  byte thread;
  byte addr
}

typedef Rdata {
  byte shepherd_ptr;
  Blocked blockedon
}


/* should I make shepherds references too? */
/* PAPER: can't have function pointers so number to the actual function */
/* so I need a list of threads. */
typedef Thread {
  byte f;
  byte thread_id;
  byte thread_state;
  byte flags;
  byte arg;
  int ret;
  byte team;
  int target_shepherd;
  Rdata rdata;
};

typedef TLS {
  int worker;
  int shepherd;
};

/* global thread pool */
Thread threads[NWORKER*NSHEPHERD*4+1];
/* Thread threads[255]; */
Worker workers[NWORKER*NSHEPHERD+1];
/* Worker workers[255]; */
Threadqueue threadqueues[NWORKER*NSHEPHERD+1];
Shepherd shepherds[NSHEPHERD];
TLS tls[NWORKER*NSHEPHERD+1];
/* TLS tls[255]; */

typedef Qlib {
  /* need to set to the number of shepherds */
  Shepherd shepherds[NSHEPHERD];
  /* which thread is mccoy */
  byte max_unique_id;
  byte max_thread_id;
  byte nshepherds;
  byte mccoy_thread;
  byte sched_shepherd_lock
};

typedef Qthreadaddr {
  byte addr;
  byte lock;
  byte EFQ
}

Qlib qlib;

inline qthread_num_shepherds(n) {
  n = NSHEPHERD
}

inline qthread_num_workers(n) {
  n = NWORKER
}

inline qthread_internal_self(ret) {
  if :: tls[_pid].worker >= 0 ->
        ret = workers[tls[_pid].worker].current
     :: else ->
        ret = -1
  fi
}
inline qthread_id(ret) {
  /* so where is this going to be stored? */
  ret = _pid
}

inline qthread_worker(shep, ret)
{
  printf("_pid %d NWORKERS %d\n", _pid, NWORKER);
  shep = tls[_pid].shepherd;
  ret = tls[_pid].worker
  printf("shep %d ret %d\n", shep, ret);
}

inline qthread_shep(ret) {
  /* so do we have globals? so that is interesting, we can do workers by _tid? */
  ret = tls[_pid].shepherd
}

/* move to different file */

inline mycounter(q, cc) {
  int tmpc;
  byte v;
  int shep;
  /* PAPER: can't have fake variables */
  qthread_worker(shep, tmpc);
  cc = threadqueues[q].w_inds[0] /* [tmpc % (qlib.nshepherds * qlib.nworkerspershep) ]; */
}

inline myqueue(qe, q) {
  byte c;
  mycounter(qe, c);
  /* q = threadqueues[qe].t  +c  */
}

byte finalizing = 0;
int mccoy = -1;

inline alloc_tqnode(q, node) {
  node = 0;
  /* I don't care if we're in an infinite loop here, I'll put in an LTL assertion that keeps it from starving */
  do :: threadqueues[q].nodes[node].allocated ->
        node = (node+1)%(NWORKER*NSHEPHERD*2+1)
     :: else ->
        threadqueues[q].nodes[node].next = -1;
        threadqueues[q].nodes[node].prev = -1;
        threadqueues[q].nodes[node].value = -1;
        threadqueues[q].nodes[node].allocated = 1;
        break
  od
  printf("tallocated %d\n", node);
}

inline free_tqnode(q, node) {
  threadqueues[q].nodes[node].allocated = 0;
}

inline qt_threadqueue_enqueue_tail(qe, t, node) {
  int q;
  int tmp1;
  node = -1;
  printf("enqueuing %d on %d\n", t, qe);
  printf("enqueuing %d's thread_state %d\n", t, threads[t].thread_state);
  printf("enqueuing %d's flags %d mccoyflag %d\n", t, threads[t].flags, RealMccoy);
  if :: threads[t].thread_state == TermShep ->
        printf("finalizing\n");
        finalizing = 1
     :: else
  fi
  printf("enqueuing checking flags threads[%d].flags %d threads[%d].flags & 1<<RealMccoy %d\n", t, threads[t].flags , t, threads[t].flags & 1<<RealMccoy);
  if :: threads[t].flags & 1<<RealMccoy ->
        printf("enqueue it's the mccoy thread, don't add, mccoy %d\n", mccoy);
        if :: mccoy >= 0 ->
              printf("mccoy thread non-null and trying to set!\n");
              assert(0);
           :: else
        fi
        mccoy = t;
     :: else ->
        printf("enqeueing tail\n");
        myqueue(qe, q);
        mycounter(qe, tmp1);
        /* I also need a way of adding in the linked list */
        alloc_tqnode(q, node);
        assert(node != -1);
        assert(threadqueues[q].qlength >= 0);
        threadqueues[q].nodes[node].value = t;
        threadqueues[q].nodes[node].next = -1;
        printf("_pid %d locking q %d\n", _pid, q);
        QTHREAD_TRYLOCK_LOCK(threadqueues[q].qlock);
        printf("enqueue locked queue\n");
        threadqueues[q].nodes[node].prev = threadqueues[q].tail;
        threadqueues[q].tail = node;
        if :: threadqueues[q].head == -1 ->
              threadqueues[q].head = node
           :: else ->
              threadqueues[q].nodes[threadqueues[q].nodes[node].prev].next = node;
        fi
        printf("enqueue inc qlength\n");
        threadqueues[q].qlength++;
        printf("enqueue qe %d q %d threadqueues[%d].qlength %d\n", qe, q, q,threadqueues[q].qlength);
        printf("_pid %d unlocking q %d\n", _pid, q);
        QTHREAD_TRYLOCK_UNLOCK(threadqueues[q].qlock);
  fi
  printf("enqueuing checking finalize finalize %d threads[t].flags & (1<<RealMccoy) %d\n", finalizing, threads[t].flags & (1<<RealMccoy));
  if :: finalizing || threads[t].flags & (1<<RealMccoy) ->
        printf("finalizing\n");
        QTHREAD_COND_LOCK(threadqueues[qe].cond);
        QTHREAD_COND_BCAST(threadqueues[qe].cond);
        QTHREAD_COND_UNLOCK(threadqueues[qe].cond);
        /* PAPER stupid promela needing unique global labels */
        goto done3
     :: else
  fi
  if :: threadqueues[qe].numwaiters > 0 ->
        QTHREAD_COND_LOCK(threadqueues[qe].cond);
        if :: threadqueues[qe].numwaiters > 0 ->
              QTHREAD_COND_SIGNAL(threadqueues[qe].cond);
           :: else
        fi
        QTHREAD_COND_UNLOCK(threadqueues[qe].cond);
     :: else
  fi
done3:
  ;
}

inline qt_threadqueue_enqueue(q, t) {
  int n;
  printf("enqueueing q %d t %d\n", q, t);
  qt_threadqueue_enqueue_tail(q, t, n)
}

inline qt_threadqueue_advisory_queuelen(ready, busy_level) {
  busy_level = 1
}

inline qt_threadqueue_choose_dest(curr_shep, dest_shep) {
  printf("choosing dest shepherd\n");
  if :: curr_shep >= 0 ->
        dest_shep = (shepherds[curr_shep].sched_shepherd+1) % qlib.nshepherds;
        shepherds[curr_shep].sched_shepherd = shepherds[curr_shep].sched_shepherd+1;
        shepherds[curr_shep].sched_shepherd = shepherds[curr_shep].sched_shepherd * (qlib.nshepherds > (dest_shep+1))
     :: else ->
        qthread_internal_incr_mod(shepherds[curr_shep].sched_shepherd, qlib.nshepherds, qlib.sched_shepherd_lock, dest_shep)
  fi
  printf("dest_shep %d\n", dest_shep);
}

bool nosortedlist = true;

inline qthread_find_active_shepherd(l, d, shep) {
  byte target = 0;
  byte nsheps = qlib.nshepherds;
  printf("list: from %d sheps\n", nsheps);
  byte busyness = 0;
  if :: nosortedlist ->
        bool found = 0;
        byte i = 0;

        do :: i < nsheps ->
              byte tmp9 = 1;
              /* QTHREAD_CASLOCK_READ_UI(shepherds[i].active, tmp9); */
              if :: tmp9 ->
                    byte shep_busy_level;
                    qt_threadqueue_advisory_queuelen(shepherds[i].ready, shep_busy_level);
                    if :: found == 0 ->
                          found = 1;
                          printf("shep %d is the least busy (%d) so far\n", i, shep_busy_level);
                          busyness = shep_busy_level;
                          target = i
                       :: found && (shep_busy_level < busyness) ->
                          printf("shep %d is the least busy (%d) so far\n", i, shep_busy_level);
                          busyness = shep_busy_level;
                          target = i
                    fi
              fi
              i++
           :: else ->
              break
        od
        assert(found);
        printf("found bored target %d\n", target)
     :: else ->
        byte alt;
        byte target_dist;
        printf("GOING THROUGH ALT CODEPATH target %d nsheps %d\n", target, nsheps);
        target = 0;
        do :: target < nsheps && !shepherds[target].tactive /* need read_UI here too */ ->
              printf("%d is inactive\n", target);
              target++
           :: else ->
              break
        od
        if :: target >= (nsheps - 1) ->
              goto doneshep
           :: else
        fi
        target_dist = shepherds[d].sorted_sheplist[shepherds[l].shep_dists[target]];
        printf("nearest active shepherd (%d) is %d away\n", shepherds[l].shep_dists[target], target_dist);
        qt_threadqueue_advisory_queuelen(shepherds[l[alt]].ready, shep_busy_level);
        target = 0;
        shepherds[target].tactive = 1;
  fi
  /* Paper talk about how to implement this */
  shep = target;
doneshep:
}

inline qt_threadqueue_enqueue_yielded(q, t) {
  qt_threadqueue_enqueue(q, t)
}

inline qthread_queue_internal_enqueue(q, t) {
  assert(0)
}

inline qt_threadqueue_dequeue_tail(qe, node) {
  int tmp1;
  int q;

  printf("deqeueing tail\n");
  myqueue(qe,q);

  printf("dequeue qe %d q %d threadqueues[%d].qlength %d\n", qe, q, q,threadqueues[q].qlength);
  if :: threadqueues[q].qlength == 0 ->
        node = -1;
        printf("dequeue empty queue finishing\n");
        goto done1
     :: else
  fi
  printf("dequeue locking\n")
  QTHREAD_TRYLOCK_TRY(threadqueues[q].qlock, tmp);
  printf("dequeue unlocked\n")
  printf("dequeue TRYLOCK tmp %d\n", tmp);
  if :: tmp == 0 ->
        node = -1;
        goto done1
     :: else
  fi
  if :: threadqueues[q].qlength == 0 ->
        goto done0
     :: else
  fi
  printf("dequeue node %d threadqueues[%d].tail %d\n",  node, q, threadqueues[q].tail);
  node = threadqueues[q].tail
  assert(threadqueues[q].nodes[node].allocated);
  threadqueues[q].tail = threadqueues[q].nodes[node].prev
  if :: threadqueues[q].tail != -1 ->
        threadqueues[q].nodes[threadqueues[q].tail].next = -1;
     :: else
  fi
  if :: threadqueues[q].head == node ->
        threadqueues[q].head = -1;
     :: else
  fi
  threadqueues[q].qlength--;
  assert(threadqueues[q].nodes[node].allocated);
  assert(threadqueues[q].qlength >= 0);
  /* now it's linked list time */
done0:
  printf("_pid %d unlocking q %d\n", _pid, q);
  QTHREAD_TRYLOCK_UNLOCK(threadqueues[q].qlock);
done1:
  ;
}

inline qt_threadqueue_dequeue_head(qe, node) {
  int tmp13;
  int q;

  node = -1;
  printf("deqeueing head\n");
  myqueue(qe,q);
  if :: threadqueues[q].qlength == 0 ->
        goto done11
     :: else
  fi
  QTHREAD_TRYLOCK_TRY(threadqueues[q].qlock, tmp13);
  printf("dequeue head unlocked\n")
  printf("dequeue head TRYLOCK tmp %d\n", tmp13);
  if :: tmp == 0 ->
        node = -1;
        goto done11
     :: else
  fi
  if :: threadqueues[q].qlength == 0 ->
        goto done10
     :: else
  fi
  printf("dequeue node %d threadqueues[%d].head %d\n",  node, q, threadqueues[q].head);
  node = threadqueues[q].head;
  assert(threadqueues[q].nodes[node].allocated);
  threadqueues[q].head = threadqueues[q].nodes[node].next
  if :: threadqueues[q].head != -1 ->
        threadqueues[q].nodes[threadqueues[q].head].prev = -1;
     :: else
  fi
  if :: threadqueues[q].tail == node ->
        threadqueues[q].tail = -1;
     :: else
  fi
  threadqueues[q].qlength--;
  assert(threadqueues[q].nodes[node].allocated == 1);
  assert(threadqueues[q].qlength >= 0);
done10:
  printf("_pid %d unlocking q %d\n", _pid, q);
  QTHREAD_TRYLOCK_UNLOCK(threadqueues[q].qlock);
done11:
}

#ifndef STEAL_RATIO
#define STEAL_RATIO 8
#endif

#ifndef CONDWAIT_BACKOFF
#define CONDWAIT_BACKOFF 2048
#endif


byte steal_ratio = STEAL_RATIO;
int condwait_backoff = CONDWAIT_BACKOFF;

inline MACHINE_FENCE() {
  assert(1)
}

inline qt_scheduler_get_thread(qe, qc, tactive, tmp) {
  /* so what are we doing here? it will spin until it gets an item */
  int numwaits = 0;
  int node = -1;
  int q0;

  printf("getting thread\n");
  do :: node == -1 ->
        qt_threadqueue_dequeue_tail(qe, node);
        myqueue(qe, q0);
        printf("dequeue get_thread qe %d node %d\n", q0, node);
        assert(node == -1 || threadqueues[q0].nodes[node].allocated);
        if :: node == -1 && steal_ratio > 0 && (numwaits  % steal_ratio) == 0 ->
              byte i = 0;
              printf("dequeue steal ratio positive and we have waited long enough\n");
              do :: i < qlib.nshepherds ->
                    byte victim_queue;
                    qt_threadqueue_dequeue_head(victim_queue, node);
                    printf("dequeue get_thread node %d\n", node);
                    myqueue(qe, q0);
                    printf("dequeue get_thread qe %d node %d\n", q0, node);
                    assert(node == -1 || threadqueues[q0].nodes[node].allocated);
                    victim_queue = shepherds[i].ready
                    if :: node != -1 ->
                          myqueue(qe, q0);
                          tmp = threadqueues[q0].nodes[node].value;
                          /* what about freeing the node? */
                          goto done2
                       :: else
                    fi
                    i++
                 :: else ->
                    break
              od
           :: else
        fi
        int w0; /* namespace clash */
        int tmp2 = -1;
        qthread_worker(tmp2, w0);
        printf("get_thread node %d w %d mccoy %d\n", node, w, mccoy);
        if :: node == -1 && w0 == -1 && mccoy ->
              t = mccoy;
              mccoy = -1;
              goto done2;
           :: node == -1 && w0 != -1 ->
              printf("dequeue waiting on thread queue %d\n", w0);
              if :: numwaits > condwait_backoff && !finalizing ->
                    QTHREAD_COND_LOCK(threadqueues[qe].cond);
                    threadqueues[qe].numwaiters++;
                    /* Machine fences don't matter yet */
                    MACHINE_FENCE();
                    if :: !finalizing ->
                          QTHREAD_COND_WAIT(threadqueues[qe].cond)
                       :: else
                    fi
                    threadqueues[qe].numwaiters--;
                    QTHREAD_COND_UNLOCK(threadqueues[qe].cond)
                    numwaits = 0
                 :: else ->
                    SPINLOCK_BODY()
              fi
           :: else
        fi
        numwaits++
     :: else ->
        break
  od
  myqueue(qe, q0);
  t = threadqueues[q0].nodes[node].value;
  tmp = t;
  printf("dequeue found thread node %d t %d\n", node, tmp);
  free_tqnode(qe, node);
done2:
  ;
}

inline qthread_wrapper(t) {
  printf("qthread_wrapper\n");
  if :: threads[t].thread_state == Yielded ->
        byte prev_t = threads[t].rdata.blockedon.thread;
        threads[t].thread_state = Running;
        printf("qthread_wrapper thread %d yielded; rescheduling\n", t);
        qt_threadqueue_enqueue_yielded(shepherds[threads[t].rdata.shepherd_ptr].ready, prev_t);
     :: else
  fi
  /* TODO Aggregated */
  if :: threads[t].ret >= 0 ->
        int retval;
        printf("tid %u, with flags %u, handling retval\n", threads[t].thread_id, threads[t].flags)

        function(threads[t].f, threads[t].arg, retval);
        /* threads[t].ret = retval; */
        printf("writing ff on thread %d and ret %d\n", t, threads[t].ret);
        rets[threads[t].ret] = 1;
        /* qthread_writeEF_const(threads[t].ret, retval); */
        /* handle sincs */
     :: else ->
        printf("qthread_wrapper tid %u executing f=%d arg=%d...\n", t, threads[t].f, threads[t].arg);
        function(threads[t].f, threads[t].arg, threads[t].ret);
  fi
  /* need to handle return values here */
  threads[t].thread_state = Terminated;
  goto fail
}

inline qthread_exec(t, c) {
  assert(t >= 0);
  assert(c);
  printf("qthread_exec\n");
  if :: (threads[t].flags & (1<<Simple)) == 0 ->
        if :: threads[t].thread_state == New ->
              printf("t(%d), c(%d): type is QTHREAD_THREAD_NEW!\n", t, c)
              threads[t].thread_state = Running
           :: else ->
              ;
        fi
        printf("t(%d): executing swapcontext...\n", t);
        qthread_wrapper(t)
     :: else ->
        printf("t(%d): threads[%d].thread_state %e\n", t, t, threads[t].thread_state)
        assert(threads[t].thread_state == New);
        threads[t].thread_state == Running;
        qthread_wrapper(t)
  fi
  /* PAPER: talk about the kinds of context switches */
  /* assert(t); */
  printf("t(%d): finished, t->thread_state = %d\n", t, threads[t].thread_state);
}

/*
typedef MasterArgs {
  Shepherd shep;
  Worker worker
};
*/
/* so the question is how the other threads interact with this */
proctype qthread_master(int my_id, worker_id)
{
  /* take an arg which is me as a worker
   also take my shepherd */
  int me = my_id;
  int w = worker_id;
  printf("MASTER _pid %d worker %d shepherd %d\n", _pid, worker_id, me);
  tls[_pid].shepherd = my_id;
  tls[_pid].worker = worker_id;

  shepherds[me].shepherd_id = my_id;
  workers[w].worker_id = worker_id;
  printf("alive! me = %d\n", shepherds[me].shepherd_id);
  printf("id(%d): forked with arg %d\n", shepherds[me].shepherd_id, workers[w].worker_id);
  /* Is there a way to see if something is uninitialized? */
  /* assert(me != NULL); */
  /* so what do you need to do to set the thread local storage? */
  /*
   so do I want to model the debug statements? that's a good question.
  */

  /* set up TLS */
  byte cur = workers[w].current;
  int tmp;
  bool done = 0;
  byte threadqueue;
  int t;
  byte f;
  /* where is this initialized? */

  Threadqueue localqueue;
  /* so you doing things with pointers. so you need to do double indirection here.  */
  /* anything you have pointers to needs to have an indirection. */
  threadqueue = shepherds[me].ready;
  /* think about affinity? */
  /* FUTURE model affinity */
  QTHREAD_CASLOCK_READ_UI(shepherds[me].tactive, tmp);
  /* so the implementation of thread queues here is interesting, this means you can test the implementations independently.

Is there a conditional preprocessor ?

   no idea of a function here. You want to write this as a bunch fo things put together. :w

  */
  /* need to have a way to figure out what to do when it's not working */
again:do
        :: !done ->
           printf("calling get_thread\n");
           qt_scheduler_get_thread(threadqueue, localqueue, t, tmp);
           t = tmp;
           assert(t >= 0);
           printf("id(%d): dequeued thread: id %d/state %e\n", my_id, t, threads[t].thread_state);
           if :: threads[t].thread_state != Nascent ->
                 printf("All preconditions should be satisfied before reaching the main scheduling loop\n")
              :: else
           fi
           assert(threads[t].thread_state != Nascent);
           if :: threads[t].thread_state == TermShep ->
                 done = 1;
                 /* free the data structure? */
                 goto again
              :: else
           fi
           printf("threads[%d].thread_state %e threads[%d].flags %d\n", t, threads[t].thread_state, t, threads[t].flags);
           assert(threads[t].thread_state == New  || threads[t].thread_state == Running || (threads[t].thread_state == Yielded && (threads[t].flags & 1<<RealMccoy)));
           assert(threads[t].f || (threads[t].flags & 1<<RealMccoy));
           /*
 Normally you allocate rdata at this point, but I'm just going to do it statically for now.
           */
           printf("Checking target shepherd! threads[%d].target_shepherd %d my_id %d\n", t, threads[t].target_shepherd, my_id);
           if :: threads[t].target_shepherd >= 0 && threads[t].target_shepherd != my_id ->
                 printf("READ UI\n");
                 /* PAPER lack of functions is a bit of a pain */
                 QTHREAD_CASLOCK_READ_UI(qlib.shepherds[threads[t].target_shepherd].tactive, tmp);
                 if :: tmp ->
                       printf("id(%d): thread %d going back home to shep %d\n", my_id, t, threads[t].target_shepherd);
                       /* PAPER: use shepherd_id instead of pointers */
                       threads[t].rdata.shepherd_ptr = threads[t].target_shepherd;
                       assert(shepherds[threads[t].rdata.shepherd_ptr].ready);
                       qt_threadqueue_enqueue(threads[t].target_shepherd, t);
                    :: else
                 fi
              :: else
           fi
           QTHREAD_CASLOCK_READ_UI(shepherds[me].tactive, tmp);
           printf("READ_UI %d %d\n", shepherds[me].tactive, tmp);
           if :: !tmp ->
                 /* PAPER: all debugs are printfs. prints are only for debugging in spin anyway. */
                 printf("id(%d): skipping thread exec because I've been disabled!\n", my_id);
                 if
                   /* PAPER: so we need the equivalent of a NULL pointer? yes, that lets us do assertions and catch uninititialzied values */
                   :: threads[t].target_shepherd == -1 || threads[t].target_shepherd == my_id ->
                      /* assert(me.sorted_sheplist);
                      assert(me.shep_dists); */
                      byte tmp11;
                      qthread_find_active_shepherd(me, me, tmp11);
                      threads[t].rdata.shepherd_ptr = tmp11;
                   :: else ->
                      byte tmp12;
                      qthread_find_active_shepherd(threads[t].target_shepherd, threads[t].target_shepherd, tmp12);
                      threads[t].rdata.shepherd_ptr = tmp12;
                 fi
                 assert(threads[t].rdata.shepherd_ptr != -1)
                 printf("id(%d): rescheduling thread %d on %d\n", my_id, t, threads[t].rdata.shepherd_ptr);
              :: else ->  /* this shepherd is active */
                 /* cur = threads[t].thread_id; */
                 /* do we need to model get context? */
                 printf("id(%d): about to exec thread %d. shepherd is %d\n", my_id, t, threads[t].rdata.shepherd_ptr);
                 /* PAPER: this is a bit of weirdness. Effectively you need to write a singular proctype and pass it through. Similar to defunctionalization. */
                 /* and this is how we made it work.
                 */
                 /* t = cur; */

                 qthread_exec(t, tmp);
                 /* does promela have a way to do this? so this is really an inline.
        but you want to do it as both inlines and proctypes.
                 */
                 printf("id(%d): back from qthread_exec, state is %e\n", my_id, threads[t].thread_state);
                 if :: (threads[t].thread_state == Migrating) ->
                       printf("id(%d): thread %d migrating to shep %d\n", my_id, threads[t].thread_id, threads[t].target_shepherd);
                       threads[t].thread_state = Running;
                       threads[t].rdata.shepherd_ptr = threads[t].target_shepherd;
                       /* assert(threads[t].rdata.ready != 0); */
                       qt_threadqueue_enqueue(threads[t].rdata.shepherd_ptr, t)
                       /* need to change the shephard pointer */
                    :: (threads[t].thread_state == YieldedNear) ->
                       threads[t].thread_state = Running;
                       /* PAPER: future work will need to deal with the spawncache */
                       printf("id(%d): thread %d yielded near; rescheduling\n", my_id, threads[t].thread_id);
                       QTHREAD_CASLOCK_READ_UI(shepherds[me].tactive, tmp);
                       qt_scheduler_get_thread(threadqueue, 0, f, tmp);
                       qt_threadqueue_enqueue(shepherds[me].ready, t);
                       qt_threadqueue_enqueue(shepherds[me].ready, f)
                    :: (threads[t].thread_state == Yielded) ->
                       threads[t].thread_state = Running;
                       printf("id(%d): thread %d yielded; rescheduling\n", my_id, threads[t].thread_id);
                       /* paper talk about how queues were represented */
                       /* well that is not going to work, that is actually a queue, so I need to have a way of understanding it */
                       /* assert(me.ready != 0); */
                       qt_threadqueue_enqueue_yielded(shepherds[me].ready, t);
                       /* enqueue thread */
                    :: (threads[t].thread_state == Queue) ->
                       byte q;
                       threadqueues[q].qid = threadqueues[threads[t].rdata.blockedon.queue].qid;
                       printf("id(%d): thread tid=%d entering user queue (q=%d, type=%e)\n", my_id, threads[t].thread_id, q, threadqueues[q].type);
                       /* how to test for validity here? */
                       /* assert(q); */
                       qthread_queue_internal_enqueue(q, t);
                    :: (threads[t].thread_state == FebBlocked) ->
                       Qthreadaddr m;
                       m.addr = threads[t].rdata.blockedon.addr;
                       /* XXX: need to understand EFQ here */
                       printf("id(%d): thread tid=%d blocked on FEB (m=%d, EFQ=%e)\n", my_id, threads[t].thread_id, m.addr, m.EFQ);
                       /* QTHREAD_FASTLOCK_UNLOCK(m.lock) */
                    :: threads[t].thread_state == ParentYield ->
                       threads[t].thread_state = ParentBlocked;
                    :: threads[t].thread_state == ParentBlocked ->
                       printf("id(%d): thread in state %e; that's illegal!\n", my_id, threads[t].thread_state);
                       assert(0);
                    :: threads[t].thread_state == ParentUnblocked ->
                       /* do I need to free t? Probably not */
                       printf("id(%d): thread in state %e; that's illegal!\n", my_id, threads[t].thread_state);
                       assert(0);
                       /* PAPER do these later
         :: threads[t].thread_state == Syscall ->
            state = Running;
            printf("id(%d): thread %d made a syscall\n", my_id, threads[t].thread_id);
            qt_blocking_subsystem_enqueue(threads[t].rdata.blockedon.io);
         :: threads[t].thread_state == Assassinated ->
            printf("id(%d): thread %d assassinated\n", my_id, threads[t].thread_id);
            qthread_internal_assassinate(t);
                       */
                       /* need a way to turn off signals */
                    :: threads[t].thread_state == Terminated ->
                       printf("id(%d): thread %d terminated\n", my_id, threads[t].thread_id);
                       /*  no need to free? */
                       /* probably want to set the thread to be dead somehow */
                    :: else ->
                       printf("id(%d): thread in state %e; that's illegal!\n", my_id, threads[t].thread_state);
                       assert(0);
                       goto fail;
                 fi
           fi
              ::  else -> break
  od
fail:
  ;
}

inline qthread_internal_incr(val) {
  val++
}

inline qthread_internal_incr_mod(val, mod, b, c) {
  val = (val+1) % mod;
  c = val;
}
/* so understanding how sincs and friends interact is important here */

inline qthread_init()
{
  /* setup qlib */
  /* alignment init */
  /* initialize hash table */
  /* initialize subsystem */
  /* initialize topology */
  /* initialize mpool */
  /* spawn all the threads */

  /* make first qthread */
  /* I think you run a qt master per shepherd. */
  /* QTHREAD_FASTLOCK_SETUP(); */
  printf("began.\n");
  /* do we need to care about qlib initialization? */
  qlib.nshepherds = NSHEPHERD;
  /* internal alignment */
  /* initialize hashes */
  /* initialize topology */
  printf("there will be %d shepherd(s)\n", NSHEPHERD);
  /* TLS_INIT */
  /* initialize hazard pointers */
  /* initialize internal teams */
  /* syncvar subsystem init */
  /* threadqueue_subsystem_init */
  /* qt_blocking_subsystem_init() */
  /*  */
  /* there are no pointers so you have to be careful here, you probably want to create a global list of schedulers.
        Also want to think about mutual exclusion */
  qlib.max_thread_id  = 1;
  qlib.max_unique_id  = 1;
  /* I need to make the mccoy thread */
  byte i = 0;
  do
    :: i < NSHEPHERD ->
       printf("setting up shepherd %d\n", i);
       qlib.shepherds[i].shepherd_id = i;
       /* just have a one to one relationship with thread queue right now */
       shepherds[i].ready = i;
       shepherds[i].tactive = 1;
       printf("shepherd %d set up\n", i);
       i++
    :: else ->
       break
  od
  printf("done setting up shepherds.\n");
  printf("allocating shep0\n");
  qthread_thread_new(0, 0, 0, 0, 0, 0, qlib.mccoy_thread);
  printf("mccoy thread = %d\n", qlib.mccoy_thread);
  threads[qlib.mccoy_thread].thread_state = Yielded;
  threads[qlib.mccoy_thread].flags = (1<<RealMccoy) | (1<<Unstealable);
  threads[qlib.mccoy_thread].rdata.shepherd_ptr = 0;
  printf("enqueueing mccoy thread\n");
  qt_threadqueue_enqueue(qlib.shepherds[0].ready, qlib.mccoy_thread);
  qlib.shepherds[0].ready = 0;
  /* do we care about cas lock setup? */
  /* workers[qlib.shepherds[0].workers[0]].worker = 0; */
  workers[qlib.shepherds[0].workers[0]].shepherd = 0;
  workers[qlib.shepherds[0].workers[0]].worker_id = 0;
  /* FIXME */
  /* qthread_internal_incr(workers[qlib.max_unique_id, qlib.shepherds[0].workers[0]].unique_id); */
  i = 0;
  byte j = 0;
  do :: i < NSHEPHERD ->
        printf("forking workers for shepherd %d\n", i);
        j = 0;
again:  do :: j < NWORKER ->
              printf("starting loop\n");
              /* do we care about nosteal? */
              /* what about stealbuffer? */
              /* if :: i == 0 && j == 0 -> */
              /*       j++; */
              /*       printf("going again i %d j %d\n", i,j); */
              /*       goto again */
              /*    :: else -> */
              /*       /\* will wait forever otherwise *\/ */
              /*       ; */
              /* fi */
              /* PAPER simulating 2d array */
              /*
              tls[i*NSHEPHERD+j].shepherd = -1;
              tls[i*NSHEPHERD+j].worker = -1;
              */
              printf("setting workers\n");
              qlib.shepherds[i].workers[j] = i*NWORKER+j;

              printf("setting shepherd\n");
              workers[qlib.shepherds[i].workers[j]].shepherd = i;

              printf("setting worker_id\n");
              workers[qlib.shepherds[i].workers[j]].worker_id = j;
              /* qthread_internal_incr(workers[qlib.max_unique_id, qlib.shepherds[0].workers[0]].unique_id);  */
              /* where does packed worker id get used? */
              printf("activate shep %d's worker %d\n", i, j);
              run qthread_master(i, j);
              printf("spawned shep %d worker %d\n", i, j);
              j++
           :: else ->
              printf("breaking\n");
              break
        od
        i++
     :: else ->
        break
  od
}

mtype = { Success };
inline qthread_initialize(status) {
  qthread_init();
  status = Success
}

/* the mccoy thread is allocated out of band, start from 1 */
byte nqthreads = 1;

inline ALLOC_QTHREAD(t) {
  t = nqthreads-1;
  nqthreads++;
}

/* Paper promela's inlining in a PITA here, I need to change the function anmes */
inline qthread_thread_new(ff, a, arg_size, r, tm, team_leader, t) {
  ALLOC_QTHREAD(t);
  printf("t = %d\n", t);
  threads[t].f = ff;
  threads[t].arg = a;
  threads[t].ret = r;
  /* rdata? */
  threads[t].team = tm;
  /* how to deal with thread ids? */
  threads[t].thread_id = 0;
  threads[t].target_shepherd = -1;
  threads[t].thread_state = New;
  printf("returning\n");
}

inline qthread_finalize()
{
  printf("began.\n");
  printf("calling early cleanup functions\n");
  /* no cleanup functions yet */
  printf("done calling early cleanup functions\n");
  byte i0 = 0;
  byte j = 0;
  int t;
  do :: i0 < NSHEPHERD ->
        do :: j < NWORKER ->
              /* make a new worker with the shutdown sentinel */
              printf("terminating worker %d:%d\n", i0, j);
              qthread_thread_new(0, 0, 0, 0, 0, 0, t);
              threads[t].thread_state = TermShep;
              threads[t].thread_id = TaskId;
              threads[t].flags = 1<<Unstealable;
              qt_threadqueue_enqueue(i0*NSHEPHERD+j, t);
              bool tmp5;
              byte tmp6;
              QTHREAD_CASLOCK_READ_UI(workers[shepherds[i0].workers[j]].tactive, tmp5)
              if :: !tmp5 ->
                    printf("re-enabling worker %d:%d, so he can exit\n", i0, j);
                    QT_CAS(workers[shepherds[i0].workers[j]].tactive, 0, 1, tmp6);
                 :: else
              fi
              j++
           :: else ->
              break
        od
        i0++
     :: else ->
        break
  od
  printf("calling early cleanup functions\n");
  /* do we care about cleanup? */
  printf("done calling early cleanup functions\n");
}


inline qthread_spawn(f, arg, ret, npreconds, preconds, target_shep, feature_flag, ret) {
  /* assert(qthread_library_initialized); */
  int me = -1;
  byte myshep;
  byte dest_shep;
  int t;
  qthread_internal_self(me);
  if :: me >= 0 ->
        myshep = threads[me].rdata.shepherd_ptr
     :: else ->
        myshep = 0;
  fi

  printf("enqueue spawn f(%d), arg(%d), targ(%d)\n", f, arg, target_shep);
  /* so you need to pick a shepherd, need to have a way of saying noshepherd */
  if :: target_shep >= 0 ->
        printf("enqueue spawn qthread_spawn given target, using %d\n", target_shep);
        dest_shep = target_shep % NSHEPHERD
     :: else ->
        printf("enqueue spawn qthread_spawn choosing target shepherd automatically\n");
        qt_threadqueue_choose_dest(myshep, dest_shep)
  fi

  printf("enqueue spawn target_shep(%d) => dest_shep(%d)\n", target_shep, dest_shep);

  qthread_thread_new(f, arg, 0, ret, 0, 0, t);
  printf("enqueue spawn newed\n");
  assert(t >= 0);
  if :: target_shep != -1  ->
        threads[t].target_shepherd = dest_shep;
        threads[t].flags = threads[t].flags | (1<<Unstealable)
     :: else
  fi
  printf("enqueue spawn enqueueing\n");
  qt_threadqueue_enqueue(threadqueues[dest_shep].t, t);
  printf("enqueue spawned\n");
  /* need to handle the teams */
}

inline qthread_fork(f, arg, ret) {
  printf("enqueue f(%d), arg(%d), ret(%d)\n", f, arg, ret);
  /* how to handle no shepherd? */
  qthread_spawn(f, arg, ret, 0, 0,  -1/* NO_SHEPHERD */, 0, ret);
  printf("enqueue forked\n");
}
