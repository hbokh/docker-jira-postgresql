## Self signed certificate (SSC)

In file `self_signed_cert.sh` change the DOMAIN-value on line 3 into whatever FQDN you want.

Run `./self_signed_cert.sh` from this directory to generate a new SSC.

Inspect the certificate with `openssl x509 -text -noout -in jira.internal.crt`.
