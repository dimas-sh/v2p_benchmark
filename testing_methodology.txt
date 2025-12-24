# Performance Testing Methodology

## Executive Overview

This document explains the performance testing methodology used to compare bare-metal and VPS infrastructure, including test parameters, rationale, and interpretation of results.

---

## Testing Framework

### Tools Used

| Tool | Purpose | Industry Status |
|------|---------|-----------------|
| **stress-ng** | CPU & RAM stress testing | Industry standard for Linux performance testing |
| **sysbench** | Single-threaded CPU benchmark | De facto standard for database server testing |
| **fio** (Flexible I/O Tester) | Disk I/O benchmarking | Gold standard for storage performance testing |
| **iperf3** | Network bandwidth testing | Standard network performance tool |

---

## Test Categories & Methodology

### 1. CPU Performance Testing

#### **Multi-Core Test (stress-ng)**
- **Duration**: 60 seconds
- **Method**: All CPU cores simultaneously stressed
- **Workers**: Equal to number of CPU cores (8 in your case)
- **Algorithm**: All available CPU stress methods (integer math, floating point, bitwise operations)

**Why these parameters?**
- 60 seconds provides stable, averaged results while avoiding thermal throttling
- All-core testing simulates real production workloads (web servers, databases, applications)
- Multiple stress methods ensure comprehensive CPU evaluation, not just one operation type

**Metric measured**: Bogo operations per second (computational throughput)

#### **Single-Core Test (sysbench)**
- **Duration**: Variable (depends on completion)
- **Method**: Prime number calculation up to 20,000
- **Threads**: 1 (single-threaded)

**Why this test?**
- Many applications are single-threaded or have single-threaded bottlenecks
- Measures CPU frequency and single-core performance (critical for latency-sensitive applications)
- Real-world relevance: PHP scripts, single-threaded Python/Node.js applications, database query execution

**Your Results Analysis:**
- **Bare-metal (dc5-0402)**: 517.20 events/sec
- **VPS (p2v-lon-test)**: 1034.84 events/sec
- **Verdict**: VPS shows **+100% improvement** (2x faster single-core)

**Why VPS is faster?**
- Bare-metal CPU: Intel Xeon E3-1230 v6 @ 3.50GHz (2017, Kaby Lake architecture)
- VPS CPU: Intel Xeon Icelake @ 2.0GHz base (2021, newer architecture)
- Despite lower base frequency, Icelake has:
  - 18% IPC (Instructions Per Cycle) improvement over Kaby Lake
  - Better branch prediction
  - Larger L2/L3 cache
  - Potential turbo boost to 3.7GHz on single core

---

### 2. Memory (RAM) Performance Testing

#### **Memory Stress Test (stress-ng)**
- **Duration**: 30 seconds
- **Method**: Continuous memory allocation, deallocation, and access pattern testing
- **Size**: 4GB (configurable, typically 50% of total RAM)
- **Workers**: Equal to CPU cores (8)

**Why these parameters?**
- 4GB allocation simulates realistic application memory usage
- Multiple workers test memory controller parallelism
- 30 seconds sufficient for memory subsystem stabilization

#### **Memory Bandwidth Test (sysbench)**
- **Total size**: 10GB transferred
- **Threads**: Equal to CPU cores (8)
- **Operation**: Sequential read/write operations

**Why this test?**
- Measures memory bus speed (critical for data-intensive applications)
- Simulates applications like:
  - In-memory databases (Redis, Memcached)
  - Video encoding/processing
  - Scientific computing
  - Large dataset processing

**Your Results Analysis:**
- **Bare-metal**: 16,469.52 MiB/sec
- **VPS**: 4,598.19 MiB/sec
- **Degradation**: **-72% (severe)**

---

### 3. RAM Degradation Analysis - Why Such Poor Performance?

#### Root Causes:

**1. CPU-to-Memory Topology**
```
Bare-Metal:
CPU ←→ Memory Controller ←→ Physical RAM (DDR4)
     [Direct connection, ~20ns latency]

VPS:
vCPU ←→ Hypervisor ←→ Host Memory Controller ←→ Physical RAM
      [Virtualization overhead, NUMA effects, ~50-80ns latency]
```

**2. Memory Overcommitment**
- VPS providers often overcommit RAM (e.g., 128GB physical RAM serving 200GB+ allocated)
- Memory ballooning: Host reclaims "unused" memory from VMs
- Swapping at hypervisor level (invisible to guest)

**3. NUMA (Non-Uniform Memory Access) Issues**
- Bare-metal: CPU and RAM typically in same NUMA node
- VPS: vCPUs may be scheduled across different physical NUMA nodes
- Cross-NUMA memory access penalty: **2-3x slower**

**4. Hypervisor Memory Management**
- Memory deduplication (KSM - Kernel Samepage Merging): Multiple VMs sharing identical pages
- Copy-on-Write overhead
- TLB (Translation Lookaside Buffer) misses due to nested page tables

**5. Shared Memory Bus Contention**
- On bare-metal: You own the memory bus
- On VPS: 10-50 VMs competing for same physical memory bus
- Memory bandwidth is **NOT** virtualization-friendly (unlike CPU, which time-slices well)

#### Technical Deep Dive:

**Why Memory Bandwidth Suffers Most in Virtualization:**

```
Bare-Metal Memory Access:
1. CPU requests data → L1 cache miss
2. Check L2 cache → miss
3. Check L3 cache → miss
4. Direct memory controller access → 50-70ns
5. Data returned

VPS Memory Access:
1. vCPU requests data → L1 cache miss
2. Check L2 cache → miss
3. Check L3 cache → miss (host CPU cache)
4. Guest page table lookup → 10-20ns
5. Hypervisor nested page table translation → 20-30ns
6. NUMA node check → potential remote access +40ns
7. Memory controller contention resolution → 10-50ns
8. Physical memory access → 50-70ns
9. Reverse translation → 10ns
10. Data returned → Total: 150-250ns (3-5x slower)
```

**Bandwidth Calculation:**
```
Bandwidth = (Data Size) / (Latency × Number of Operations)

Bare-metal: 10GB / (70ns × efficient pipelining) = ~16,000 MiB/s
VPS:        10GB / (200ns × contention delays) = ~4,500 MiB/s
```

#### Is This Normal?

**Yes.** Memory bandwidth degradation of 50-75% is **typical** for VPS environments:

| VPS Provider Type | Expected RAM Bandwidth Loss |
|-------------------|----------------------------|
| Budget VPS (DigitalOcean, Linode) | 60-80% loss |
| Premium VPS (AWS c6i, GCP c2) | 30-50% loss |
| Dedicated vCPU VPS | 20-40% loss |
| Bare-metal | 0% (baseline) |

#### Real-World Impact:

**Applications Severely Affected:**
- ❌ In-memory databases (Redis, Memcached): **30-50% throughput loss**
- ❌ Video encoding/transcoding: **2-3x slower**
- ❌ Machine learning training: **Significant slowdown**
- ❌ Big data processing (Spark, Hadoop): **Poor performance**

**Applications Minimally Affected:**
- ✅ Web servers (Apache, Nginx): **< 5% impact** (data in CPU cache)
- ✅ Application servers (PHP-FPM, Node.js): **< 10% impact**
- ✅ Databases with small working sets: **10-20% impact**

---

### 4. Disk I/O Performance Testing

#### **Sequential Read/Write Tests**
- **Block size**: 1MB (large blocks)
- **I/O depth**: 1 (single outstanding I/O)
- **Direct I/O**: Yes (bypass filesystem cache)
- **Duration**: 60 seconds

**Why these parameters?**
- 1MB blocks simulate: log writing, backup operations, large file transfers
- Direct I/O ensures we test actual disk, not RAM cache
- 60 seconds averages out disk cache effects

**Real-world scenarios:**
- Database backups
- Log file writes
- Media file streaming
- VM disk image operations

**Your Results:**
- Sequential Read: VPS **+178%** faster (429.76 vs 154.33 MB/s)
- Sequential Write: VPS **+107%** faster (319.45 vs 154.17 MB/s)

**Why VPS is faster?**
- Bare-metal: Likely spinning HDD or older SSD
- VPS: NVMe SSD backend (common in modern datacenter VPS)

#### **Random Read/Write Tests (4K blocks)**
- **Block size**: 4KB (database page size)
- **I/O depth**: 32 (32 simultaneous operations)
- **Jobs**: 4 (4 parallel workers)
- **Direct I/O**: Yes

**Why these parameters?**
- 4KB = standard database page size (MySQL, PostgreSQL)
- High I/O depth simulates concurrent user requests
- Multiple jobs test parallelism (critical for multi-user databases)

**Real-world scenarios:**
- Database transactions (90% of queries are random reads)
- Web application file access
- Virtual machine disk I/O
- Container storage

**Your Results:**
- Random Read IOPS: VPS **+418%** faster (1024 vs 198 IOPS)
- Random Write IOPS: VPS **+137%** faster (1039 vs 438 IOPS)

**Why such massive improvement?**
```
Bare-metal HDD:
- Random Read: ~100-200 IOPS (mechanical seek time: 5-10ms)
- Random Write: ~100-200 IOPS

VPS NVMe SSD:
- Random Read: ~500K-1M IOPS capable
- Random Write: ~300K-500K IOPS capable
- But limited by virtualization overhead to ~1000-2000 IOPS in this test
```

---

### 5. Network Performance Testing

#### **Why Manual Testing?**
Network testing requires:
1. External endpoint (another server)
2. Known baseline network capacity
3. Controlled network environment

**Recommended methodology:**
```bash
# On remote server
iperf3 -s

# On test server
iperf3 -c <remote_ip> -t 30 -i 1 -P 4
```

**Parameters:**
- `-t 30`: 30-second test
- `-i 1`: Report every 1 second
- `-P 4`: 4 parallel streams (tests bandwidth saturation)

**Key metrics:**
- Throughput (Gbps)
- Jitter (network stability)
- Packet loss (quality)
- Retransmits (TCP congestion)

---

## Test Configuration Philosophy

### Why 60-Second Duration?

```
< 30 seconds:  Too short, results unstable (thermal effects, cache warming)
30-60 seconds: Optimal (stable results, minimal thermal throttling)
> 120 seconds: Diminishing returns, thermal throttling begins
```

### Why Direct I/O?

```
Without Direct I/O:
Test → Linux Page Cache (RAM) → "Amazing" fake results

With Direct I/O:
Test → Actual Disk Hardware → Real performance
```

### Why Multiple Workers/Jobs?

Modern applications are concurrent:
- Web server: 100-1000 simultaneous connections
- Database: 50-500 concurrent queries
- Application: Multiple threads/processes

Single-threaded tests don't reflect production reality.

---

## Interpreting Your Specific Results

### Summary Table:

| Metric | Bare-Metal | VPS | Change | Impact |
|--------|------------|-----|--------|--------|
| CPU Single-Core | 517 ops/s | 1035 ops/s | **+100%** ✅ | Better app responsiveness |
| RAM Bandwidth | 16,470 MiB/s | 4,598 MiB/s | **-72%** ⚠️ | Severe for memory-intensive apps |
| Disk Seq Read | 154 MB/s | 430 MB/s | **+178%** ✅ | Much faster backups/transfers |
| Disk Random Read | 198 IOPS | 1,024 IOPS | **+418%** ✅ | Dramatically better database performance |
| Disk Random Write | 438 IOPS | 1,039 IOPS | **+137%** ✅ | Better write-heavy workloads |

### Migration Decision Matrix:

**Proceed if your workload is:**
- ✅ Web applications (mostly CPU + disk)
- ✅ API servers (mostly CPU)
- ✅ Databases with good caching (disk > memory)
- ✅ File servers (disk-bound)

**Reconsider if your workload is:**
- ⚠️ In-memory caching (Redis, Memcached)
- ⚠️ Data analytics (Spark, Pandas)
- ⚠️ Video processing (ffmpeg)
- ⚠️ Scientific computing (NumPy, MATLAB)

### The 72% RAM Bandwidth Loss - Should You Worry?

**Most applications: NO**

Why? **Working Set Size** matters more than bandwidth:

```
Typical Web Application Memory Usage:
- PHP-FPM workers: 50-100MB each
- Application data: 100-500MB
- Total: < 2GB

This fits in CPU L3 cache (8-16MB) + frequent access patterns
→ RAM bandwidth rarely saturated
→ Actual impact: < 5%
```

**When to worry:**
```
Memory-Intensive Application:
- Processing 1GB+ datasets in memory
- Scanning through TBs of data
- ML model training (large matrix operations)
→ Constantly saturating memory bus
→ Actual impact: 30-70% slower
```

---

## Conclusion

Your VPS shows:
- **Superior CPU & Disk performance** (ideal for most applications)
- **Inferior RAM bandwidth** (acceptable unless memory-bound)

**Recommendation**: ✅ **PROCEED** with migration for typical web/database workloads.

**Monitor post-migration**: Application response times, cache hit rates, and memory utilization.

If memory bandwidth becomes an issue → consider dedicated vCPU or bare-metal instances.
