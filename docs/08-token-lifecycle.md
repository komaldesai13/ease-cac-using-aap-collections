# 08 — Short-lived tokens instead of long-lived passwords

**Playbook:** [`playbooks/08-token-lifecycle.yml`](../playbooks/08-token-lifecycle.yml)
**Requires:** nothing.
**Changes anything?** It creates two tokens and revokes both before exiting.
**Runtime:** ~15 seconds.

A CI pipeline that runs Configuration as Code needs credentials. The lazy answer
is to give it the admin password and never rotate it.

## Run it

```bash
ansible-playbook playbooks/08-token-lifecycle.yml
# or
./demo.sh 08
```

## What it does

1. Mints a **read-only** token — the right credential for a nightly drift or
   audit job. It literally cannot change anything.
2. Makes a real Gateway call **authenticated with that token**, not with the
   password.
3. Mints a **read+write** token for the apply job.
4. Revokes both from an `always:` block, so they go away even if something
   above failed.

## The demo move

Point at the authentication task and name what is missing from it:

```yaml
- ansible.platform.organization:
    name: Default
    state: exists
    aap_hostname: "{{ aap_gateway.hostname }}"
    aap_token: "{{ ansible_facts.aap_token.token }}"
```

> "There's no password on this task. We're authenticating with a credential that
> did not exist sixty seconds ago and won't exist in another sixty. If this
> build log leaks tomorrow, the token in it is already dead."

## Details worth pointing out

**The token publishes itself.** `ansible.platform.token` sets
`ansible_facts.aap_token`, so downstream tasks pick it up with no copy-paste and
no `set_fact` dance.

**Scope is blast radius.** A `read` token cannot modify the platform even if the
playbook it is handed tries to. Give the nightly drift job the read token and
the deploy job the write token, and a bug in the audit pipeline cannot damage
production.

**Revoke in `always:`.** A token you forget to revoke is just a password with
extra steps. The `always:` block is what makes it genuinely short-lived rather
than nominally short-lived.

## The pattern in a pipeline

```yaml
# 1. mint, scoped to the job
- ansible.platform.token:
    description: "pipeline {{ ci_job_id }}"
    scope: write
    state: present

# 2. the entire CaC run uses ansible_facts.aap_token

# 3. revoke, in a step that always runs
- ansible.platform.token:
    existing_token_id: "{{ ansible_facts.aap_token.id }}"
    state: absent
```

The token's lifetime is the job's lifetime.

## Why this matters beyond the booth

Automation credentials are the ones that never get rotated, because rotating
them means finding every pipeline that uses them. Minting per-run tokens sidesteps
the problem: there is nothing long-lived to rotate, nothing to leak that stays
valid, and the description field tells you which job created each one.

The description is worth using well — `"pipeline {{ ci_job_id }}"` means a token
that shows up unexpectedly can be traced to the run that made it.

## Next

[09 — Rebuild from Git](09-rebuild-from-git.md), the closing act.
