FROM phusion/baseimage:jammy-1.0.1

ARG DEBIAN_FRONTEND=noninteractive

# Install and configure munge
RUN apt-get update \
  && apt-get install --yes munge \
  && apt-get clean && rm -rf /var/lib/apt/lists/* \
  && mkdir -p /var/run/munge && chown munge:munge /var/run/munge \
  && mkdir -p /etc/service/munge \
  && echo "#!/bin/bash" > /etc/service/munge/run \
  && echo "set -e" >> /etc/service/munge/run \
  && echo "chown munge:munge /var/{lib,log,run}/munge" >> /etc/service/munge/run \
  && echo "chown -R munge:munge /etc/munge" >> /etc/service/munge/run \
  && echo "chmod 700 /etc/munge" >> /etc/service/munge/run \
  && echo "chmod 400 /etc/munge/munge.key" >> /etc/service/munge/run \
  && echo "exec /sbin/setuser munge /usr/sbin/munged -F" >> /etc/service/munge/run \
  && chmod +x /etc/service/munge/run

# Install and configure apache2
ENV LC_ALL=C.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8
ENV APACHE_RUN_USER=www-data
ENV APACHE_RUN_GROUP=www-data
ENV APACHE_LOG_DIR=/var/log/apache2
ENV APACHE_LOCK_DIR=/var/lock/apache2
ENV APACHE_PID_FILE=/var/run/apache2.pid
ENV APACHE_RUN_DIR=/var/run/apache2
RUN apt-get update \
  && apt-get install --yes apache2 libapache2-mod-wsgi-py3 javascript-common \
  && apt-get clean && rm -rf /var/lib/apt/lists/* \
  && a2dissite default-ssl \
  && a2enmod wsgi \
  && a2enconf javascript-common \
  && locale-gen en_US.UTF-8 \
  && chown -R www-data:www-data /var/log/apache2 \
  && mkdir -p /etc/service/apache2 \
  && echo "#!/bin/bash\nset -e\nexec /usr/sbin/apache2 -D FOREGROUND" > /etc/service/apache2/run \
  && chmod +x /etc/service/apache2/run

EXPOSE 80/tcp

RUN build_deps="\
    build-essential \
    libmunge-dev \
    git \
  " \
  && apt-get update \
  && apt-get install --yes ${build_deps} \
  && cd /tmp \
  && git clone --single-branch --branch slurm-22-05-7-1 https://github.com/SchedMD/slurm \
  && cd slurm && ./configure && make -j && make install \
  && apt-get purge --yes --auto-remove ${build_deps} \
  && apt-get clean && rm -rf /var/lib/apt/lists/* \
  && rm -rf /tmp/slurm

RUN build_deps="\
    git \
    python3-dev \
    python3-setuptools \
    python3-pip \
  " \
  && apt-get update \
  && apt-get install --yes ${build_deps} \
  && pip3 install cython==0.29.30 \
  && cd /tmp \
  && git clone --single-branch --branch v22.5.0 https://github.com/pyslurm/pyslurm.git \
  && cd pyslurm \
  && SLURM_LIB_DIR=/usr/local/lib \
     SLURM_INCLUDE_DIR=/usr/local/include \
     python3 setup.py install \
  && pip uninstall -y cython \
  && pip cache purge \
  && apt-get purge --yes --auto-remove ${build_deps} \
  && apt-get clean && rm -rf /var/lib/apt/lists/* \
  && rm -rf /tmp/pyslurm

COPY deb/*.deb /tmp/
COPY node-async /tmp/node-async

# Install slurm-web
RUN apt-get update \
  && apt-get install --yes \
    nodejs libjs-jquery libjs-bootstrap libjs-jquery-flot \
    libjs-jquery-tablesorter libjs-requirejs libjs-requirejs-text \
    libjs-three libjs-d3 libjs-handlebars libjs-async python3-pip \
  && pip3 install \
    itsdangerous==1.1.0 \
  && apt-get install --yes \
    python3-flask python3-ldap python3-clustershell python3-redis \
  && cp /tmp/node-async/* /usr/lib/nodejs \
  && dpkg -i /tmp/libjs-bootstrap-tagsinput_0.8.0-1_all.deb \
             /tmp/libjs-bootstrap-typeahead_0.11.1-1_all.deb \
             /tmp/node-opentypejs_0.4.3-2_all.deb \
             /tmp/slurm-web-common_2.4.0_amd64.deb \
             /tmp/slurm-web-confdashboard_2.4.0_amd64.deb \
             /tmp/slurm-web-dashboard_2.4.0_amd64.deb \
             /tmp/slurm-web-restapi_2.4.0_amd64.deb \
             /tmp/slurm-web_2.4.0_amd64.deb \
  && apt-get clean && rm -rf /var/lib/apt/lists/* \
  && rm -rf /tmp/*

CMD ["/sbin/my_init"]
