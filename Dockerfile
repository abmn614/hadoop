FROM alpine:3.12

RUN apk update && apk upgrade

RUN apk add openssl openssh pdsh openjdk8-jre procps

ENV JAVA_HOME /usr/lib/jvm/java-1.8-openjdk
ENV PATH $PATH:$JAVA_HOME/bin

RUN ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_dsa_key
RUN ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key
RUN ssh-keygen -q -N "" -t rsa -f /root/.ssh/id_rsa
RUN cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys
RUN echo "Host * \
  UserKnownHostsFile /dev/null \
  StrictHostKeyChecking no \
  LogLevel quiet \
  Port 2122" > /root/.ssh/config
RUN chmod 600 /root/.ssh/config
RUN chown root:root /root/.ssh/config
RUN echo "Port 22" >> /etc/ssh/sshd_config

RUN /usr/sbin/sshd

COPY hadoop-3.2.1.tar.gz /tmp

ENV HADOOP_VERSION 3.2.1
ENV HADOOP_HOME /usr/local/hadoop-$HADOOP_VERSION
ENV PATH $PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
ENV HADOOP_CONF_DIR $HADOOP_HOME/etc/hadoop

RUN tar -xvf /tmp/hadoop-$HADOOP_VERSION.tar.gz -C /usr/local && rm -rf /tmp/hadoop-$HADOOP_VERSION.tar.gz

RUN sed -i '1i\export JAVA_HOME=$JAVA_HOME' $HADOOP_CONF_DIR/hadoop-env.sh

RUN echo "hadoop standalone 环境已搭建完成" \
	&& echo "hadoop目录为/bin/hadoop，执行/bin/hadoop 可查看可用命令" \
	&& echo "执行hadoop测试任务"

RUN mkdir /input && cp $HADOOP_CONF_DIR/*.xml /input \
	&& $HADOOP_HOME/bin/hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.2.1.jar grep /input /output 'dfs[a-z.]+' \
	&& cat output/*