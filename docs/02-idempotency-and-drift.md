# 02 — Idempotency and drift detection

**Playbook:** [`playbooks/02-idempotency-and-drift.yml`](../playbooks/02-idempotency-and-drift.yml)
**Requires:** [scenario 01](01-tenant-onboarding.md) to have run.
**Changes anything?** Yes, temporarily — it plants drift and then corrects it.
**Runtime:** ~30 seconds.

This is the scenario that wins the argument. If you only have five minutes at
the booth, run this one.

## Run it

```bash
ansible-playbook playbooks/01-tenant-onboarding.yml   # if not already applied
ansible-playbook playbooks/02-idempotency-and-drift.yml
# or
./demo.sh 02
```

## The four acts

| Act | What happens | The line to say |
|---|---|---|
| **1** | Re-apply the identical config → `changed=0` | "Same command, zero changes. That's why this can run from CI on every commit." |
| **2** | The playbook edits an org description out of band | "Now I'm the colleague who fixes something at 2am and forgets to tell anyone." |
| **3** | `--check --diff` finds the drift, writes nothing | "Nothing is being written. This is a diff between production and `main`." |
| **4** | Re-apply → drift corrected, then re-verified | "And we're back in sync, without anyone deciding what 'in sync' means." |

Act 3 is the one people lean forward for. Let the drift report sit on screen.

## What you should see

```
Resources checked   : 2
Resources drifted   : 1
Drifted             : ['TechGenie-Engineering']
```

## Details worth pointing out

**Act 1 is not a trick.** The playbook asserts `changed == 0` and fails loudly
if anything reported a change. Idempotency here is a tested property, not a
claim on a slide.

**Act 3 writes nothing.** `check_mode: true` plus `diff: true` on the same tasks
that do the applying. There is no separate "plan" tool to keep in sync with the
"apply" tool — it is one code path with a flag.

**Act 4 corrects exactly one resource.** The undrifted organization is left
alone, because it already matches. Convergence, not redeployment.

## Why this matters beyond the booth

Configuration drift is not usually malice; it is a Friday-evening fix that never
made it back into the repo. The cost shows up months later when staging and
production quietly stop behaving the same way, and nobody can say when they
diverged.

Two things follow from this scenario:

**A nightly read-only drift job.** Schedule `--check --diff`, fail the job when
anything reports changed, and route it to a ticket. You find out about drift on
a Tuesday morning from a report, instead of during an incident.

**A plan step in the pipeline.** Run `--check --diff` on every pull request and
post the output as a comment. Reviewers see the actual effect of the change on
the actual environment before approving — not just the YAML diff.

```bash
# nightly compliance job
ansible-playbook site.yml --check --diff

# in a merge request
ansible-playbook site.yml --check --diff | tee plan.txt
```

## Next

[03 — RBAC as code](03-rbac-as-code.md).
