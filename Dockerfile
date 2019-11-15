FROM registry.fedoraproject.org/fedora:latest as builder

MAINTAINER Šimon Lukašík <isimluk@fedoraproject.org>

RUN dnf install -y 'dnf-command(builddep)' make wget diffutils file git texlive bison dash gtk-doc patch && dnf builddep -y gnutls && dnf clean all
RUN git clone --depth 1 https://gitlab.com/gnutls/gnutls

WORKDIR gnutls
RUN ./bootstrap && ./configure --disable-dane --disable-rpath --disable-guile --disable-tests --disable-doc && make
RUN cp /gnutls/src/.libs/gnutls-serv /gnutls/src/

# workaround https://github.com/containers/libpod/issues/3110 remove later
RUN cp -a /gnutls /gnutls2

FROM registry.fedoraproject.org/fedora:latest

COPY --from=builder /gnutls2 /gnutls

# workaround https://github.com/containers/libpod/issues/3110 remove later
RUN cp /gnutls/src/.libs/gnutls-serv /gnutls/src/

RUN dnf install -y autogen-libopts

WORKDIR /gnutls/doc/credentials

EXPOSE 5556

CMD exec ./gnutls-http-serv -d 4 --require-client-cert
