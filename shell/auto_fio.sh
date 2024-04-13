#!/bin/bash

# 检查fio压测条件函数
check_and_install_fio_libaio_jq() {
  if ! command -v fio &> /dev/null || ! rpm -q libaio &> /dev/null || ! command -v jq &> /dev/null; then
    echo "fio、libaio 或 jq 工具未安装，开始安装..."
    yum install -y fio libaio jq libaio-devel
  else
    echo "fio、libaio 和 jq 工具已安装，继续执行后续操作。"
  fi
}

# 调用fio压测条件函数
check_and_install_fio_libaio_jq

# 默认参数
SIZE="10G"
RUNTIME="300"
NUMJOBS_LIST=(1 4 8 16 32 64 128)
BS_LIST=(4k 128k)
RW_LIST=(write read randwrite randread)
IODEPTH="128"
OUTPUT_DIR="./fio_results"

# 询问用户磁盘路径
read -p "请输入测试磁盘路径 [/dev/sdc]: " FILENAME
FILENAME=${FILENAME:-/dev/sdc}

mkdir -p "${OUTPUT_DIR}"

# 执行测试
for NUMJOBS in "${NUMJOBS_LIST[@]}"; do
  for BS in "${BS_LIST[@]}"; do
    for RW in "${RW_LIST[@]}"; do
      # 构建测试名
      TEST_NAME="${RW}_${BS}_numjobs${NUMJOBS}"
      # 输出文件路径
      OUTPUT_FILE="${OUTPUT_DIR}/${TEST_NAME}.json"

      echo "Running ${TEST_NAME}..."
      fio --name="${TEST_NAME}" \
          --filename="${FILENAME}" \
          --size="${SIZE}" \
          --runtime="${RUNTIME}" \
          --ioengine=libaio \
          --rw="${RW}" \
          --bs="${BS}" \
          --numjobs="${NUMJOBS}" \
          --iodepth="${IODEPTH}" \
          --group_reporting \
          --direct=1 \
          --output-format=json \
          --output="${OUTPUT_FILE}"
      # 提取和打印关键指标
      echo "Results for ${TEST_NAME}:"
      echo "IOPS, Bandwidth (MB/s), Avg Latency (ms), Max Latency (ms)"
      cat "${OUTPUT_FILE}" | jq -r '.jobs[] | [
        "IOPS: " + (.read.iops | tostring),
        "Bandwidth (MB/s): " + ((.read.bw_bytes / 1024 / 1024) | tostring),
        "Avg Latency (ms): " + ((.read.clat_ns.mean / 1000000) | tostring),
        "Max Latency (ms): " + ((.read.clat_ns.max / 1000000) | tostring)
      ] | .[]'
      sleep 5
    done
  done
done

echo "FIO tests completed."
echo "FIO 压测完成."
1