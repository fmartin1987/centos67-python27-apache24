FROM fmartin1987/centos67-python27:latest

# Apache compilation
RUN \
    yum install -y gcc gcc-c++ autoconf automake && \
    cd /usr/src && \
    wget https://archive.apache.org/dist/httpd/httpd-2.4.16.tar.gz && \
    wget https://archive.apache.org/dist/apr/apr-util-1.5.4.tar.gz && \
    wget https://archive.apache.org/dist/apr/apr-1.5.2.tar.gz && \
    wget https://ftp.pcre.org/pub/pcre/pcre-8.37.tar.gz && \
    tar -zxf httpd-2.4.16.tar.gz && \
    tar -zxf apr-1.5.2.tar.gz && \
    tar -zxf apr-util-1.5.4.tar.gz && \
    tar -zxf pcre-8.37.tar.gz && \
    cd pcre-8.37 && \
    ./configure --prefix=/usr/local/pcre && \
    make && \
    make install && \
    cd .. && \
    mv apr-1.5.2 httpd-2.4.16/srclib/apr && \
    mv apr-util-1.5.4 httpd-2.4.16/srclib/apr-util && \
    cd httpd-2.4.16 && \
    ./configure --enable-so --enable-ssl --with-mpm=prefork --with-included-apr --with-pcre=/usr/local/pcre/ && \
    make && \
    make install

# Enable SSL
RUN \
    sed -i '/^#.*socache_shmcb_module/s/^#//' /usr/local/apache2/conf/httpd.conf && \
    sed -i '/^#.*mod_ssl.so/s/^#//' /usr/local/apache2/conf/httpd.conf && \
    sed -i '/^#.*httpd-ssl.conf/s/^#//' /usr/local/apache2/conf/httpd.conf && \
    cd /usr/src/ && \
    openssl req -nodes -new -x509 -days 365 -keyout server.key -out server.crt -subj "/C=ES" && \
    cp server.key /usr/local/apache2/conf/ && \
    cp server.crt /usr/local/apache2/conf/

# Load WSGI Module
RUN \
    cd /usr/src && \
    wget https://codeload.github.com/GrahamDumpleton/mod_wsgi/tar.gz/4.4.13 && \
    tar -zxf 4.4.13 && \
    cd mod_wsgi-4.4.13/ && \
    ./configure --with-apxs=/usr/local/apache2/bin/apxs --with-python=/usr/local/bin/python2.7 && \
    make && \
    make install && \
    echo "LoadModule wsgi_module modules/mod_wsgi.so" >> /usr/local/apache2/conf/httpd.conf

# Load XSendFiles Module
RUN \
    cd /usr/src/ && \
    wget https://tn123.org/mod_xsendfile/mod_xsendfile.c && \
    /usr/local/apache2/bin/apxs -cia mod_xsendfile.c

# Load Deflate Module
RUN \
    sed -i '/^#.*deflate_module/s/^#//' /usr/local/apache2/conf/httpd.conf && \
    echo "" >> /usr/local/apache2/conf/httpd.conf && \
    echo "# mod_deflate.so Config" >> /usr/local/apache2/conf/httpd.conf && \
    echo "AddOutputFilterByType DEFLATE text/html text/plain text/css application/x-javascript" >> /usr/local/apache2/conf/httpd.conf && \
    echo "DeflateCompressionLevel 9" >> /usr/local/apache2/conf/httpd.conf
