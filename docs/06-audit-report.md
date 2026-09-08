# 06 — Audit report: read the platform back out

**Playbook:** [`playbooks/06-audit-report.yml`](../playbooks/06-audit-report.yml)
**Template:** [`templates/audit-report.md.j2`](../templates/audit-report.md.j2)
**Requires:** nothing, though it is more interesting after scenarios 01 and 03.
**Changes anything?** No. Read-only, safe at any time.
**Runtime:** ~15 seconds.

Configuration as Code is not only about writing. The `gateway_api` lookup reads
any Gateway API endpoint into a variable, which means the current state of your
platform is just data you can template.

## Run it

```bash
ansible-playbook playbooks/06-audit-report.yml
# or
./demo.sh 06
```

It writes `reports/aap-state-YYYY-MM-DD.md` and prints it to the terminal.

## What comes out

A dated Markdown report containing:

- platform totals — organizations, teams, users, role definitions
- **every superuser on the Gateway**, with last-login dates
- the organizations, teams, users and custom roles in scope for this demo

## The demo move

Scroll straight past the totals to the **Privileged accounts** table and let it
sit there.

> "This list should be short, and you should be able to explain every entry.
> Most people cannot produce this table for their own platform in under a day.
> That took twelve seconds, and it's a file I can commit."

## Details worth pointing out

**`query()` versus `lookup()`.** Use `query()` against a collection endpoint —
it returns a list. `lookup()` joins results into a single string, which is
almost never what you want.

**Filter on the server, not in Jinja.** The superuser list uses `query_params`:

```yaml
query('ansible.platform.gateway_api', 'users',
      query_params={'is_superuser': true}, ...)
```

The Gateway does the filtering and sends back three rows. Pulling all ten
thousand users and filtering in Jinja gets the same answer and times out on a
real installation. This is the single most useful habit to take away from this
scenario.

**Any endpoint works.** The lookup is not limited to a fixed list of resources —
it takes an API path, including the service APIs behind the Gateway:

```yaml
lookup('ansible.platform.gateway_api', 'api/eda/v1/organizations')
```

## Why this matters beyond the booth

Three uses, in increasing order of value:

1. **Evidence for auditors.** Generate the report on a schedule, commit it next
   to the configuration that produced it. The auditor sees both what you
   intended and what was actually running.
2. **Month-over-month diffs.** `git diff` two reports and read the change in
   privileged access as a diff instead of as two spreadsheets.
3. **Importing what already exists.** Point the lookup at a platform that was
   built by hand, and use the output to write your first `vars/` files. This is
   usually how a team gets from "we have no CaC" to "we have CaC" without a
   rebuild.

Combined with [scenario 02](02-idempotency-and-drift.md), you have both halves:
this tells you what *is*, `--check --diff` tells you where that differs from
what *should be*.

## Next

[07 — Guardrails](07-guardrails.md).
