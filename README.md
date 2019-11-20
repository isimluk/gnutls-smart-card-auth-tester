# Container for testing smart card authentication

[![Docker Repository on Quay](https://quay.io/repository/slukasik/gnutls-smart-card-auth-tester/status "Docker Repository on Quay")](https://quay.io/repository/slukasik/gnutls-smart-card-auth-tester)

## Quick steps:
 - `podman run -it -p "5556:5556" quay.io/slukasik/gnutls-smart-card-auth-tester`
 - insert smart card and point your browser to https://127.0.0.1:5556/

 ---


# Blog from [isimluk.com](http://isimluk.com/posts/2019/11/how-to-debug-smart-card-authentication-client/)

## Dummy intro to smart card authentication
Smart card authentication is just like authentication with certificates and private keys (X509, PKI).
The difference is that instead of fetching your private key and certificate from the disk, you let
smart card do the cryptographic operations for you and private key never leaves the card. Special
protocols are used on the client to allow communication between browser and the smart card.

## Setting things can be difficult
Smart card authentication over HTTPS may be challenging thing to deploy. Especially, for
newcomers. At one step You have to set-up all the components properly.

 - First of all, you need to prepare your smart card, PIV, and make sure proper X509 key and certificate is present.
 - Then You need to configure your browser and whole client stack with nss, opensc, pcscd, p11-kit-proxy, etc).
 - Finally, your server needs to be set-up properly to solicit and validate inserted card.

When the you make even one mistake with one of the components the authentication will not
work. And there will be very little debugging steps available. What You need to do is to
test each component alone to identify which component is not set-up properly.

Good idea is to start debug client parts (the card & the browser).

## GnuTLS test server with stock CA & certificates

[GnuTLS upstream](https://gitlab.com/gnutls/gnutls/) provides minimalistic HTTPS server that logs detailed
debugging information about what the client system is sending over. You can either compile the gnutls from
sources or you can start in no time with single-purpose container

    podman run -it \
        -p "5556:5556" \
        quay.io/slukasik/gnutls-smart-card-auth-tester

Upon this command, you will have HTTPS server running on localhost on port 5556, point your browser
to https://127.0.0.1:5556/

You will be presented with browser warning about unknown certificate. This is expected. The server running
in the container does not contain certificate signed by any of the well known certificate authorities. You
are safe to accept the risk and continue.

![warning](http://isimluk.com/blog-pics/2019-smartcard/01-warning.jpg)

After accepting the risk, your connection will fail.

![warning](http://isimluk.com/blog-pics/2019-smartcard/02-failed.jpg)


You can now review the server logs in the podman container.

```
* Received alert '46': Unknown certificate.
Error in handshake: A TLS fatal alert has been received.
```

The failure here is caused by the fact that client and server cannot build shared trust.
Our server never saw your smart card in action and thus it should not admit the user in.

To fix the above error we either need the smart card certificate to be signed. And CA of
the signature needs to be known by our server.

## GnuTLS test server with particular CA and stock certificates

In an easy case, where you already have your smartcard signed and CA certificate is available
to You. You can restart the gnutls container with bindmouted CA to proper location. Following
command assumes the CA certificate in `ca.crt.pem`.

```
podman run -it -p "5556:5556" \
    --mount type=bind,source=ca.crt.pem,target=/gnutls/doc/credentials/x509/ca.pem \
    quay.io/slukasik/gnutls-smart-card-auth-tester
```

## GnuTLS test server with custom CA and custom certificates
### Getting smart card signed
In case you don't have smart card signed and do not have access to the CA. You can generate your own CA
and get your smartcard secrets signed by that. There are two ways to achieve this, either you generate keys
outside of smart cards and upload it to the card, or you let card generate the keys and CSR (Certificate
Signing Request) and after your CA signs the CSR you upload resulting certificate to the card. The latter
option is preferential as private key never leaves the card.

### Create your own CA

```
mkdir ca
cd ca/
mkdir newcerts certs crl private requests
touch index.txt
echo 1000 > serial

# Download dummy config for your testing CA
wget http://isimluk.com/blog-data/2019-smart_card/openssl_root.cnf

# Generate private key
openssl ecparam -genkey -name secp384r1 \
    | openssl ec -aes256 -out private/ca.key.pem

# Generate certificate for the private key
openssl req -config openssl_root.cnf -new -x509 -sha384 \
    -extensions v3_ca -key private/ca.key.pem -out certs/ca.crt.pem

# Check created certificate
openssl x509 -noout -text -in certs/ca.crt.pem
```

### Generate CSR on the card

Consult your smart card manual on how to generate Certificate Signing Request.

### Sign the CSR by Your CA

```
# verify CSR is well formed
openssl req -verify -in CSRfromCard.csr -text -noout

# sign CSR
openssl x509 -req -days 360 -in CSRfromCard.csr \
    -CA certs/ca.crt.pem -CAkey private/ca.key.pem
    -CAcreateserial -out signedCardCert.crt

# checked singned certificate
openssl x509 -text -noout -in signedCardCert.crt
```

### Upload the signed certificate to your smart card
Consult your smart card manual on how to upload the certificate.
Make sure to not remove your private key that remains still on the smart card.

### Create your own server certificates
Now, when we have client keys in place. We can generate keys for server as well.

```
openssl req -x509 -newkey rsa:2048 -days 365 -nodes \
    -keyout serverPrivate.key \
    -out serverCert.pem \
    -subj '/CN=mycert'
```

## GnuTLS test server with custom CA & certificates

```
podman run -it -p "5556:5556" \
    --mount type=bind,source=$(pwd),target=/certs \
    quay.io/slukasik/gnutls-smart-card-auth-tester \
    ../../src/gnutls-serv -d 4 --require-client-cert \
        --x509cafile /certs/ca/certs/ca.crt.pem \
        --x509certfile /certs/serverCert.pem \
        --x509keyfile /certs/serverPrivate.key
```

Now, when you visit yours https://127.0.0.1:5556/ you will be asked for the PIV pin for your smart card.

![success](/blog-pics/2019-smartcard/03-pinentry.jpg)

Upon correct PIV pin entry, smart card will offer keys(s) on the card for you to select appropriate key
for this test server.

![success](http://isimluk.com/blog-pics/2019-smartcard/04-select-cert.jpg)

Voilà! Success page shows up.

![success](http://isimluk.com/blog-pics/2019-smartcard/03-success.jpg)

*Kudos go to [Jakub Jelen](https://github.com/jakuje) who hinted GnuTLS server to me. Thank You Jakube!*
