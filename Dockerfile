FROM debian:8

# less priviledge user, the id should map the user the downloaded files belongs to
RUN groupadd -r dummy && useradd -r -g dummy dummy -u 1000

# webui + aria2
RUN apt-get update \
	&& apt-get install -y aria2 busybox curl \
	&& rm -rf /var/lib/apt/lists/*

ADD ./docs /webui-aria2

# gosu install latest
RUN curl -L https://github.com/tianon/gosu/releases/download/1.14/gosu-amd64 > /usr/local/bin/gosu
RUN chmod +x /usr/local/bin/gosu

# goreman supervisor install latest
RUN curl -L https://github.com/mattn/goreman/releases/download/v0.3.11/goreman_v0.3.11_linux_amd64.tar.gz > goreman.tar.gz
RUN tar xvf goreman.tar.gz && mv /goreman*/goreman /usr/local/bin/goreman && rm -R goreman*
RUN touch /data/aria2.conf
RUN chmod 0777 /data/aria2.conf
RUN echo "max-download-result=100000" >> /data/aria2.conf
RUN echo "max-concurrent-downloads=30" >> /data/aria2.conf
RUN echo "log=/tmp/aria2c.log" >> /data/aria2.conf
RUN echo "download-result=full" >> /data/aria2.conf
RUN echo "continue=true" >> /data/aria2.conf
RUN echo "allow-overwrite=true" >> /data/aria2.conf

# goreman setup
RUN echo "web: gosu dummy /bin/busybox httpd -f -p 8080 -h /webui-aria2\nbackend: gosu dummy /usr/bin/aria2c --enable-rpc --rpc-listen-all --dir=/data --conf-path=/data/aria2.conf" > Procfile

# aria2 downloads directory
VOLUME /data

# aria2 RPC port, map as-is or reconfigure webui
EXPOSE 6800/tcp

# webui static content web server, map wherever is convenient
EXPOSE 8080/tcp

CMD ["start"]
ENTRYPOINT ["/usr/local/bin/goreman"]
