# ns8-kutt

[Kutt](https://github.com/thedevs-network/kutt) URL shortener for
[NethServer 8](https://github.com/NethServer/ns8-core): short links with
custom addresses and domains, visit statistics, expiration, password
protection, a REST API and browser extensions.

The module runs the official images, following Kutt's
[`docker-compose.postgres.yml`](https://github.com/thedevs-network/kutt/blob/main/docker-compose.postgres.yml):

| Container | Image | Role |
|---|---|---|
| `kutt-app` | `docker.io/kutt/kutt` | Kutt, port 3000, published on 127.0.0.1 for Traefik |
| `postgresql-app` | `docker.io/postgres` (alpine) | database, `postgres-data` volume |
| `redis-app` | `docker.io/redis` (alpine) | cache, no persistence |

The image versions are in `build-images.sh`, in the format Renovate reads.

## Install

Instantiate the module with:

    add-module ghcr.io/geniusdynamics/kutt:latest 1

The output of the command returns the instance name:

    {"module_id": "kutt1", "image_name": "kutt", "image_url": "ghcr.io/geniusdynamics/kutt:latest"}

## Configure

Configure the instance from the Settings page, or with `configure-module`.
Only `host` is required; any setting left out keeps its current value (the
Kutt default on the first configuration).

```
api-cli run configure-module --agent module/kutt1 --data - <<EOF
{
  "host": "kutt.example.org",
  "http2https": true,
  "lets_encrypt": false,
  "site_name": "Kutt",
  "link_length": 6,
  "disallow_registration": true,
  "disallow_anonymous_links": true
}
EOF
```

Then open `https://kutt.example.org`: on the first visit Kutt asks to
create the admin account.

### Settings

The Settings page groups the variables of Kutt's
[`.example.env`](https://github.com/thedevs-network/kutt/blob/main/.example.env):

| Section | `configure-module` field | Kutt variable | Default |
|---|---|---|---|
| Site and links | `site_name` | `SITE_NAME` | `Kutt` |
| | `link_length` | `LINK_LENGTH` | `6` |
| | `link_custom_alphabet` | `LINK_CUSTOM_ALPHABET` | without look-alike characters |
| Access | `disallow_registration` | `DISALLOW_REGISTRATION` | `true` |
| | `disallow_anonymous_links` | `DISALLOW_ANONYMOUS_LINKS` | `true` |
| | `disallow_login_form` | `DISALLOW_LOGIN_FORM` | `false`, needs OIDC |
| | `enable_rate_limit` | `ENABLE_RATE_LIMIT` | `false` |
| Custom domains | `server_ip_address` | `SERVER_IP_ADDRESS` | empty |
| | `server_cname_address` | `SERVER_CNAME_ADDRESS` | empty |
| | `custom_domain_use_https` | `CUSTOM_DOMAIN_USE_HTTPS` | `false` |
| Contact and e-mail | `mail_from` | `MAIL_FROM` | `<site name> <noreply@<host>>` |
| | `report_email` | `REPORT_EMAIL` | empty |
| | `contact_email` | `CONTACT_EMAIL` | empty |
| OpenID Connect | `oidc_enabled` | `OIDC_ENABLED` | `false` |
| | `oidc_issuer` | `OIDC_ISSUER` | empty |
| | `oidc_client_id` | `OIDC_CLIENT_ID` | empty |
| | `oidc_client_secret` | `OIDC_CLIENT_SECRET` | empty; an empty value keeps the saved secret |
| | `oidc_scope` | `OIDC_SCOPE` | `openid profile email` |
| | `oidc_email_claim` | `OIDC_EMAIL_CLAIM` | `email` |
| | `oidc_prompt` | `OIDC_PROMPT` | empty |
| | `oidc_button_text` | `OIDC_BUTTON_TEXT` | `Log in with OIDC` |

For OpenID Connect, register `https://<host>/login/oidc` as the redirect URL
of the Kutt client in the provider.

The module sets the other variables itself:

- `DEFAULT_DOMAIN` is `host`, `PORT` is 3000 and `TRUST_PROXY` is `true`
  (Traefik passes the visitor address).
- `DB_*` point to PostgreSQL and `REDIS_*` to Redis, on 127.0.0.1 in the pod.
- `JWT_SECRET` and the database password are random, generated at install.
- `MAIL_*` come from the cluster smarthost (see below).

Custom domains need their own Traefik route and certificate: Kutt only
answers for them once the requests reach it.

### Secrets

The secrets never go to the module environment (Redis):

- `state/passwords.env` (mode 0600): `DB_PASSWORD`, `JWT_SECRET` and
  `OIDC_CLIENT_SECRET`
- `state/postgres.env` (mode 0600): the PostgreSQL user, database and
  password
- `state/kutt.env` and `state/smarthost.env` (mode 0600): the settings
  passed to Kutt

`get-configuration` returns `oidc_client_secret_set`, never the secret.

## Get the configuration

    api-cli run get-configuration --agent module/kutt1

## Smarthost setting discovery

Kutt sends e-mail for password reset, e-mail verification and link
reports. Before `kutt-app` starts, `bin/discover-smarthost` writes the
`MAIL_*` settings from the cluster smarthost to `smarthost.env`. Without a
smarthost e-mail is off. The `smarthost-changed` event restarts `kutt-app`.

## Backup and restore

The backup holds a `pg_dump` of the database (`kutt.pg_dump`), the secrets
and the `kutt-custom` volume (custom styles and images in `/kutt/custom`).
Restore loads the dump into a new database and configures the instance with
the saved settings. Let's Encrypt stays off after a restore or a clone,
because the DNS name may not point to the new node yet; turn it on again
from the Settings page.

## Update

    api-cli run update-module --data '{"module_url":"ghcr.io/geniusdynamics/kutt:latest","instances":["kutt1"],"force":true}'

Kutt runs its database migrations at every start.

## Uninstall

    remove-module --no-preserve kutt1

## Debug

    runagent -m kutt1 env
    runagent -m kutt1 podman ps
    runagent -m kutt1 podman logs kutt-app
    journalctl -t kutt1

## Testing

The QEMU suite in `tests/` installs, configures and removes the module, and
checks that Kutt answers through Traefik and that the secrets stay out of
the environment. To run it on a node:

    ./test-module.sh <NODE_ADDR> ghcr.io/geniusdynamics/kutt:latest

## UI translation

Translated with [Weblate](https://hosted.weblate.org/projects/ns8/).
