#!/bin/bash

# 获取当前月日
DATE=$(date +%m%d)

# 1. 检查 application-xingye.yml 是否存在
if [ -f application-xingye.yml ]; then
  # 如果 application.yml 存在，先备份
  if [ -f application.yml ]; then
    BK_FILE="application.ymlbk${DATE}"
    IDX=1
    # 如果同名备份已存在，递增后缀
    while [ -f "${BK_FILE}" ]; do
      BK_FILE="application.ymlbk${DATE}-${IDX}"
      IDX=$((IDX+1))
    done
    mv application.yml "${BK_FILE}"
  fi
  # 替换 application-xingye.yml 为 application.yml
  mv application-xingye.yml application.yml
fi

# 2. 检查 iet-iom-service-0.0.1-SNAPSHOT-new.jar 是否存在
if [ -f iet-iom-service-0.0.1-SNAPSHOT-new.jar ]; then
  # 如果原 jar 存在，先备份
  if [ -f iet-iom-service-0.0.1-SNAPSHOT.jar ]; then
    BK_JAR="iet-iom-service-0.0.1-SNAPSHOT.jarbk${DATE}"
    IDX=1
    # 如果同名备份已存在，递增后缀
    while [ -f "${BK_JAR}" ]; do
      BK_JAR="iet-iom-service-0.0.1-SNAPSHOT.jarbk${DATE}-${IDX}"
      IDX=$((IDX+1))
    done
    mv iet-iom-service-0.0.1-SNAPSHOT.jar "${BK_JAR}"
  fi
  # 替换新 jar 为正式 jar
  mv iet-iom-service-0.0.1-SNAPSHOT-new.jar iet-iom-service-0.0.1-SNAPSHOT.jar
fi

# 3. 杀掉 wslconnect 相关进程
ps -ef | grep wslconnect | grep 127.0.0.1:22007 | grep -v grep | awk '{print $2}' | xargs -r kill -9