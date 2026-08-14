# Ticket 2026-08-14_02 — Joiner / Mover / Leaver end to end (Camille Roussel)

**Ticket ID:** 2026-08-14_02
**Date:** 2026-08-14
**Category:** Lifecycle
**Environment:** Real — `corp.adlab.local` on Azure (DC01)

## Request

**Requester (simulated):** Laurent Girard, IT Manager — run the full joiner/mover/leaver cycle for
one employee end to end, deliberately including the mover mistake most admins make, to have a
documented example of both the failure mode and the fix.

## Approval

**Approver (simulated):** Laurent Girard, IT Manager.
**Four-eyes note:** each stage (create, transfer, offboard) treated as its own reviewed change, not
a single bulk action.

## Actions taken

**L1 — Joiner.** Camille Roussel joins as Marketing Assistant — **via ADUC (GUI)**:
1. New User in `OU=Marketing`: name, logon name `croussel`, password set, "must change password at
   next logon" left unchecked.
2. Properties → Organization tab: `Title: Marketing Assistant`, `Department: Marketing`.
3. `Marketing Team` group → Members → Add → `croussel`.

Confirmed:
```powershell
Get-ADUser -Identity croussel -Properties Department,Title | Select DistinguishedName,Department,Title
Get-ADPrincipalGroupMembership croussel | Select Name
```
```
DistinguishedName: CN=Camille Roussel,OU=Marketing,DC=corp,DC=adlab,DC=local
Department: Marketing   Title: Marketing Assistant
Name: Domain Users, Marketing Team
```

**L2 — Mover.** Camille transfers to Finance as Finance Analyst — **via ADUC (GUI)**, deliberately
in the wrong order first to demonstrate the trap:
1. Move Camille Roussel to `OU=Finance`.
2. Organization tab: `Title: Finance Analyst`, `Department: Finance`.
3. `Finance-ReadOnly-Staff` group → Members → Add → `croussel` — **without removing her from
   `Marketing Team` yet.**

Checked the (intentionally broken) intermediate state:
```powershell
Get-ADPrincipalGroupMembership croussel | Select Name
```
```
Name: Domain Users, Marketing Team, Finance-ReadOnly-Staff
```
Both the old and new access are present at once — the object moved OUs, but nothing removed the
group membership tied to the old role. Corrected:
```powershell
Remove-ADGroupMember -Identity "Marketing Team" -Members croussel -Confirm:$false
```

**L3 — Leaver.** Camille leaves the company — **via ADUC (GUI)**:
1. Disable Account.
2. Move to `OU=Disabled Accounts`.

Then removed the remaining access and confirmed the full teardown:
```powershell
Remove-ADGroupMember -Identity "Finance-ReadOnly-Staff" -Members croussel -Confirm:$false
Get-ADUser -Identity croussel -Properties Enabled | Select DistinguishedName,Enabled
Get-ADPrincipalGroupMembership croussel | Select Name
```

## Validation

```
DistinguishedName: CN=Camille Roussel,OU=Disabled Accounts,DC=corp,DC=adlab,DC=local
Enabled: False
Name: Domain Users
```
Only `Domain Users` remains — every role-specific group picked up across both Marketing and
Finance was fully removed by the end of the cycle, not just the most recent one.

## Evidence

- `evidence/2026-08-14_02_mover-trap-both-groups.png` — **What:** ADUC showing Camille physically
  relocated to the Finance OU, alongside `Get-ADUser` confirming the updated Title/Department and
  `Get-ADPrincipalGroupMembership` listing both `Marketing Team` and `Finance-ReadOnly-Staff` at
  once. **Why:** proves the mover trap actually occurs — OU relocation and attribute updates do not
  touch group membership at all.
- `evidence/2026-08-14_02_mover-trap-fixed.png` — **What:** the before/after of
  `Get-ADPrincipalGroupMembership`, `Remove-ADGroupMember` in between. **Why:** proves the fix —
  only `Finance-ReadOnly-Staff` remains after the old membership is explicitly removed.
- `evidence/2026-08-14_02_leaver-disabled-and-access-removed.png` — **What:** ADUC's Disabled
  Accounts OU with Camille listed alongside earlier leavers (Charlotte Perrin, Marc Wolter),
  terminal showing `Enabled: False` and only `Domain Users` left. **Why:** proves the leaver stage
  removed both logon capability and every remaining group-based access.

All images redacted: VM public IP and taskbar clock covered.

## Result & user confirmation

Full joiner → mover → leaver cycle completed for one identity, spanning two departments and both
access-tier structures built in earlier tickets (Marketing in A7-A11, Finance AGDLP in A10). The
mover mistake was reproduced deliberately and corrected, rather than just avoided — the "before"
state is on record as real evidence of the failure mode, not just a description of it.

## Regulatory relevance

DORA Article 9(4)(c) — access limited to what a role legitimately needs — is exactly what the
uncorrected mover state violates: an employee's access should reflect only their current role, not
the sum of every role they have ever held. The leaver stage's complete access removal is the same
principle applied at offboarding — access must end when the legitimate need ends, not linger until
someone happens to notice.

## What I learned

The mover is the easiest stage to get wrong, and the mistake is subtle: relocating an object to a
new OU changes nothing about group membership — they are entirely separate mechanisms, the same
disconnect already seen with `Department`/`Title` in A7, but this time applied to something that
actually matters for security. Watching `Get-ADPrincipalGroupMembership` list both `Marketing Team`
and `Finance-ReadOnly-Staff` on the same person made it obvious why privilege creep is such a
common audit finding — it's rarely malicious, just a missed removal step after the new access was
already confirmed working.
