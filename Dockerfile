FROM ghcr.io/linuxserver/baseimage-kasmvnc:alpine318

# set version label
ARG BUILD_DATE
ARG VERSION
ARG FIREFOX_VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="thelamer"

# title
ENV TITLE=Firefox

RUN \
  echo "**** install packages ****" && \
  if [ -z ${FIREFOX_VERSION+x} ]; then \
    FIREFOX_VERSION=$(curl -sL "http://dl-cdn.alpinelinux.org/alpine/v3.18/community/x86_64/APKINDEX.tar.gz" | tar -xz -C /tmp \
    && awk '/^P:firefox$/,/V:/' /tmp/APKINDEX | sed -n 2p | sed 's/^V://'); \
  fi && \
  apk add --no-cache \
    firefox==${FIREFOX_VERSION} \
    font-noto-cjk && \
  sed -i 's|</applications>|  <application title="Mozilla Firefox" type="normal">\n    <maximized>yes</maximized>\n  </application>\n</applications>|' /etc/xdg/openbox/rc.xml && \
  echo "**** default firefox settings ****" && \
  FIREFOX_SETTING="/usr/lib/firefox/browser/defaults/preferences/firefox.js" && \
  echo 'pref("datareporting.policy.firstRunURL", "");' > ${FIREFOX_SETTING} && \
  echo 'pref("datareporting.policy.dataSubmissionEnabled", false);' >> ${FIREFOX_SETTING} && \
  echo 'pref("datareporting.healthreport.service.enabled", false);' >> ${FIREFOX_SETTING} && \
  echo 'pref("datareporting.healthreport.uploadEnabled", false);' >> ${FIREFOX_SETTING} && \
  echo 'pref("trailhead.firstrun.branches", "nofirstrun-empty");' >> ${FIREFOX_SETTING} && \
  echo 'pref("browser.aboutwelcome.enabled", false);' >> ${FIREFOX_SETTING} && \
  echo "**** add langpacks ****" && \
  FIREFOX_VERSION=$(curl -sI https://download.mozilla.org/?product=firefox-latest | awk -F '(releases/|/win32)' '/Location/ {print $2}') && \
  RELEASE_URL="https://releases.mozilla.org/pub/firefox/releases/${FIREFOX_VERSION}/win64/xpi/" && \
  LANGS=$(curl -Ls ${RELEASE_URL} | awk -F '(xpi">|</a>)' '/href.*xpi/ {print $2}' | tr '\n' ' ') && \
  EXTENSION_DIR=/usr/lib/firefox/distribution/extensions/ && \
  mkdir -p ${EXTENSION_DIR} && \
  for LANG in ${LANGS}; do \
    LANGCODE=$(echo ${LANG} | sed 's/\.xpi//g'); \
    echo "Downloading ${LANG} Language pack"; \
    curl -o \
      ${EXTENSION_DIR}langpack-${LANGCODE}@firefox.mozilla.org.xpi -Ls \
      ${RELEASE_URL}${LANG} ; \
  done && \
  echo "**** cleanup ****" && \
  rm -rf \
    /tmp/*

# add local files
COPY /root /

# ports and volumes
EXPOSE 3000

VOLUME /config
