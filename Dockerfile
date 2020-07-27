FROM node:12
LABEL maintainer="soulteary@gmail.com"

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

## Alpine Linux 
# RUN echo '' > /etc/apk/repositories && \
#     echo "https://mirror.tuna.tsinghua.edu.cn/alpine/v3.10/main"         >> /etc/apk/repositories && \
#     echo "https://mirror.tuna.tsinghua.edu.cn/alpine/v3.10/community"    >> /etc/apk/repositories && \
#     echo "Asia/Shanghai" > /etc/timezone

# RUN apk update && apk add git && \
#     yarn global add knex-migrator grunt-cli ember-cli bower

## Ubuntu
RUN rm -rf /etc/apt/sources.list
## 复制系统源配置（已经更新为阿里云）
COPY patches/sources.list /etc/apt/sources.list
## 安装git 、yarn 安装依赖
RUN apt-get update && apt-get install git && \
    yarn config set registry https://registry.npm.taobao.org/ && \
    yarn global add knex-migrator grunt-cli ember-cli bower

## 复制fix代码
COPY patches/mobiledoc-kit/event-manager.js /patches/mobiledoc-kit/event-manager.js

# FOR GHOST 3.9.0
ARG GHOST_RELEASE_VERSION=3.26.1
RUN git clone --recurse-submodules https://github.com/TryGhost/Ghost.git --depth=1 --branch=$GHOST_RELEASE_VERSION /Ghost && \
    cd /Ghost && \
    yarn setup

# 0.12.4-ghost.1
# ARG MOBILEDOC_KIT_VERSION=v0.11.1-ghost.4
ARG MOBILEDOC_KIT_VERSION=0.12.4-ghost.1

ARG EVENT_MANAGER_HASH=9a0456060f1c816a0a66bdcf3363e928
RUN git clone https://github.com/TryGhost/mobiledoc-kit.git /mobiledoc-kit && \
    cd /mobiledoc-kit && \
    git checkout $MOBILEDOC_KIT_VERSION && \
    (echo "$EVENT_MANAGER_HASH  /mobiledoc-kit/src/js/editor/event-manager.js" | md5sum -c -s -) && \
    cp /patches/mobiledoc-kit/event-manager.js /mobiledoc-kit/src/js/editor/event-manager.js && \
    yarn && \
    cp -r /mobiledoc-kit/dist /patches/mobiledoc-kit/dist && \
    rm -rf /mobiledoc-kit

RUN rm -rf /Ghost/core/client/node_modules/\@tryghost/mobiledoc-kit/dist && \
    cp -r /patches/mobiledoc-kit/dist /Ghost/core/client/node_modules/\@tryghost/mobiledoc-kit/

WORKDIR /Ghost

RUN grunt prod

EXPOSE 2368

CMD ["npm", "start"]
