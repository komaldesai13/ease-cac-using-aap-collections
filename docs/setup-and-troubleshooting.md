# Setup and troubleshooting

Everything the [README Install section](../README.md#install) does, and why each
step exists. Read this if `./demo.sh check` will not go green, or if you are
setting the demo up on a fresh laptop the morning of the event.

The short version: **a working environment is a Python 3.10+ virtualenv with
ansible-core ≥ 2.16, two collections, and the `requests` package.** Miss any one
of those and preflight stops with a specific message. Each is covered below.

---

## The four moving parts

| Part | Requirement | Installed by |
|---|---|---|
| Python | 3.10 or newer | your OS / `python3 -m venv .venv` |
| ansible-core | ≥ 2.16 | `pip install 'ansible-core>=2.16'` |
| `ansible.platform` | 2.7 branch | `ansible-galaxy collection install -r requirements.yml` |
| `ansible.posix` | any | same command |
| `requests` | any | `pip install -r requirements.txt` |

From a clean checkout:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install 'ansible-core>=2.16'
ansible-galaxy collection install -r requirements.yml
pip install -r requirements.txt
./demo.sh check
```

`.venv/` is gitignored. **Activate it in every shell you demo from** — `demo.sh`
just calls `ansible-playbook`, so it uses whatever is on your PATH.

---

## Why ansible-core 2.16 is a hard requirement

`ansible.platform` declares `requires_ansible: ">=2.16.0"` in its
`meta/runtime.yml`. On an older core, `ansible-galaxy` installs the collection
anyway and only prints a warning:

```
[WARNING]: Collection ansible.platform does not support Ansible version 2.15.13
```

That warning is easy to scroll past, and the failure it predicts arrives later —
typically mid-scenario, in front of people. Preflight turns it into an upfront
assert instead.

The knock-on constraint: **ansible-core 2.16 requires Python 3.10+ on the
control node.** A stock macOS Python 3.9 caps you at ansible-core 2.15, so there
is no upgrade path within an existing 3.9 venv — you need a new one on a newer
interpreter. Python 3.14 works fine (ansible-core 2.21 supports it).

---

## Why `pip install -r requirements.txt` is a separate step

`ansible-galaxy` installs a collection's *content*. It does **not** install the
collection's Python dependencies, even though `ansible.platform` ships a
`requirements.txt` asking for `requests`.

`requests` is imported inside the collection's platform-manager process, so
skipping this step gets you all the way to the Gateway call before failing —
with the real cause buried in a `multiprocessing` traceback:

```
ModuleNotFoundError: No module named 'requests'
```

It must land in the **same interpreter that runs `ansible-playbook`**, which is
why activating the venv first matters.

---

## Where `group_vars/` lives, and why

Connection settings are in **`inventory/group_vars/`**, next to
`inventory/demo.ini` — *not* at the repo root.

Ansible auto-loads `group_vars/` from exactly two places: beside the inventory,
and beside the playbook being run. The playbooks in this repo live in
`playbooks/`, so a root-level `group_vars/` would load for `site.yml` but be
invisible to every scenario, producing:

```
The conditional check 'aap_gateway.password | length > 0' failed.
'aap_gateway' is undefined
```

Keeping it beside the inventory means it loads for every playbook regardless of
where the file sits. If you add a playbook, put it in `playbooks/` and this
keeps working.

---

## The `yaml` stdout callback is gone

`ansible.cfg` used to set `stdout_callback = yaml` for readable block output at
the back of a room. That callback was removed from ansible-core in 2.19, and its
`community.general` replacement was removed in that collection's 12.0.0 — both
fallbacks are dead ends on a current core.

The supported equivalent, and what `ansible.cfg` uses now:

```ini
stdout_callback = default
result_format = yaml
```

Output is unchanged. If you see `Could not load 'yaml' callback plugin`, you are
on an `ansible.cfg` from before this change.

---

## Symptom → cause

| Symptom | Cause | Fix |
|---|---|---|
| `'aap_gateway' is undefined` | `group_vars/` not beside the inventory | it belongs in `inventory/group_vars/` |
| `No Gateway password` | `AAP_PASSWORD` not exported in this shell | `export AAP_PASSWORD='...'` |
| `ansible-core 2.x is too old` | core below 2.16 | new venv on Python 3.10+, `pip install 'ansible-core>=2.16'` |
| `Collection ansible.platform does not support Ansible version` | same as above, as a galaxy warning | same as above |
| collection list prints nothing | install did not take, or wrong venv | re-run with `--force`, check `which ansible` |
| `ModuleNotFoundError: No module named 'requests'` | galaxy does not install Python deps | `pip install -r requirements.txt` |
| `Could not load 'yaml' callback plugin` | stale `ansible.cfg` | `stdout_callback = default` + `result_format = yaml` |
| `Failed to resolve '<host>'` | wrong `AAP_HOSTNAME`, VPN down, pod asleep | check the hostname and your network |
| Certificate errors | self-signed demo pod | `export AAP_VALIDATE_CERTS=false` |
| `STALE STATE` from preflight | leftovers under your `DEMO_PREFIX` | `ansible-playbook teardown.yml` |

---

## Verifying without an AAP

You do not need a reachable Gateway to confirm the toolchain is sound. Point it
at a hostname that does not exist and run preflight:

```bash
AAP_HOSTNAME=https://nope.invalid AAP_PASSWORD=x ./demo.sh check
```

Every environment check should pass and the run should fail only at *"Reach the
Gateway and count organizations"* with a DNS error. That means Python,
ansible-core, both collections and `requests` are all correct, and the only
thing left is pointing at a real AAP.
