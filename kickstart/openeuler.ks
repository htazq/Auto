# 使用图形安装界面
graphical

# 设置语言为英语（美国）
lang en_US.UTF-8

# 设置键盘布局为美国
keyboard us

# 设置root用户密码
rootpw password

# 配置防火墙，开启SSH服务
firewall --service=ssh

# 禁用SELinux
selinux --disable

# 设置时区为亚洲/上海
timezone Asia/Shanghai

# 接受最终用户许可协议
eula --agreed

# 禁用首次启动向导
firstboot --disable

# 设置安装源URL
url --url=http://172.18.2.14:16000/eiso/pmd5/e9e337b497600d10cd17e81e40294d07/

# 软件包配置
%packages
@core
%end

# 安装完成后重启
reboot
