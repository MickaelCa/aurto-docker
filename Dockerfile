FROM archlinux

ENV USER_ID="1002" \
    TZ="Europe/Paris" \
    GOSU_VERSION="1.11"

COPY --chown=root:root sudo_config /etc/sudoers.d/aurto_sudo

WORKDIR /tmp

# base setup
RUN cd /tmp; \
    chmod -R 750 /etc/sudoers.d; \
    pacman -Syu --noconfirm; \
    pacman -S base-devel --noconfirm; \
    useradd -u ${USER_ID} -G wheel -m aurto;

# install gosu
RUN cd /tmp; \
    mkdir gosu; \
    cd gosu; \
    curl -L https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-amd64 > gosu; \
    curl -L https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-amd64.asc > gosu.asc; \
    gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
    gpg --batch --verify gosu.asc gosu; \
    mv gosu /usr/local/bin/gosu; \
    chmod +x /usr/local/bin/gosu

# Install aurutils
RUN cd /tmp; \
    curl -L https://aur.archlinux.org/cgit/aur.git/snapshot/aurutils.tar.gz | tar xz; \
    chown -R aurto aurutils; \
    cd aurutils; \
    gosu aurto gpg --recv-keys DBE7D3DD8C81D58D0A13D0E76BC26A17B9B7018A; \
    gosu aurto makepkg -srci --noconfirm

# install aurto
RUN cd /tmp; \
    curl -L https://aur.archlinux.org/cgit/aur.git/snapshot/aurto.tar.gz | tar xz; \
    chown -R aurto aurto; \
    cd aurto; \
    sed -i -e 's/systemctl enable --now/systemctl enable/g' aurto.install; \
    gosu aurto makepkg -srci --noconfirm

WORKDIR /home/aurto

# cleanup && timezone
RUN rm -r /tmp/*; \
    pacman -Sy; \
    pacman -Rs base-devel --noconfirm; \
    ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime && echo ${TZ} > /etc/timezone

ENTRYPOINT ["/lib/systemd/systemd"]

VOLUME /etc/aurto /var/cache/pacman/aurto



