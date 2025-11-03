FROM jenkins/jenkins:lts-jdk17

# 切换到 root 用户安装软件
USER root

# 更新源并安装必要的工具（使用 Debian 兼容的包名）
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    gnupg \
    apt-transport-https \
    ca-certificates \
    build-essential \
    automake \
    bison \
    flex \
    libtool \
    pkg-config \
    libssl-dev \
    libboost-all-dev \
    && rm -rf /var/lib/apt/lists/*

# 安装 Docker
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian bullseye stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io

# 安装 JDK 8
RUN mkdir -p /opt/java && \
    cd /opt/java && \
    wget -q https://github.com/adoptium/temurin8-binaries/releases/download/jdk8u392-b08/OpenJDK8U-jdk_x64_linux_hotspot_8u392b08.tar.gz && \
    tar -xzf OpenJDK8U-jdk_x64_linux_hotspot_8u392b08.tar.gz && \
    mv jdk8u392-b08 jdk8 && \
    rm OpenJDK8U-jdk_x64_linux_hotspot_8u392b08.tar.gz

# 设置 JDK 17 路径
RUN ln -sf /opt/java/openjdk /opt/java/jdk17

# 安装 Maven - 使用国内镜像
RUN cd /opt && \
    wget -q https://mirrors.tuna.tsinghua.edu.cn/apache/maven/maven-3/3.9.6/binaries/apache-maven-3.9.6-bin.tar.gz && \
    tar -xzf apache-maven-3.9.6-bin.tar.gz && \
    mv apache-maven-3.9.6 maven && \
    rm apache-maven-3.9.6-bin.tar.gz

# 安装 Thrift 0.9.3 编译依赖
RUN apt-get update && apt-get install -y \
    libevent-dev \
    byacc

# 编译安装 Thrift 0.9.3（简化版本）
RUN cd /tmp && \
    wget -q http://archive.apache.org/dist/thrift/0.9.3/thrift-0.9.3.tar.gz && \
    tar -xzf thrift-0.9.3.tar.gz && \
    cd thrift-0.9.3 && \
    ./configure \
        --without-java \
        --without-python \
        --without-cpp \
        --without-c_glib \
        --without-csharp \
        --without-erlang \
        --without-haskell \
        --without-perl \
        --without-php \
        --without-php_extension \
        --without-ruby \
        --without-go \
        --without-lua && \
    make && \
    make install && \
    cd /tmp && \
    rm -rf thrift-0.9.3 thrift-0.9.3.tar.gz

# 配置环境变量
ENV JAVA_HOME_8=/opt/java/jdk8
ENV JAVA_HOME_17=/opt/java/jdk17
ENV MAVEN_HOME=/opt/maven
ENV PATH=$MAVEN_HOME/bin:$JAVA_HOME_8/bin:$JAVA_HOME_17/bin:$PATH

# 将 Jenkins 用户添加到 docker 组
RUN usermod -aG docker jenkins

# 切换回 jenkins 用户
USER jenkins
