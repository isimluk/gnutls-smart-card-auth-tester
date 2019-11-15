# Container for testing smart card authentication

[![Docker Repository on Quay](https://quay.io/repository/slukasik/gnutls-smart-card-auth-tester/status "Docker Repository on Quay")](https://quay.io/repository/slukasik/gnutls-smart-card-auth-tester)

## Quick steps:
 - `podman run -it -p "5556:5556" quay.io/slukasik/gnutls-smart-card-auth-tester`
 - insert smart card and point your browser to https://127.0.0.1:5556/

## Description
Smart card authentication over HTTPS may be challenging thing to deploy. You need to have
browser, smart card and server set-up properly, all in one step. When the you make even
single mistake with one of the components the authentication will not work and there won't
be too many debugging. Fortunately, there is very neat stub server build by [gnutls upstream](https://gitlab.com/gnutls/gnutls/)
that can be used to debug capabilities of your client browser. You can simply run

```
podman run -it -p "5556:5556" quay.io/slukasik/gnutls-smart-card-auth-tester
```

and point your browser to https://127.0.0.1:5556/
