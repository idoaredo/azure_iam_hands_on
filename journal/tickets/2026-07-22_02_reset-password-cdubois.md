# Ticket 2026-07-22_02 — Reset a password, with change at next logon (Claire Dubois)

**Ticket ID:** 2026-07-22_02
**Date:** 2026-07-22
**Category:** AD
**Environment:** Real — `corp.adlab.local` on Azure (DC01)

## Request

**Requester (simulated):** Isabelle Moreau, HR Director, on behalf of Claire Dubois — routine
password reset.

## Approval

**Not applicable — no approval required.** Routine help-desk password reset, not a change
requiring prior sign-off.

## Actions taken

**Confirmed the starting state** — `cdubois` already carried the must-change flag from
`seed-ad.ps1` (Phase 1):
```powershell
Get-ADUser -Identity cdubois -Properties PasswordExpired,pwdLastSet
```
`PasswordExpired : True`, `pwdLastSet : 0`.

**Reset via ADUC:** right-clicked Claire Dubois → Reset Password → set a new password, ticked
**"User must change password at next logon"**. Noted the dialog also offers **"Unlock the user's
account"**, greyed to the account's actual state (`Account Lockout Status on this Domain
Controller: Unlocked`) — left unticked, since Claire Dubois was not locked out. That checkbox
exists in this dialog specifically for the common combined case (a user locks themselves out
while retrying a forgotten password), so a reset and an unlock can happen in the same action; it
is a no-op when the account isn't locked, same as the "Unlock account" checkbox on the Account
tab discussed in ticket
[2026-07-22_01](2026-07-22_01_unlock-tweber.md).

Confirmed by the system dialog: **"The password for Claire Dubois has been changed."**

## Validation

```powershell
Get-ADUser -Identity cdubois -Properties PasswordExpired,pwdLastSet
```
Same result as before the reset: `PasswordExpired : True`, `pwdLastSet : 0` — **expected, not a
failure**. The must-change-at-next-logon flag was already set before this reset and remains set
after it; the query cannot show that the password *value* changed, only that the flag's state is
correct. The actual proof the reset took effect is the system's own confirmation dialog, not this
query.

## Evidence

- `evidence/2026-07-22_02_cdubois-reset-dialog.png` — **What:** the Reset Password dialog with
  the new password entered and "User must change password at next logon" ticked, alongside the
  terminal's starting-state query. **Why:** documents the action taken and the state beforehand.
- `evidence/2026-07-22_02_cdubois-password-changed.png` — **What:** the "The password for Claire
  Dubois has been changed" confirmation dialog, with the same `Get-ADUser` query run again below
  it. **Why:** this dialog — not the repeated query — is the actual proof the reset succeeded.
  Both redacted (VM public IP, time of day).

## Result & user confirmation

Password reset, must-change-at-next-logon confirmed active. Claire Dubois will be required to set
a new password at her next interactive logon (simulated confirmation).

## Regulatory relevance

Same DORA Art. 9(4)(c) thread as the rest of this lab: keeping the "must change" flag in force
until the user actually sets their own secret is what makes the reset the user's own, and not the
admin's, at the moment access is actually used. See [`../../REGULATORY-CONTEXT.md`](../../REGULATORY-CONTEXT.md).

## What I learned

The "Unlock the user's account" checkbox inside the Reset Password dialog is the same no-op
mechanism as the "Unlock account" checkbox on the Account tab — it only matters if the account
happens to be locked, and it's placed here specifically because forgotten password and lockout
often happen together in real life. I also learned that a repeated `PasswordExpired`/`pwdLastSet`
query showing identical values before and after a reset isn't a sign that nothing happened — it
means the flag was already correct both times. The real evidence that the password changed is the
system's own confirmation message, since AD never lets you query the password itself.
