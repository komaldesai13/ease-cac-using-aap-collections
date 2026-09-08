# 05 — Connection modes, and why persistent connections matter

**Playbook:** [`playbooks/05-connection-modes.yml`](../playbooks/05-connection-modes.yml)
**Requires:** nothing — it creates and removes its own probe organization.
**Changes anything?** No net change; it cleans up after itself.
**Runtime:** ~1–3 minutes for all three modes.

The performance scenario. `ansible.platform` can reach the Gateway three ways,
and for a large Configuration-as-Code run the difference is most of the wall
clock.

## The three modes

| Mode | Inventory group | What happens |
|---|---|---|
| **local** | `aap_local` | The module's action plugin runs on the control node and makes the API calls itself. The default; nothing to configure. |
| **http-direct** | `aap_http_direct` | The `ansible.platform.http` connection plugin handles transport. Each task opens a fresh session. |
| **http-persistent** | `aap_http_persistent` | Same plugin, but one manager process authenticates once and every task in the play reuses that session. |

The wiring for each lives in [`group_vars/`](../group_vars/) — one short file per
group, which is the whole configuration burden.

## Run it

```bash
./demo.sh 05          # runs all three back to back and prints each elapsed time
```

Or one at a time:

```bash
ansible-playbook playbooks/05-connection-modes.yml -l aap_local
ansible-playbook playbooks/05-connection-modes.yml -l aap_http_direct
ansible-playbook playbooks/05-connection-modes.yml -l aap_http_persistent
```

Each run does the same ten API round trips and times itself.

## What you should see

```
Mode         : aap-persistent
Round trips  : 10
Elapsed      : 6s
Idempotent   : True
```

Compare the `Elapsed` line across the three runs. Persistent should be the
fastest, and the gap widens with the number of tasks — ten round trips is a
hint, four hundred is the real story.

> Numbers depend on your pod, your network and the conference Wi-Fi. Read them
> off the screen; don't promise a figure in advance.

## The point to make

> "All three produced identical results — the assert at the end checks that. The
> connection mode is a **performance** decision, not a **correctness** one. You
> pick it based on how big your run is, and nothing in your playbooks changes."

That is worth dwelling on. In most tools, changing transport means changing
code. Here it is one line of inventory.

## Details worth pointing out

**Where the time goes.** In direct mode every task pays for a fresh TCP
connection, a fresh TLS handshake, and a fresh authentication. Persistent mode
pays once for the play. The API work is identical — the overhead is not.

**`persistent_manager_idle_timeout`.** The manager process exits after an hour
of inactivity by default. Set it lower on a shared control node, or `0` to
disable idle shutdown.

**Messages about an "ephemeral manager".** Lines like `using ephemeral manager`
or `Shutting down ephemeral manager` are informational, not errors. Expect them
in local mode.

## Why this matters beyond the booth

A real customer's CaC repository is not five resources, it is several hundred:
every organization, team, credential, project and job template in the estate.
At that size, per-task re-authentication is the dominant cost, and a run that
takes forty minutes gets scheduled weekly instead of on every merge.

Making the run fast is what makes it *frequent*, and frequency is what actually
keeps drift out. A drift check that runs nightly catches a Friday change on
Saturday. One that runs monthly catches it in the audit.

## Next

[06 — Audit report](06-audit-report.md).
