# 01 — Day-one tenant onboarding

**Playbook:** [`playbooks/01-tenant-onboarding.yml`](../playbooks/01-tenant-onboarding.yml)
**Data:** [`vars/tenant.yml`](../vars/tenant.yml)
**Changes anything?** Yes — creates organizations, teams and users.
**Runtime:** ~20 seconds.

The opener. A new business unit needs somewhere to work in AAP: organizations,
teams, and people.

## Run it

```bash
ansible-playbook playbooks/01-tenant-onboarding.yml
# or
./demo.sh 01
```

Then open the AAP UI and show the organizations that just appeared. The switch
from terminal to browser is what makes it land — people believe the UI.

## The demo move

Open `vars/tenant.yml` **first**, before you run anything. Scroll it slowly.
Then run the playbook. The point you are making is the gap between those two
files:

- `vars/tenant.yml` is what the business asked for. A non-Ansible person can
  read it, and can review a change to it.
- `playbooks/01-tenant-onboarding.yml` never changes. It is not a script that
  creates two organizations — it is a loop over however many you declare.

Add a fourth user to `vars/tenant.yml` live, re-run, and only that user is
created. That is the whole pitch in fifteen seconds.

## What to say while it runs

> "Notice there is no 'create org' logic in here. I'm not telling AAP *how* to
> build this — I'm telling it *what should exist*. The module works out the
> difference, and if it's already right, it does nothing."

## Details worth pointing out

**Teams reference their organization by name.** No ID lookup, no "create the
org, copy the ID, paste it into the next call". The module resolves it. This is
the single biggest difference from driving the REST API by hand, where half
your playbook ends up being `uri` calls to find IDs.

**There are no passwords in this repo.** The users are created without one and
sign in through the authenticator from [scenario 04](04-authentication-as-code.md).
`vars/tenant.yml` is safe to commit, to review in a pull request, and to put on
a conference slide.

If a local password is genuinely needed, it goes in Vault and pairs with
`update_secrets: false`:

```yaml
password: "{{ vault_demo_password }}"
update_secrets: false
```

Without `update_secrets: false` the user module re-sends the password on every
run and reports `changed: true` forever — which means your pipeline can never
go green and [scenario 02](02-idempotency-and-drift.md) breaks. This is the
most common gotcha with this module.

## Why this matters beyond the booth

Onboarding is where platform teams lose the most time and make the most
mistakes, because it is repetitive, occasional, and done under deadline. The
version in Git can be reviewed before it is applied, applied identically to
staging and production, and read six months later by someone trying to work out
why a team exists.

## Next

[02 — Idempotency and drift](02-idempotency-and-drift.md) — the scenario that
wins the argument.
