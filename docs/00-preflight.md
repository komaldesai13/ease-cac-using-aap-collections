# 00 — Preflight

**Playbook:** [`playbooks/00-preflight.yml`](../playbooks/00-preflight.yml)
**Changes anything?** No.
**Runtime:** ~10 seconds.

Run this before the booth opens, and again any time the venue Wi-Fi looks
suspicious. It is the only scenario that is not for the audience.

## What it checks

1. A Gateway password is actually set (the most common cause of a dead demo).
2. ansible-core is ≥ 2.16, which `ansible.platform` requires. Galaxy only warns
   about this at install time; here it is a hard stop.
3. `ansible.platform` is installed, and prints the version it found.
4. `requests` is importable by the interpreter running the playbook —
   `ansible-galaxy` does not install a collection's Python dependencies.
5. The Gateway is reachable and the credentials work — proven with a read-only
   `gateway_api` lookup, not a guess.
6. No leftovers from a previous run are sitting on the Gateway under your
   `DEMO_PREFIX`.

Checks 2–4 are environment checks: they run before anything touches the network,
so a broken laptop fails in a second with a message that says what to install.
[Setup and troubleshooting](setup-and-troubleshooting.md) explains each one.

## Run it

```bash
export AAP_HOSTNAME=https://aap.example.com
export AAP_USERNAME=admin
export AAP_PASSWORD='...'
export DEMO_PREFIX=TechGenie

ansible-playbook playbooks/00-preflight.yml
# or
./demo.sh check
```

## What you should see

```
Gateway reachable            : YES
Organizations visible        : 4
Leftovers with prefix 'TechGenie' : 0 []

READY — run playbooks/01-tenant-onboarding.yml
```

If it says `STALE STATE`, run `ansible-playbook teardown.yml` and try again.

## Why this matters beyond the booth

The Gateway check is three lines of `gateway_api` lookup, and it is the same
pattern a real pipeline uses as a gate before an apply stage: prove you can
reach and authenticate to the target before you start changing it. Failing in
ten seconds with a clear message beats failing halfway through a 400-resource
run with a partially-configured platform.

## If it fails

| Symptom | Cause |
|---|---|
| `No Gateway password` | `AAP_PASSWORD` not exported in this shell. |
| `ansible-core 2.x is too old` | Core below 2.16. Needs a venv on Python 3.10+. |
| `ansible.platform` not in the collection list | See installation in the [README](../README.md#install). |
| `cannot import 'requests'` | `pip install -r requirements.txt`, in the active venv. |
| `'aap_gateway' is undefined` | `group_vars/` moved out of `inventory/`. |
| Certificate errors | `export AAP_VALIDATE_CERTS=false` for a self-signed demo pod. |
| Connection refused / timeout | Wrong hostname, VPN down, or the pod is asleep. |

Full explanations, and the fix for each, are in
[Setup and troubleshooting](setup-and-troubleshooting.md).
