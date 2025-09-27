# 使用官方 Jenkins LTS 基础镜像
FROM jenkins/jenkins:lts

# 切换到 root 用户以安装额外软件
USER root

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

# 拷贝自定义的 init.groovy.d 脚本（初始化配置）
COPY init.groovy.d/ /usr/share/jenkins/ref/init.groovy.d/

# 暴露 Jenkins 默认端口
EXPOSE 8081
EXPOSE 50000

# 设置 Jenkins 主目录（官方默认）
ENV JENKINS_HOME /var/jenkins_home
