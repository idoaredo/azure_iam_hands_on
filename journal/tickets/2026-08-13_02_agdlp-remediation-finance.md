# Ticket 2026-08-13_02 — AGDLP remediation (Finance file-share access)

**Ticket ID:** 2026-08-13_02
**Date:** 2026-08-13
**Category:** AD
**Environment:** Real — `corp.adlab.local` on Azure (DC01)

## Request

**Requester (simulated):** Access review / compliance — flagged that the Finance file-share
resource groups have people added directly instead of through a department or access-tier group,
and asked for it to be restructured to a standard AGDLP chain without changing who currently has
access.

## Approval

**Approver (simulated):** Laurent Girard, IT Manager.
**Four-eyes note:** the remediation plan (create access-tier groups, nest, then remove direct
membership — in that order) was reviewed before touching a group with live access implications.

## Actions taken

1. Confirmed the current (broken) state before changing anything:
```powershell
Get-ADGroupMember -Identity "FS-Finance-ReadWrite"
Get-ADGroupMember -Identity "FS-Finance-ReadOnly"
```
Found **3** people (`nsimon`, `sbernard`, `plefevre`) directly in ReadWrite and **1** (`eclarke`)
directly in ReadOnly — not a uniform department-wide split, despite all four also being members of
the single `Finance Team` Global group.
2. Created two access-tier Global groups instead of reusing `Finance Team`:
```powershell
New-ADGroup -Name "Finance-ReadWrite-Staff" -GroupScope Global -GroupCategory Security -Path "OU=Finance,DC=corp,DC=adlab,DC=local" -Description "Finance staff with file share write access"
New-ADGroup -Name "Finance-ReadOnly-Staff" -GroupScope Global -GroupCategory Security -Path "OU=Finance,DC=corp,DC=adlab,DC=local" -Description "Finance staff with file share read-only access"
```
3. Populated them to match today's actual access exactly:
```powershell
Add-ADGroupMember -Identity "Finance-ReadWrite-Staff" -Members nsimon,sbernard,plefevre
Add-ADGroupMember -Identity "Finance-ReadOnly-Staff" -Members eclarke
```
4. Nested each Global group into its matching Domain Local resource group — **via ADUC**. First
   attempt used the **Member Of** tab of `FS-Finance-ReadOnly` instead of **Members**, which
   silently reverses the operation direction: it tried to make the Domain Local group a member of
   the Global group, refused by Windows with `A global group cannot have a local group as a
   member.` Corrected by using the **Members** tab instead, adding `Finance-ReadOnly-Staff` (and
   `Finance-ReadWrite-Staff`) as members of the resource groups, not the other way around.
5. Confirmed nesting before touching direct membership:
```powershell
Get-ADGroupMember -Identity "FS-Finance-ReadWrite"
Get-ADGroupMember -Identity "FS-Finance-ReadOnly"
```
Both new Global groups appeared alongside the original direct members.
6. Removed the direct memberships — only after nesting was verified:
```powershell
Remove-ADGroupMember -Identity "FS-Finance-ReadWrite" -Members nsimon,sbernard,plefevre -Confirm:$false
Remove-ADGroupMember -Identity "FS-Finance-ReadOnly" -Members eclarke -Confirm:$false
```
(First typed `Remove-ADGroup` by mistake — wrong cmdlet, would have deleted the group entirely;
caught by the parameter-binding error before it ran, corrected to `Remove-ADGroupMember`.)

## Validation

```powershell
Get-ADGroupMember -Identity "FS-Finance-ReadWrite" -Recursive
Get-ADGroupMember -Identity "FS-Finance-ReadOnly" -Recursive
```
Same four people, same 3/1 split as the original "broken" state — `plefevre`, `sbernard`, `nsimon`
under ReadWrite, `eclarke` under ReadOnly — now resolved through the nested Global groups instead
of direct placement on the resource group.

## Evidence

- `evidence/2026-08-13_02_agdlp-recursive-before-removal.png` — **What:** `-Recursive` output on
  both resource groups right after nesting, still with direct members also in place. **Why:**
  baseline showing the four people still resolve correctly at this intermediate stage.
- `evidence/2026-08-13_02_agdlp-nesting-confirmed.png` — **What:** non-recursive
  `Get-ADGroupMember` on both resource groups, listing the new Global group *and* the original
  direct members side by side. **Why:** proves the nesting itself succeeded, independent of the
  recursive result.
- `evidence/2026-08-13_02_agdlp-removal-and-final-recursive.png` — **What:** the
  `Remove-ADGroupMember` commands, followed by the final `-Recursive` check. **Why:** the payoff
  evidence — same four people, same access split, now flowing only through the group chain.

All images redacted: VM public IP and taskbar clock covered.

## Result & user confirmation

Finance file-share access restructured into a full AGDLP chain (person → access-tier Global group
→ Domain Local resource group → permission) with zero change to who has ReadWrite vs ReadOnly.
`Finance Team` and the `FS-Finance-*` resource groups themselves were left untouched — only the
path between person and resource group changed.

## Regulatory relevance

DORA Article 9(4)(c) — access must be limited to "what is required for legitimate and approved
functions." The remediation this ticket avoided (nesting the whole department into both resource
groups) is exactly the failure mode that principle warns against — it would have silently handed
ReadWrite to someone who should only have ReadOnly. See
[`../../REGULATORY-CONTEXT.md`](../../REGULATORY-CONTEXT.md).

## What I learned

AGDLP has a mandatory direction, and Windows actually enforces it: a Domain Local group can contain
a Global group as a member, never the reverse. I hit this for real using the wrong ADUC tab
(**Member Of** instead of **Members**), which silently flips the operation even though I had opened
what I thought was the "correct" group.

The naive fix here — nest the whole department's one group into both resource groups — would have
been a real mistake, not just a style issue: since access wasn't uniform (3 people ReadWrite, 1
ReadOnly), that shortcut would have quietly handed ReadWrite to someone who should only have
ReadOnly. The correct structure separates by **access tier**, not by department — `Finance Team`
stays exactly as it was, answering a different question ("who is in Finance") from the new groups
("who has *this* access").

The biggest lesson, though, is about **sequencing**, not group design: nest first, verify, only
then remove the old direct membership — never the other way around. This isn't a style preference.
On a live system, people are actively using that access right now — removing direct membership
before the replacement path is confirmed working means an instant, real gap where someone loses
access they still need, even if it gets "fixed" a minute later. There's no safe way to pivot after
the fact; the correct order has to be right the first time.
