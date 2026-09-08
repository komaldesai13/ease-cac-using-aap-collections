# 09 — Disaster recovery: rebuild the platform from Git

**Playbook:** [`playbooks/09-rebuild-from-git.yml`](../playbooks/09-rebuild-from-git.yml)
**Requires:** scenarios 01, 03 and 04 applied — or just run `./demo.sh all` first.
**Changes anything?** It deletes everything and rebuilds it.
**Runtime:** ~1–2 minutes.

The closing act. Everything the previous scenarios built gets deleted live, in
front of the audience, and then rebuilt from the repository while a clock runs.

## Run it

```bash
./demo.sh all      # make sure there's something to destroy
./demo.sh 09
```

## What to say before you press enter

> "I'm about to delete everything we just built. Watch the clock."

Then let it run. Do not narrate the middle — the scrolling output is the point.

## What you should see

```
==========================================================================
  Platform destroyed and rebuilt in 47 seconds
  Verified against declared state: MATCH
==========================================================================

No runbook. No screenshots. No one who 'knows how it was set up'.
Just the repository.
```

## Details worth pointing out

**The number is not the point.** Say this out loud, because someone will ask
whether 47 seconds scales to their estate. It won't — theirs is bigger. The
point is that the answer is *knowable at all*, and that you can rehearse it on
a Tuesday afternoon instead of discovering it during an incident.

**Rebuilt is not the same as correct.** The playbook finishes with a read-only
`check_mode` pass that compares the rebuilt platform against the declared state,
and asserts it matches. This is the step real DR plans skip: they restore
something, see no errors, and call it recovered.

**One clock across several playbooks.** `set_fact` writes a host fact, and host
facts survive into the plays imported afterwards — which is how one playbook
times four others.

## Why this matters beyond the booth

Most disaster recovery plans for a platform layer are a document describing what
someone would do, written by a person who has since changed jobs. They are never
tested, because testing them means destroying production.

When the configuration *is* the recovery procedure, testing it is cheap. Run it
against a scratch environment every week. The plan cannot rot, because the plan
is the same code that built the thing.

The same mechanism covers cases that are not disasters at all:

| Situation | What you run |
|---|---|
| Stand up a new region | `./demo.sh all` against a different inventory |
| Give a customer a demo environment | same code, different `DEMO_PREFIX` |
| Recover from a bad change | `git revert <sha>` then apply |
| Recover from a lost cluster | apply to the new one |

That last row is the one people came to hear, but the first three are what they
will use every week.

## Next

Back to the [README](../README.md), or read
[WHY-CAC.md](../WHY-CAC.md) for the case to make between demos.
