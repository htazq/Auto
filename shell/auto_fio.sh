#!/bin/bash

# 全局变量和环境变量
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
SIZE="10G"
RUNTIME="300"
NUMJOBS_LIST=(1 4 8 16 32 64 128)
BS_LIST=(4k 128k)
RW_LIST=(write read randwrite randread)
IODEPTH="128"
FILENAME="/dev/sdc" # 默认测试磁盘路径

# 检查并安装 fio、libaio 和 jq 工具
check_and_install_fio_libaio_jq() {
  if ! command -v fio &> /dev/null || ! rpm -q libaio &> /dev/null || ! command -v jq &> /dev/null; then
    echo "fio、libaio 或 jq 工具未安装，开始安装..."
    yum install -y fio libaio jq libaio-devel
  else
    echo "fio、libaio 和 jq 工具已安装，继续执行后续操作。"
  fi
}

# 获取输出目录
get_output_dir() {
  local disk="$(basename -- "$1")"
  echo "${disk}_fio_results"
}

# 打印并写入 CSV 文件并显示在终端
print_and_save_results() {
  local output_dir="$1"
  local output_file="${output_dir}/results.csv"

  # 创建或清空输出 CSV 文件
  > "$output_file"

  # 打印并写入 CSV 表头
  echo "文件名,IOPS,带宽(MB/s),平均延迟(ms),最大延迟(ms)" | tee -a "$output_file"

  # 遍历 JSON 文件并提取数据
  for json_file in "$output_dir"/*.json; do
    if [ ! -f "$json_file" ]; then
      echo "JSON 文件无法读取: $json_file" | tee -a "$output_file"
      continue
    fi

    # 使用 jq 提取并打印所需数据
    jq -r '.jobs[] | 
      if .read.io_bytes > 0 then 
          [
              .jobname,
              (.read.iops | tonumber | floor),
              (.read.bw_bytes / 1024 / 1024 | tonumber),
              (.read.clat_ns.mean / 1000000 | tonumber),
              (.read.clat_ns.max / 1000000 | tonumber)
          ] 
      elif .write.io_bytes > 0 then
          [
              .jobname,
              (.write.iops | tonumber | floor),
              (.write.bw_bytes / 1024 / 1024 | tonumber),
              (.write.clat_ns.mean / 1000000 | tonumber),
              (.write.clat_ns.max / 1000000 | tonumber)
          ] 
      else 
          empty 
      end | @csv' "$json_file" | tee -a "$output_file"
  done

  echo "结果已经保存到 ${output_file}，并在终端显示。"
  echo "您可以使用以下命令进行表格化查看：column -s, -t < ${output_file} | less -#2 -N -S"
}

# 主逻辑
main() {
  check_and_install_fio_libaio_jq

  echo "1.脚本会检查并安装fio、libaio和jq工具，如果未安装，脚本会自动尝试安装它们"
  echo "2.运行脚本时，系统会提示您输入要测试的磁盘路径。默认是 /dev/sdc，如果要测试其他磁盘，请输入相应的磁盘路径"
  echo "3.系统会提示您输入存放测试结果的输出目录。如果留空，则使用默认目录（例如sdb_fio_results）。如果目录不存在，脚本会创建它。如果已存在，脚本会直接在该目录下生成或更新结果文件."
  echo "4.测试完成后，结果将被保存为CSV格式的文件，并在终端打印出来。您可以使用 column -s, -t < 文件路径 | less -#2 -N -S 命令来以表格形式查看结果。"

  read -p "请输入测试磁盘路径 [/dev/sdc]: " input
  FILENAME=${input:-$FILENAME}

  # 获取输出目录
  OUTPUT_DIR=$(get_output_dir "$FILENAME")

  # 询问用户是否要使用自定义的输出目录
  read -p "请输入自定义的输出目录（留空则使用默认目录 ${OUTPUT_DIR}）: " custom_output_dir
  if [ -n "$custom_output_dir" ]; then
    OUTPUT_DIR=$custom_output_dir
  fi

  # 如果输出目录已存在，则直接打印并写入 CSV 文件并显示
  if [ -d "$OUTPUT_DIR" ]; then
    echo "检测到输出目录 ${OUTPUT_DIR} 已存在，直接执行打印并写入 CSV 文件以及显示结果。"
    print_and_save_results "$OUTPUT_DIR"
    return
  fi

  # 创建输出目录
  mkdir -p "$OUTPUT_DIR"

  # 执行测试
  for NUMJOBS in "${NUMJOBS_LIST[@]}"; do
    for BS in "${BS_LIST[@]}"; do
      for RW in "${RW_LIST[@]}"; do
        TEST_NAME="${RW}_${BS}_numjobs${NUMJOBS}"
        OUTPUT_FILE="${OUTPUT_DIR}/${TEST_NAME}.json"

        echo "Running ${TEST_NAME}..."
        if ! fio --name="${TEST_NAME}" --filename="${FILENAME}" --size="${SIZE}" \
                --runtime="${RUNTIME}" --ioengine=libaio --rw="${RW}" --bs="${BS}" \
                --numjobs="${NUMJOBS}" --iodepth="${IODEPTH}" --group_reporting \
                --direct=1 --output-format=json --output="${OUTPUT_FILE}"; then
          echo "fio 测试失败，测试名: ${TEST_NAME}" >&2
          exit 1
        fi
      done
    done
  done

  print_and_save_results "$OUTPUT_DIR"
}

main
