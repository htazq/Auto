import os
import datetime
import subprocess
import json
import logging
from typing import List, Tuple

def remove_excess_backups(folder_path: str, max_backup_count: int) -> None:
    backups = [f for f in os.listdir(folder_path) if f.endswith('.tar.gz')]
    backups.sort(key=lambda f: os.path.getmtime(os.path.join(folder_path, f)), reverse=True)
    
    if len(backups) > max_backup_count:
        files_to_remove = backups[max_backup_count:]
        
        for file_to_remove in files_to_remove:
            backup_file = os.path.join(folder_path, file_to_remove)
            try:
                os.remove(backup_file)
                logging.info(f"Removed old backup: {backup_file}")
            except OSError as e:
                logging.error(f"Failed to remove old backup {backup_file}: {e}")


def backup_folder(
    folder_path: str,
    backup_target: str,
    app_token: str,
    uids: List[str],
    max_backup_count: int = 30
) -> None:
    # 设置日志输出的文件和日志等级
    logging.basicConfig(filename="/var/log/backup.log", level=logging.INFO,format="%(asctime)s %(levelname)s:%(message)s", datefmt="%Y-%m-%d %H:%M:%S")
    
    # 日志记录开始执行的时间
    logging.info("Backup script started.")

    try:
        today = datetime.datetime.now()
        backup_file = f"{os.path.basename(folder_path)}-{today.strftime('%Y-%m-%d-%H-%M-%S')}.tar.gz"
        backup_path = os.path.join(folder_path, backup_file)

        remove_excess_backups(folder_path, max_backup_count)

        subprocess.run(["tar", "-czvf", backup_path, folder_path])

        exit_code = subprocess.run(["rclone", "copy", backup_path, backup_target]).returncode

        if exit_code == 0:
            os.remove(backup_path)
        else:
            subprocess.run(["rclone", "copy", backup_path, backup_target])

            exit_code = subprocess.run(["rclone", "copy", backup_path, backup_target]).returncode
            if exit_code == 0:
                os.remove(backup_path)
            else:
                raise Exception("文件上传失败")

        files_with_sizes: List[Tuple[str, float]] = [(f, os.path.getsize(os.path.join(folder_path, f)) / (1024 * 1024)) for f in os.listdir(folder_path)]
        total_size = sum(size for _, size in files_with_sizes)

        message = f"备份已完成\n备份文件名：{backup_file}\n已备份的文件数量：{len(files_with_sizes)}\n文件大小：\n"
        for file, size in files_with_sizes:
            message += f"{file}: {size:.2f} MB\n"
        message += f"备份空间总占用：{total_size:.2f} MB"

        payload = {
            "appToken": app_token,
            "content": message,
            "summary": "备份通知",
            "contentType": 2,
            "uids": uids
        }
        subprocess.run(["curl", "-X", "POST", "https://wxpusher.zjiecode.com/api/send/message", "-H", "Content-Type:application/json", "-d", json.dumps(payload)])

        # 备份成功后的日志记录
        logging.info("Backup successful.")
    except Exception as e:
        # 异常处理和错误反馈
        error_message = f"脚本执行发生异常: {str(e)}"
        logging.error(error_message)

    # 日志记录脚本执行结束的时间
    logging.info("Backup script finished.")

# 使用示例
folder_path = "/home/website"  # 备份文件夹路径
backup_target = "rclone的盘符:对应的文件夹"  # 备份目标路径，注意是rclone的盘符路径
app_token = "xxxxx"  # 微信通知的应用程序令牌
uids = ["xxxxx"]  # 接收微信通知的用户ID

backup_folder(folder_path, backup_target, app_token, uids)
