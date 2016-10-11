FROM ubuntu:16.04
MAINTAINER MaAO

# Configure odoo
ENV ODOO_USER=${ODOO_USER:-odoo} \
    ODOO_INSTALL_DIR=${ODOO_INSTALL_DIR:-/opt/odoo} \
    ODOO_DB_HOST=${ODOO_DB_HOST:-localhost} \
    ODOO_DB_PORT=${ODOO_DB_PORT:-5432} \
    ODOO_DB_USER=${ODOO_DB_USER:-odoo} \
    ODOO_DB_PASSWORD=${ODOO_DB_PASSWORD:-odoo} \
    ODOO_REPO=${ODOO_REPO:-https://github.com/managment-and-acounting-on-line/maao} \
    ODOO_BRANCH=${ODOO_BRANCH:-maao-9.0} \
    ODOO_ADMIN_PASS=${ODOO_ADMIN_PASS} 

# generate locales
RUN locale-gen en_US.UTF-8 && update-locale && \
    	echo 'LANG="en_US.UTF-8"' > /etc/default/locale

# Install dependencies
RUN apt-get update -qq && apt-get upgrade -qq -y && \
    apt-get install -qqq -y libtiff5-dev libjpeg8-dev zlib1g-dev \
        libfreetype6-dev liblcms2-dev libwebp-dev wget git perl \
        python-setuptools g++ libpq-dev python-dev python-pychart \
        xfonts-base xfonts-75dpi libxrender1 libxext6 fontconfig \
        postgresql-client python-babel python-chardet python-cryptography \
        python-openssl python-markupsafe lsb-release nodejs graphviz \
		docutils-doc python-egenix-mxdatetime python-egenix-mxtools \
		python-ndg-httpsclient python-libxml2  python-ipaddress \
        docutils-common javascript-common libart-2.0-2 libjs-jquery \
        libtidy-0.99-0 libxslt1.1 libyaml-0-2 node-amdefine node-source-map \
        python-antlr python-bs4 python-funcsigs python-html5lib python-pbr \
        python-pil python-pygments python-pyinotify python-renderpm \
        python-reportlab-accel python-roman python-stdnum python-urllib3 \
        python-utidylib && \
    easy_install -U setuptools pip && \
    pip install --upgrade pip virtualenv erppeek python-slugify gevent \
    	psycopg2 psycogreen greenlet xlwt 

# Install wkhtmltox
ADD http://download.gna.org/wkhtmltopdf/0.12/0.12.2.1/wkhtmltox-0.12.2.1_linux-trusty-amd64.deb /tmp/wkhtmltox.deb
RUN dpkg --force-depends -i /tmp/wkhtmltox.deb && \
    apt-get -f install -y -qqq && \
    rm /tmp/wkhtmltox.deb

# Add odoo user
RUN adduser --system --home=${ODOO_INSTALL_DIR} --quiet --group ${ODOO_USER}

# Install odoo-helper scripts
RUN wget -O - https://raw.githubusercontent.com/katyukha/odoo-helper-scripts/dev/install-system.bash | bash -s
RUN odoo-helper system update dev

# Add odoo files from archive
ADD https://github.com/management-and-acounting-on-line/maao/archive/${ODOO_BRANCH}.tar.gz /tmp/maao.tar.gz
WORKDIR /tmp
RUN tar -xzf /tmp/maao.tar.gz && \
    mv /tmp/maao-${ODOO_BRANCH} /opt/odoo/odoo && \
    rm /tmp/maao.tar.gz

# Add installer script
COPY ./install_odoo_simple.bash /root/install_odoo_simple.bash

# Install odoo
RUN bash /root/install_odoo_simple.bash

# Fix acces rights for config
RUN chown -R root:$ODOO_USER /opt/odoo/conf && \
    chmod -R 0640 /opt/odoo/conf;

# Fix access rights for data dir
RUN chown -R $ODOO_USER:$ODOO_USER /opt/odoo/data

# Choose user to odoo's user
USER $ODOO_USER
WORKDIR $ODOO_INSTALL_DIR

VOLUME ["/opt/odoo/repositories", "/opt/odoo/conf/", "/opt/odoo/logs", \
        "/opt/odoo/custom_addons", "/opt/odoo/downloads", "/opt/odoo/backups"]

ENTRYPOINT ["odoo-helper"]
CMD ["server", "run"]

EXPOSE "8069 8071 8072"
