# Docker开发环境镜像构建
## 环境准备
1. Linux虚拟机一台，可连接外网。
2. 实现安装好docker，以CentOS为例。
```
yum install docker 
```


## 配置本地仓库
```

```


## 创建应用文件夹
```

```
`pkg`目录用来放置依赖的程序包，或者类似python的`requirements.txt`。
`src`目录用来放置应用本身的代码。

## 编写`Dockerfile`
在根目录下放置一个`Dockerfile`文件，该文件描述了这个镜像是如何构建起来的。
```
FROM python:3.7.5-alpine3.10
MAINTAINER fred_chen “chw_throx@163.com”
ADD src/flask-demo /opt/test/flask-demo
ADD pkg/requirements.txt /opt/test/deps/requirements.txt
RUN pip install -r /opt/test/deps/requirements.txt
WORKDIR /opt/test/flask-demo/
RUN addgroup -S flaskusr && adduser -S flaskusr -G flaskusr
USER flaskusr
ENV FLASK_APP=app.py
CMD flask run --host=0.0.0.0
EXPOSE 5000
```

第一行`FROM python:3.7.5-alpine3.10`，代表这个镜像是基于一个名叫`python`的镜像进行构建的，`3.7.5-alpine3.10`是这个镜像的标签，在构建时指定。
第二行是维护者邮箱。
第三行，第四行，我使用`ADD`操作，将代码拷贝到了`/opt/test/flask-demo`，需要注意的是Dockerfile有两种写法即：`ADD`和`COPY`，两者的区别在于，`ADD`会在拷贝完成后，自动给文件加上753权限，如果对应文件是压缩文件的话，`ADD`操作会把压缩文件展开。
如果目的路径不存在，`ADD`和`COPY`操作都会将其创建出来。
第五行，使用`RUN`命令运行`pip install` 安装`flask`所需的依赖包。
第六行，使用`WORKDIR`指定运行的工作目录
第七行和第八行，创建用户`flaskusr:flaskusr`并将其指定为运行用户。
在这里，遇到一个小坑，在一般linux系统里，创建用户组和用户一般的命令是`groupadd`和`useradd`，在这一个基础发行版里却是`addgroup`和`adduser`，之前一直在折腾这个。`alpine`这个发行版和`ubuntu`以及`CentOS`不一样，它的软件包管理既不是`yum`也不是`apt-get`，而是`apk`，在所有招式都用尽之后，我才发现其实是它的命令格式的问题。
第九行和第十行，指定`flask`的运行时环境变量和容器运行的命令。
最后一行，使用`EXPOSE`告诉Docker运行时要暴露5000端口。需要注意的是，在运行时还需要指定`-p 5000:5000`

## 构建容器镜像
使用命令
```
docker build -t docker-flask:v1
```

## 运行容器
后台运行
```
docker run -p 5000:5000 -d docker-flask:v1 
```
交互式运行
```
docker -i -t docker-flask:v1 /bin/bash
```
需要指出的是，最后输入的`/bin/bash`会取代`Dockerfile`里面的`CMD`指定的命令，也就是说，交互式运行时，flask不会启动。

## 查看容器运行状态
```
docker ps
```

## 停止容器
```
docker stop [docker id]
```
