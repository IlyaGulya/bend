#include <stdint.h>
#include <unistd.h>
#include <libproc.h>
#include <sys/resource.h>
#include <pthread.h>
#include <stdatomic.h>
#include <fcntl.h>
static int report_fd;
static _Atomic int phase, running;
static pthread_t thread;
static uint64_t peaks[3][2];
int artifact_memory(uint64_t *out) {
  struct rusage_info_v4 r;
  if (proc_pid_rusage(getpid(), RUSAGE_INFO_V4, (rusage_info_t *)&r)) return -1;
  out[0]=r.ri_phys_footprint; out[1]=r.ri_resident_size; return 0;
}
static void sample(void) {
  uint64_t m[2]; int p=atomic_load(&phase);
  if (!artifact_memory(m)) for(int i=0;i<2;i++) if(m[i]>peaks[p][i]) peaks[p][i]=m[i];
  uint64_t record[7]={(uint64_t)p,peaks[0][0],peaks[0][1],peaks[1][0],peaks[1][1],peaks[2][0],peaks[2][1]};
  if(report_fd>=0)pwrite(report_fd,record,sizeof(record),0);
}
static void *loop(void *unused) { (void)unused; while(atomic_load(&running)){sample();usleep(10000);}sample();return 0; }
int artifact_start(void){report_fd=open("/Users/ilyagulya/Projects/My/bend/checkpoints/parser-artifact-8g.phase-memory.bin",O_CREAT|O_TRUNC|O_WRONLY,0600);if(report_fd<0)return -1;atomic_store(&running,1);return pthread_create(&thread,0,loop,0);}
void artifact_phase(int p){atomic_store(&phase,p);}
void artifact_stop(uint64_t *out){atomic_store(&running,0);pthread_join(thread,0);for(int p=0;p<3;p++)for(int i=0;i<2;i++)out[p*2+i]=peaks[p][i];}
