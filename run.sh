#!/bin/bash
set -eo pipefail  # Removed 'u' to allow unset variables, removed 'e' handling per function

# =============================================================================
# PERFORMANCE BENCHMARK SCRIPT
# Purpose: Compare bare-metal vs VPS with reproducible metrics
# =============================================================================

readonly SCRIPT_VERSION="1.2.0"
readonly TIMESTAMP=$(date +%Y%m%d_%H%M%S)
readonly HOSTNAME=$(hostname -s)
readonly LOG_DIR="benchmark_logs_${HOSTNAME}_${TIMESTAMP}"

# Test parameters (tune based on server specs)
readonly CPU_WORKERS=$(nproc)
readonly CPU_TEST_DURATION=600  # seconds
readonly RAM_TEST_SIZE="20G"    # adjust to ~50% of total RAM
readonly RAM_TEST_DURATION=300
readonly DISK_TEST_SIZE="20G"
readonly DISK_TEST_DURATION=300
readonly FIO_IODEPTH=32

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# Required packages
readonly REQUIRED_PKGS=(
    "stress-ng"
    "fio"
    "iperf3"
    "sysbench"
    "sysstat"
    "bc"
)

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_warn() {
"run2v.sh" 501L, 17428B                                                                 21,23         Top
#!/bin/bash
set -eo pipefail  # Removed 'u' to allow unset variables, removed 'e' handling per function

# =============================================================================
# PERFORMANCE BENCHMARK SCRIPT
# Purpose: Compare bare-metal vs VPS with reproducible metrics
# =============================================================================

readonly SCRIPT_VERSION="1.2.0"
readonly TIMESTAMP=$(date +%Y%m%d_%H%M%S)
readonly HOSTNAME=$(hostname -s)
readonly LOG_DIR="benchmark_logs_${HOSTNAME}_${TIMESTAMP}"

# Test parameters (tune based on server specs)
readonly CPU_WORKERS=$(nproc)
readonly CPU_TEST_DURATION=1800  # seconds
readonly RAM_TEST_SIZE="20G"    # adjust to ~50% of total RAM
readonly RAM_TEST_DURATION=1200
readonly DISK_TEST_SIZE="20G"
readonly DISK_TEST_DURATION=1200
readonly FIO_IODEPTH=32

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# Required packages
readonly REQUIRED_PKGS=(
    "stress-ng"
    "fio"
    "iperf3"
    "sysbench"
    "sysstat"
    "bc"
)

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_warn() {
"run2v.sh" 501L, 17431B written
root@p2v-lon-openstuck:/opt/dev-test#
root@p2v-lon-openstuck:/opt/dev-test#
root@p2v-lon-openstuck:/opt/dev-test# ./run2v.sh
[INFO] Starting benchmark suite v1.2.0
[INFO] Hostname: p2v-lon-openstuck
[INFO] Timestamp: 20251223_090905
[INFO] Checking required packages...
[WARN] Missing packages: stress-ng fio iperf3 bc
[INFO] Installing missing packages...
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
stress-ng is already the newest version (0.17.06-1build1).
fio is already the newest version (3.36-1ubuntu0.1).
iperf3 is already the newest version (3.16-1build2).
bc is already the newest version (1.07.1-3ubuntu4).
0 upgraded, 0 newly installed, 0 to remove and 0 not upgraded.
[INFO] Log directory created: benchmark_logs_p2v-lon-openstuck_20251223_090905

[INFO] === Phase 1: System Info ===
[INFO] Gathering system information...
[INFO] System info saved to benchmark_logs_p2v-lon-openstuck_20251223_090905/00_system_info.txt

[INFO] === Phase 2: CPU Tests ===
[INFO] Running CPU multi-core stress test (1800s)...
stress-ng: info:  [3006] setting to a 30 mins, 0 secs run per stressor
stress-ng: info:  [3006] dispatching hogs: 8 cpu
stress-ng: info:  [3006] note: /proc/sys/kernel/sched_autogroup_enabled is 1 and this can impact scheduling throughput for processes not attached to a tty. Setting this to 0 may improve performance metrics

stress-ng: metrc: [3006] stressor       bogo ops real time  usr time  sys time   bogo ops/s     bogo ops/s
stress-ng: metrc: [3006]                           (secs)    (secs)    (secs)   (real time) (usr+sys time)
stress-ng: metrc: [3006] cpu            21659755   1800.00  14394.34      1.32     12033.19        1504.60
stress-ng: info:  [3006] skipped: 0
stress-ng: info:  [3006] passed: 8: cpu (8)
stress-ng: info:  [3006] failed: 0
stress-ng: info:  [3006] metrics untrustworthy: 0
stress-ng: info:  [3006] successful run completed in 30 mins, 0.01 secs
[INFO] CPU multi-core test completed
[INFO] Cooldown for 15s...
[INFO] Running CPU single-core test with sysbench...

[INFO] === Phase 2: CPU Tests ===
[INFO] Running CPU multi-core stress test (1800s)...
stress-ng: info:  [3006] setting to a 30 mins, 0 secs run per stressor
stress-ng: info:  [3006] dispatching hogs: 8 cpu
stress-ng: info:  [3006] note: /proc/sys/kernel/sched_autogroup_enabled is 1 and this can impact scheduling throughput for processes not attached to a tty. Setting this to 0 may improve performance metrics

stress-ng: metrc: [3006] stressor       bogo ops real time  usr time  sys time   bogo ops/s     bogo ops/s
stress-ng: metrc: [3006]                           (secs)    (secs)    (secs)   (real time) (usr+sys time)
stress-ng: metrc: [3006] cpu            21659755   1800.00  14394.34      1.32     12033.19        1504.60
stress-ng: info:  [3006] skipped: 0
stress-ng: info:  [3006] passed: 8: cpu (8)
stress-ng: info:  [3006] failed: 0
stress-ng: info:  [3006] metrics untrustworthy: 0
stress-ng: info:  [3006] successful run completed in 30 mins, 0.01 secs
[INFO] CPU multi-core test completed
[INFO] Cooldown for 15s...
[INFO] Running CPU single-core test with sysbench...
[INFO] CPU single-core test completed
[INFO] Cooldown for 15s...

[INFO] === Phase 3: RAM Tests ===
[INFO] Running RAM stress test (1200s)...
stress-ng: info:  [3310] setting to a 20 mins, 0 secs run per stressor
stress-ng: info:  [3310] dispatching hogs: 8 vm
stress-ng: info:  [3310] note: /proc/sys/kernel/sched_autogroup_enabled is 1 and this can impact scheduling throughput for processes not attached to a tty. Setting this to 0 may improve performance metrics


stress-ng: metrc: [3310] stressor       bogo ops real time  usr time  sys time   bogo ops/s     bogo ops/s
stress-ng: metrc: [3310]                           (secs)    (secs)    (secs)   (real time) (usr+sys time)
stress-ng: metrc: [3310] vm            716831420   1201.37   5763.40   1433.06    596675.95       99608.81
stress-ng: info:  [3310] skipped: 0
stress-ng: info:  [3310] passed: 8: vm (8)
stress-ng: info:  [3310] failed: 0
stress-ng: info:  [3310] metrics untrustworthy: 0
stress-ng: info:  [3310] successful run completed in 20 mins, 5.10 secs
[INFO] Testing RAM bandwidth...
[INFO] RAM test completed
[INFO] Cooldown for 15s...

[INFO] === Phase 4: Disk I/O Tests ===
[INFO] Testing disk sequential read...
[INFO] Disk sequential read completed
[INFO] Cooldown for 10s...
[INFO] Testing disk sequential write...




[INFO] Disk sequential write completed
[INFO] Cooldown for 10s...
[INFO] Testing disk random read (IOPS focus)...

Read from remote host sshproxy.vps.net: Operation timed out
Connection to sshproxy.vps.net closed.
client_loop: send disconnect: Broken pipe
dima@Mac-C6KPXJQL9F ~ %
dima@Mac-C6KPXJQL9F ~ % go vps
Last login: Wed Dec 24 07:09:53 2025 from 37.130.227.132

	THIS IS NEW SSH-PROXY-SERVER


Enter passphrase for /home/dmitrys/.ssh/id_rsa:
Identity added: /home/dmitrys/.ssh/id_rsa (/home/dmitrys/.ssh/id_rsa)
Lifetime set to 43200 seconds
[dmitrys@ssh-proxy ~]$
[dmitrys@ssh-proxy ~]$
[dmitrys@ssh-proxy ~]$ ssh ubuntu@109.123.92.199
Welcome to Ubuntu 24.04.3 LTS (GNU/Linux 6.8.0-90-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

 System information as of Wed 24 Dec 07:39:39 UTC 2025

  System load:  0.0              Processes:             191
  Usage of /:   0.2% of 1.87TB   Users logged in:       0
  Memory usage: 0%               IPv4 address for ens3: 109.123.92.199
  Swap usage:   0%


Expanded Security Maintenance for Applications is not enabled.

0 updates can be applied immediately.

Enable ESM Apps to receive additional future security updates.
See https://ubuntu.com/esm or run: sudo pro status


Last login: Tue Dec 23 10:23:58 2025 from 83.170.66.7
ubuntu@p2v-lon-openstuck:~$ suudo su -
Command 'suudo' not found, did you mean:
  command 'sudo' from deb sudo (1.9.15p5-3ubuntu5.24.04.1)
  command 'sudo' from deb sudo-ldap (1.9.15p5-3ubuntu5.24.04.1)
Try: sudo apt install <deb name>
ubuntu@p2v-lon-openstuck:~$ sudo su -
root@p2v-lon-openstuck:~#
root@p2v-lon-openstuck:~#
root@p2v-lon-openstuck:~#
root@p2v-lon-openstuck:~#
root@p2v-lon-openstuck:~# gi
ginstall-info       gio-querymodules    git-receive-pack    git-upload-archive
gio                 git                 git-shell           git-upload-pack
root@p2v-lon-openstuck:~# gi
ginstall-info       gio-querymodules    git-receive-pack    git-upload-archive
gio                 git                 git-shell           git-upload-pack
root@p2v-lon-openstuck:~# gi
ginstall-info       gio-querymodules    git-receive-pack    git-upload-archive
gio                 git                 git-shell           git-upload-pack
root@p2v-lon-openstuck:~# git
git                 git-receive-pack    git-shell           git-upload-archive  git-upload-pack
root@p2v-lon-openstuck:~# git commit
fatal: not a git repository (or any of the parent directories): .git
root@p2v-lon-openstuck:~#
root@p2v-lon-openstuck:~#
root@p2v-lon-openstuck:~#
root@p2v-lon-openstuck:~#
root@p2v-lon-openstuck:~#
root@p2v-lon-openstuck:~#
root@p2v-lon-openstuck:~#
root@p2v-lon-openstuck:~#
root@p2v-lon-openstuck:~#
root@p2v-lon-openstuck:~#
root@p2v-lon-openstuck:~# cat /opt/dev-test/run2v.sh
#!/bin/bash
set -eo pipefail  # Removed 'u' to allow unset variables, removed 'e' handling per function

# =============================================================================
# PERFORMANCE BENCHMARK SCRIPT
# Purpose: Compare bare-metal vs VPS with reproducible metrics
# =============================================================================

readonly SCRIPT_VERSION="1.2.0"
readonly TIMESTAMP=$(date +%Y%m%d_%H%M%S)
readonly HOSTNAME=$(hostname -s)
readonly LOG_DIR="benchmark_logs_${HOSTNAME}_${TIMESTAMP}"

# Test parameters (tune based on server specs)
readonly CPU_WORKERS=$(nproc)
readonly CPU_TEST_DURATION=1800  # seconds
readonly RAM_TEST_SIZE="20G"    # adjust to ~50% of total RAM
readonly RAM_TEST_DURATION=1200
readonly DISK_TEST_SIZE="20G"
readonly DISK_TEST_DURATION=1200
readonly FIO_IODEPTH=32

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# Required packages
readonly REQUIRED_PKGS=(
    "stress-ng"
    "fio"
    "iperf3"
    "sysbench"
    "sysstat"
    "bc"
)

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

check_packages() {
    log_info "Checking required packages..."
    local missing=()

    for pkg in "${REQUIRED_PKGS[@]}"; do
        if ! dpkg -l | grep -q "^ii  $pkg "; then
            missing+=("$pkg")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_warn "Missing packages: ${missing[*]}"
        log_info "Installing missing packages..."
        apt-get update -qq
        apt-get install -y "${missing[@]}"
    else
        log_info "All required packages are installed"
    fi
}

create_log_dir() {
    mkdir -p "$LOG_DIR"
    log_info "Log directory created: $LOG_DIR"
}

cooldown() {
    local seconds=${1:-10}
    log_info "Cooldown for ${seconds}s..."
    sleep "$seconds"
}

# =============================================================================
# SYSTEM INFO
# =============================================================================

gather_system_info() {
    log_info "Gathering system information..."
    local info_file="${LOG_DIR}/00_system_info.txt"

    {
        echo "=== SYSTEM INFO ==="
        echo "Timestamp: $(date -Iseconds)"
        echo "Hostname: $HOSTNAME"
        echo "Kernel: $(uname -r)"
        echo "OS: $(lsb_release -d | cut -f2)"
        echo ""
        echo "=== CPU ==="
        lscpu | grep -E "Model name|CPU\(s\)|Thread|Core|Socket|MHz"
        echo ""
        echo "=== MEMORY ==="
        free -h
        echo ""
        echo "=== DISK ==="
        lsblk -o NAME,SIZE,TYPE,MOUNTPOINT
        df -h | grep -v tmpfs
        echo ""
        echo "=== NETWORK ==="
        ip -br addr
    } > "$info_file"

    log_info "System info saved to $info_file"
}

# =============================================================================
# CPU TESTS
# =============================================================================

test_cpu_multicore() {
    log_info "Running CPU multi-core stress test (${CPU_TEST_DURATION}s)..."
    local log_file="${LOG_DIR}/01_cpu_multicore.csv"

    # Header
    echo "metric,value,unit" > "$log_file"

    # Run stress-ng with metrics
    set +e  # Don't exit on error
    stress-ng --cpu "$CPU_WORKERS" \
              --cpu-method all \
              --metrics-brief \
              --timeout "${CPU_TEST_DURATION}s" \
              --yaml "${LOG_DIR}/01_cpu_multicore_raw.yaml" \
              2>&1 | tee "${LOG_DIR}/01_cpu_multicore_raw.log"
    set -e

    # Extract metrics - try multiple patterns
    local bogo_ops=""
    local bogo_ops_sec=""

    # Pattern 1: "cpu  N  total_ops  ops/s"
    if [[ -f "${LOG_DIR}/01_cpu_multicore_raw.log" ]]; then
        bogo_ops=$(grep "^cpu " "${LOG_DIR}/01_cpu_multicore_raw.log" | awk '{print $3}' | grep -oE '[0-9]+' | head -1 || echo "")
        bogo_ops_sec=$(grep "^cpu " "${LOG_DIR}/01_cpu_multicore_raw.log" | awk '{print $4}' | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo "")
    fi

    # Pattern 2: Fallback - look for any line with "bogo ops"
    if [[ -z "$bogo_ops_sec" ]]; then
        bogo_ops_sec=$(grep -i "bogo ops" "${LOG_DIR}/01_cpu_multicore_raw.log" | grep -oE '[0-9]+\.[0-9]+' | tail -1 || echo "0")
    fi

    echo "workers,${CPU_WORKERS},cores" >> "$log_file"
    echo "duration,${CPU_TEST_DURATION},seconds" >> "$log_file"
    echo "bogo_ops,${bogo_ops:-0},ops" >> "$log_file"
    echo "bogo_ops_per_sec,${bogo_ops_sec:-0},ops/s" >> "$log_file"

    # Get load average
    local load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',' || echo "0")
    echo "load_average_1min,${load},load" >> "$log_file"

    log_info "CPU multi-core test completed"
}

test_cpu_singlecore() {
    log_info "Running CPU single-core test with sysbench..."
    local log_file="${LOG_DIR}/02_cpu_singlecore.csv"

    echo "metric,value,unit" > "$log_file"

    # Prime numbers calculation (single-threaded)
    set +e
    sysbench cpu --cpu-max-prime=20000 --threads=1 run \
        > "${LOG_DIR}/02_cpu_singlecore_raw.log" 2>&1
    set -e

    local events=$(grep "total number of events:" "${LOG_DIR}/02_cpu_singlecore_raw.log" | awk '{print $5}' | grep -oE '[0-9]+' || echo "0")
    local time=$(grep "total time:" "${LOG_DIR}/02_cpu_singlecore_raw.log" | awk '{print $3}' | tr -d 's' | grep -oE '[0-9]+\.[0-9]+' || echo "0")
    local events_per_sec=$(grep "events per second:" "${LOG_DIR}/02_cpu_singlecore_raw.log" | awk '{print $4}' | grep -oE '[0-9]+\.[0-9]+' || echo "0")

    echo "events,${events},count" >> "$log_file"
    echo "time,${time},seconds" >> "$log_file"
    echo "events_per_sec,${events_per_sec},events/s" >> "$log_file"

    log_info "CPU single-core test completed"
}

# =============================================================================
# RAM TESTS
# =============================================================================

test_ram() {
    log_info "Running RAM stress test (${RAM_TEST_DURATION}s)..."
    local log_file="${LOG_DIR}/03_ram.csv"

    echo "metric,value,unit" > "$log_file"

    # Get baseline
    local mem_total=$(free -m | awk '/^Mem:/ {print $2}')
    local mem_avail_before=$(free -m | awk '/^Mem:/ {print $7}')

    # Run stress test with memory allocation
    set +e
    stress-ng --vm "$CPU_WORKERS" \
              --vm-bytes "$RAM_TEST_SIZE" \
              --vm-method all \
              --metrics-brief \
              --timeout "${RAM_TEST_DURATION}s" \
              2>&1 | tee "${LOG_DIR}/03_ram_raw.log"
    set -e

    # Get peak usage
    local mem_avail_after=$(free -m | awk '/^Mem:/ {print $7}')
    local swap_used=$(free -m | awk '/^Swap:/ {print $3}')

    echo "mem_total,${mem_total},MB" >> "$log_file"
    echo "mem_available_before,${mem_avail_before},MB" >> "$log_file"
    echo "mem_available_after,${mem_avail_after},MB" >> "$log_file"
    echo "swap_used,${swap_used},MB" >> "$log_file"

    # Memory bandwidth test with sysbench
    log_info "Testing RAM bandwidth..."
    set +e
    sysbench memory --memory-total-size=10G --threads="$CPU_WORKERS" run \
        > "${LOG_DIR}/03_ram_bandwidth_raw.log" 2>&1
    set -e

    local mem_speed=$(grep "MiB/sec" "${LOG_DIR}/03_ram_bandwidth_raw.log" 2>/dev/null | tail -1 | awk '{print $(NF-1)}' | grep -oE '[0-9]+\.[0-9]+' || echo "0")
    echo "memory_bandwidth,${mem_speed},MiB/sec" >> "$log_file"

    log_info "RAM test completed"
}

# =============================================================================
# DISK I/O TESTS
# =============================================================================

test_disk_seq_read() {
    log_info "Testing disk sequential read..."
    local log_file="${LOG_DIR}/04_disk_seq_read.csv"

    set +e
    fio --name=seq_read \
        --filename="${LOG_DIR}/fio_test_file" \
        --size="$DISK_TEST_SIZE" \
        --rw=read \
        --bs=1M \
        --direct=1 \
        --numjobs=1 \
        --time_based \
        --runtime="$DISK_TEST_DURATION" \
        --group_reporting \
        --output-format=json \
        --output="${LOG_DIR}/04_disk_seq_read.json" \
        > /dev/null 2>&1
    set -e

    # Parse JSON - fio structure: jobs[0].read.*
    local iops="0"
    local bw_mbps="0"
    local lat_mean="0"

    if [[ -f "${LOG_DIR}/04_disk_seq_read.json" ]]; then
        iops=$(grep -A50 '"read" :' "${LOG_DIR}/04_disk_seq_read.json" 2>/dev/null | grep '"iops" :' | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo "0")
        local bw_kbps=$(grep -A50 '"read" :' "${LOG_DIR}/04_disk_seq_read.json" 2>/dev/null | grep '"bw" :' | head -1 | grep -oE '[0-9]+' | head -1 || echo "0")
        bw_mbps=$(echo "scale=2; $bw_kbps / 1024" | bc 2>/dev/null || echo "0")
        lat_mean=$(grep -A50 '"lat_ns" :' "${LOG_DIR}/04_disk_seq_read.json" 2>/dev/null | grep '"mean" :' | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo "0")
    fi

    echo "metric,value,unit" > "$log_file"
    echo "iops,${iops},iops" >> "$log_file"
    echo "bandwidth,${bw_mbps},MB/s" >> "$log_file"
    echo "latency_mean,${lat_mean},ns" >> "$log_file"

    log_info "Disk sequential read completed"
}

test_disk_seq_write() {
    log_info "Testing disk sequential write..."
    local log_file="${LOG_DIR}/05_disk_seq_write.csv"

    set +e
    fio --name=seq_write \
        --filename="${LOG_DIR}/fio_test_file" \
        --size="$DISK_TEST_SIZE" \
        --rw=write \
        --bs=1M \
        --direct=1 \
        --numjobs=1 \
        --time_based \
        --runtime="$DISK_TEST_DURATION" \
        --group_reporting \
        --output-format=json \
        --output="${LOG_DIR}/05_disk_seq_write.json" \
        > /dev/null 2>&1
    set -e

    local iops="0"
    local bw_mbps="0"
    local lat_mean="0"

    if [[ -f "${LOG_DIR}/05_disk_seq_write.json" ]]; then
        iops=$(grep -A50 '"write" :' "${LOG_DIR}/05_disk_seq_write.json" 2>/dev/null | grep '"iops" :' | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo "0")
        local bw_kbps=$(grep -A50 '"write" :' "${LOG_DIR}/05_disk_seq_write.json" 2>/dev/null | grep '"bw" :' | head -1 | grep -oE '[0-9]+' | head -1 || echo "0")
        bw_mbps=$(echo "scale=2; $bw_kbps / 1024" | bc 2>/dev/null || echo "0")
        lat_mean=$(grep -A50 '"lat_ns" :' "${LOG_DIR}/05_disk_seq_write.json" 2>/dev/null | grep '"mean" :' | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo "0")
    fi

    echo "metric,value,unit" > "$log_file"
    echo "iops,${iops},iops" >> "$log_file"
    echo "bandwidth,${bw_mbps},MB/s" >> "$log_file"
    echo "latency_mean,${lat_mean},ns" >> "$log_file"

    log_info "Disk sequential write completed"
}

test_disk_rand_read() {
    log_info "Testing disk random read (IOPS focus)..."
    local log_file="${LOG_DIR}/06_disk_rand_read.csv"

    set +e
    fio --name=rand_read \
        --filename="${LOG_DIR}/fio_test_file" \
        --size="$DISK_TEST_SIZE" \
        --rw=randread \
        --bs=4k \
        --direct=1 \
        --numjobs=4 \
        --iodepth="$FIO_IODEPTH" \
        --time_based \
        --runtime="$DISK_TEST_DURATION" \
        --group_reporting \
        --output-format=json \
        --output="${LOG_DIR}/06_disk_rand_read.json" \
        > /dev/null 2>&1
    set -e

    local iops="0"
    local bw_mbps="0"
    local lat_mean="0"

    if [[ -f "${LOG_DIR}/06_disk_rand_read.json" ]]; then
        iops=$(grep -A50 '"read" :' "${LOG_DIR}/06_disk_rand_read.json" 2>/dev/null | grep '"iops" :' | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo "0")
        local bw_kbps=$(grep -A50 '"read" :' "${LOG_DIR}/06_disk_rand_read.json" 2>/dev/null | grep '"bw" :' | head -1 | grep -oE '[0-9]+' | head -1 || echo "0")
        bw_mbps=$(echo "scale=2; $bw_kbps / 1024" | bc 2>/dev/null || echo "0")
        lat_mean=$(grep -A50 '"lat_ns" :' "${LOG_DIR}/06_disk_rand_read.json" 2>/dev/null | grep '"mean" :' | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo "0")
    fi

    echo "metric,value,unit" > "$log_file"
    echo "iops,${iops},iops" >> "$log_file"
    echo "bandwidth,${bw_mbps},MB/s" >> "$log_file"
    echo "latency_mean,${lat_mean},ns" >> "$log_file"

    log_info "Disk random read completed"
}

test_disk_rand_write() {
    log_info "Testing disk random write (IOPS focus)..."
    local log_file="${LOG_DIR}/07_disk_rand_write.csv"

    set +e
    fio --name=rand_write \
        --filename="${LOG_DIR}/fio_test_file" \
        --size="$DISK_TEST_SIZE" \
        --rw=randwrite \
        --bs=4k \
        --direct=1 \
        --numjobs=4 \
        --iodepth="$FIO_IODEPTH" \
        --time_based \
        --runtime="$DISK_TEST_DURATION" \
        --group_reporting \
        --output-format=json \
        --output="${LOG_DIR}/07_disk_rand_write.json" \
        > /dev/null 2>&1
    set -e

    local iops="0"
    local bw_mbps="0"
    local lat_mean="0"

    if [[ -f "${LOG_DIR}/07_disk_rand_write.json" ]]; then
        iops=$(grep -A50 '"write" :' "${LOG_DIR}/07_disk_rand_write.json" 2>/dev/null | grep '"iops" :' | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo "0")
        local bw_kbps=$(grep -A50 '"write" :' "${LOG_DIR}/07_disk_rand_write.json" 2>/dev/null | grep '"bw" :' | head -1 | grep -oE '[0-9]+' | head -1 || echo "0")
        bw_mbps=$(echo "scale=2; $bw_kbps / 1024" | bc 2>/dev/null || echo "0")
        lat_mean=$(grep -A50 '"lat_ns" :' "${LOG_DIR}/07_disk_rand_write.json" 2>/dev/null | grep '"mean" :' | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo "0")
    fi

    echo "metric,value,unit" > "$log_file"
    echo "iops,${iops},iops" >> "$log_file"
    echo "bandwidth,${bw_mbps},MB/s" >> "$log_file"
    echo "latency_mean,${lat_mean},ns" >> "$log_file"

    # Cleanup test file
    rm -f "${LOG_DIR}/fio_test_file" 2>/dev/null || true

    log_info "Disk random write completed"
}

# =============================================================================
# NETWORK TEST (optional - requires external endpoint)
# =============================================================================

test_network() {
    log_info "Network test requires external iperf3 server"
    log_warn "Skipping network test (run manually with: iperf3 -c <server>)"

    local log_file="${LOG_DIR}/08_network.csv"
    echo "metric,value,unit" > "$log_file"
    echo "status,skipped,manual_test_required" >> "$log_file"

    # Instructions for manual test
    cat > "${LOG_DIR}/08_network_instructions.txt" <<EOF
NETWORK TEST INSTRUCTIONS
=========================

To test network performance, you need an iperf3 server.

1. On a remote machine with good connectivity:
   iperf3 -s

2. On this machine:
   iperf3 -c <server_ip> -t 30 -i 1 -J > network_test.json

3. Parse results:
   grep "sum_sent" network_test.json
   grep "sum_received" network_test.json

Expected metrics:
- Bandwidth (Mbps/Gbps)
- Retransmits
- Jitter (if UDP)
EOF
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    log_info "Starting benchmark suite v${SCRIPT_VERSION}"
    log_info "Hostname: $HOSTNAME"
    log_info "Timestamp: $TIMESTAMP"

    check_root
    check_packages
    create_log_dir

    echo ""
    log_info "=== Phase 1: System Info ==="
    gather_system_info || log_warn "System info collection had issues, continuing..."

    echo ""
    log_info "=== Phase 2: CPU Tests ==="
    test_cpu_multicore || log_warn "CPU multicore test had issues, continuing..."
    cooldown 15
    test_cpu_singlecore || log_warn "CPU singlecore test had issues, continuing..."
    cooldown 15

    echo ""
    log_info "=== Phase 3: RAM Tests ==="
    test_ram || log_warn "RAM test had issues, continuing..."
    cooldown 15

    echo ""
    log_info "=== Phase 4: Disk I/O Tests ==="
    test_disk_seq_read || log_warn "Disk seq read test had issues, continuing..."
    cooldown 10
    test_disk_seq_write || log_warn "Disk seq write test had issues, continuing..."
    cooldown 10
    test_disk_rand_read || log_warn "Disk rand read test had issues, continuing..."
    cooldown 10
    test_disk_rand_write || log_warn "Disk rand write test had issues, continuing..."
    cooldown 10

    echo ""
    log_info "=== Phase 5: Network Tests ==="
    test_network || log_warn "Network test had issues, continuing..."

    echo ""
    log_info "========================================"
    log_info "Benchmark completed successfully!"
    log_info "Results saved to: $LOG_DIR"
    log_info "========================================"
    log_info ""
    log_info "Next steps:"
    log_info "1. Copy logs to analysis machine"
    log_info "2. Run parser: ./parse_results.sh $LOG_DIR"
    log_info "3. Compare with other server results"
}

# Run main function
main "$@"
