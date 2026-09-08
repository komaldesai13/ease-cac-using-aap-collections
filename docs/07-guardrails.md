# 07 — Platform guardrails: settings and feature flags

**Playbook:** [`playbooks/07-guardrails.yml`](../playbooks/07-guardrails.yml)
**Data:** [`vars/guardrails.yml`](../vars/guardrails.yml)
**Requires:** nothing.
**Changes anything?** Temporarily — it restores the original value before it exits.
**Runtime:** ~15 seconds.

Compliance baselines are usually a PDF. "Session timeout must be 30 minutes"
sits in a document, and whether it *is* 30 minutes is anyone's guess until an
audit.

## Safety on a shared AAP

The playbook reads the current value first, applies the baseline, proves
idempotency, and then restores what it found — from an `always:` block, so the
restore happens even if a task in the middle fails. The pod is handed back
exactly as it was found.

Feature flags are **reported, not flipped**. Changing product feature flags on
a shared demo environment would be rude, and reading them makes the same point.

## Run it

```bash
ansible-playbook playbooks/07-guardrails.yml
# or
./demo.sh 07
```

## What you should see

```
Policy says   : SESSION_COOKIE_AGE = 1800
Reality is    : SESSION_COOKIE_AGE = 3600
Compliant     : False
...
Changed from : 3600
Changed to   : 1800
...
SESSION_COOKIE_AGE restored to 3600
```

## Details worth pointing out

**`check_mode` gives you a read.** The settings module reports `old_values`
without writing anything, so the "are we compliant?" question is answerable
without the authority to change the answer. A read-only token
([scenario 08](08-token-lifecycle.md)) can run this.

**The result is self-documenting.** `old_values` and `new_values` come back in
the task result, so the change record writes itself:

```yaml
enforced.settings.old_values.SESSION_COOKIE_AGE  # 3600
enforced.settings.new_values.SESSION_COOKIE_AGE  # 1800
```

Pipe that into your change-management system and the ticket fills itself in.

**`state: enforced`.** Available on most modules in this collection. Where
`present` only reconciles the keys you supplied, `enforced` also resets
unspecified options to their defaults — for a security baseline that is usually
what you want, because it closes the gap where someone sets a field you never
thought to declare.

## Why this matters beyond the booth

The gap this closes is between *having* a policy and *enforcing* one.

A baseline in a document is checked when someone remembers. A baseline in this
repo is checked on every pipeline run, and the diff between policy and reality
is a number your dashboard can graph. Session lifetime is a real control — CIS
and PCI-DSS 8.2.8 both specify it — which is why it makes an honest example
rather than a toy one.

Scheduled nightly with `--check`, a non-zero changed count is a genuine
compliance finding, raised the morning after it happened rather than at the
next audit.

## Next

[08 — Token lifecycle](08-token-lifecycle.md).
