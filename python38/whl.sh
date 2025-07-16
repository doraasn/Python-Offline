# 安装以下库：
# concurrent-log-handler matplotlib pandas flask kneed PyYAML requests

# 联网环境下下载
/usr/local/python3.8/bin/pip3.8 download \
  concurrent-log-handler==0.9.28 \
  matplotlib==3.7.5 \
  pandas==2.0.3 \
  flask==3.0.3 \
  kneed==0.8.5 \
  PyYAML==6.0.2 \
  requests==2.32.4 \
  urllib3==1.26.20 \
  -d offline_pkgs
# 离线安装
cd offline_pkgs
/usr/local/python3.8/bin/pip3.8 install --no-index --find-links=. concurrent-log-handler matplotlib pandas flask kneed PyYAML requests
# 验证
python -c "import concurrent_log_handler, matplotlib, pandas, flask, kneed, yaml, requests; print('all ok')"