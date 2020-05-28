FROM centos:7

ARG IPADDR=192.168.53.43
ARG DOMAIN=t2w.local.server

RUN yum update -y 
RUN yum install -y wget make gcc git gcc-c++ libtool autoconf  pcre bison libcurl-devel libxml2-devel pcre-devel openssl-devel epel-release screen
RUN yum install -y tor python2-pip dehydrated
RUN pip install -U pip && pip2 install nyx

RUN cd $(mktemp -d) && export SREGEX_INC=/opt/sregex/include && export SREGEX_LIB=/opt/sregex/lib && git clone https://github.com/agentzh/sregex && cd sregex && make && make install && cd .. && git clone https://github.com/nginx/nginx && cd nginx && git clone https://github.com/openresty/replace-filter-nginx-module && ./auto/configure --sbin-path=/usr/sbin/nginx --modules-path=/usr/lib64/nginx/modules --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock --http-client-body-temp-path=/var/cache/nginx/client_temp --http-proxy-temp-path=/var/cache/nginx/proxy_temp --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp --http-scgi-temp-path=/var/cache/nginx/scgi_temp --user=nginx --group=nginx --lock-path=/var/lock/nginx.lock --http-client-body-temp-path=/var/lib/nginx/body --http-proxy-temp-path=/var/lib/nginx/proxy --with-http_gzip_static_module --with-http_ssl_module --with-http_realip_module --with-stream_ssl_module --with-http_v2_module --with-threads --with-http_addition_module --with-http_gunzip_module --with-http_auth_request_module --with-http_degradation_module --add-module=$(pwd)/replace-filter-nginx-module --with-ld-opt="-Wl,-rpath,/usr/local/lib" && make -j4 && make install && useradd -d /etc/nginx/ -s /sbin/nologin nginx && mkdir -p /var/lib/nginx/body /var/cache/nginx/fastcgi_temp /var/www/{html,site} && mv /etc/nginx/nginx.conf{,.bak} && touch /var/www/{site,html}/index.html

COPY nginx.conf /etc/nginx/
COPY blacklist.conf /etc/nginx

RUN sed -i "s/IP-ADDRESS-PLACEHOLDER/$IPADDR/g" /etc/nginx/nginx.conf && sed -i "s/DOMAIN-TLD-PLACEHOLDER/$DOMAIN/g" /etc/nginx/nginx.conf && sed -i "s/DOMAIN-TLD-PLACEHOLDER/$DOMAIN/g" /etc/nginx/blacklist.conf

RUN cd $(mktemp -d) && git clone https://github.com/z3APA3A/3proxy && cd 3proxy && ln -s Makefile.Linux Makefile && make && make install && mv /etc/3proxy/conf/3proxy.cfg{,.bak}
COPY 3proxy.cfg /etc/3proxy/conf/
RUN chown proxy:proxy /etc/3proxy/conf/3proxy.cfg

RUN cd /etc/tor && mv torrc{,.bak}
COPY torrc /etc/tor
RUN chmod 644 /etc/tor/torrc

# do this manually to get ssl certificate
#RUN mkdir /var/www/dehydrated && echo "$DOMAIN *.$DOMAIN" > /etc/dehydrated/domains.txt 
#COPY dehydrated /etc/dehydrated/config
#RUN /usr/bin/dehydrated --register --accept-terms && /usr/bin/dehydrated --full-chain --cron

COPY control.sh /root

COPY entrypoint.sh /usr/bin/entrypoint.sh

RUN chmod +x /usr/bin/entrypoint.sh /root/control.sh


RUN yum remove -y git gcc gcc-c++ epel-release

WORKDIR /

EXPOSE 80 443

ENTRYPOINT /usr/bin/entrypoint.sh
