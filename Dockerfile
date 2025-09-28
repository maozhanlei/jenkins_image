# 使用官方 Jenkins LTS 基础镜像
FROM jenkins/jenkins:lts

# 切换到 root 用户以安装额外软件
USER root

# 1. 安装系统依赖
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git \
    curl \
    unzip \
    ca-certificates \
    gnupg \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

# 2. 安装 Docker 客户端（兼容宿主机 Docker）
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y docker-ce-cli && \
    rm -rf /var/lib/apt/lists/*

# 3. 安装 JDK 1.8 和 JDK 17（通过 Adoptium Temurin）
# JDK 8
RUN curl -sSL https://github.com/adoptium/temurin8-binaries/releases/download/jdk8u402-b06/OpenJDK8U-jdk_x64_linux_hotspot_8u402b06.tar.gz | tar -xz -C /opt && \
    ln -s /opt/jdk8u402-b06 /opt/jdk-8

# JDK 17
RUN curl -sSL https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.10%2B7/OpenJDK17U-jdk_x64_linux_hotspot_17.0.10_7.tar.gz | tar -xz -C /opt && \
    ln -s /opt/jdk-17.0.10+7 /opt/jdk-17

# 4. 安装 Maven 3.9.10
ARG MAVEN_VERSION=3.9.10
RUN curl -sSL https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz | tar -xz -C /opt && \
    ln -s /opt/apache-maven-${MAVEN_VERSION} /opt/maven && \
    chown -R jenkins:jenkins /opt/apache-maven-*

# 5. 配置环境变量
ENV JAVA_HOME_8 /opt/jdk-8
ENV JAVA_HOME_17 /opt/jdk-17
ENV MAVEN_HOME /opt/maven
ENV PATH $MAVEN_HOME/bin:$JAVA_HOME_17/bin:$PATH

# 6. 将 Jenkins 用户添加到 docker 组（需与宿主机 docker 组 GID 匹配）
ARG DOCKER_GID=999
RUN groupmod -g ${DOCKER_GID} docker && \
    usermod -aG docker jenkins

# 7. 创建目录并设置权限
RUN mkdir -p /var/jenkins_home && \
    chown -R jenkins:jenkins /var/jenkins_home && \
    chmod -R 755 /var/jenkins_home

# 8. 切换回 Jenkins 用户
USER jenkins

# 9. 预装 Jenkins 插件
RUN jenkins-plugin-cli --plugins \
    git \
    docker-workflow \
    pipeline-stage-view \
    maven-plugin \
    jdk-tool

# 10. 暴露端口
EXPOSE 8080
EXPOSE 50000

# 11. 设置 Jenkins 主目录
ENV JENKINS_HOME /var/jenkins_home
