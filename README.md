# Ease Configuration as Code with the `ansible.platform` collection

Live-demo playbooks for the Ansible booth at TechGenie.

Ten self-contained scenarios that manage Ansible Automation Platform — its
organizations, teams, people, permissions, authentication and guardrails — as
declarative, version-controlled code. Each one runs in under two minutes,
cleans up after itself, and has a page of notes on what to say while it runs.

Built from the playbooks used in the AAP 2.7 `ansible.platform`
[testathon](https://github.com/rohitthakur2590/aap-2.7-ansible-platform-testathon-playbooks),
reshaped from test cases into a demo narrative.

---

## The demo in one paragraph

Everything AAP knows about who you are and what you may do — organizations,
teams, users, roles, SSO mappings, platform settings — can be a file in Git
instead of a sequence of clicks nobody wrote down. This repo shows that, then
shows the three things that follow from it: you can *detect* when reality
diverges, *prove* what is currently true, and *rebuild the whole thing* from the
repository while someone watches a clock.

---

## Scenarios

| # | Scenario | Runs in | Notes |
|---|---|---|---|
| 00 | [Preflight](docs/00-preflight.md) | 10s | Check before the booth opens. Read-only. |
| 01 | [Tenant onboarding](docs/01-tenant-onboarding.md) | 20s | Orgs, teams and people from one file. **Start here.** |
| 02 | [Idempotency and drift](docs/02-idempotency-and-drift.md) | 30s | **The scenario that wins the argument.** |
| 03 | [RBAC as code](docs/03-rbac-as-code.md) | 20s | Who can do what, reviewable in a pull request. |
| 04 | [Authentication as code](docs/04-authentication-as-code.md) | 15s | SSO group → AAP access, enforced not synced. |
| 05 | [Connection modes](docs/05-connection-modes.md) | 1–3m | local vs http vs persistent, timed live. |
| 06 | [Audit report](docs/06-audit-report.md) | 15s | Export live platform state to Markdown. Read-only. |
| 07 | [Guardrails](docs/07-guardrails.md) | 15s | Compliance settings as executable policy. |
| 08 | [Token lifecycle](docs/08-token-lifecycle.md) | 15s | Credentials that expire on purpose. |
| 09 | [Rebuild from Git](docs/09-rebuild-from-git.md) | 1–2m | Destroy and rebuild, on a clock. **The closer.** |
|  | [site.yml and teardown.yml](docs/site-and-teardown.md) |  | Everything at once, and how to clean up. |

Also: **[WHY-CAC.md](WHY-CAC.md)** — the case to make between demos, and
answers to the questions people actually ask.

---

## Setup

### Install

`ansible.platform` 2.7 is not on Galaxy yet, so install it from the branch:

```bash
ansible-galaxy collection install \
  git+https://github.com/ansible/ansible.platform.git,stable-2.7 --force

ansible-galaxy collection install ansible.posix   # for the timing callback
```

Verify:

```bash
ansible-galaxy collection list ansible.platform
```

### Point it at your AAP

```bash
export AAP_HOSTNAME=https://your-aap.example.com
export AAP_USERNAME=admin
export AAP_PASSWORD='...'
export AAP_VALIDATE_CERTS=false     # self-signed demo pod
export DEMO_PREFIX=TechGenie        # namespaces every resource this repo creates
```

Nothing else needs editing. If you prefer YAML to environment variables, the
same values live in [`group_vars/all.yml`](group_vars/all.yml).

### Check it works

```bash
./demo.sh check
```

---

## Running

```bash
./demo.sh list      # what's available
./demo.sh check     # preflight
./demo.sh 01        # one scenario
./demo.sh 05        # scenario 05 across all three connection modes
./demo.sh all       # site.yml — apply everything
./demo.sh plan      # site.yml --check --diff — change nothing, show what would happen
./demo.sh clean     # teardown
```

Or the long way, if you would rather the audience see real commands:

```bash
ansible-playbook playbooks/01-tenant-onboarding.yml
ansible-playbook site.yml --check --diff
ansible-playbook teardown.yml
```

### A 15-minute booth run

`check` → `01` → **`02`** → `03` → `06` → **`09`** → `clean`

The two in bold are the ones people remember. If you only get five minutes, run
`01` and `02`.

---

## How the repo is laid out

```
vars/                    ← THE SOURCE OF TRUTH. Open these on screen first.
  tenant.yml               organizations, teams, users
  rbac.yml                 role definitions and who gets them
  auth.yml                 authenticator and its maps
  guardrails.yml           compliance settings

playbooks/               ← one scenario per file, heavily commented
docs/                    ← one page per scenario: how to run it, what to say
group_vars/              ← Gateway connection, and the three connection modes
inventory/demo.ini       ← one host per connection mode (all localhost)
templates/               ← the audit report
reports/                 ← generated output (gitignored)

site.yml                 ← apply everything
teardown.yml             ← remove everything
demo.sh                  ← short commands for the booth
```

The split is deliberate and it is the demo: **`vars/` changes, `playbooks/`
doesn't.** Adding a fourth organization is a three-line diff to a data file that
a non-Ansible person can review. It is not a code change.

---

## Notes for whoever runs this

**Every scenario is safe on a shared AAP.** Resources are namespaced with
`DEMO_PREFIX`, the authenticator in scenario 04 is created **disabled**, the
settings in scenario 07 are restored from an `always:` block, and scenarios 05,
06 and 08 clean up after themselves.

**Scenarios 01, 03 and 04 leave their resources in place** so you can show them
in the AAP UI. Everything else is self-cleaning. `./demo.sh clean` resets.

**Run `./demo.sh check` between visitors.** It takes ten seconds and tells you
whether the last person left the pod in a strange state.

**Known gotchas** are collected in [WHY-CAC.md](WHY-CAC.md#gotchas-worth-knowing) —
worth reading once before you stand up.

---

## Requirements

| | |
|---|---|
| `ansible-core` | 2.15+ |
| `ansible.platform` | 2.7 (from `stable-2.7`) |
| `ansible.posix` | any (timing callback) |
| An AAP 2.7 Gateway | with admin credentials |

---

## License

MIT. Demo material — adapt it freely.
