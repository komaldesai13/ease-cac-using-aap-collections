# 04 — Authentication as code

**Playbook:** [`playbooks/04-authentication-as-code.yml`](../playbooks/04-authentication-as-code.yml)
**Data:** [`vars/auth.yml`](../vars/auth.yml)
**Requires:** [scenario 01](01-tenant-onboarding.md).
**Changes anything?** Yes — creates one **disabled** authenticator and its maps.
**Runtime:** ~15 seconds.

Authenticator maps are how an identity provider group becomes AAP access. Most
teams maintain that mapping in a spreadsheet, and the spreadsheet is wrong.

## Safety on a shared AAP

The demo uses the built-in **`local`** authenticator plugin and creates it
**disabled**, so running this in front of an audience cannot change how anyone
signs in. No LDAP or SAML server is needed in the room.

The bottom of [`vars/auth.yml`](../vars/auth.yml) has the real LDAP shape in a
comment block — show that on screen, run the safe one.

## Run it

```bash
ansible-playbook playbooks/04-authentication-as-code.yml
# or
./demo.sh 04
```

## The demo move

Scroll to the commented LDAP block in `vars/auth.yml` and land on this line:

```yaml
revoke: true
```

> "This one word is the difference between a sync and a control. Without it,
> access is granted the first time someone matches a group and then keeps
> working forever. With it, if the IdP stops saying you're in that group, you
> lose the access on your next login — automatically, with no offboarding
> ticket."

Offboarding is the part of identity management that quietly fails everywhere.
This is the line that fixes it.

## Details worth pointing out

**Maps are ordered.** `order:` decides which map wins for a given `map_type`.
That is exactly the kind of detail that lives in one person's head and leaves
when they do. Here it is a number in a file.

**The whole auth config is idempotent.** The playbook re-applies the
authenticator and asserts the second run reports no change, so re-running the
pipeline never disturbs a working login path.

**Types of map worth knowing:**

| `map_type` | Grants |
|---|---|
| `is_superuser` | Full platform administration |
| `organization` | Membership or a role in one organization |
| `team` | Membership or a role in one team |
| `allow` / `deny` | Whether the user may log in at all |

## Why this matters beyond the booth

The usual failure mode is not that the mapping is wrong on day one — it is that
the org chart moves and the mapping does not. Someone changes team and keeps
their old access. Someone leaves the company and their group membership is
removed in the IdP, but their AAP access stays because nothing re-evaluates it.

Declaring the mapping and running it on a schedule means the IdP is the single
source of truth for who someone is, and this repo is the single source of truth
for what that entitles them to. Both are auditable, and neither depends on
anyone remembering to file a ticket.

## Next

[05 — Connection modes](05-connection-modes.md).
