# Lab 04 — AGDLP remediation (A10)

**Prerequisite:** Lab 03 complete. This is *the* AD group-design question in interviews — worth
its own guide rather than a rushed subsection.

## Objective

Take the deliberately broken Finance access model planted by `seed-ad.ps1` and rebuild it as a
real AGDLP chain — without changing who has what access, only how that access is structured.

## Why this matters

Anyone can recite "user → Global → Domain Local → Permission." Interviews probe whether you
understand *why*: what breaks without it, and what happens when access isn't perfectly uniform
across a department — which is the part most people get wrong, and which this lab's seed data was
built to expose.

## Concepts before the clicks

- **The anti-pattern:** granting access **per person, directly on the resource group**. Every
  joiner and leaver then has to be edited in every resource group individually, with no single
  place that says "this is who's in Finance."
- **The naive fix is also wrong.** The obvious-looking remediation — "just nest the department's
  one Global group into the resource group" — only works if **everyone in the department has
  identical access**. Check the actual seed data first, always, before remediating:

```powershell
Get-ADGroupMember -Identity "FS-Finance-ReadWrite"
Get-ADGroupMember -Identity "FS-Finance-ReadOnly"
```

  You'll find **three** people (`nsimon`, `sbernard`, `plefevre`) directly in ReadWrite, and
  **one** (`eclarke`) directly in ReadOnly — all four are also members of the single `Finance
  Team` Global group. If you nest `Finance Team` into *both* Domain Local groups to "fix" this,
  every one of the four gains **both** ReadWrite and ReadOnly — that's not a remediation, that's a
  silent access-scope change, and on a file share in a bank that is exactly the kind of thing an
  access review is designed to catch.
- **The correct fix:** AGDLP nests groups by **access tier**, not by department, whenever a
  department's access isn't uniform. A department can — and often should — have more than one
  Global group underneath it.

## Steps

**1. Confirm the current (broken) state** — the two queries above. Note the asymmetry: 3 vs 1,
not a clean department-wide split.

**2. Create two access-tier Global groups**, one per resource tier, instead of reusing the
department-wide `Finance Team`:

```powershell
New-ADGroup -Name "Finance-ReadWrite-Staff" -GroupScope Global -GroupCategory Security `
  -Path "OU=Finance,DC=corp,DC=adlab,DC=local" -Description "Finance staff with file share write access"
New-ADGroup -Name "Finance-ReadOnly-Staff" -GroupScope Global -GroupCategory Security `
  -Path "OU=Finance,DC=corp,DC=adlab,DC=local" -Description "Finance staff with file share read-only access"
```

**3. Populate them to match today's actual access exactly** — this is the step that preserves
access instead of changing it:

```powershell
Add-ADGroupMember -Identity "Finance-ReadWrite-Staff" -Members nsimon,sbernard,plefevre
Add-ADGroupMember -Identity "Finance-ReadOnly-Staff" -Members eclarke
```

**4. Nest each new Global group into the matching Domain Local resource group:**

```powershell
Add-ADGroupMember -Identity "FS-Finance-ReadWrite" -Members "Finance-ReadWrite-Staff"
Add-ADGroupMember -Identity "FS-Finance-ReadOnly" -Members "Finance-ReadOnly-Staff"
```

**5. Remove the direct memberships** — access now flows through the Global groups, not through
individual placement on the resource group:

```powershell
Remove-ADGroupMember -Identity "FS-Finance-ReadWrite" -Members nsimon,sbernard,plefevre -Confirm:$false
Remove-ADGroupMember -Identity "FS-Finance-ReadOnly" -Members eclarke -Confirm:$false
```

**6. Verify nothing actually changed from the affected users' point of view** — same four people,
same two-tier split, now via groups instead of direct membership:

```powershell
Get-ADGroupMember -Identity "FS-Finance-ReadWrite" -Recursive
Get-ADGroupMember -Identity "FS-Finance-ReadOnly" -Recursive
```
`-Recursive` expands nested groups down to the actual users — this is what you'd show an auditor
to prove "these are the humans who really have this access," regardless of how many layers of
group nesting sit in between.

## What about `Finance Team`?

It still exists, untouched, with all four people in it — and that's correct, not leftover mess.
`Finance Team` answers "who is in the Finance department" (useful for the `All Staff` distribution
list, future GPO scoping, a department-wide access review). `Finance-ReadWrite-Staff` and
`Finance-ReadOnly-Staff` answer a narrower question: "who has *this specific* access." A
department group and an access-tier group are not always the same thing, and conflating them is
exactly what produces the over-broad "nest the one group everywhere" mistake this lab exists to
avoid.

## Interview-ready summary

*"AGDLP isn't 'one group per department' — it's one Global group per distinct access requirement.
When I found three people with read/write and one with read-only, all mixed into a single
department group, I didn't nest that group into both resource groups — that would have handed
read/write to someone who shouldn't have it. I built two access-tier groups that matched the
existing access exactly, nested each into its matching resource group, then removed the direct
memberships. Same access, same four people, now structured so a future joiner or leaver is one
edit in one place instead of a hunt through every resource group."*

## Evidence for the ticket

- The "before" `Get-ADGroupMember` output on both resource groups (direct members, 3 vs 1 split).
- The two new Global groups and their membership.
- The "after" `Get-ADGroupMember -Recursive` output, showing the same four people land in the
  same two tiers as before — access preserved, structure fixed.

## Traps

- Nesting a single department-wide group into every resource group "for simplicity" — silently
  broadens access the moment that department isn't uniform, which most real departments aren't.
- Forgetting `-Recursive` when verifying — without it, `Get-ADGroupMember` on the resource group
  shows the nested *group*, not the people, and it's easy to mistake "one group member" for "one
  person has access."
- Removing the direct memberships *before* the nested group is in place and verified — briefly
  locks everyone out. Always nest first, verify, then remove the old direct membership.
