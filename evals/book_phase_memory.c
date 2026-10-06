#include <stdint.h>
#include <unistd.h>
#include <libproc.h>
#include <sys/resource.h>
int book_phase_memory(uint64_t *out) {
  struct rusage_info_v4 r;
  if (proc_pid_rusage(getpid(), RUSAGE_INFO_V4, (rusage_info_t *)&r)) return -1;
  out[0] = r.ri_phys_footprint;
  out[1] = r.ri_resident_size;
  out[2] = r.ri_lifetime_max_phys_footprint;
  return 0;
}
