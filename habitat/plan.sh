pkg_name=example-node
pkg_origin=core
pkg_version=12.16.1
pkg_description="Node.js® is a JavaScript runtime built on Chrome's V8 JavaScript engine."
pkg_license=('MIT')
pkg_maintainer="The Habitat Maintainers <humans@habitat.sh>"
pkg_deps=(core/glibc core/gcc-libs core/python2 core/bash)
pkg_build_deps=(core/gcc core/grep core/make core/curl)
pkg_bin_dirs=(bin)
pkg_include_dirs=(include)
pkg_interpreters=(bin/node)
pkg_lib_dirs=(lib)

do_prepare() {
  # ./configure has a shebang of #!/usr/bin/env python2. Fix it.
  cd ${HAB_CACHE_SRC_PATH}/${pkg_name}-${pkg_version}
  sed -e "s#/usr/bin/env python#$(pkg_path_for python2)/bin/python2#" -i configure
}

do_download() {
  curl -u admin:password -O http://ec2-34-216-236-150.us-west-2.compute.amazonaws.com:8081/artifactory/example-repo-local/node-v12.16.1.tar.gz
  attach
}

do_verify() {
  return 0
}

do_unpack(){ 
  tar -xzvf "node-v12.16.1.tar.gz" && mv "node-v12.16.1" "${HAB_CACHE_SRC_PATH}/${pkg_name}-${pkg_version}"
  attach
  #unzip "node-0.10.29.zip" &&  mv "node-0.10.29" "${HAB_CACHE_SRC_PATH}/${pkg_name}-${pkg_version}"
}

do_build() {
  cd ${HAB_CACHE_SRC_PATH}/${pkg_name}-${pkg_version}
  ./configure \
    --prefix "${pkg_prefix}" \
    --dest-cpu "x64" \
    --dest-os "linux"
  make -j"$(nproc)"
}

do_install() {
  attach
  cd ${HAB_CACHE_SRC_PATH}/${pkg_name}-${pkg_version}
  do_default_install

  # Node produces a lot of scripts that hardcode `/usr/bin/env`, so we need to
  # fix that everywhere to point directly at the env binary in core/coreutils.
  attach
  grep -nrlI '^\#\!/usr/bin/env' "$pkg_prefix" | while read -r target; do
    sed -e "s#\#\!/usr/bin/env node#\#\!${pkg_prefix}/bin/node#" -i "$target"
    sed -e "s#\#\!/usr/bin/env sh#\#\!$(pkg_path_for bash)/bin/sh#" -i "$target"
    sed -e "s#\#\!/usr/bin/env bash#\#\!$(pkg_path_for bash)/bin/bash#" -i "$target"
    sed -e "s#\#\!/usr/bin/env python#\#\!$(pkg_path_for python2)/bin/python2#" -i "$target"
  done

  # This script has a hardcoded bare `node` command
  sed -e "s#^\([[:space:]]\)\+node\([[:space:]]\)#\1${pkg_prefix}/bin/node\2#" -i "${pkg_prefix}/lib/node_modules/npm/bin/node-gyp-bin/node-gyp" 
}
