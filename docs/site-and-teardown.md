# site.yml and teardown.yml

The two playbooks that are not numbered scenarios.

---

## `site.yml` — the whole platform, one command

**Playbook:** [`site.yml`](../site.yml)

This is what a GitOps pipeline runs on merge to `main`. It is deliberately
boring: it imports the same scenario playbooks you demo individually, so there
is no second copy of the logic to drift out of sync.

```bash
ansible-playbook site.yml                  # apply everything
ansible-playbook site.yml --check --diff   # show what WOULD change
# or
./demo.sh all
./demo.sh plan
```

### The demo move

Run it twice.

```bash
./demo.sh all     # first run: everything is created
./demo.sh all     # second run: changed=0 across the board
```

> "Same command. The second run did nothing, because there was nothing to do.
> That's what lets you put this on a merge hook rather than in a runbook."

Then show the plan:

```bash
./demo.sh plan
```

> "This is a plan for your platform, produced by the same code that applies it.
> Not a separate planning tool you have to keep in sync — one code path, one
> flag."

### In a pipeline

```yaml
stages: [validate, plan, apply]

validate:
  script:
    - ansible-lint
    - ansible-playbook site.yml --syntax-check

plan:                       # runs on every merge request
  script:
    - ansible-playbook site.yml --check --diff

apply:                      # runs on merge to main
  script:
    - ansible-playbook site.yml
  when: manual
```

`validate` and `plan` need no write access at all — give that stage a read-only
token from [scenario 08](08-token-lifecycle.md).

---

## `teardown.yml` — remove everything this repo created

**Playbook:** [`teardown.yml`](../teardown.yml)

```bash
ansible-playbook teardown.yml
# or
./demo.sh clean
```

Run it between demos, run it if a scenario dies halfway, run it before you hand
the pod back. It is safe to run when nothing exists.

### How it stays safe

**Order matters.** Assignments are removed before the roles they reference;
teams and users before their organizations. Deleting a parent before its
children either fails or orphans things.

**Missing is fine.** Every task tolerates a `Not Found`:

```yaml
register: _rm
failed_when:
  - _rm.failed | default(false)
  - "'Not Found' not in (_rm.msg | default(''))"
```

Deleting something that is already gone is not an error — it is the desired
state, already met. A second run is a clean no-op.

**Scoped to the prefix.** It only removes what is declared in `vars/`, plus the
probe organizations from [scenario 05](05-connection-modes.md). It will not
touch anything else on a shared Gateway.

### Why a teardown playbook is worth having

Being able to delete an environment as reliably as you create it is what makes
the create side trustworthy. If teardown is manual, people stop tearing down,
environments accumulate, and you end up paying for eleven staging clusters
nobody can identify.

It is also how you verify your CaC is complete: if `teardown.yml` leaves
something behind, that something was created by a hand nobody recorded.
