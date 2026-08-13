# Ticket 2026-08-13_01 — Organizational Units and groups (Marketing stand-up)

**Ticket ID:** 2026-08-13_01
**Date:** 2026-08-13 (actions spanned 2026-08-11 and 2026-08-13)
**Category:** AD
**Environment:** Real — `corp.adlab.local` on Azure (DC01)

## Request

**Requester (simulated):** HR / Leadership — the Marketing department is being stood up. Daniel
Foster (previously Sales) transfers over as its first member.

## Approval

**Approver (simulated):** Laurent Girard, IT Manager.
**Four-eyes note:** OU and group creation reviewed before execution.

## Actions taken

1. `New-ADOrganizationalUnit -Name "Marketing" -Path "DC=corp,DC=adlab,DC=local"` — new OU created.
2. `Move-ADObject` — moved `dfoster` from `OU=Sales` to `OU=Marketing`. First attempt was refused
   with `The operation could not be performed because the object's parent is either uninstantiated
   or deleted` — a stale ADWS cache not yet recognising the just-created OU. `Restart-Service ADWS`
   resolved it; the move then succeeded.
3. `Set-ADUser -Identity dfoster -Department "Marketing" -Title "Marketing Coordinator"` — the move
   does not update these attributes on its own, confirmed by an intermediate `Get-ADUser` still
   showing `Department: Sales` right after the move.
4. Deletion-protection proof, using a disposable OU so `Marketing` stayed untouched:
   `New-ADOrganizationalUnit -Name "Temp Test OU"`, then `Remove-ADOrganizationalUnit` — refused
   (`Access is denied`), confirming `ProtectedFromAccidentalDeletion` defaults to `$true`. Cleared
   the flag with `Set-ADOrganizationalUnit -ProtectedFromAccidentalDeletion $false`, removed for
   real with `-Confirm:$false`, and confirmed removal with an empty `Get-ADOrganizationalUnit`.
5. Created Security group **Marketing Team** (Global scope) in the Marketing OU — **via ADUC**
   (New Object → Group).
6. Added `dfoster` to Marketing Team — **via ADUC** (group Properties → Members → Add).
7. `Remove-ADGroupMember -Identity "Marketing Team" -Members dfoster -Confirm:$false`, confirmed
   empty with `Get-ADGroupMember`, then `Add-ADGroupMember` to restore membership — both directions
   exercised via PowerShell.
8. Created Distribution group **Marketing Distribution List** (Global scope) — **via ADUC**, same
   process but `Group type: Distribution`. Added `dfoster` as a member.
9. `Get-ADGroup` on both groups side by side to compare `GroupCategory`/`GroupScope`.

## Validation

```powershell
Get-ADGroup -Identity "Marketing Team" -Properties GroupCategory,GroupScope
Get-ADGroup -Identity "Marketing Distribution List" -Properties GroupCategory,GroupScope
```
```
GroupCategory : Security      GroupScope : Global   (Marketing Team)
GroupCategory : Distribution  GroupScope : Global   (Marketing Distribution List)
```
Same `GroupScope`, different `GroupCategory` — the one attribute that separates "can be granted a
permission" from "can only receive mail".

## Evidence

- `evidence/2026-08-11_01_dfoster-moved-to-marketing.png` — **What:** the failed `Move-ADObject`
  attempt (ADWS cache error), followed by the successful move after `Restart-Service ADWS`, and a
  `Get-ADUser` still showing the old `Department`. **Why:** proves both the ADWS gotcha and that
  attributes don't follow a move automatically.
- `evidence/2026-08-11_01_dfoster-department-title-updated.png` — **What:** `Set-ADUser` followed
  by `Get-ADUser` showing `Department: Marketing`, `Title: Marketing Coordinator`. **Why:** proves
  the attribute fix.
- `evidence/2026-08-11_01_temp-ou-deletion-protection.png` — **What:** the refused
  `Remove-ADOrganizationalUnit` (`Access is denied`), then the flag cleared and the OU removed with
  `-Confirm:$false`. **Why:** proves `ProtectedFromAccidentalDeletion` defaults on.
- `evidence/2026-08-13_01_group-created-gui-and-verified.png` — **What:** the ADUC "Marketing Team
  Properties" General tab (Security, Global, description) alongside `Get-ADGroup` confirming the
  same. **Why:** proves the group was created correctly via the GUI.
- `evidence/2026-08-13_01_dfoster-added-to-group-gui.png` — **What:** ADUC Members tab showing
  Daniel Foster, alongside `Get-ADGroupMember` confirming the same. **Why:** proves the GUI-side
  add is reflected in the directory.
- `evidence/2026-08-13_01_group-member-removed-powershell.png` — **What:** ADUC Members tab empty,
  alongside `Remove-ADGroupMember`/`Get-ADGroupMember` (empty) in PowerShell. **Why:** proves the
  removal direction, cross-checked in both tools.
- `evidence/2026-08-13_01_group-member-readded-final.png` — **What:** full PowerShell history of
  remove → confirm empty → re-add → confirm present. **Why:** closes the add/remove cycle.
- `evidence/2026-08-13_01_security-vs-distribution-comparison.png` — **What:** ADUC "Marketing
  Distribution List" Members tab (Daniel Foster) next to the side-by-side `Get-ADGroup` comparison
  of both groups. **Why:** the payoff evidence for A11 — same scope, different category.

All images redacted: VM public IP (RDP connection bar) and taskbar clock covered.

## Result & user confirmation

Marketing department stood up end to end: OU created, first member moved and re-attributed,
deletion protection proven, Security group created and membership cycled, Distribution group
created and compared against the Security group. A7, A8/A9, and A11 all closed.

## Simulator comparison

The deletion-protection default (step 4) is the same behaviour that was missing from the
`iam_guide` simulator until it was fixed (see that repo's ticket 2026-07-16_01) — confirming it
here on the real cmdlet is the other half of that finding. The ADWS cache gotcha (step 2) has no
equivalent in the simulator at all — it is a real-infrastructure timing issue a simulator has no
reason to model, and the kind of thing no tutorial mentions until it happens to you.

## What I learned

Moving an object and updating its text attributes are completely independent operations —
`Move-ADObject` only changes the object's location in the tree (the DN), nothing else. I also hit,
first-hand, the fact that ADWS keeps its own cache of the directory structure that can lag right
after creating a new object, producing a confusing error ("parent is either uninstantiated or
deleted") that has nothing to do with the command itself — `Restart-Service ADWS` clears it. And
the Security vs Distribution difference isn't subtle or cosmetic: only Security carries a SID that
participates in the access token, so a Distribution group is genuinely invisible to any permission
check — using the wrong one by mistake fails silently instead of throwing an error.
