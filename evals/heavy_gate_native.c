/* Lightweight heavy-gate supervisor. No vmmap, shell parsing, or RSS-only fallback.
 * Darwin's physical-footprint ledger charges internal compressed pages (including
 * compressor pages backed by swap); Linux conservatively sums VmRSS + VmSwap.
 * Sampling is periodic, not a hard kernel allocation quota. Process groups catch
 * ordinary orphaned descendants; remembered start identities catch observed
 * descendants which leave the group. Linux also adopts orphans as a subreaper.
 */
#define _GNU_SOURCE
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/file.h>
#include <sys/wait.h>
#include <sys/resource.h>
#include <stdint.h>
#include <inttypes.h>
#include <unistd.h>
#include <fcntl.h>
#include <signal.h>
#include <poll.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#ifdef __APPLE__
#include <libproc.h>
#else
#include <dirent.h>
#include <sys/prctl.h>
#endif

typedef struct {
  pid_t pid, ppid, group;
  uint64_t start, rss, footprint, high;
  int selected, zombie;
} Proc;
static Proc *rows, *known;
static size_t count, capacity, known_count, known_capacity;
static volatile sig_atomic_t interrupted;
static void on_signal(int sig) { interrupted = sig; }
static uint64_t millis(void) {
  struct timespec t;
  clock_gettime(CLOCK_MONOTONIC, &t);
  return (uint64_t)t.tv_sec * 1000 + t.tv_nsec / 1000000;
}
static int identity(pid_t pid, Proc *p) {
  memset(p, 0, sizeof(*p));
  p->pid = pid;
#ifdef __APPLE__
  struct proc_bsdinfo b;
  if (proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &b, sizeof(b)) != sizeof(b)) return -1;
  p->ppid = b.pbi_ppid; p->group = b.pbi_pgid;
  p->start = b.pbi_start_tvsec * 1000000 + b.pbi_start_tvusec;
  p->zombie = b.pbi_status == 5; /* SZOMB */
#else
  char path[64], text[8192];
  snprintf(path, sizeof(path), "/proc/%d/stat", pid);
  FILE *f = fopen(path, "r");
  if (!f) return -1;
  int ok = fgets(text, sizeof(text), f) != NULL;
  fclose(f);
  char *end = ok ? strrchr(text, ')') : NULL;
  if (!ok || !end || end[1] != ' ') return -1;
  /* stat fields 3..22; comm may itself contain spaces and ')' characters. */
  char *save = NULL, *token = strtok_r(end + 2, " ", &save);
  for (int field = 3; field <= 22; field++, token = strtok_r(NULL, " ", &save)) {
    if (!token) return -1;
    if (field == 3) p->zombie = *token == 'Z';
    if (field == 4) p->ppid = atoi(token);
    if (field == 5) p->group = atoi(token);
    if (field == 22) p->start = strtoull(token, NULL, 10);
  }
#endif
  return 0;
}
static int memory(Proc *p) {
  if (p->zombie) return 0;
#ifdef __APPLE__
  struct rusage_info_v4 r;
  if (proc_pid_rusage(p->pid, RUSAGE_INFO_V4, (rusage_info_t *)&r) != 0) return -1;
  p->rss = r.ri_resident_size;
  p->footprint = r.ri_phys_footprint;
  p->high = r.ri_lifetime_max_phys_footprint;
#else
  char path[64], line[512];
  snprintf(path, sizeof(path), "/proc/%d/status", p->pid);
  FILE *f = fopen(path, "r");
  if (!f) return -1;
  uint64_t rss = 0, swap = 0, high = 0, value;
  int have_rss = 0, have_swap = 0;
  while (fgets(line, sizeof(line), f)) {
    if (sscanf(line, "VmRSS: %" SCNu64 " kB", &value) == 1) { rss = value * 1024; have_rss = 1; }
    if (sscanf(line, "VmSwap: %" SCNu64 " kB", &value) == 1) { swap = value * 1024; have_swap = 1; }
    if (sscanf(line, "VmHWM: %" SCNu64 " kB", &value) == 1) high = value * 1024;
  }
  fclose(f);
  if (!have_rss || !have_swap) return -1;
  p->rss = rss; p->footprint = rss + swap; p->high = high;
#endif
  return 0;
}
static int append(pid_t pid) {
  Proc p;
  if (identity(pid, &p)) return 0; /* vanished during enumeration */
  if (count == capacity) {
    size_t next = capacity ? capacity * 2 : 256;
    Proc *grown = realloc(rows, next * sizeof(*rows));
    if (!grown) return -1;
    rows = grown; capacity = next;
  }
  rows[count++] = p;
  return 0;
}
static int enumerate(void) {
  count = 0;
#ifdef __APPLE__
  static pid_t *pids;
  static size_t slots;
  int hint = proc_listallpids(NULL, 0);
  if (hint <= 0) return -1;
  /* proc_listallpids returns a count, not a byte length. Reuse the buffer. */
  if ((size_t)hint + 256 > slots) {
    size_t next = (size_t)hint + 512;
    pid_t *grown = realloc(pids, next * sizeof(*pids));
    if (!grown) return -1;
    pids = grown; slots = next;
  }
  int n = proc_listallpids(pids, (int)(slots * sizeof(*pids)));
  if (n <= 0 || (size_t)n >= slots) return -1;
  for (int i = 0; i < n; i++) if (pids[i] > 0 && append(pids[i])) return -1;
#else
  DIR *dir = opendir("/proc");
  if (!dir) return -1;
  struct dirent *entry;
  while ((entry = readdir(dir))) {
    char *end;
    long pid = strtol(entry->d_name, &end, 10);
    if (*entry->d_name && !*end && pid > 0 && append((pid_t)pid)) { closedir(dir); return -1; }
  }
  closedir(dir);
#endif
  return 0;
}
static int sample(pid_t root, uint64_t root_start, uint64_t *rss, uint64_t *footprint, uint64_t *high, int *live) {
  if (enumerate()) return -1;
  *rss = *footprint = *high = 0; *live = 0;
  for (size_t i = 0; i < count; i++) {
    Proc *p = &rows[i];
    p->selected = p->group == root || (p->pid == root && p->start == root_start);
#ifndef __APPLE__
    if (p->ppid == getpid()) p->selected = 1;
#endif
    for (size_t j = 0; !p->selected && j < known_count; j++)
      if (p->pid == known[j].pid && p->start == known[j].start) p->selected = 1;
  }
  int changed;
  do {
    changed = 0;
    for (size_t i = 0; i < count; i++) if (!rows[i].selected)
      for (size_t j = 0; j < count; j++) if (rows[j].selected && rows[i].ppid == rows[j].pid) {
        rows[i].selected = 1; changed = 1; break;
      }
  } while (changed);
  known_count = 0;
  for (size_t i = 0; i < count; i++) if (rows[i].selected) {
    Proc *p = &rows[i];
    if (known_count == known_capacity) {
      size_t next = known_capacity ? known_capacity * 2 : 64;
      Proc *grown = realloc(known, next * sizeof(*known));
      if (!grown) return -1;
      known = grown; known_capacity = next;
    }
    known[known_count++] = *p;
  }
  int failed = 0;
  for (size_t i = 0; i < known_count; i++) {
    Proc *p = &known[i];
    if (p->zombie) continue;
    (*live)++;
    if (memory(p)) {
      Proc now;
      if (!identity(p->pid, &now) && now.start == p->start && !now.zombie) failed = 1;
      else (*live)--;
      continue;
    }
    *rss += p->rss; *footprint += p->footprint;
    if (p->high > *high) *high = p->high;
  }
  return failed ? -1 : 0;
}
static void terminate_tree(pid_t root, int sig) {
  /* The exclusive lease stays held until cleanup completes. */
  kill(-root, sig);
  for (size_t i = 0; i < known_count; i++) {
    Proc now;
    if (!identity(known[i].pid, &now) && now.start == known[i].start) kill(now.pid, sig);
  }
}
static int authenticate(const char *path, const char *token) {
  int fd = open(path, O_RDWR | O_NOFOLLOW | O_CLOEXEC);
  if (fd < 0) return 1;
  struct stat st;
  if (fstat(fd, &st) || st.st_uid != getuid() || !S_ISREG(st.st_mode) || (st.st_mode & 077)) { close(fd); return 1; }
  if (!flock(fd, LOCK_EX | LOCK_NB)) { close(fd); return 1; } /* no live lease */
  if (errno != EWOULDBLOCK && errno != EAGAIN) { close(fd); return 1; }
  char text[512] = {0}, expected[65] = {0};
  int owner, root;
  uint64_t start, began, timeout;
  ssize_t n = pread(fd, text, sizeof(text) - 1, 0);
  close(fd);
  if (n <= 0 || sscanf(text, "%d %" SCNu64 " %d %64s %" SCNu64 " %" SCNu64,
                      &owner, &start, &root, expected, &began, &timeout) != 6 || strcmp(token, expected)) return 1;
  Proc p;
  if (identity(owner, &p) || p.start != start || p.zombie) return 1;
  /* A token alone is not enough: the calling Bun process must be in the tree. */
  pid_t pid = getppid();
  for (int depth = 0; depth < 4096 && pid > 1; depth++) {
    if (identity(pid, &p)) return 1;
    if (p.pid == root || p.group == root)
      /* An authenticated descendant inherits the original monotonic deadline. */
      return !timeout || timeout > INT32_MAX || millis() - began >= timeout ? 2 : 0;
    pid = p.ppid;
  }
  return 1;
}
static void report(const char *status, const char *reason, int code, int sig,
                   uint64_t rss, uint64_t footprint, uint64_t elapsed, uint64_t timeout,
                   const char *phase, int stopped) {
  char line[512];
  int n = snprintf(line, sizeof(line),
    "{\"status\":\"%s\",\"reason\":\"%s\",\"commandExitCode\":%d,\"commandSignal\":%d,\"peakRssBytes\":%" PRIu64 ",\"peakFootprintBytes\":%" PRIu64 ",\"elapsedMs\":%" PRIu64 ",\"timeoutMs\":%" PRIu64 ",\"reportPhase\":\"%s\",\"ownedTreeStopped\":%s}\n",
    status, reason, code, sig, rss, footprint, elapsed, timeout, phase,
    stopped == 1 ? "true" : (stopped == 0 ? "false" : "null"));
  if (n <= 0 || (size_t)n >= sizeof(line)) return;
  /* A terminal decision is written immediately and may be refined by the final
     report; overwrite so the file is always one bounded record. */
  if (!ftruncate(3, 0) && lseek(3, 0, SEEK_SET) >= 0) {
    ssize_t written = 0;
    while (written < n) {
      ssize_t chunk = write(3, line + written, (size_t)(n - written));
      if (chunk <= 0) break;
      written += chunk;
    }
  }
}
int main(int argc, char **argv) {
  if (argc == 4 && !strcmp(argv[1], "--authenticate")) return authenticate(argv[2], argv[3]);
  if (argc < 11 || strcmp(argv[1], "--run")) return 125;
  const char *lock_path = argv[2], *token = argv[3];
  uint64_t memory_limit = strtoull(argv[4], NULL, 10), rss_limit = strtoull(argv[5], NULL, 10);
  int interval = atoi(argv[6]), grace = atoi(argv[7]);
  char *end;
  errno = 0;
  uint64_t timeout = strtoull(argv[8], &end, 10);
  if (argv[8][0] < '0' || argv[8][0] > '9' || *end || errno || !timeout || timeout > INT32_MAX) return 125;
  if (strcmp(argv[9], "--") || !memory_limit || !rss_limit || interval < 10 || grace < 0) return 125;
  uint64_t began = millis(), peak_rss = 0, peak_footprint = 0;
  int fd = open(lock_path, O_RDWR | O_CREAT | O_NOFOLLOW | O_CLOEXEC, 0600);
  struct stat st;
  if (fd < 0 || fstat(fd, &st) || st.st_uid != getuid() || !S_ISREG(st.st_mode) || (st.st_mode & 077)) {
    report("FAIL", "lock_error", -1, 0, 0, 0, millis() - began, timeout, "complete", -1); return 125;
  }
  if (flock(fd, LOCK_EX | LOCK_NB)) {
    int busy = errno == EWOULDBLOCK || errno == EAGAIN;
    report(busy ? "LOCK_BUSY" : "FAIL", busy ? "exclusive_lock_busy" : "lock_error", -1, 0, 0, 0, millis() - began, timeout, "complete", -1);
    close(fd); return busy ? 75 : 125;
  }
  Proc self;
  if (identity(getpid(), &self) || memory(&self)) {
    report("FAIL", "sampler_unavailable", -1, 0, 0, 0, millis() - began, timeout, "complete", -1); close(fd); return 125;
  }
#ifndef __APPLE__
  if (prctl(PR_SET_CHILD_SUBREAPER, 1)) {
    report("FAIL", "subreaper_unavailable", -1, 0, 0, 0, millis() - began, timeout, "complete", -1); close(fd); return 125;
  }
#endif
  signal(SIGTERM, on_signal); signal(SIGINT, on_signal); signal(SIGHUP, on_signal);
  signal(SIGPIPE, SIG_IGN);
  int ready[2];
  if (pipe(ready)) { report("FAIL", "launch_error", -1, 0, 0, 0, millis() - began, timeout, "complete", -1); close(fd); return 125; }
  pid_t root = fork();
  if (root == 0) {
    close(ready[1]); close(fd); close(3);
    if (setsid() < 0) _exit(125);
    char byte;
    if (read(ready[0], &byte, 1) != 1) _exit(125);
    close(ready[0]);
    /* stdin is intentionally EOF; parent stdin is the supervisor lifeline. */
    int null_fd = open("/dev/null", O_RDONLY);
    if (null_fd < 0 || dup2(null_fd, 0) < 0) _exit(125);
    if (null_fd > 2) close(null_fd);
    signal(SIGTERM, SIG_DFL); signal(SIGINT, SIG_DFL); signal(SIGHUP, SIG_DFL); signal(SIGPIPE, SIG_DFL);
    execvp(argv[10], &argv[10]);
    perror("heavy-gate exec"); _exit(127);
  }
  close(ready[0]);
  if (root < 0) { close(ready[1]); report("FAIL", "launch_error", -1, 0, 0, 0, millis() - began, timeout, "complete", -1); close(fd); return 125; }
  Proc child;
  int initialized = !identity(root, &child);
  char lease[512];
  int len = snprintf(lease, sizeof(lease), "%d %" PRIu64 " %d %s %" PRIu64 " %" PRIu64 "\n",
                     getpid(), self.start, root, token, began, timeout);
  if (!initialized || ftruncate(fd, 0) || pwrite(fd, lease, len, 0) != len) {
    close(ready[1]); kill(root, SIGKILL); waitpid(root, NULL, 0);
    report("FAIL", "lease_error", -1, 0, 0, 0, millis() - began, timeout, "complete", 1); close(fd); return 125;
  }
  if (write(ready[1], "x", 1) != 1) interrupted = SIGTERM;
  close(ready[1]);
  const char *reason = NULL;
  uint64_t stopping = 0;
  int killed = 0, exited = 0, exit_status = 0, live = 1, parent_open = 1;
  for (;;) {
    int status;
    pid_t reaped;
    while ((reaped = waitpid(-1, &status, WNOHANG)) > 0)
      if (reaped == root) { exited = 1; exit_status = status; }
    uint64_t rss, footprint, high;
    if (sample(root, child.start, &rss, &footprint, &high, &live)) {
      live = 1; /* fail closed: keep the lease until a complete sample succeeds */
      if (!reason) reason = "sampler_error";
    } else {
      if (rss > peak_rss) peak_rss = rss;
      if (footprint > peak_footprint) peak_footprint = footprint;
      if (high > peak_footprint) peak_footprint = high;
      if (!reason && peak_footprint > memory_limit) reason = "physical_footprint_limit";
      if (!reason && peak_rss > rss_limit) reason = "rss_limit";
    }
    if (!reason && interrupted) reason = "interrupted";
    if (!reason && millis() - began >= timeout) reason = "deadline_exceeded";
    /* Root exit does not release the lock while descendants remain. */
    if (!reason && exited && live) reason = "descendants_after_exit";
    if (reason && !stopping) {
      stopping = millis(); terminate_tree(root, SIGTERM);
      /* A terminal reason is recorded before destructive cleanup finishes:
         if the supervisor itself is SIGKILLed mid-cleanup, a receipt exists. */
      int limited = !strcmp(reason, "physical_footprint_limit") || !strcmp(reason, "rss_limit");
      report(limited ? "RESOURCE_LIMIT" : "FAIL", reason, -1, 0, peak_rss, peak_footprint, millis() - began, timeout, "decision", 0);
    }
    if (stopping) {
      terminate_tree(root, killed ? SIGKILL : SIGTERM);
      if (!killed && millis() - stopping >= (uint64_t)grace) { terminate_tree(root, SIGKILL); killed = 1; }
    }
    if (exited && !live) break;
    struct pollfd parent = { .fd = 0, .events = POLLIN | POLLHUP };
    uint64_t now = millis();
    int wait_ms = interval;
    if (!reason) {
      uint64_t elapsed = now - began;
      uint64_t remaining = elapsed < timeout ? timeout - elapsed : 0;
      if (remaining < (uint64_t)wait_ms) wait_ms = (int)remaining;
    } else if (!killed) {
      uint64_t elapsed = now - stopping;
      uint64_t remaining = elapsed < (uint64_t)grace ? (uint64_t)grace - elapsed : 0;
      if (remaining < (uint64_t)wait_ms) wait_ms = (int)remaining;
    }
    int n = poll(parent_open ? &parent : NULL, parent_open ? 1 : 0, wait_ms);
    if (n > 0 && parent.revents) {
      char byte;
      ssize_t bytes = read(0, &byte, 1);
      if (bytes <= 0) parent_open = 0;
      if (bytes <= 0 || byte == 's') interrupted = SIGTERM;
    } else if (n < 0 && errno != EINTR) interrupted = SIGTERM;
  }
  int code = exited && WIFEXITED(exit_status) ? WEXITSTATUS(exit_status) : -1;
  int sig = WIFSIGNALED(exit_status) ? WTERMSIG(exit_status) : 0;
  int limited = reason && (!strcmp(reason, "physical_footprint_limit") || !strcmp(reason, "rss_limit"));
  const char *result = limited ? "RESOURCE_LIMIT" : (reason || code != 0 ? "FAIL" : "PASS");
  if (!reason) reason = sig ? "command_signal" : "command_exit";
  report(result, reason, code, sig, peak_rss, peak_footprint, millis() - began, timeout, "complete", 1);
  /* Never unlink the flock inode: unlinking permits two simultaneous owners. */
  close(fd); free(rows); free(known);
  return limited ? 73 : (!strcmp(result, "PASS") ? 0 : (reason && !strcmp(reason, "interrupted") ? 130 : 1));
}
