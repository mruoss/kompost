# The `PostgresInstance` Resource

Kompost needs to know how to talk to the target Postgres server.
`PostgresInstance` and `PostgresClusterInstance` resources are used to tell
Kompost about the existence of a Postgres server and how to connect to it.

## Connection Details

The fields `host`, `port`, `username` and either one of `plainPassword` or
`passwordSecretRef` are required to successfully create a `PostgresInstance`
resource.

```yaml
apiVersion: kompost.chuge.li/v1alpha1
kind: PostgresInstance
metadata:
  name: app-database
  namespace: default
spec:
  hostname: postgres.svc
  port: 5432
  username: postgres
  passwordSecretRef:
    name: server-credentials
    key: password
```

## SSL Connection

In order to connect via SSL, you can set `spec.ssl.enabled` to `true`.

```yaml
apiVersion: kompost.chuge.li/v1alpha1
kind: PostgresInstance
metadata:
  name: app-database
  namespace: default
spec:
  hostname: postgres.svc
  port: 5432
  username: postgres
  ssl:
    enabled: true
  passwordSecretRef:
    name: server-credentials
    key: password
```

This won't verify the SSL certificate provided by the server. If you need to
verify the peer certificate, set `spec.ssl.verify` to `verify_peer` and optionally
provide a CA certificate in PEM format in `spec.ssl.ca`. If the CA is ommitted,
the verification only succeeds, if the provided certificate has been signed by
a publicly trusted CA.

```yaml
apiVersion: kompost.chuge.li/v1alpha1
kind: PostgresInstance
metadata:
  name: app-database
  namespace: default
spec:
  hostname: postgres.svc
  port: 5432
  username: postgres
  ssl:
    enabled: true
    verify: verify_peer
    ca: |
      -----BEGIN CERTIFICATE-----
      MIIDrzCCApegAwIBAgIQCDvgVpBCRrGhdWrJWZHHSjANBgkqhkiG9w0BAQUFADBh
      MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3
      d3cuZGlnaWNlcnQuY29tMSAwHgYDVQQDExdEaWdpQ2VydCBHbG9iYWwgUm9vdCBD
      QTAeFw0wNjExMTAwMDAwMDBaFw0zMTExMTAwMDAwMDBaMGExCzAJBgNVBAYTAlVT
      MRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5j
      b20xIDAeBgNVBAMTF0RpZ2lDZXJ0IEdsb2JhbCBSb290IENBMIIBIjANBgkqhkiG
      9w0BAQEFAAOCAQ8AMIIBCgKCAQEA4jvhEXLeqKTTo1eqUKKPC3eQyaKl7hLOllsB
      CSDMAZOnTjC3U/dDxGkAV53ijSLdhwZAAIEJzs4bg7/fzTtxRuLWZscFs3YnFo97
      nh6Vfe63SKMI2tavegw5BmV/Sl0fvBf4q77uKNd0f3p4mVmFaG5cIzJLv07A6Fpt
      43C/dxC//AH2hdmoRBBYMql1GNXRor5H4idq9Joz+EkIYIvUX7Q6hL+hqkpMfT7P
      T19sdl6gSzeRntwi5m3OFBqOasv+zbMUZBfHWymeMr/y7vrTC0LUq7dBMtoM1O/4
      gdW7jVg/tRvoSSiicNoxBN33shbyTApOB6jtSj1etX+jkMOvJwIDAQABo2MwYTAO
      BgNVHQ8BAf8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQUA95QNVbR
      TLtm8KPiGxvDl7I90VUwHwYDVR0jBBgwFoAUA95QNVbRTLtm8KPiGxvDl7I90VUw
      DQYJKoZIhvcNAQEFBQADggEBAMucN6pIExIK+t1EnE9SsPTfrgT1eXkIoyQY/Esr
      hMAtudXH/vTBH1jLuG2cenTnmCmrEbXjcKChzUyImZOMkXDiqw8cvpOp/2PV5Adg
      06O/nVsJ8dWO41P0jmP6P6fbtGbfYmbW0W5BjfIttep3Sp+dWOIrWcBAI+0tKIJF
      PnlUkiaY4IBIqDfv8NZ5YBberOgOzW6sRBc4L0na4UU+Krk2U886UAb3LujEV0ls
      YSEY1QSteDwsOoBrp+uvFRTp2InBuThs4pFsiv9kuXclVzDAGySj4dzp30d8tbQk
      CAUw7C29C79Fv1C5qfPrmAESrciIxpg0X40KPMbp1ZWVbd4=
      -----END CERTIFICATE-----

  passwordSecretRef:
    name: server-credentials
    key: password
```

## Credentials

### The Password Secret

On production environments the password used to connect to the server should be
stored in a secret which is then referenced inside the instance resource:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: server-credentials
  namespace: default
stringData:
  password: secure-password
```

The secret can have any shape. Use `.spec.passwordSecretRef.key` to pass the key
inside the secret holding the password.

```yaml
apiVersion: kompost.chuge.li/v1alpha1
kind: PostgresInstance
metadata:
  name: app-database
  namespace: default
spec:
  hostname: postgres.svc
  port: 5432
  username: postgres
  passwordSecretRef:
    name: server-credentials
    key: password
```

### Plain Password inside the Instance

!!! warning Only use for testing

    Only use this for testing purposes and use dummy passwords
    inside `PostgresInstance` resources.

Instead of referencing a secret, you can pass the password directly inside the
instance resource:

```yaml
apiVersion: kompost.chuge.li/v1alpha1
kind: PostgresInstance
metadata:
  name: app-database
  namespace: default
spec:
  hostname: postgres.svc
  port: 5432
  username: postgres
  plainPassword: dummy-password
```

## Checking the Status of the Resource

In order to check the resource's status, use `kubectl describe` and look out for
the list of conditions in `status.conditions`. If all the `Status` fields are
`True`, you're good to go.

```sh
$ kubectl describe pginst app-database

[...]
Status:
  Conditions:
    Last Heartbeat Time:   2023-02-26T18:21:35.683152Z
    Last Transition Time:  2023-02-26T18:21:16.417437Z
    Message:               Connection to database was established
    Status:                True
    Type:                  Connected
    Last Heartbeat Time:   2023-02-26T18:21:35.683135Z
    Last Transition Time:  2023-02-26T18:21:16.343485Z
    Status:                True
    Type:                  Credentials
    Last Heartbeat Time:   2023-02-26T18:21:35.696358Z
    Last Transition Time:  2023-02-26T18:21:16.434984Z
    Message:               The conneted user has the required privileges
    Status:                True
    Type:                  Privileged
  Observed Generation:     1
Events:
  Type     Reason      Age   From     Message
  ----     ------      ----  ----     -------
  Warning  Failed Add  24s   kompost  tcp connect (postgres.svc:5432): connection refused - :econnrefused
```
