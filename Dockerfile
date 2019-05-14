FROM centos:7

MAINTAINER Smart Ideas, llc. <roland.adams@smartideasllc.net>

RUN yum -y update

RUN yum -y install make unzip wget gcc gcc-c++ install java-1.8.0-openjdk-devel && yum -y clean all

ENV NODEJS_VERSION=v6.17.1
ENV PATH=/apps/node/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/bin

RUN mkdir -p /apps
RUN cd /apps && \
	curl -s -L -O https://nodejs.org/dist/${NODEJS_VERSION}/node-${NODEJS_VERSION}-linux-x64.tar.xz && tar xf node-${NODEJS_VERSION}-linux-x64.tar.xz
RUN cd /apps && \
	mv node-${NODEJS_VERSION}-linux-x64 node

RUN npm install -g ionic cordova

RUN yum install -y git

# Setup andriod studio
RUN mkdir -p /opt/sdk-tools-linux-4333796 && \
    cd /opt/sdk-tools-linux-4333796 && \
    wget https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip && \
   unzip sdk-tools-linux-4333796.zip && \
   rm -rf sdk-tools-linux-4333796.zip

# Install Gradle
RUN wget https://services.gradle.org/distributions/gradle-4.10.3-bin.zip && \
    mkdir /opt/gradle && \
    unzip -d /opt/gradle gradle-4.10.3-bin.zip && \
    rm -rf gradle-4.10.3-bin.zip
	
RUN cd /opt && \
    chown -R root:root sdk-tools-linux-4333796 && \
    ln -s sdk-tools-linux-4333796 android-sdk

# Setup
# RUN sudo vim /etc/profile.d/android-sdk-env.sh

ENV ANDROID_HOME="/opt/android-sdk"
ENV PATH="$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:/opt/gradle/gradle-4.10.3/bin:$PATH"

ENV JAVA_HOME /etc/alternatives/jre

#Fix bug in angular 
ENV NODE_OPTIONS=--max_old_space_size=4096

# sudo source /etc/profile.d/android-sdk-env.sh

#CMD ["yes","|","$ANDROID_HOME/tools/bin/sdkmanager","--licenses"]
RUN yes | $ANDROID_HOME/tools/bin/sdkmanager --licenses

# cd /opt/android-sdk/tools
#CMD ["$ANDROID_HOME/tools/bin/sdkmanager","--update","--no-ui"]
RUN $ANDROID_HOME/tools/bin/sdkmanager --update

# Andoid studio build tools
# RUN echo y | android update sdk --no-ui --filter build-tools-24.0.0,android-24
RUN echo y | android update sdk --no-ui --filter build-tools-26.0.0,android-26
RUN echo y | android update sdk --no-ui --filter platform-tools,tools

RUN mkdir /scripts
ADD entrypoint.sh /scripts/entrypoint.sh
RUN ["chmod", "+x", "/scripts/entrypoint.sh"]

# Change build directory
WORKDIR /build

VOLUME /build

# Create and build application to download the gradle files
RUN wget https://github.com/rbadamsjr/Ionic3Project/archive/master.zip && \
    mkdir -p /tmp/ && \
    unzip -d /tmp/ master.zip && \
    rm -rf master.zip &&\
	cd /tmp/Ionic3Project-master &&\
	npm install && \
	ionic cordova platform remove android && \
	ionic cordova platform add android && \
	ionic cordova build android --prod && \
	rm -rf /tmp/Ionic3Project-master

ENTRYPOINT ["sh","/scripts/entrypoint.sh"]