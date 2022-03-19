FROM phusion/baseimage:focal-1.2.0

ENV DEBIAN_FRONTEND=noninteractive

# Install python3 and slurmctld
RUN apt-get update \
  && apt-get install --yes \
    git \
    python3 \
    python3-pip \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install and configure munge
RUN apt-get update \
  && apt-get install --yes munge \
  && apt-get clean && rm -rf /var/lib/apt/lists/* \
  && mkdir -p /var/run/munge && chown munge:munge /var/run/munge \
  && mkdir -p /etc/service/munge \
  && echo "#!/bin/bash\nset -e\nchown munge:munge /var/{lib,log,run}/munge\nexec /sbin/setuser munge /usr/sbin/munged -f" > /etc/service/munge/run \
  && chmod +x /etc/service/munge/run

# Install and configure apache2
ENV LC_ALL=C.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8
RUN apt-get update \
  && apt-get install --yes apache2 libapache2-mod-wsgi-py3 javascript-common \
  && apt-get clean && rm -rf /var/lib/apt/lists/* \
  && a2dissite default-ssl \
  && a2enmod wsgi \
  && a2enconf javascript-common \
  && locale-gen en_US.UTF-8 \
  && chown -R www-data:www-data /var/log/apache2 \
  && echo www-data > /etc/container_environment/APACHE_RUN_USER \
  && echo www-data > /etc/container_environment/APACHE_RUN_GROUP \
  && echo /var/log/apache2 > /etc/container_environment/APACHE_LOG_DIR \
  && echo /var/lock/apache2 > /etc/container_environment/APACHE_LOCK_DIR \
  && echo /var/run/apache2.pid > /etc/container_environment/APACHE_PID_FILE \
  && echo /var/run/apache2 > /etc/container_environment/APACHE_RUN_DIR \
  && mkdir -p /etc/service/apache2 \
  && echo "#!/bin/bash\nset -e\nexec /usr/sbin/apache2 -D FOREGROUND" > /etc/service/apache2/run \
  && chmod +x /etc/service/apache2/run
EXPOSE 80/tcp

# Build python2-pyslurm
#COPY pyslurm/debian.python2 /tmp/debian.python2
#RUN build_deps="\
#    cython \
#    debhelper \
#    devscripts \
#    equivs \
#    libslurm-dev \
#    python \
#    python-dev \
#    python-setuptools \
#    slurm-wlm-basic-plugins \
#  " \
#  && apt-get update \
#  && apt-get install --yes ${build_deps} \
#  && cd /tmp \
#  && git clone --single-branch --branch 19-05-0 https://github.com/pyslurm/pyslurm.git \
#  # (start) Patch pyslurm 19-05-0 so that it works with stock Slurm 19.05.5 on Ubuntu 20.04 (aka focal)
#  && sed -i "53s|None|'/usr/lib/x86_64-linux-gnu'|" pyslurm/setup.py \
#  && sed -i "54s|None|'/usr/include/slurm'|" pyslurm/setup.py \
#  && sed -i "99s|/slurm|/slurm-wlm|" pyslurm/setup.py \
#  # (end) Patch pyslurm 19-05-0 so that it works with stock Slurm 19.05.5 on Ubuntu 20.04 (aka focal)
#  && cp -R debian.python2 pyslurm/debian \
#  && cd pyslurm && rm -rf .git .github .gitignore .travis.yml \
#  && tar cvfj ../python2-pyslurm_19.05.0.orig.tar.bz2 . \
#  && mk-build-deps -ri -t "apt-get --yes --no-install-recommends" \
#  && debuild -us -uc \
#  && cd .. && (find . -not -name "*.deb" -exec rm -rf {} \; > /dev/null 2>&1 || true) \
#  && apt-get purge --yes --auto-remove ${build_deps} \
#  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Build python3-pyslurm
COPY pyslurm/debian.python3 /tmp/debian.python3
RUN build_deps="\
    cython \
    cython3 \
    debhelper \
    devscripts \
    dh-python \
    equivs \
    libslurm-dev \
    slurm-wlm-basic-plugins \
  "\
  && apt-get update \
  && apt-get install --yes ${build_deps} \
  && cd /tmp \
  && git clone --single-branch --branch 19-05-0 https://github.com/pyslurm/pyslurm.git \
  # (start) Patch pyslurm 19-05-0 so that it works with stock Slurm 19.05.5 on Ubuntu 20.04 (aka focal)
  && sed -i "53s|None|'/usr/lib/x86_64-linux-gnu'|" pyslurm/setup.py \
  && sed -i "54s|None|'/usr/include/slurm'|" pyslurm/setup.py \
  && sed -i "99s|/slurm|/slurm-wlm|" pyslurm/setup.py \
  # (end) Patch pyslurm 19-05-0 so that it works with stock Slurm 19.05.5 on Ubuntu 20.04 (aka focal)
  && cp -R debian.python3 pyslurm/debian \
  && cd pyslurm && rm -rf .git .github .gitignore .travis.yml \
  && tar cvfj ../python3-pyslurm_19.05.0.orig.tar.bz2 . \
  && mk-build-deps -ri -t "apt-get --yes --no-install-recommends" \
  && debuild -us -uc \
  && cd .. && (find . -not -name "*.deb" -exec rm -rf {} \; > /dev/null 2>&1 || true) \
  && apt-get purge --yes --auto-remove ${build_deps} \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN build_deps="\
    debhelper \
    devscripts \
    equivs \
  " \
  && apt-get update \
  && apt-get install --yes ${build_deps} \
  && cd /tmp \
  # Build node-opentypejs
  && git clone --single-branch --branch debian/0.4.3-2 https://github.com/edf-hpc/opentypejs.git \
  && cd opentypejs && rm -rf .git* .jshint* .npmignore \
  && tar cvfj ../opentypejs_0.4.3.orig.tar.bz2 . \
  && mk-build-deps -ri -t "apt-get --yes --no-install-recommends" \
  && debuild -us -uc \
  && cd .. && (find . -not -name "*.deb" -exec rm -rf {} \; > /dev/null 2>&1 || true) \
  # Build libjs-bootstrap-typeahead
  && git clone --single-branch --branch debian/0.11.1-1 https://github.com/edf-hpc/libjs-bootstrap-typeahead.git \
  && cd libjs-bootstrap-typeahead && rm -rf .git* .jshint* .travis* \
  && tar cvfj ../libjs-bootstrap-typeahead_0.11.1.orig.tar.bz2 . \
  && mk-build-deps -ri -t "apt-get --yes --no-install-recommends" \
  && debuild -us -uc \
  && cd .. && (find . -not -name "*.deb" -exec rm -rf {} \; > /dev/null 2>&1 || true) \
  # Build libjs-bootstrap-tagsinput
  && git clone --single-branch --branch debian/0.8.0-1 https://github.com/edf-hpc/libjs-bootstrap-tagsinput.git \
  && cd libjs-bootstrap-tagsinput && rm -rf .git* .travis* \
  && tar cvfj ../libjs-bootstrap-tagsinput_0.8.0.orig.tar.bz2 . \
  && mk-build-deps -ri -t "apt-get --yes --no-install-recommends" \
  && debuild -us -uc \
  && cd .. && (find . -not -name "*.deb" -exec rm -rf {} \; > /dev/null 2>&1 || true) \
  && apt-get purge --yes --auto-remove ${build_deps} \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Build and install slurm-web
COPY DejaVuSansMono.typeface.js.tar.gz /tmp
RUN build_deps="\
    apache2-dev \
    debhelper \
    devscripts \
    dh-python \
    equivs \
    fonts-dejavu-core \
    node-uglify \
    python3-all \
  "\
  && apt-get update \
  && apt-get install --yes ${build_deps} \
  && dpkg -i /tmp/node-opentypejs_0.4.3-2_all.deb \
  && cd /tmp \
  && git clone --single-branch --branch v2.4.0 https://github.com/edf-hpc/slurm-web.git \
  # (start) Patch slurm-web v2.4.0
  && sed -i "16s|'\*.wsgi'|['\*.wsgi']|" slurm-web/setup.py \
  && sed -i "9s|^|#|" slurm-web/debian/rules \
  && mkdir -p slurm-web/dashboard/js/fonts \
  && tar -zxvf *.js.tar.gz --directory slurm-web/dashboard/js/fonts \
  && chown root:root slurm-web/dashboard/js/fonts/* \
  # (end) Patch slurm-web v2.4.0
  && cd slurm-web && rm -rf .git* .code* .css* .es* \
  && tar cvfj ../slurm_web_v2.4.0.orig.tar.bz2 . \
  && mk-build-deps -ri -t "apt-get --yes --no-install-recommends" \
  && debuild -us -uc \
  && cd .. && (find . -not -name "*.deb" -exec rm -rf {} \; > /dev/null 2>&1 || true) \
  && apt-get remove --yes node-opentypejs \
  && apt-get purge --yes --auto-remove ${build_deps} \
  # Install runtime dependencies
  && apt-get install --yes \
    libjs-async \
    libjs-bootstrap \
    libjs-d3 \
    libjs-handlebars \
    libjs-jquery \
    libjs-jquery-flot \
    libjs-jquery-tablesorter \
    libjs-requirejs \
    libjs-requirejs-text \
    libjs-three \
#    nodejs \
    python3-clustershell \
    python3-flask \
    python3-ldap \
    python3-redis \
    slurm-wlm-basic-plugins \
  && dpkg -i /tmp/libjs-bootstrap-typeahead_0.11.1-1_all.deb \
  && dpkg -i /tmp/libjs-bootstrap-tagsinput_0.8.0-1_all.deb \
  && dpkg -i /tmp/python3-pyslurm_19.05.0_amd64.deb \
  && dpkg -i /tmp/slurm-web-common_2.4.0_amd64.deb \
  && dpkg -i /tmp/slurm-web-restapi_2.4.0_amd64.deb \
  && dpkg -i /tmp/slurm-web-confdashboard_2.4.0_amd64.deb \
  && dpkg -i /tmp/slurm-web-dashboard_2.4.0_amd64.deb \
  && dpkg -i /tmp/slurm-web_2.4.0_amd64.deb \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

CMD ["/sbin/my_init"]
