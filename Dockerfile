# 使用官方 Jenkins LTS 基础镜像
FROM jenkins/jenkins:lts

# 切换到 root 用户以安装额外软件
USER root

# 创建目录并设置权限
RUN mkdir -p /var/jenkins_home && \
    chown -R jenkins:jenkins /var/jenkins_home && \
    chmod -R 755 /var/jenkins_home

# 安装必要工具（可选）
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git \
    curl \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# 切换回 Jenkins 用户
USER jenkins

# 提前安装插件（加快启动速度）
# 格式: pluginID:version，如果不写版本则安装最新
RUN jenkins-plugin-cli --plugins \
    "git:latest" \
    "docker-workflow:latest" \
    "pipeline-stage-view:latest"

# 暴露 Jenkins 默认端口
EXPOSE 8080
EXPOSE 50000

# 设置 Jenkins 主目录（官方默认）
ENV JENKINS_HOME /var/jenkins_home
