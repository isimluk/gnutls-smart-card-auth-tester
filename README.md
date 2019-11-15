# Container for testing smart card authentication

[![Docker Repository on Quay](https://quay.io/repository/slukasik/gnutls-smart-card-auth-tester/status "Docker Repository on Quay")](https://quay.io/repository/slukasik/gnutls-smart-card-auth-tester)

## Quick steps:
 - `podman run -it -p "5556:5556" quay.io/slukasik/gnutls-smart-card-auth-tester`
 - insert smart card and point your browser to https://127.0.0.1:5556/

## Description
Smart card authentication over HTTPS may be challenging thing to deploy. Especially, for
newcomers. At one step, You have to set-up all the components properly, you need to prepare
your smart card, configure your browser (and whole client stack with nss, opensc, pcscd,
p11-kit-proxy, etc.) and finally your server needs to be set-up properly to solicit and
validate inserted card.

When the you make even one mistake with one of the components the authentication will not
work. Usually, there will be very little debugging steps available. Fortunately, there is
very neat stub server build by [gnutls upstream](https://gitlab.com/gnutls/gnutls/)
that can be used to debug capabilities of your client browser. You can simply run

```
podman run -it -p "5556:5556" quay.io/slukasik/gnutls-smart-card-auth-tester
```

and point your browser to https://127.0.0.1:5556/
