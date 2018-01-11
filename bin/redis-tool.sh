#!/bin/bash
# create 实现构建redis集群的目录
# redis-cluster
# ├── 7000
# │   └── redis.conf
# ├── 7001
# │   └── redis.conf
# ...
# └── 7031
#     └── redis.conf
#
# startnodes 启动所有节点
# startcluster [--localhost]启动本地集群 [--outside]将本地节点添加到已有集群中
# kill 关闭所有redis节点
# check 检查集群状态

# 本机ip地址
localIP=192.168.1.61
# 安装集群的根目录
rootPath=~/WorkSpace/redis-cluster-test/redis-cluster
# redis的安装路径
redisPath=/usr/local/Cellar/redis/redis
# 单台机器节点总数
nodes=32
# 从这个端口数开始
startPort=7000
# master个数，不能超过单台机器总节点数的一半，默认剩下的都是slave
master=14
# 集群中已经存在的redis节点，用于在另外一台机器上部署的节点加入现有集群
clusterNowAddr=192.168.1.61:7000

nodesCount=`expr $nodes - 1`


if [ ! -d $rootPath ]; then
	mkdir $rootPath
fi

if [ ! -d $rootPath/db ]; then
	mkdir $rootPath/db
fi

if [[ $1 = "create" ]]; then
	for i in `seq 0 $nodesCount` 
	do
	    nowPort=`expr $startPort + $i`
		if [ ! -d ${rootPath}"/"${nowPort} ]; then
	        mkdir ${rootPath}"/"${nowPort}
	    fi
	    confFile=${rootPath}"/"${nowPort}"/redis.conf"
	    if [ -f ${confFile} ]; then
	        rm ${confFile}
	    fi
	    echo "bind $localIP" >> ${confFile}
	    echo "port $nowPort" >> ${confFile}
	    echo "appendfilename \"appendonly-$nowPort.aof\"" >> ${confFile}
	    echo "cluster-config-file nodes-$nowPort.conf" >> ${confFile}
	    echo "dir ${rootPath}/db/" >> ${confFile}
	    echo "cluster-node-timeout 5000" >> ${confFile}
	    echo "cluster-enabled yes" >> ${confFile}
	    echo "appendonly yes" >> ${confFile}
	    echo "aof-rewrite-incremental-fsync yes" >> ${confFile}
	    echo "finish ${localIP}:${nowPort}"
	done
	echo "create dir structure successfully!"

elif [[ $1 = "startnodes" ]]; then
	for i in `seq 0 $nodesCount`
	do
		nowPort=`expr $startPort + $i`
		nohup ${redisPath}/src/redis-server ${rootPath}/${nowPort}/redis.conf >> ${rootPath}/${nowPort}/redis-${nowPort}.log 2>&1 &
	done
	echo "start nodes successfully!"

elif [[ $1 = "startcluster" ]] && [[ $2 = "--localhost" ]]; then
	trib=$redisPath"/src/redis-trib.rb"
	tribCreate="${trib} create"
	masterCount=`expr ${master} - 1`
	for i in `seq 0 $masterCount`
	do
		nowPort=`expr $startPort + $i`
		tribCreate="${tribCreate} ${localIP}:${nowPort} "
	done
	${tribCreate}
	echo $tribCreate
	if [ ${masterCount} -lt ${nodesCount} ]; then
		masterCount=`expr ${masterCount} + 1`
		tribAdd="${trib} add-node --slave"
		for i in `seq ${masterCount} ${nodesCount}`
		do
			nowPort=`expr $startPort + $i`
			tribCmd="${tribAdd} ${localIP}:${nowPort} ${localIP}:${startPort}"
			${tribCmd}
			echo $tribCmd
		done
	fi
	echo "start cluster successfully!"

elif [[ $1 = "startcluster" ]] && [[ $2 = "--outside" ]]; then
	trib=$redisPath"/src/redis-trib.rb"
	tribAdd="${trib} add-node"
	masterCount=`expr ${master} - 1`
	for i in `seq 0 $masterCount`
	do
		nowPort=`expr $startPort + $i`
		tribCmd="${tribAdd} ${localIP}:${nowPort} ${clusterNowAddr}"
		${tribCmd}
		echo ${tribCmd}
	done
	if [ ${masterCount} -lt ${nodesCount} ]; then
		masterCount=`expr ${masterCount} + 1`
		tribAdd="${tribAdd} --slave"
		for i in `seq ${masterCount} ${nodesCount}`
		do
			nowPort=`expr $startPort + $i`
			tribCmd="${tribAdd} ${localIP}:${nowPort} ${clusterNowAddr}"
			${tribCmd}
			echo $tribCmd
		done
	fi

	# rebalance
	tribRebalance="${trib} rebalance --threshold 1 --use-empty-masters ${clusterNowAddr}"
	echo ${tribRebalance}
	${tribRebalance}
	echo "add to cluster successfully!"

elif [[ $1 = "kill" ]]; then
	# centos
	ret=`ps -fe | grep python | awk '{print $2}' | xargs -i  kill -s 9 {}`
	# macOS
	# ret=`ps -fe | grep redis | awk '{print $2}' | xargs -I p kill "p"`
	if [[ $ret -ne 0 ]]; then
		echo "kill failed!"
		exit
	else
		echo "kill successfully!"
	fi

elif [[ $1 = "check" ]]; then
	trib=$redisPath"/src/redis-trib.rb"
	tribCheck="${trib} check ${localIP}:${startPort}"
	${tribCheck}

elif [ -z $1 ]; then
	echo -e "Usage: ./redis-tool.sh <command> <options>"
	echo -e "  create          to create base dir structure"
	echo -e "  startnodes      to start all nodes up"
	echo -e "  startcluster    to start cluster & set master and slave"
	echo -e "      --localhost     to start cluster locally"
	echo -e "      --outside       to add nodes to other ip and start cluster"
    echo -e "  kill            to kill all redis process"
    echo -e "  check           to check cluster's state"
else
	echo -e "Usage: ./redis-tool.sh <command> <options>"
	echo -e "  create          to create base dir structure"
	echo -e "  startnodes      to start all nodes up"
	echo -e "  startcluster    to start cluster & set master and slave"
	echo -e "      --localhost     to start cluster locally"
	echo -e "      --outside       to add nodes to other ip and start cluster"
    echo -e "  kill            to kill all redis process"
    echo -e "  check           to check cluster's state"
fi




