# amigus.bind

An Ansible role to install and configure BIND 9 as a caching resolver,
forwarder,
and/or authoritative server with optional DNS-over-TLS,
and DNS-over-HTTP listeners
and optional auto-updating Response Policy Zones (RPZ).

The role supports Alpine, RedHat and OpenSUSE Linux variants.
It renders a complete `named.conf`,
sets up optional logging,
manages local RPZ files,
and can generate self-signed certificates for TLS endpoints.

It contains a stand-alone Python program that converts the domain/URL blocklists into RPZ zone files.
It also contains a shell script that invokes the Python program periodically via `cron`,
after downloading the latest version of the blocklist.

## Requirements

- Ansible 2.14+ (tested with 2.16+)
- Target OS: Alpine Linux, Rocky Linux 9 (RedHat family), openSUSE Tumbleweed
- Python 3 available on managed hosts

## Supported features

- Authoritative primary and secondary zones
- Caching resolver with configurable forwarders (forward first/only)
- Response Policy Zones (primary and secondary), with ocron-driven updates
- DNS-over-TLS and DNS-over-HTTP listeners, with automatic self-signed certs

## Role variables (overview)

Variables are grouped by feature.
See “Full variable reference” below for all options and their types.

- Core
  - `bind_usergroup` (default: `named`)
  - `bind_service_name` (default: `named`)
  - `bind_dnssec_validation` (default: `false`)
  - `bind_query_logging` (default: `false`)
  - `bind_queries_logfile` (path, optional)
  - `bind_acls`, `bind_query_acls`, `bind_recursion_acls` (access control)
  - `bind_listen_interfaces`, `bind_listen_interfaces_v6` (listener addresses)

  - Forwarding and zones
  - `bind_forward_only` (default: `false`), `bind_forwarders` (list)
  - `bind_forward_zones` (list of forward zones)
  - `bind_primary_zones` (list of primary zones), `bind_primary_zone_allow_update` (default: `none`)
  - `bind_secondary_zones` (list of secondary zones), `bind_secondary_zone_allow_transfer` (default: `none`)
  - `bind_ixfr_from_differences` (default: `true`)

  - Named root a.k.a., root.hints file
  - `bind_named_root` (OS default path)
  - `bind_named_root_url` (default: `https://www.internic.net/domain/named.root`)

  - RPZ
  - `bind_response_policy_zones` (primary RPZ definitions)
  - `bind_response_policy_secondary_zones` (secondary RPZ definitions)
  - `bind_rpz_domains`, `bind_rpz_passthru_domains` (local overrides in `rpz` zone)
  - `bind_rpz_logfile`, `bind_rpz_passthru_logfile` (optional logging)

  - TLS/DoT/DoH
  - `bind_tls` (list of TLS contexts; each defines `name`, `key_file`, `cert_file`, optional `ca_file` and listen interfaces)
  - `bind_http` (list of HTTP endpoints bound to TLS contexts)
  - `bind_tls_common_name` (CN for self-signed certs if not provided per item)
  - `bind_tls_subject_alt_name` (SANs for self-signed certs; default empty)
  - `bind_tls_key_type` (default `RSA`), `bind_tls_key_size` (default `2048`)
  - `bind_tls_selfsigned_not_after` (default `+1825d`)
  - `bind_tls_dhparam_file` (OS default path), `bind_tls_dhparam_size` (default `2048`)

OS-specific paths such as `bind_conf_file`, `bind_directory`, `bind_primary_zone_directory`, `bind_secondary_zone_directory`, and `bind_tls_dhparam_file` are set via `vars/` per-family and can be overridden if needed.

## Handlers and notifications

The role notifies handlers to reconfigure/reload via RNDC and attempts to enable/start the `named` service. In containerized CI, service start may be a no-op; configuration rendering and file setup are still validated in Molecule.

## Templates and scripts

- `templates/conf.j2` renders `named.conf` based on all variables above.
- `templates/rpz.j2` renders a local RPZ zone with passthrough and blocked domains.
- `files/genrpz.py` converts text, CSV or JSON files containing domains or URLs into response policy zones.
- `files/update-rpz.sh` downloads the latest RPZ or blocklist and runs genrpz.py on it in the latter case.

## Example playbook

```yaml
---
- hosts: dns
  become: true
  roles:
    - role: amigus.bind
      vars:
        bind_forward_only: true
        bind_forwarders: [8.8.8.8, 8.8.4.4]
        bind_tls_common_name: localhost
        bind_tls_subject_alt_name:
          - DNS:localhost
          - IP:127.0.0.1
        bind_tls:
          - name: dns_tls
            key_file: /etc/named/dns_tls.key
            cert_file: /etc/named/dns_tls.crt
        bind_http:
          - name: local
            tls: dns_tls
```

There are more in [examples](examples).

## Tags

- `install` – install packages, create log dirs
- `conf` – render `named.conf` and zones
- `rpz` – render local RPZ base zone
- `namedroot` – update root hints from internic
- `tls`, `selfsigned`, `dhparam` – certificate and DH parameter generation
- `cron`, `scripts` – RPZ update scripts and scheduling

## Full variable reference

See `meta/argument_specs.yml` for type-checked option definitions, defaults, and nested structures. This file is kept in sync with `defaults/` and `vars/`.

## Testing

This repository includes a Molecule scenario with a small matrix of Alpine, Rocky 9, and openSUSE Tumbleweed containers that exercise:

- Forwarder-only configuration with logging
- RPZ primary and secondary zones with cron-ready scripts
- DNS-over-TLS/HTTP with self-signed certificates and DH params

Run the scenario locally (requires Podman):

```bash
molecule test
```

## License

MIT

## Author

Adam Migus <adam@migus.org>
