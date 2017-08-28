FROM gentoo/stage3-amd64-nomultilib

# get portage snapshot
RUN wget -O - http://distfiles.gentoo.org/snapshots/portage-latest.tar.xz | tar xJ -C /usr

RUN emerge crossdev

# create overlay
RUN mkdir -p /usr/local/portage-crossdev/{profiles,metadata}
RUN echo 'crossdev' > /usr/local/portage-crossdev/profiles/repo_name
RUN echo 'masters = gentoo' > /usr/local/portage-crossdev/metadata/layout.conf
RUN chown -R portage:portage /usr/local/portage-crossdev
RUN mkdir -p /etc/portage/repos.conf
RUN echo -e '[crossdev]\n\
location = /usr/local/portage-crossdev\n\
priority = 10\n\
masters = gentoo\n\
auto-sync = no\n' > /etc/portage/repos.conf/crossdev.conf

# optimize host make.conf
RUN sed -i \
  -e 's/CFLAGS="\(.*\)"/CFLAGS="-march=native -O2 -pipe -fomit-frame-pointer"/' \
  -e '/CXXFLAGS/ a MAKEOPTS="-j9 -l8"' \
  /etc/portage/make.conf

#ENV TARGET=aarch64-linux-android
#ENV TARGET=aarch64-unknown-linux-gnueabi
ENV TARGET=aarch64-unknown-linux-gnu
RUN crossdev --stable -v -t $TARGET

RUN sed -i \
  -e 's/CFLAGS="\(.*\)"/CFLAGS="\1 -march=armv8-a -mtune=generic"/' \
  -e 's/USE="\(.*\)"/USE="\1 -acl -test"/' \
  -e '/CXXFLAGS/ a MAKEOPTS="-j9 -l8"' \
  /usr/$TARGET/etc/portage/make.conf

# remove buildpkg from features?

ENV PROFILE=/usr/portage/profiles/default/linux/arm64/13.0
RUN rm /usr/$TARGET/etc/portage/make.profile
RUN ln -s $PROFILE /usr/$TARGET/etc/portage/make.profile
