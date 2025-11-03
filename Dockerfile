# 使用阿里云镜像源
FROM registry.cn-hangzhou.aliyuncs.com/jenkins/jenkins:lts-jdk17

USER root

# 配置阿里云软件源
RUN sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list && \
    sed -i 's/security.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list

# 安装基础工具
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    gnupg \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 配置 Docker 阿里云镜像加速
RUN mkdir -p /etc/docker && \
    echo '{"registry-mirrors": ["https://registry.cn-hangzhou.aliyuncs.com"]}' > /etc/docker/daemon.json

# 安装 Docker (使用阿里云镜像)
RUN curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://mirrors.aliyun.com/docker-ce/linux/debian bullseye stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io

# 安装 JDK 8 (使用国内镜像)
RUN mkdir -p /opt/java && \
    cd /opt/java && \
    wget https://mirrors.tuna.tsinghua.edu.cn/Adoptium/8/jdk/x64/linux/OpenJDK8U-jdk_x64_linux_hotspot_8u362b09.tar.gz && \
    tar -xzf OpenJDK8U-jdk_x64_linux_hotspot_8u362b09.tar.gz && \
    mv jdk8u362-b09 jdk8 && \
    rm OpenJDK8U-jdk_x64_linux_hotspot_8u362b09.tar.gz

# 安装 JDK 17
RUN ln -sf /opt/java/openjdk /opt/java/jdk17

# 安装 Maven (使用国内镜像)
RUN cd /opt && \
    wget https://mirrors.bfsu.edu.cn/apache/maven/maven-3/3.9.5/binaries/apache-maven-3.9.5-bin.tar.gz && \
    tar -xzf apache-maven-3.9.5-bin.tar.gz && \
    mv apache-maven-3.9.5 maven && \
    rm apache-maven-3.9.5-bin.tar.gz

# 安装 Thrift 0.9.3 (使用国内镜像)
RUN cd /tmp && \
    wget https://archive.apache.org/dist/thrift/0.9.3/thrift-0.9.3.tar.gz && \
    tar -xzf thrift-0.9.3.tar.gz && \
    cd thrift-0.9.3 && \
    # 安装编译依赖
    apt-get update && apt-get install -y \
        build-essential \
        automake \
        libtool \
        pkg-config \
        libboost-dev \
        libevent-dev \
        && ./configure --disable-libs --disable-tests --disable-tutorial && \
    make -C compiler/cpp && \
    cp compiler/cpp/thrift /usr/local/bin/ && \
    cd /tmp && \
    rm -rf thrift-0.9.3 thrift-0.9.3.tar.gz && \
    apt-get clean

# 配置环境变量
ENV JAVA_HOME_8=/opt/java/jdk8
ENV JAVA_HOME_17=/opt/java/jdk17
ENV MAVEN_HOME=/opt/maven
ENV PATH=$MAVEN_HOME/bin:$JAVA_HOME_8/bin:$JAVA_HOME_17/bin:$PATH

# 将 Jenkins 用户添加到 docker 组
RUN usermod -aG docker jenkins

USER jenkins
