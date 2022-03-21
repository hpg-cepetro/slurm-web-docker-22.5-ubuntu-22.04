FROM phusion/baseimage:focal-1.2.0

ARG DEBIAN_FRONTEND=noninteractive

# Build python2-pyslurm
#COPY pyslurm/debian.python2 /tmp/debian.python2
#RUN build_deps="\
#    cython \
#    debhelper \
#    devscripts \
#    equivs \
#    git \
#    libslurm-dev \
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
    git \
    libslurm-dev \
    python3-dev \
    python3-setuptools \
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
    git \
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

# Build slurm-web
COPY slurm-web/DejaVuSansMono.typeface.json.tar.gz /tmp
RUN build_deps="\
    apache2-dev \
    debhelper \
    devscripts \
    dh-python \
    equivs \
    fonts-dejavu-core \
    git \
    node-uglify \
    python3-all \
  "\
  && apt-get update \
  && apt-get install --yes ${build_deps} \
  && dpkg -i /tmp/node-opentypejs_0.4.3-2_all.deb \
  && cd /tmp \
  && git clone --single-branch --branch v2.4.0 https://github.com/edf-hpc/slurm-web.git \
  # (patch-start)
  # (patch) regress to fix wrong job coloring in jobsmap problem (what a shame)
  # @see https://github.com/edf-hpc/slurm-web/issues/210
  && git clone --single-branch --branch v2.2.2 https://github.com/edf-hpc/slurm-web.git slurm-web.v2.2.2 \
  && mv -f slurm-web.v2.2.2/dashboard/js/draw/2d-* slurm-web/dashboard/js/draw/\
  && rm -rf slurm-web.v2.2.2 \
  # (patch) fix a simple syntax error
  && sed -i "16s|'\*.wsgi'|['\*.wsgi']|" slurm-web/setup.py \
  # (patch) fix "cannot find package.json" problem
  && tar -zxvf DejaVuSansMono.typeface.json.tar.gz \
  && chown root:root DejaVuSansMono.typeface.json \
  && sed -i "9s|nodejs.*|cp /tmp/DejaVuSansMono.typeface.json dashboard/js/fonts/DejaVuSansMono.typeface.json|" slurm-web/debian/rules \
  # (patch) fix old syntax problem
  && sed -i "493s|font.*|font: font,|" slurm-web/dashboard/js/draw/3d-draw.js \
  && sed -i "488s|^|//|" slurm-web/dashboard/js/draw/3d-draw.js \
  && sed -i "488 a loader.load(config.RACKNAME.FONT.PATH, function(font) {" slurm-web/dashboard/js/draw/3d-draw.js \
  && sed -i "488 a var loader = new THREE.FontLoader();" slurm-web/dashboard/js/draw/3d-draw.js \
  # (patch) fix old syntax problem
  && find slurm-web/dashboard/js/ -name "*.js" \
    -exec sed -i "s|\.success(func|\.done(func|g" {} \; \
    -exec sed -i "s|\.error(func|\.fail(func|g" {} \; \
    -exec sed -i "s|\.complete(|\.always(|g" {} \; \
  # (patch-end)
  && cd slurm-web && rm -rf .git* .code* .css* .es* \
  && tar cvfj ../slurm_web_v2.4.0.orig.tar.bz2 . \
  && mk-build-deps -ri -t "apt-get --yes --no-install-recommends" \
  && debuild -us -uc \
  && cd .. && (find . -not -name "*.deb" -exec rm -rf {} \; > /dev/null 2>&1 || true) \
  && apt-get remove --yes node-opentypejs \
  && apt-get purge --yes --auto-remove ${build_deps} \
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

# Install slurm-web
RUN apt-get update \
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
