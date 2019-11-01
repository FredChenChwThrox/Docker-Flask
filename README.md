# 使用Docker进行Web开发
## 推荐电子书

首先推荐一本电子书《Docker从入门到实践》，覆盖了Docker在使用的方方面面。

 https://yeasy.gitbooks.io/docker_practice/content/ 

另外还有docker的官方文档，比如这是docker-compose.yml的说明文档。

 https://docs.docker.com/compose/compose-file/#build 

## 环境准备

1. Linux虚拟机一台，可连接外网。
2. 实现安装好docker，以CentOS为例。
```shell
yum install docker
```


## 配置本地仓库
```shell
echo "172.17.1.140 reg.test.k8s" >> /etc/hosts # 添加域名映射
echo "{ \"insecure-registries\": [\"reg.test.k8s\"] }" > /etc/docker/daemon.json # 添加仓库配置到 docker 配置文件
systemctl restart docker # 重启 docker
docker pull reg.test.k8s/library/nginx # 测试
```


## 创建应用文件夹
```shell
[root@localhost flask]# tree
.
├── docker-compose.yml
├── Dockerfile
├── pkg
│   └── requirements.txt
└── src
    └── flask_demo
        └── app.py
```

`pkg`目录用来放置依赖的程序包，或者类似python的`requirements.txt`。
`src`目录用来放置应用本身的代码。
`Dockerfile`是docker镜像描述文件
`docker-compose.yml`用来编排docker服务，后面开发过程中，我们会用到这个

注意，工作文件夹，一定不能放在`/root`目录下，这会导致后续的权限问题。

## 编写`Dockerfile`
在根目录下放置一个`Dockerfile`文件，该文件描述了这个镜像是如何构建起来的。
```dockerfile
FROM python:3.7.5-alpine3.10
MAINTAINER fred_chen “chw_throx@163.com”
ADD src/flask_demo /opt/test/flask_demo
ADD pkg/requirements.txt /opt/test/deps/requirements.txt
RUN pip install -r /opt/test/deps/requirements.txt
WORKDIR /opt/test/flask_demo/
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
```shell
docker build -t docker-flask:v1
```

## 运行容器
后台运行
```shell
docker run -p [host_port]:[container_port] -d [image_name]:[tag]
```
交互式运行
```shell
docker -i -t [image_name]:[tag] /bin/sh
```
需要指出的是，最后输入的`/bin/bash`会取代`Dockerfile`里面的`CMD`指定的命令，也就是说，交互式运行时，flask不会启动。

## 查看容器运行状态
```
docker ps

docker inspect container-id
```

## 停止容器
```
docker stop [docker id]
```



## 使用容器的开发姿势

使用容器进行开发的好处在与：开发环境和生产环境是一致的。那怎样利用容器进行开发呢？

关于这个问题，我有过一些思考。要保证开发环境和生产环境的一致性，需要研发提交代码时连同环境一起提交。那实际的开发流程可能是这样：

![DockerDevWorkFlow](pic/DockerDevWorkFlow.png)

研发在开发过程中，修改代码后重新构建docker并进行部署调试，以这样的方式进行。

但是这样有一个问题，当容器是非常轻量级的时候，构建和部署的时间消耗并不明显，但是当服务是基于类似tomcat这种应用服务时，本身的启动时间就非常长，如果使用这样的开发流程就会十分麻烦。那是否有方法能够省去不断重启服务的麻烦呢。

其实方法是有的，但是要麻烦一些，运行的时候，可以使用`-v host_dir:container_dir`的方式来把宿主机的目录挂载到镜像中去。

更优雅一些的方式是使用`docker-compose`这个工具。

## 利用`docker-compose`进行开发

安装`docker-compose`

`docker-compose`这个工具是基于`python`的，可以通过`pip`进行安装

```
pip install docker-compose
```

编写docker-compose.yaml文件，放置在与`Dockerfile` 同一级目录里。

`docker-compose.yaml`内容

```yaml
version: '3'
services:
    web: # 服务的名字
        build: . # 从当前目录构建
        image: flask_dev:v1 # 指定容器的名字和tag
        ports:
            - "5000:5000" # 将容器的5000端口映射到宿主机的5000端口
        volumes:
            - ./src/flask_demo:/opt/test/flask_demo # 将代码映射到容器内部位置
        environments:
            - FLASK_DEBUG=1 # 打开flask的debug模式



```

写完脚本后用`docker-compose`进行构建:

```shell
docker-compose build --force-rm web
```

 接着运行

```shell
docker-compose run web
```

由于容器在退出之后仍然会留着系统中，容器启动次数多了了以后会产生很多垃圾，因此可以在启动时指定`--rm`，让docker在容器推出后将其删除。

```shell
docker-compose run --rm web
```

在整个过程中，我遇到了两个坑：

1. 源代码目录放置在`/root`目录下，由于容器内的程序是以`flaskusr`运行的，在运行的时候没有权限访问外部的文件。？
2. SELinux没有关闭，导致挂载后目录中的文件无法访问。



