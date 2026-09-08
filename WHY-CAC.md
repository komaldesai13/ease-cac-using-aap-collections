# Why this matters to Ansible users

Notes for the conversation *between* demos — what to say when someone asks
"but why would I do this?", and what to say when they push back.

---

## The one-sentence version

Everything AAP knows about who you are and what you may do can live in Git
instead of in a sequence of clicks nobody wrote down — and once it does, you can
review it, test it, prove it, and rebuild from it.

## The four claims, and the scenario that proves each

Do not assert these. Run the thing.

| Claim | Proven by |
|---|---|
| It is **declarative** — you describe the end state, not the steps | [01](docs/01-tenant-onboarding.md) |
| It is **idempotent**, so it is safe to run constantly | [02](docs/02-idempotency-and-drift.md), act 1 |
| It can **tell you when reality has diverged**, without changing anything | [02](docs/02-idempotency-and-drift.md), act 3 |
| It can **rebuild the platform** from the repository | [09](docs/09-rebuild-from-git.md) |

---

## What Ansible users actually get

### Your platform config joins the software development workflow

This is the whole thing, and everything below is a consequence of it.

Once AAP configuration is YAML in a repository, it inherits the workflow your
application teams have used for a decade: pull requests, review, CI, tags,
`git revert`, `git blame`. You are not adopting a new process. You are deleting
a bespoke one.

```bash
git log --follow vars/rbac.yml     # every permission change, ever
git blame vars/tenant.yml          # who added this team, and when
git revert <sha>                   # take a change back
```

The person who asks "who gave them access to production, and why?" gets an
answer with a name, a date and a linked ticket, in about four seconds.

### Review happens before the change, not after

A change made in the UI is reviewed by discovering it later. A change made here
is reviewed as a diff, by a second person, before it reaches the platform.

That reordering is most of the value. It is also the part that requires no new
tooling — you already have a code review process.

### The data and the logic separate cleanly

This repo is built so the demo makes the point without you saying it:

- **`vars/`** — what your organization needs. Reviewable by someone who has
  never written a playbook.
- **`playbooks/`** — how to make that true. Written once, then left alone.

Adding a fourth organization is a three-line diff to a data file. It is not a
code change, and it does not need an Ansible expert to approve it.

### One definition, every environment

Same playbooks, different inventory. The class of bug that starts with "it
works in staging" comes from environments being configured by different people
on different days. One definition removes the cause rather than detecting the
symptom.

### Onboarding stops depending on one person's memory

A new platform engineer reads `vars/` and knows the shape of the estate. They
can run `--check` to see what a change *would* do before they have permission to
do it. Their first contribution is a reviewed pull request rather than a
supervised click.

Executable documentation cannot go stale, because it is the thing that runs.

---

## Why the `ansible.platform` collection specifically

Rather than `uri` tasks against the Gateway API, which is the usual alternative:

**Resources are referenced by name.** `organization: Engineering`, not
`organization_id: 47`. Doing this over the raw API means half your playbook is
`uri` calls to look up IDs, plus the error handling for when the lookup fails.

**Idempotency is the module's job.** `state: present` reconciles. Over the raw
API you write the GET, the comparison, the branch between POST and PATCH, and
the `changed` bookkeeping — for every resource type, and you get it subtly wrong
on at least one.

**Check mode works.** `--check --diff` is what makes drift detection and a plan
stage possible. You do not get that from `uri`.

**Connection modes are a tuning knob, not a rewrite.** One inventory line moves
a large run from per-task authentication to a single reused session. See
[scenario 05](docs/05-connection-modes.md).

**`state: exists` asks instead of tells.** A compliance check that proves an
access control is in place without having the authority to create one.

**One collection, one platform.** `ansible.platform` covers the Gateway;
`ansible.controller` and `ansible.eda` cover what runs behind it. Objects created
in one are visible to the others — an organization created via `ansible.platform`
is immediately usable as `organization:` in an `ansible.controller.job_template`.
No duplication, no sync job.

```yaml
- ansible.platform.organization:      # define it once, in the Gateway
    name: Engineering

- ansible.controller.inventory:        # reference it here
    name: production-servers
    organization: Engineering

- ansible.eda.eda_project:             # and here
    name: monitoring-rules
    organization: Engineering
```

---

## Questions people actually ask

**"We already have a wiki page for this."**
A wiki page describes what someone did once. It is not executed, so nothing
detects when it stops being true. Run [scenario 02](docs/02-idempotency-and-drift.md)
and ask when their wiki page last noticed a drift.

**"What about the changes we make in the UI in an emergency?"**
Make them. That is what the UI is for at 2am. The difference is that
[scenario 02](docs/02-idempotency-and-drift.md) finds the change on Tuesday
morning and asks someone to either commit it or revert it — rather than it
sitting there unnoticed for a year.

**"Isn't this just Terraform for AAP?"**
Same idea, different fit. If your team already runs Ansible, this needs no new
tool, no new language and no state file to store, lock and corrupt. State lives
in the platform, and every run reads it fresh.

**"How do we start? We have hundreds of resources already."**
Do not rebuild. Use [scenario 06](docs/06-audit-report.md) — point the
`gateway_api` lookup at what you already have and generate your first `vars/`
files from live state. Then run `--check` until it reports zero changes. At that
point your repo describes reality, and you have adopted CaC without touching
production once.

**"Who reviews these pull requests?"**
Whoever reviews access requests today. The reviewing does not change; the
artifact does — a diff instead of a ticket.

**"What does it cost us?"**
Honestly: a week or two to get the first environment described, and the ongoing
discipline of not clicking. What you get back is time you currently spend on
onboarding, environment setup, drift investigations and audit evidence
gathering. Those are worth measuring in your own organization before you quote
a number — see the note below.

---

## A note on ROI numbers

You will be tempted to put a savings figure on a slide. Be careful: any number
not measured in the customer's own environment is a guess, and a sharp visitor
will treat one bad number as a reason to doubt everything else you said.

What is safe to say, because the demo demonstrates it in the room:

- Environment setup goes from a sequence of manual steps to one command
  ([09](docs/09-rebuild-from-git.md), with the clock on screen).
- Drift detection goes from *never* to *scheduled*
  ([02](docs/02-idempotency-and-drift.md)).
- Audit evidence goes from a manual collection exercise to a generated file
  ([06](docs/06-audit-report.md)).

If someone wants a business case, help them measure their own baseline: how long
did the last environment build take, how many access changes did they make last
quarter, how long did the last audit take to gather evidence for. Their numbers
will be more persuasive than yours, and they will be true.

---

## Gotchas worth knowing

Read these once before you stand up at the booth.

**`update_secrets` and idempotency.** The `user` module with a `password:` set
reports `changed: true` on every run, because `update_secrets` defaults to
`true` and the password is re-sent each time. Add `update_secrets: false` on any
task that needs to be idempotent. This repo sidesteps it by not setting
passwords at all.

**`del` is a reserved word in Python.** Do not use it as a `register:` name.
`deleted` works.

**"no hosts matched" when running in AAP.** Hosts must be added *inside* each
inventory group, not just at the top level.

**"using ephemeral manager" / "Shutting down ephemeral manager".** Informational,
not errors. Expected with `connection: local`.

**`present` versus `enforced`.** `present` reconciles only the keys you supplied.
`enforced` also resets unspecified options to their defaults. For a security
baseline, `enforced` is usually what you want — it closes the gap where someone
sets a field you never thought to declare.

**`query()` versus `lookup()`.** Use `query()` against a collection endpoint; it
returns a list. `lookup()` joins the results into one string.

**Filter on the server.** Pass `query_params` to the `gateway_api` lookup rather
than pulling everything back and filtering in Jinja. On a real installation the
difference is a report that works and one that times out.

---

## Further reading

- [AAP documentation](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform)
- [`ansible.platform` collection](https://github.com/ansible/ansible.platform)
- [Testathon playbooks this demo grew from](https://github.com/rohitthakur2590/aap-2.7-ansible-platform-testathon-playbooks)
- [Ansible Forum](https://forum.ansible.com)
