import json
import glob
import os
import subprocess
import argparse
import time
from datetime import datetime

# 定义测试参数
SIZE = "10G"
RUNTIME = "300"
NUMJOBS_LIST = [1, 4, 8, 16, 32, 64, 128]
BS_LIST = ["4k", "128k"]
RW_LIST = ["write", "read", "randwrite", "randread"]
IODEPTH = "128"
OUTPUT_DIR = "./fio_results"
ERROR_LOG = "fio_error.log"

# 解析命令行参数
parser = argparse.ArgumentParser(description="FIO 测试和结果可视化脚本。")
parser.add_argument("--visualize-only", action="store_true", help="仅进行数据可视化，不执行 FIO 测试。")
parser.add_argument("--disk-path", default="/dev/sdc", help="测试磁盘的路径，默认为 /dev/sdc。")
args = parser.parse_args()

# 记录错误日志
def log_error(message):
    with open(ERROR_LOG, "a") as log_file:
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        log_file.write(f"[{timestamp}] {message}\n")

# 执行 FIO 测试并输出结果
def run_fio_tests(filename: str):
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    for numjobs in NUMJOBS_LIST:
        for bs in BS_LIST:
            for rw in RW_LIST:
                test_name = f"{rw}_{bs}_numjobs{numjobs}"
                output_file = os.path.join(OUTPUT_DIR, f"{test_name}.json")
                print(f"正在执行测试: {test_name}...")

                fio_cmd = [
                    "fio",
                    "--name", test_name,
                    "--filename", filename,
                    "--size", SIZE,
                    "--runtime", RUNTIME,
                    "--ioengine", "libaio",
                    "--rw", rw,
                    "--bs", bs,
                    "--numjobs", str(numjobs),
                    "--iodepth", IODEPTH,
                    "--group_reporting",
                    "--direct", "1",
                    "--output-format", "json",
                    "--output", output_file
                ]
                
                try:
                    subprocess.run(fio_cmd, check=True)
                    time.sleep(5)
                except subprocess.CalledProcessError as e:
                    log_error(f"FIO 测试失败: {e}")
                    continue  # 跳过当前测试，继续下一个

# 提取 JSON 文件数据并打印表格
def extract_and_print_data(json_files):
    print(f"{'文件名':<40}{'IOPS':>10}{'带宽(MB/s)':>20}{'平均延迟(ms)':>20}{'最大延迟(ms)':>20}")
    
    for json_file in json_files:
        try:
            with open(json_file, 'r') as f:
                data = json.load(f)
        except (json.decoder.JSONDecodeError, IOError) as e:
            log_error(f"JSON 文件无法读取: {json_file}，错误: {e}")
            continue
        
        jobs = data.get('jobs', [])
        for job in jobs:
            for op_type in ["read", "write"]:
                op_data = job.get(op_type, {})
                if op_data.get('io_bytes', 0) > 0:
                    iops = op_data.get('iops', 0)
                    bandwidth = op_data.get('bw', 0) / 1024  # 转换为MB/s
                    avg_latency = op_data.get('clat_ns', {}).get('mean', 0) / 1000000  # 转换为毫秒
                    max_latency = op_data.get('clat_ns', {}).get('max', 0) / 1000000  # 转换为毫秒
                    basename = os.path.basename(json_file)
                    op_label, concurrency = basename.replace('.json', '').rsplit('_', 1)
                    print(f"{op_label+'_'+concurrency:<40}{iops:>10.2f}{bandwidth:>20.2f}{avg_latency:>20.2f}{max_latency:>20.2f}")

# 主程序
if __name__ == "__main__":
    if not args.visualize_only:
        run_fio_tests(args.disk_path)
    
    json_files = glob.glob(os.path.join(OUTPUT_DIR, '*.json'))
    extract_and_print_data(json_files)
