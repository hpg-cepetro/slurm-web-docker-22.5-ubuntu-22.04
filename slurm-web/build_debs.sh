#!/bin/bash
set -Eeuo pipefail

# Build dependencies
export build_deps="\
  debhelper \
  devscripts \
  equivs \
  git \
"
apt-get update
apt-get install --yes ${build_deps}
cd /tmp
# Build node-opentypejs
git clone --single-branch --branch debian/0.4.3-2 https://github.com/edf-hpc/opentypejs.git
cd opentypejs 
rm -rf .git* .jshint* .npmignore
tar cvfj ../opentypejs_0.4.3.orig.tar.bz2 .
mk-build-deps -ri -t "apt-get --yes --no-install-recommends"
debuild -us -uc
cd ..
(find . -not -name "*.deb" -exec rm -rf {} \; > /dev/null 2>&1 || true)
# Build libjs-bootstrap-typeahead
git clone --single-branch --branch debian/0.11.1-1 https://github.com/edf-hpc/libjs-bootstrap-typeahead.git
cd libjs-bootstrap-typeahead
rm -rf .git* .jshint* .travis*
tar cvfj ../libjs-bootstrap-typeahead_0.11.1.orig.tar.bz2 .
mk-build-deps -ri -t "apt-get --yes --no-install-recommends"
debuild -us -uc
cd ..
(find . -not -name "*.deb" -exec rm -rf {} \; > /dev/null 2>&1 || true)
# Build libjs-bootstrap-tagsinput
git clone --single-branch --branch debian/0.8.0-1 https://github.com/edf-hpc/libjs-bootstrap-tagsinput.git
cd libjs-bootstrap-tagsinput 
rm -rf .git* .travis*
tar cvfj ../libjs-bootstrap-tagsinput_0.8.0.orig.tar.bz2 .
mk-build-deps -ri -t "apt-get --yes --no-install-recommends"
debuild -us -uc
cd ..
(find . -not -name "*.deb" -exec rm -rf {} \; > /dev/null 2>&1 || true)
apt-get purge --yes --auto-remove ${build_deps}
apt-get clean 
rm -rf /var/lib/apt/lists/*

# Build slurm-web
cp /build/slurm-web/DejaVuSansMono.typeface.json.tar.gz /tmp
export build_deps="\
  apache2-dev \
  debhelper \
  devscripts \
  dh-python \
  equivs \
  fonts-dejavu-core \
  git \
  node-uglify \
  python3-all \
"
apt-get update
apt-get install --yes ${build_deps}
dpkg -i /tmp/node-opentypejs_0.4.3-2_all.deb
cd /tmp
git clone --single-branch --branch v2.4.0 https://github.com/edf-hpc/slurm-web.git
# (patch-start)
# font-converter.js depends on an old version of node-async
cp /build/node-async/* /usr/lib/nodejs
# Do not depend on pyslurm (will be built later)
sed -i "36d" slurm-web/debian/control
# (problem) use one (human) language for this project
sed -i "s|cœurs utilisés|cores used|" slurm-web/dashboard/js/utils/tagsinput.js
# (problem) regress to old version and change code due to version incompatibility
# @see https://github.com/edf-hpc/slurm-web/issues/210
##  git clone --single-branch --branch v2.2.2 https://github.com/edf-hpc/slurm-web.git slurm-web.v2.2.2 \
##  mv -f slurm-web.v2.2.2/dashboard/js/draw/2d-draw.js slurm-web/dashboard/js/draw/\
##  rm -rf slurm-web.v2.2.2 \
##  sed -i "245 a \        if (!(Number.isInteger(Number(job)) && Number(job) >= 1)) continue;" slurm-web/dashboard/js/draw/2d-draw.js \
##  # (problem) fix a syntax error due to version incompatibility
##  sed -i "16s|'\*.wsgi'|['\*.wsgi']|" slurm-web/setup.py \
## (problem) fix "cannot find package.json" (due to possible Ubuntu 20.04?)
##tar -zxvf DejaVuSansMono.typeface.json.tar.gz
##chown root:root DejaVuSansMono.typeface.json
##sed -i "9s|nodejs.*|cp /tmp/DejaVuSansMono.typeface.json dashboard/js/fonts/DejaVuSansMono.typeface.json|" slurm-web/debian/rules
# (problem) fix a syntax error due to version incompatibility
# @see https://github.com/edf-hpc/slurm-web/issues/115#issuecomment-292572760
sed -i "493s|font.*|font: font,|" slurm-web/dashboard/js/draw/3d-draw.js
sed -i "488s|^|//|" slurm-web/dashboard/js/draw/3d-draw.js
sed -i "488 a loader.load(config.RACKNAME.FONT.PATH, function(font) {" slurm-web/dashboard/js/draw/3d-draw.js
sed -i "488 a var loader = new THREE.FontLoader();" slurm-web/dashboard/js/draw/3d-draw.js
# (problem) fix a syntax error due to version incompatibility
# @see https://stackoverflow.com/a/46395784
find slurm-web/dashboard/js/ -name "*.js" \
  -exec sed -i "s|\.success(func|\.done(func|g" {} \; \
  -exec sed -i "s|\.error(func|\.fail(func|g" {} \; \
  -exec sed -i "s|\.complete(|\.always(|g" {} \;
# (problem) fix a sematic error
sed -i "61s|users.*|users.push(tags[0]);|" slurm-web/dashboard/js/utils/tagsinput.js
# (problem) fix tablesorter errors
sed -i '13 a \    <link href="/javascript/jquery-tablesorter/css/theme.default.css" rel="stylesheet">' slurm-web/dashboard/html/index.html
sed -i "70 a \      \$('table.tablesorter').tablesorter(self.tablesorterOptions);" slurm-web/dashboard/js/modules/jobs/jobs.js
cd slurm-web
# Apply PR 219 by macdems
git apply /build/slurm-web/pr219.patch
# (patch-end)
rm -rf .git* .code* .css* .es*
tar cvfj ../slurm_web_v2.4.0.orig.tar.bz2 .
mk-build-deps -ri -t "apt-get --yes --no-install-recommends"
debuild -us -uc
cd .. 
(find . -not -name "*.deb" -exec rm -rf {} \; > /dev/null 2>&1 || true)
apt-get remove --yes node-opentypejs
apt-get purge --yes --auto-remove ${build_deps}
apt-get clean 
rm -rf /var/lib/apt/lists/*

mkdir /build/deb 
cp /tmp/*.deb /build/deb
