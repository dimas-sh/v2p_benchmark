#!/bin/bash
set -euo pipefail

# =============================================================================
# BENCHMARK RESULTS PARSER & COMPARATOR
# Purpose: Parse CSV logs and generate human-readable comparison
# =============================================================================

readonly PARSER_VERSION="1.1.0"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'

# Output files (global scope)
REPORT_FILE=""
EXEC_SUMMARY_FILE=""

# Ensure they're exported
export REPORT_FILE
export EXEC_SUMMARY_FILE

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

usage() {
    cat <<EOF
Usage: $0 <log_dir1> [log_dir2] [log_dir3] ...

Parse benchmark results and generate comparison report.

Examples:
  $0 benchmark_logs_server1_20240101_120000
  $0 logs_baremetal logs_vps

Output:
  - Prints formatted comparison to stdout
  - Saves detailed report to benchmark_report_<timestamp>.txt
  - Saves executive summary to executive_summary_<timestamp>.txt
EOF
    exit 1
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

extract_csv_value() {
    local file="$1"
    local metric="$2"

    if [[ ! -f "$file" ]]; then
        echo "N/A"
        return
    fi

    grep "^${metric}," "$file" | cut -d',' -f2 | head -1
}

extract_hostname() {
    local log_dir="$1"
    local info_file="${log_dir}/00_system_info.txt"

    if [[ -f "$info_file" ]]; then
        grep "^Hostname:" "$info_file" | cut -d' ' -f2
    else
        basename "$log_dir" | cut -d'_' -f3
    fi
}

extract_cpu_info() {
    local log_dir="$1"
    local info_file="${log_dir}/00_system_info.txt"

    if [[ -f "$info_file" ]]; then
        grep "Model name:" "$info_file" | cut -d':' -f2- | xargs | head -c 60
    else
        echo "Unknown"
    fi
}

extract_ram_total() {
    local log_dir="$1"
    extract_csv_value "${log_dir}/03_ram.csv" "mem_total"
}

is_numeric() {
    local val="$1"
    [[ "$val" =~ ^-?[0-9]+\.?[0-9]*$ ]] && [[ "$val" != "N/A" ]]
}

safe_bc() {
    local expr="$1"
    if echo "$expr" | bc -l 2>/dev/null | grep -qE '^-?[0-9]+\.?[0-9]*$'; then
        echo "$expr" | bc -l
    else
        echo "N/A"
    fi
}

# =============================================================================
# PARSING FUNCTIONS
# =============================================================================

parse_cpu_metrics() {
    local log_dir="$1"
    local multicore_file="${log_dir}/01_cpu_multicore.csv"
    local singlecore_file="${log_dir}/02_cpu_singlecore.csv"

    local workers=$(extract_csv_value "$multicore_file" "workers")
    local bogo_ops=$(extract_csv_value "$multicore_file" "bogo_ops_per_sec")
    local load=$(extract_csv_value "$multicore_file" "load_average_1min")
    local single_events=$(extract_csv_value "$singlecore_file" "events_per_sec")

    # Clean values (remove non-numeric prefixes like "stressor")
    bogo_ops=$(echo "$bogo_ops" | grep -oE '[0-9]+\.?[0-9]*' | head -1)
    load=$(echo "$load" | grep -oE '[0-9]+\.?[0-9]*' | head -1)
    single_events=$(echo "$single_events" | grep -oE '[0-9]+\.?[0-9]*' | head -1)

    # Set defaults if empty
    bogo_ops=${bogo_ops:-N/A}
    load=${load:-N/A}
    single_events=${single_events:-N/A}

    echo "$workers|$bogo_ops|$load|$single_events"
}

parse_ram_metrics() {
    local log_dir="$1"
    local ram_file="${log_dir}/03_ram.csv"

    local total=$(extract_csv_value "$ram_file" "mem_total")
    local avail_before=$(extract_csv_value "$ram_file" "mem_available_before")
    local avail_after=$(extract_csv_value "$ram_file" "mem_available_after")
    local swap=$(extract_csv_value "$ram_file" "swap_used")
    local bandwidth=$(extract_csv_value "$ram_file" "memory_bandwidth")

    # Clean values (remove parentheses and non-numeric chars)
    total=$(echo "$total" | grep -oE '[0-9]+\.?[0-9]*' | head -1)
    avail_before=$(echo "$avail_before" | grep -oE '[0-9]+\.?[0-9]*' | head -1)
    avail_after=$(echo "$avail_after" | grep -oE '[0-9]+\.?[0-9]*' | head -1)
    swap=$(echo "$swap" | grep -oE '[0-9]+\.?[0-9]*' | head -1)
    bandwidth=$(echo "$bandwidth" | grep -oE '[0-9]+\.?[0-9]*' | head -1)

    # Calculate used memory safely
    local used="N/A"
    if is_numeric "$avail_before" && is_numeric "$avail_after"; then
        used=$(safe_bc "scale=2; $avail_before - $avail_after")
        if [[ "$used" == "N/A" ]] || (( $(echo "$used < 0" | bc -l 2>/dev/null || echo 0) )); then
            used="0"
        fi
    fi

    total=${total:-N/A}
    swap=${swap:-N/A}
    bandwidth=${bandwidth:-N/A}

    echo "$total|$used|$swap|$bandwidth"
}

parse_disk_metrics() {
    local log_dir="$1"

    # Sequential Read
    local seq_r_iops=$(extract_csv_value "${log_dir}/04_disk_seq_read.csv" "iops")
    local seq_r_bw=$(extract_csv_value "${log_dir}/04_disk_seq_read.csv" "bandwidth")
    local seq_r_lat=$(extract_csv_value "${log_dir}/04_disk_seq_read.csv" "latency_mean")

    # Sequential Write
    local seq_w_iops=$(extract_csv_value "${log_dir}/05_disk_seq_write.csv" "iops")
    local seq_w_bw=$(extract_csv_value "${log_dir}/05_disk_seq_write.csv" "bandwidth")
    local seq_w_lat=$(extract_csv_value "${log_dir}/05_disk_seq_write.csv" "latency_mean")

    # Random Read
    local rand_r_iops=$(extract_csv_value "${log_dir}/06_disk_rand_read.csv" "iops")
    local rand_r_bw=$(extract_csv_value "${log_dir}/06_disk_rand_read.csv" "bandwidth")
    local rand_r_lat=$(extract_csv_value "${log_dir}/06_disk_rand_read.csv" "latency_mean")

    # Random Write
    local rand_w_iops=$(extract_csv_value "${log_dir}/07_disk_rand_write.csv" "iops")
    local rand_w_bw=$(extract_csv_value "${log_dir}/07_disk_rand_write.csv" "bandwidth")
    local rand_w_lat=$(extract_csv_value "${log_dir}/07_disk_rand_write.csv" "latency_mean")

    # Clean all values
    seq_r_iops=$(echo "$seq_r_iops" | grep -oE '[0-9]+\.?[0-9]*' | head -1); seq_r_iops=${seq_r_iops:-N/A}
    seq_r_bw=$(echo "$seq_r_bw" | grep -oE '[0-9]+\.?[0-9]*' | head -1); seq_r_bw=${seq_r_bw:-N/A}
    seq_r_lat=$(echo "$seq_r_lat" | grep -oE '[0-9]+\.?[0-9]*' | head -1); seq_r_lat=${seq_r_lat:-N/A}

    seq_w_iops=$(echo "$seq_w_iops" | grep -oE '[0-9]+\.?[0-9]*' | head -1); seq_w_iops=${seq_w_iops:-N/A}
    seq_w_bw=$(echo "$seq_w_bw" | grep -oE '[0-9]+\.?[0-9]*' | head -1); seq_w_bw=${seq_w_bw:-N/A}
    seq_w_lat=$(echo "$seq_w_lat" | grep -oE '[0-9]+\.?[0-9]*' | head -1); seq_w_lat=${seq_w_lat:-N/A}

    rand_r_iops=$(echo "$rand_r_iops" | grep -oE '[0-9]+\.?[0-9]*' | head -1); rand_r_iops=${rand_r_iops:-N/A}
    rand_r_bw=$(echo "$rand_r_bw" | grep -oE '[0-9]+\.?[0-9]*' | head -1); rand_r_bw=${rand_r_bw:-N/A}
    rand_r_lat=$(echo "$rand_r_lat" | grep -oE '[0-9]+\.?[0-9]*' | head -1); rand_r_lat=${rand_r_lat:-N/A}

    rand_w_iops=$(echo "$rand_w_iops" | grep -oE '[0-9]+\.?[0-9]*' | head -1); rand_w_iops=${rand_w_iops:-N/A}
    rand_w_bw=$(echo "$rand_w_bw" | grep -oE '[0-9]+\.?[0-9]*' | head -1); rand_w_bw=${rand_w_bw:-N/A}
    rand_w_lat=$(echo "$rand_w_lat" | grep -oE '[0-9]+\.?[0-9]*' | head -1); rand_w_lat=${rand_w_lat:-N/A}

    echo "$seq_r_iops|$seq_r_bw|$seq_r_lat|$seq_w_iops|$seq_w_bw|$seq_w_lat|$rand_r_iops|$rand_r_bw|$rand_r_lat|$rand_w_iops|$rand_w_bw|$rand_w_lat"
}

# =============================================================================
# OUTPUT FUNCTIONS
# =============================================================================

# Dual output - both to stdout and file
print_both() {
    echo "$@" | tee -a "$REPORT_FILE"
}

print_both_e() {
    echo -e "$@" | tee -a "$REPORT_FILE"
}

# File only output (for exec summary)
print_exec() {
    if [[ -n "$EXEC_SUMMARY_FILE" ]]; then
        echo "$@" >> "$EXEC_SUMMARY_FILE"
    else
        echo "ERROR: EXEC_SUMMARY_FILE not set" >&2
    fi
}

print_exec_e() {
    if [[ -n "$EXEC_SUMMARY_FILE" ]]; then
        echo -e "$@" >> "$EXEC_SUMMARY_FILE"
    else
        echo "ERROR: EXEC_SUMMARY_FILE not set" >&2
    fi
}

strip_colors() {
    sed 's/\x1b\[[0-9;]*m//g'
}

# =============================================================================
# FORMATTING & OUTPUT
# =============================================================================

print_header() {
    local output=""
    output+="
"
    output+="═══════════════════════════════════════════════════════════════════════
"
    output+="            PERFORMANCE BENCHMARK COMPARISON REPORT
"
    output+="═══════════════════════════════════════════════════════════════════════
"
    output+="
"

    echo -e "$output" | tee -a "$REPORT_FILE"
}

print_server_info() {
    local log_dirs=("$@")

    print_both_e "${BOLD}SERVERS COMPARED:${NC}"
    print_both ""

    for log_dir in "${log_dirs[@]}"; do
        local hostname=$(extract_hostname "$log_dir")
        local cpu=$(extract_cpu_info "$log_dir")
        local ram=$(extract_ram_total "$log_dir")

        print_both_e "  ${GREEN}▪${NC} ${BOLD}$hostname${NC}"
        print_both "    CPU: $cpu"
        print_both "    RAM: ${ram} MB"
        print_both "    Logs: $log_dir"
        print_both ""
    done
}

format_number() {
    local num="$1"
    if is_numeric "$num"; then
        printf "%.2f" "$num"
    else
        echo "$num"
    fi
}

calculate_percentage() {
    local val1="$1"
    local val2="$2"

    if ! is_numeric "$val1" || ! is_numeric "$val2"; then
        echo "N/A"
        return
    fi

    if (( $(echo "$val2 == 0" | bc -l 2>/dev/null || echo 0) )); then
        echo "N/A"
        return
    fi

    local pct=$(safe_bc "scale=2; (($val1 - $val2) / $val2) * 100")

    if [[ "$pct" == "N/A" ]]; then
        echo "N/A"
        return
    fi

    if (( $(echo "$pct > 0" | bc -l) )); then
        echo -e "${GREEN}+${pct}%${NC}"
    elif (( $(echo "$pct < 0" | bc -l) )); then
        echo -e "${RED}${pct}%${NC}"
    else
        echo "0.00%"
    fi
}

print_cpu_comparison() {
    local log_dirs=("$@")

    local header="┌─ CPU PERFORMANCE ──────────────────────────────────────────────────────┐"
    print_both_e "${BOLD}${header}${NC}"

    local line=$(printf "%-20s %10s %15s %12s %15s\n" "Server" "Workers" "Bogo ops/s" "Load Avg" "Single ops/s")
    print_both "$line"
    print_both "────────────────────────────────────────────────────────────────────────────"

    declare -a bogo_vals
    declare -a single_vals

    for log_dir in "${log_dirs[@]}"; do
        local hostname=$(extract_hostname "$log_dir")
        IFS='|' read -r workers bogo load single <<< "$(parse_cpu_metrics "$log_dir")"

        bogo_vals+=("$bogo")
        single_vals+=("$single")

        local line=$(printf "%-20s %10s %15s %12s %15s\n" \
            "$hostname" \
            "$workers" \
            "$(format_number "$bogo")" \
            "$(format_number "$load")" \
            "$(format_number "$single")")
        print_both "$line"
    done

    # Show comparison if 2 servers
    if [[ ${#log_dirs[@]} -eq 2 ]]; then
        local diff_bogo=$(calculate_percentage "${bogo_vals[1]}" "${bogo_vals[0]}")
        local diff_single=$(calculate_percentage "${single_vals[1]}" "${single_vals[0]}")
        print_both "────────────────────────────────────────────────────────────────────────────"

        # For file output, strip colors
        local diff_bogo_plain=$(echo "$diff_bogo" | strip_colors)
        local diff_single_plain=$(echo "$diff_single" | strip_colors)

        # Print with colors to stdout, without to file
        echo -e "$(printf "%-20s %10s %15s %12s %15s\n" "Difference" "-" "$diff_bogo" "-" "$diff_single")"
        printf "%-20s %10s %15s %12s %15s\n" "Difference" "-" "$diff_bogo_plain" "-" "$diff_single_plain" >> "$REPORT_FILE"
    fi

    local footer="└────────────────────────────────────────────────────────────────────────┘"
    print_both_e "${BOLD}${footer}${NC}"
    print_both ""
}

print_ram_comparison() {
    local log_dirs=("$@")

    local header="┌─ RAM PERFORMANCE ──────────────────────────────────────────────────────┐"
    print_both_e "${BOLD}${header}${NC}"

    local line=$(printf "%-20s %12s %12s %12s %15s\n" "Server" "Total(MB)" "Used(MB)" "Swap(MB)" "BW(MiB/s)")
    print_both "$line"
    print_both "────────────────────────────────────────────────────────────────────────────"

    declare -a bw_vals

    for log_dir in "${log_dirs[@]}"; do
        local hostname=$(extract_hostname "$log_dir")
        IFS='|' read -r total used swap bandwidth <<< "$(parse_ram_metrics "$log_dir")"

        bw_vals+=("$bandwidth")

        local line=$(printf "%-20s %12s %12s %12s %15s\n" \
            "$hostname" \
            "$(format_number "$total")" \
            "$(format_number "$used")" \
            "$(format_number "$swap")" \
            "$(format_number "$bandwidth")")
        print_both "$line"
    done

    if [[ ${#log_dirs[@]} -eq 2 ]]; then
        local diff_bw=$(calculate_percentage "${bw_vals[1]}" "${bw_vals[0]}")
        print_both "────────────────────────────────────────────────────────────────────────────"

        local diff_bw_plain=$(echo "$diff_bw" | strip_colors)
        echo -e "$(printf "%-20s %12s %12s %12s %15s\n" "Difference" "-" "-" "-" "$diff_bw")"
        printf "%-20s %12s %12s %12s %15s\n" "Difference" "-" "-" "-" "$diff_bw_plain" >> "$REPORT_FILE"
    fi

    local footer="└────────────────────────────────────────────────────────────────────────┘"
    print_both_e "${BOLD}${footer}${NC}"
    print_both ""
}

print_disk_comparison() {
    local log_dirs=("$@")

    local header="┌─ DISK I/O PERFORMANCE ─────────────────────────────────────────────────┐"
    print_both_e "${BOLD}${header}${NC}"
    print_both ""
    print_both_e "${BOLD}Sequential Operations:${NC}"

    local line=$(printf "%-20s %15s %15s %15s\n" "Server" "Read MB/s" "Write MB/s" "R Latency(µs)")
    print_both "$line"
    print_both "────────────────────────────────────────────────────────────────────────────"

    declare -a seq_r_bw_vals
    declare -a seq_w_bw_vals

    for log_dir in "${log_dirs[@]}"; do
        local hostname=$(extract_hostname "$log_dir")
        IFS='|' read -r seq_r_iops seq_r_bw seq_r_lat seq_w_iops seq_w_bw seq_w_lat \
                       rand_r_iops rand_r_bw rand_r_lat rand_w_iops rand_w_bw rand_w_lat \
                       <<< "$(parse_disk_metrics "$log_dir")"

        seq_r_bw_vals+=("$seq_r_bw")
        seq_w_bw_vals+=("$seq_w_bw")

        # Convert ns to µs for readability
        local lat_us="N/A"
        if is_numeric "$seq_r_lat"; then
            lat_us=$(safe_bc "scale=2; $seq_r_lat / 1000")
        fi

        local line=$(printf "%-20s %15s %15s %15s\n" \
            "$hostname" \
            "$(format_number "$seq_r_bw")" \
            "$(format_number "$seq_w_bw")" \
            "$(format_number "$lat_us")")
        print_both "$line"
    done

    if [[ ${#log_dirs[@]} -eq 2 ]]; then
        local diff_r=$(calculate_percentage "${seq_r_bw_vals[1]}" "${seq_r_bw_vals[0]}")
        local diff_w=$(calculate_percentage "${seq_w_bw_vals[1]}" "${seq_w_bw_vals[0]}")
        print_both "────────────────────────────────────────────────────────────────────────────"

        local diff_r_plain=$(echo "$diff_r" | strip_colors)
        local diff_w_plain=$(echo "$diff_w" | strip_colors)
        echo -e "$(printf "%-20s %15s %15s %15s\n" "Difference" "$diff_r" "$diff_w" "-")"
        printf "%-20s %15s %15s %15s\n" "Difference" "$diff_r_plain" "$diff_w_plain" "-" >> "$REPORT_FILE"
    fi

    print_both ""
    print_both_e "${BOLD}Random Operations (4K):${NC}"

    local line=$(printf "%-20s %15s %15s %15s\n" "Server" "Read IOPS" "Write IOPS" "R Latency(µs)")
    print_both "$line"
    print_both "────────────────────────────────────────────────────────────────────────────"

    declare -a rand_r_iops_vals
    declare -a rand_w_iops_vals

    for log_dir in "${log_dirs[@]}"; do
        local hostname=$(extract_hostname "$log_dir")
        IFS='|' read -r seq_r_iops seq_r_bw seq_r_lat seq_w_iops seq_w_bw seq_w_lat \
                       rand_r_iops rand_r_bw rand_r_lat rand_w_iops rand_w_bw rand_w_lat \
                       <<< "$(parse_disk_metrics "$log_dir")"

        rand_r_iops_vals+=("$rand_r_iops")
        rand_w_iops_vals+=("$rand_w_iops")

        # Convert ns to µs
        local lat_us="N/A"
        if is_numeric "$rand_r_lat"; then
            lat_us=$(safe_bc "scale=2; $rand_r_lat / 1000")
        fi

        local line=$(printf "%-20s %15s %15s %15s\n" \
            "$hostname" \
            "$(format_number "$rand_r_iops")" \
            "$(format_number "$rand_w_iops")" \
            "$(format_number "$lat_us")")
        print_both "$line"
    done

    if [[ ${#log_dirs[@]} -eq 2 ]]; then
        local diff_r=$(calculate_percentage "${rand_r_iops_vals[1]}" "${rand_r_iops_vals[0]}")
        local diff_w=$(calculate_percentage "${rand_w_iops_vals[1]}" "${rand_w_iops_vals[0]}")
        print_both "────────────────────────────────────────────────────────────────────────────"

        local diff_r_plain=$(echo "$diff_r" | strip_colors)
        local diff_w_plain=$(echo "$diff_w" | strip_colors)
        echo -e "$(printf "%-20s %15s %15s %15s\n" "Difference" "$diff_r" "$diff_w" "-")"
        printf "%-20s %15s %15s %15s\n" "Difference" "$diff_r_plain" "$diff_w_plain" "-" >> "$REPORT_FILE"
    fi

    local footer="└────────────────────────────────────────────────────────────────────────┘"
    print_both_e "${BOLD}${footer}${NC}"
    print_both ""
}

print_summary() {
    local log_dirs=("$@")

    log_info "DEBUG: print_summary called with ${#log_dirs[@]} directories" >&2

    if [[ ${#log_dirs[@]} -ne 2 ]]; then
        log_warn "Executive summary requires exactly 2 servers for comparison, got ${#log_dirs[@]}" >&2
        print_exec "Executive Summary Generation Skipped"
        print_exec "Reason: Requires exactly 2 servers for comparison"
        print_exec "Provided: ${#log_dirs[@]} server(s)"
        return
    fi

    local server1=$(extract_hostname "${log_dirs[0]}")
    local server2=$(extract_hostname "${log_dirs[1]}")

    log_info "DEBUG: Comparing $server1 vs $server2" >&2

    print_both_e "${BOLD}┌─ MIGRATION DECISION SUMMARY ───────────────────────────────────────────┐${NC}"
    print_both ""
    print_both_e "${BOLD}Key Findings:${NC}"
    print_both ""

    # Store findings for executive summary
    local cpu_status=""
    local disk_r_status=""
    local disk_w_status=""
    local ram_status=""
    local cpu_diff=""
    local disk_r_diff=""
    local disk_w_diff=""
    local ram_diff=""

    # CPU comparison
    IFS='|' read -r w1 bogo1 l1 single1 <<< "$(parse_cpu_metrics "${log_dirs[0]}")"
    IFS='|' read -r w2 bogo2 l2 single2 <<< "$(parse_cpu_metrics "${log_dirs[1]}")"

    log_info "DEBUG: CPU single1=$single1 single2=$single2" >&2

    if is_numeric "$single1" && is_numeric "$single2"; then
        cpu_diff=$(safe_bc "scale=1; (($single2 - $single1) / $single1) * 100")

        if [[ "$cpu_diff" != "N/A" ]] && (( $(echo "$cpu_diff < -15" | bc -l 2>/dev/null || echo 0) )); then
            print_both_e "  ${RED}⚠${NC}  CPU performance degradation: ${cpu_diff}%"
            cpu_status="CRITICAL: ${cpu_diff}% degradation"
        elif [[ "$cpu_diff" != "N/A" ]] && (( $(echo "$cpu_diff < -5" | bc -l 2>/dev/null || echo 0) )); then
            print_both_e "  ${YELLOW}●${NC}  Minor CPU difference: ${cpu_diff}%"
            cpu_status="ACCEPTABLE: ${cpu_diff}% difference"
        else
            print_both_e "  ${GREEN}✓${NC}  CPU performance acceptable (${cpu_diff}%)"
            cpu_status="GOOD: ${cpu_diff}% difference"
        fi
    else
        print_both_e "  ${YELLOW}●${NC}  CPU comparison: insufficient data"
        cpu_status="INSUFFICIENT DATA"
        cpu_diff="N/A"
    fi

    # Disk random IOPS comparison
    IFS='|' read -r _ _ _ _ _ _ r1 _ _ w1 _ _ <<< "$(parse_disk_metrics "${log_dirs[0]}")"
    IFS='|' read -r _ _ _ _ _ _ r2 _ _ w2 _ _ <<< "$(parse_disk_metrics "${log_dirs[1]}")"

    log_info "DEBUG: Disk r1=$r1 r2=$r2 w1=$w1 w2=$w2" >&2

    if is_numeric "$r1" && is_numeric "$r2"; then
        disk_r_diff=$(safe_bc "scale=1; (($r2 - $r1) / $r1) * 100")

        if [[ "$disk_r_diff" != "N/A" ]] && (( $(echo "$disk_r_diff < -30" | bc -l 2>/dev/null || echo 0) )); then
            print_both_e "  ${RED}⚠${NC}  Disk read IOPS degradation: ${disk_r_diff}%"
            disk_r_status="CRITICAL: ${disk_r_diff}% degradation"
        elif [[ "$disk_r_diff" != "N/A" ]] && (( $(echo "$disk_r_diff < -10" | bc -l 2>/dev/null || echo 0) )); then
            print_both_e "  ${YELLOW}●${NC}  Moderate disk read degradation: ${disk_r_diff}%"
            disk_r_status="MODERATE: ${disk_r_diff}% degradation"
        else
            print_both_e "  ${GREEN}✓${NC}  Disk read IOPS acceptable (${disk_r_diff}%)"
            disk_r_status="GOOD: ${disk_r_diff}% difference"
        fi
    else
        print_both_e "  ${YELLOW}●${NC}  Disk read comparison: insufficient data"
        disk_r_status="INSUFFICIENT DATA"
        disk_r_diff="N/A"
    fi

    if is_numeric "$w1" && is_numeric "$w2" && [[ "$w1" != "0" ]] && [[ "$w2" != "0" ]]; then
        disk_w_diff=$(safe_bc "scale=1; (($w2 - $w1) / $w1) * 100")

        if [[ "$disk_w_diff" != "N/A" ]] && (( $(echo "$disk_w_diff < -30" | bc -l 2>/dev/null || echo 0) )); then
            print_both_e "  ${RED}⚠${NC}  Disk write IOPS degradation: ${disk_w_diff}%"
            disk_w_status="CRITICAL: ${disk_w_diff}% degradation"
        elif [[ "$disk_w_diff" != "N/A" ]] && (( $(echo "$disk_w_diff < -10" | bc -l 2>/dev/null || echo 0) )); then
            print_both_e "  ${YELLOW}●${NC}  Moderate disk write degradation: ${disk_w_diff}%"
            disk_w_status="MODERATE: ${disk_w_diff}% degradation"
        else
            print_both_e "  ${GREEN}✓${NC}  Disk write IOPS acceptable (${disk_w_diff}%)"
            disk_w_status="GOOD: ${disk_w_diff}% difference"
        fi
    else
        print_both_e "  ${YELLOW}●${NC}  Disk write comparison: no data or zero values"
        disk_w_status="NO DATA"
        disk_w_diff="N/A"
    fi

    # RAM bandwidth
    IFS='|' read -r _ _ _ bw1 <<< "$(parse_ram_metrics "${log_dirs[0]}")"
    IFS='|' read -r _ _ _ bw2 <<< "$(parse_ram_metrics "${log_dirs[1]}")"

    log_info "DEBUG: RAM bw1=$bw1 bw2=$bw2" >&2

    if is_numeric "$bw1" && is_numeric "$bw2"; then
        ram_diff=$(safe_bc "scale=1; (($bw2 - $bw1) / $bw1) * 100")

        if [[ "$ram_diff" != "N/A" ]] && (( $(echo "$ram_diff < -20" | bc -l 2>/dev/null || echo 0) )); then
            print_both_e "  ${RED}⚠${NC}  RAM bandwidth degradation: ${ram_diff}%"
            ram_status="CRITICAL: ${ram_diff}% degradation"
        elif [[ "$ram_diff" != "N/A" ]] && (( $(echo "$ram_diff < -10" | bc -l 2>/dev/null || echo 0) )); then
            print_both_e "  ${YELLOW}●${NC}  Minor RAM bandwidth difference: ${ram_diff}%"
            ram_status="ACCEPTABLE: ${ram_diff}% difference"
        else
            print_both_e "  ${GREEN}✓${NC}  RAM bandwidth acceptable (${ram_diff}%)"
            ram_status="GOOD: ${ram_diff}% difference"
        fi
    else
        print_both_e "  ${YELLOW}●${NC}  RAM bandwidth comparison: insufficient data"
        ram_status="INSUFFICIENT DATA"
        ram_diff="N/A"
    fi

    print_both ""
    print_both_e "${BOLD}Recommendation:${NC}"
    print_both "  Evaluate if the measured differences are acceptable for your workload:"
    print_both "  • CPU: single-threaded performance impact on app responsiveness"
    print_both "  • Disk: random IOPS critical for databases and VMs"
    print_both "  • RAM: bandwidth affects data-intensive operations"
    print_both ""
    print_both "  Consider cost savings vs performance trade-offs for migration decision."
    print_both ""
    print_both_e "${BOLD}└────────────────────────────────────────────────────────────────────────┘${NC}"
    print_both ""

    log_info "DEBUG: About to call generate_executive_summary" >&2
    log_info "DEBUG: cpu_status=$cpu_status" >&2
    log_info "DEBUG: disk_r_status=$disk_r_status" >&2
    log_info "DEBUG: EXEC_SUMMARY_FILE=$EXEC_SUMMARY_FILE" >&2

    # Generate Executive Summary - FIXED: ensure variables are defined
    generate_executive_summary "$server1" "$server2" \
        "${cpu_status:-N/A}" \
        "${disk_r_status:-N/A}" \
        "${disk_w_status:-N/A}" \
        "${ram_status:-N/A}" \
        "${cpu_diff:-N/A}" \
        "${disk_r_diff:-N/A}" \
        "${disk_w_diff:-N/A}" \
        "${ram_diff:-N/A}"

    log_info "DEBUG: generate_executive_summary completed" >&2
}

# =============================================================================
# EXECUTIVE SUMMARY GENERATION
# =============================================================================

generate_executive_summary() {
    local server1="$1"
    local server2="$2"
    local cpu_status="$3"
    local disk_r_status="$4"
    local disk_w_status="$5"
    local ram_status="$6"
    local cpu_diff="${7:-N/A}"
    local disk_r_diff="${8:-N/A}"
    local disk_w_diff="${9:-N/A}"
    local ram_diff="${10:-N/A}"

    log_info "DEBUG: Generating executive summary..." >&2

    # Write everything in one go to avoid scope issues
    cat >> "$EXEC_SUMMARY_FILE" <<EOF
================================================================================
                    EXECUTIVE SUMMARY
              Infrastructure Migration Assessment
================================================================================

Date: $(date '+%B %d, %Y')
Assessment Type: Performance Benchmark Comparison
Source Server: $server1 (Current Bare-Metal)
Target Server: $server2 (Proposed VPS)

================================================================================
PERFORMANCE COMPARISON SUMMARY
================================================================================

EOF

    log_info "DEBUG: Building metrics table..." >&2

    # Build recommendation
    local critical_count=0
    local moderate_count=0
    local good_count=0

    [[ "$cpu_status" =~ ^CRITICAL ]] && ((critical_count++)) || true
    [[ "$disk_r_status" =~ ^CRITICAL ]] && ((critical_count++)) || true
    [[ "$disk_w_status" =~ ^CRITICAL ]] && ((critical_count++)) || true
    [[ "$ram_status" =~ ^CRITICAL ]] && ((critical_count++)) || true

    [[ "$cpu_status" =~ ^(MODERATE|ACCEPTABLE) ]] && ((moderate_count++)) || true
    [[ "$disk_r_status" =~ ^MODERATE ]] && ((moderate_count++)) || true
    [[ "$disk_w_status" =~ ^MODERATE ]] && ((moderate_count++)) || true
    [[ "$ram_status" =~ ^ACCEPTABLE ]] && ((moderate_count++)) || true

    [[ "$cpu_status" =~ ^GOOD ]] && ((good_count++)) || true
    [[ "$disk_r_status" =~ ^GOOD ]] && ((good_count++)) || true
    [[ "$disk_w_status" =~ ^GOOD ]] && ((good_count++)) || true
    [[ "$ram_status" =~ ^GOOD ]] && ((good_count++)) || true

    cat >> "$EXEC_SUMMARY_FILE" <<EOF
┌──────────────────────────────────────────────────────────────────────────┐
│ METRIC                  │ STATUS              │ PERFORMANCE DELTA        │
├──────────────────────────────────────────────────────────────────────────┤
│ $(printf "%-23s" "CPU Performance") │ $(printf "%-19s" "$cpu_status") │ $(printf "%24s" "${cpu_diff}%") │
│ $(printf "%-23s" "Disk Read IOPS") │ $(printf "%-19s" "$disk_r_status") │ $(printf "%24s" "${disk_r_diff}%") │
│ $(printf "%-23s" "Disk Write IOPS") │ $(printf "%-19s" "$disk_w_status") │ $(printf "%24s" "${disk_w_diff}%") │
│ $(printf "%-23s" "RAM Bandwidth") │ $(printf "%-19s" "$ram_status") │ $(printf "%24s" "${ram_diff}%") │
└──────────────────────────────────────────────────────────────────────────┘

================================================================================
OVERALL ASSESSMENT
================================================================================

EOF

    log_info "DEBUG: Building overall assessment..." >&2

    # Overall assessment
    local overall_status=""
    local recommendation=""
    local risk_level=""

    if [[ $critical_count -ge 2 ]]; then
        overall_status="HIGH RISK - NOT RECOMMENDED"
        risk_level="HIGH"
        recommendation="RECOMMENDATION: Do NOT proceed with migration"

        cat >> "$EXEC_SUMMARY_FILE" <<EOF
Status: $overall_status
Risk Level: $risk_level

$recommendation

RATIONALE:
  • Multiple critical performance degradations detected ($critical_count metrics)
  • Significant impact expected on application performance
  • VPS infrastructure shows substantial limitations for current workload

SUGGESTED ACTIONS:
  1. Re-evaluate VPS provider and tier selection
  2. Consider dedicated CPU/storage VPS options
  3. Perform application-specific load testing
  4. Assess if workload can be optimized for lower IOPS requirements

EOF

    elif [[ $critical_count -eq 1 ]]; then
        overall_status="MEDIUM RISK - CONDITIONAL APPROVAL"
        risk_level="MEDIUM"
        recommendation="RECOMMENDATION: Proceed with CAUTION"

        cat >> "$EXEC_SUMMARY_FILE" <<EOF
Status: $overall_status
Risk Level: $risk_level

$recommendation

RATIONALE:
  • One critical performance metric detected
  • Migration feasible if critical metric aligns with non-critical workload
  • Cost savings may justify moderate performance trade-off

CONDITIONAL REQUIREMENTS:
  1. Validate that degraded metric does not impact core business functions
  2. Establish performance monitoring baselines post-migration
  3. Prepare rollback plan in case of user-facing performance issues
  4. Conduct limited pilot migration (10-20% of workload)

RISK MITIGATION:
  • Plan migration during low-traffic periods
  • Implement performance monitoring alerts
  • Keep bare-metal available for 30-day fallback period

EOF

    else
        overall_status="LOW RISK - APPROVED"
        risk_level="LOW"
        recommendation="RECOMMENDATION: PROCEED with migration"

        cat >> "$EXEC_SUMMARY_FILE" <<EOF
Status: $overall_status
Risk Level: $risk_level

$recommendation

RATIONALE:
  • No critical performance degradations detected
  • Performance differences within acceptable thresholds
  • VPS infrastructure suitable for current workload requirements

MIGRATION BENEFITS:
  • Cost optimization through VPS pricing model
  • Improved infrastructure flexibility and scalability
  • Reduced hardware maintenance overhead
  • Enhanced disaster recovery capabilities

POST-MIGRATION ACTIONS:
  1. Monitor application performance metrics for 30 days
  2. Validate cost savings meet projected targets
  3. Document performance baselines for future comparisons
  4. Decommission bare-metal after successful validation period

EOF
    fi

    log_info "DEBUG: Adding financial section..." >&2

    {
        echo "================================================================================"
        echo "FINANCIAL CONSIDERATIONS"
        echo "================================================================================"
        echo ""
        echo "NOTE: Complete this section with actual cost data"
        echo ""
        echo "Current Monthly Cost (Bare-Metal):"
        echo "  • Hardware lease/ownership: \$________"
        echo "  • Colocation/datacenter: \$________"
        echo "  • Maintenance & support: \$________"
        echo "  • TOTAL: \$________"
        echo ""
        echo "Projected Monthly Cost (VPS):"
        echo "  • VPS subscription: \$________"
        echo "  • Additional storage: \$________"
        echo "  • Bandwidth overage: \$________"
        echo "  • TOTAL: \$________"
        echo ""
        echo "Annual Savings: \$________ (estimated)"
        echo "Break-even Period: ________ months"
        echo ""
    } >> "$EXEC_SUMMARY_FILE"

    log_info "DEBUG: Adding Q&A section..." >&2

    cat >> "$EXEC_SUMMARY_FILE" <<EOF
================================================================================
KEY STAKEHOLDER QUESTIONS ANSWERED
================================================================================

Q: Will users experience performance degradation?
EOF

    if [[ $critical_count -ge 1 ]]; then
        echo "A: YES - Critical performance metrics show degradation. User impact likely." >> "$EXEC_SUMMARY_FILE"
    else
        echo "A: NO - Performance differences within acceptable range. Minimal user impact." >> "$EXEC_SUMMARY_FILE"
    fi

    cat >> "$EXEC_SUMMARY_FILE" <<EOF

Q: What are the technical risks?
A: Risk Level: $risk_level
   • Critical issues: $critical_count
   • Moderate concerns: $moderate_count
   • Acceptable metrics: $good_count

Q: When can we proceed?
EOF

    if [[ $critical_count -ge 2 ]]; then
        echo "A: NOT RECOMMENDED at this time. Re-assess after addressing critical issues." >> "$EXEC_SUMMARY_FILE"
    elif [[ $critical_count -eq 1 ]]; then
        echo "A: Conditional approval. Proceed after validating critical metric impact." >> "$EXEC_SUMMARY_FILE"
    else
        echo "A: APPROVED. Migration can proceed with standard change management process." >> "$EXEC_SUMMARY_FILE"
    fi

    cat >> "$EXEC_SUMMARY_FILE" <<EOF

Q: What is the rollback plan?
A: Keep current bare-metal infrastructure active for 30 days post-migration.
   Rollback can be executed within 4-8 hours if critical issues arise.

================================================================================
NEXT STEPS
================================================================================

1. Review this assessment with technical leadership
2. Complete financial cost-benefit analysis
3. Obtain stakeholder approval for migration decision
4. If approved: Develop detailed migration plan and timeline
5. Schedule follow-up meeting to discuss findings and decision

================================================================================
REPORT METADATA
================================================================================

Generated: $(date '+%Y-%m-%d %H:%M:%S %Z')
Parser Version: $PARSER_VERSION
Detailed Report: $REPORT_FILE

================================================================================
                         END OF EXECUTIVE SUMMARY
================================================================================
EOF

    log_info "DEBUG: Executive summary completed!" >&2
}

# =============================================================================
# MAIN
# =============================================================================

main() {
    if [[ $# -lt 1 ]]; then
        usage
    fi

    # Initialize output files
    local timestamp=$(date +%Y%m%d_%H%M%S)
    REPORT_FILE="benchmark_report_${timestamp}.txt"
    EXEC_SUMMARY_FILE="executive_summary_${timestamp}.txt"

    # Create empty files
    > "$REPORT_FILE"
    > "$EXEC_SUMMARY_FILE"

    log_info "Parsing benchmark results..."
    log_info "Detailed report will be saved to: $REPORT_FILE"
    log_info "Executive summary will be saved to: $EXEC_SUMMARY_FILE"

    # Validate log directories
    for log_dir in "$@"; do
        if [[ ! -d "$log_dir" ]]; then
            log_error "Directory not found: $log_dir"
            exit 1
        fi
    done

    # Check if comparing same server
    if [[ $# -eq 2 ]]; then
        local host1=$(extract_hostname "$1")
        local host2=$(extract_hostname "$2")
        if [[ "$host1" == "$host2" ]]; then
            log_warn "WARNING: Both log directories appear to be from the same server: $host1"
            log_warn "For meaningful comparison, run benchmarks on TWO DIFFERENT servers"
        fi
    fi

    print_header
    print_server_info "$@"
    print_cpu_comparison "$@"
    print_ram_comparison "$@"
    print_disk_comparison "$@"
    print_summary "$@"

    echo ""
    log_info "========================================="
    log_info "Report generation complete!"
    log_info "========================================="
    log_info "Files created:"
    log_info "  • Detailed report: $REPORT_FILE"
    log_info "  • Executive summary: $EXEC_SUMMARY_FILE"
    log_info ""
    log_info "To view reports:"
    log_info "  cat $REPORT_FILE"
    log_info "  cat $EXEC_SUMMARY_FILE"
}

main "$@"
