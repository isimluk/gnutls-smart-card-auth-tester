# Container for testing smart card authentication

This provides very simple webserver created by gnutls upstream.

```
podman run -it -p "5556:5556" gnutls-smart-card-auth-tester
```

Point your browser to https://localhost:5556/
