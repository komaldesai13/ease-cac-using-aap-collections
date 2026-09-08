# 03 — RBAC as code

**Playbook:** [`playbooks/03-rbac-as-code.yml`](../playbooks/03-rbac-as-code.yml)
**Data:** [`vars/rbac.yml`](../vars/rbac.yml)
**Requires:** [scenario 01](01-tenant-onboarding.md).
**Changes anything?** Yes — creates role definitions and grants.
**Runtime:** ~20 seconds.

"Who has access to production?" is a question most platform teams answer by
opening the UI and squinting.

## Run it

```bash
ansible-playbook playbooks/03-rbac-as-code.yml
# or
./demo.sh 03
```

## The demo move

Open `vars/rbac.yml` on screen and ask: *"How long would it take you to produce
this list for your own platform right now?"* That question does more work than
the playbook does.

## What it does

1. **Asks the Gateway which permissions exist** for `shared.organization`, via
   the `gateway_api` lookup against `role_metadata`. Nobody has to guess at
   permission strings or grep the docs — and neither does the auditor reading
   your repo. (If the endpoint isn't exposed on your build, the playbook says so
   and carries on.)
2. **Creates custom role definitions** from `demo_role_definitions`.
3. **Grants roles to teams** — the pattern that scales.
4. **Grants roles to individual users** — used sparingly, for the auditor.
5. **Proves one grant exists** using `state: exists`, which asks a question
   rather than making a change.

## Details worth pointing out

**Team grants over user grants.** Adding a person to a team is a one-line diff.
Granting one person direct access to six objects, six times, is how you end up
with an access review nobody can complete. `vars/rbac.yml` deliberately shows
both so you can contrast them.

**`state: exists` is the compliance primitive.** It returns whether the
assignment is in place without touching it, so a pipeline can *prove* an access
control is present:

```yaml
- ansible.platform.role_team_assignment:
    role_definition: "Prod-Deployer"
    team: "Platform-SRE"
    assignment_objects:
      - name: "Production"
        type: organizations
    state: exists
  register: check

- ansible.builtin.assert:
    that: check.exists
    fail_msg: "Required production access is missing."
```

**`revoke` and enforcement.** See [scenario 04](04-authentication-as-code.md) for
the authenticator-map equivalent, which is where "granted once" becomes
"continuously enforced".

## Why this matters beyond the booth

An access change made in the UI has no author, no reason, and no reviewer. The
same change made here has all three, plus a revert button:

```bash
git log --follow vars/rbac.yml       # every permission change, ever
git blame vars/rbac.yml              # who granted this, and when
git revert <sha> && ./demo.sh all    # take it back
```

That is the difference between an access review that takes a week of
screenshots and one that takes an afternoon of reading diffs.

## Next

[04 — Authentication as code](04-authentication-as-code.md).
