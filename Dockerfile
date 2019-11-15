FROM registry.fedoraproject.org/fedora:latest

MAINTAINER Šimon Lukašík <isimluk@fedoraproject.org>

RUN dnf install -y 'dnf-command(builddep)' make wget diffutils file git texlive bison dash gtk-doc patch && dnf builddep -y gnutls && dnf clean all
RUN git clone --depth 1 https://gitlab.com/gnutls/gnutls

WORKDIR gnutls
RUN ./bootstrap && ./configure --disable-dane --disable-rpath --disable-guile --disable-tests --disable-doc && make

WORKDIR doc/credentials

EXPOSE 5556

CMD exec ./gnutls-http-serv -d 4 --require-client-cert
