# Ticket 2026-08-14_01 — Delegation of Control (password resets on Sales)

**Ticket ID:** 2026-08-14_01
**Date:** 2026-08-14
**Category:** AD
**Environment:** Real — `corp.adlab.local` on Azure (DC01)

## Request

**Requester (simulated):** Laurent Girard, IT Manager — every Sales password reset currently
escalates to him personally; he wants the help desk (`IT Support`) able to handle it directly,
without becoming domain admins.

## Approval

**Approver (simulated):** Laurent Girard, IT Manager.
**Four-eyes note:** delegation scope (task + OU) reviewed before running the wizard, given the
security implications of granting any permission on a live OU.

## Actions taken

1. Ran the **Delegation of Control Wizard** via ADUC on the `Sales` OU — **via GUI**:
   - Group: `IT Support` (pre-seeded, Global/Security, in the Information Technology OU)
   - Task: "Reset user passwords and force password change at next logon"
2. Confirmed the resulting ACE:
```powershell
dsacls "OU=Sales,DC=corp,DC=adlab,DC=local" | Select-String "IT Support"
```
```
Allow CORP\IT Support   Reset Password
Allow CORP\IT Support   SPECIAL ACCESS for pwdLastSet
```
3. Attempted to simulate the delegation as `tweber` (a member of `IT Support`) using
   `runas /user:corp\tweber powershell.exe` — **refused by Windows itself**:
```
1385: Logon failure: the user has not been granted the requested logon type at this computer.
```
   Domain Controllers restrict interactive logon to a small set of privileged groups by default;
   an ordinary domain account cannot log on locally to a DC at all, regardless of any delegated AD
   permission. Pivoted to `-Credential` instead, which authenticates the AD operation itself (an
   LDAP bind) rather than requiring a Windows logon session — the same thing RSAT on a real
   workstation would do.
4. `Sales` had no active users left (all prior occupants had been moved or disabled in earlier
   tickets), so created a disposable test user first:
```powershell
New-ADUser -Name "Julie Renard" -GivenName "Julie" -Surname "Renard" -DisplayName "Julie Renard" -SamAccountName "jrenard" -UserPrincipalName "jrenard@corp.adlab.local" -Path "OU=Sales,DC=corp,DC=adlab,DC=local" -Title "Sales Representative" -Department "Sales" -AccountPassword (ConvertTo-SecureString "LabP@ssw0rd!2026" -AsPlainText -Force) -Enabled $true
```
5. **Positive test** — reset `jrenard`'s password as `tweber`, inside the delegated scope:
```powershell
$cred = Get-Credential corp\tweber
Set-ADAccountPassword -Identity jrenard -NewPassword (ConvertTo-SecureString "NewP@ssw0rd!2026" -AsPlainText -Force) -Reset -Credential $cred
```
   Succeeded (no output — the same silent-success pattern seen throughout this lab).
6. **Negative test 1** — reset `eclarke`'s password (Finance, outside the delegated OU) as
   `tweber`:
```powershell
Set-ADAccountPassword -Identity eclarke -NewPassword (ConvertTo-SecureString "NewP@ssw0rd!2026" -AsPlainText -Force) -Reset -Credential $cred
```
   Refused: `Access is denied`.
7. **Negative test 2** — create a new user inside `Sales` (outside the delegated task) as `tweber`:
```powershell
New-ADUser -Name "unauth test" -SamAccountName "unauthtst" -Path "OU=Sales,DC=corp,DC=adlab,DC=local" -Enabled $false -Credential $cred
```
   Refused: `Access is denied`.

## Validation

The two negative tests are the real validation: `tweber` could reset a password inside `Sales`
(step 5) but was refused for anything outside either boundary — a different OU (step 6) or a
different task (step 7). Both boundaries hold independently.

## Evidence

- `evidence/2026-08-14_01_delegation-ace-and-successful-reset.png` — **What:** `jrenard` created,
  the `dsacls` output showing the two granted ACEs, the failed `runas` attempt with its exact
  error, and the successful `-Credential`-based password reset. **Why:** proves the delegation was
  applied correctly and works end to end for the intended task.
- `evidence/2026-08-14_01_delegation-scope-boundaries-denied.png` — **What:** both negative tests
  (`eclarke` reset, new-user creation in Sales), each refused with `Access is denied`. **Why:**
  proves the delegation is scoped to exactly one OU and exactly one task, not broader.

All images redacted: VM public IP and taskbar clock covered.

## Result & user confirmation

`IT Support` can now reset passwords (and force change at next logon) for any user in `Sales`,
without any broader administrative right — confirmed both by the ACL itself and by a live
functional test with real accept/reject outcomes, not just a review of the configuration.

## Simulator comparison

The `runas` logon-type refusal has no equivalent in the `iam_guide` simulator — it's a real
Windows/AD hardening behaviour (DCs restrict interactive logon by default) that only shows up
against a genuine domain controller, and it ended up demonstrating the Tier-0 principle more
convincingly than any explanation could have.

## Regulatory relevance

CSSF Circular 12/552 (segregation of duties, dedicated roles) — delegating exactly "reset
passwords on this OU" instead of granting broader admin rights is segregation of duties applied at
the OU level: the help desk gets the operational capability it needs, and nothing that would let
it take on risk outside its role. See [`../../REGULATORY-CONTEXT.md`](../../REGULATORY-CONTEXT.md).

## What I learned

Delegation isn't just a documented intention — Windows enforces it at the LDAP level, and that's
testable with a real `Access is denied`, not a hypothetical. The most useful failure of the day
wasn't even a mistake: the refused `runas` attempt proved, without me having to explain it in
theory, exactly why help desk staff never log on to a domain controller directly — the box itself
refuses that logon type for an ordinary account, delegated permission or not. Pivoting to
`-Credential` turned out to be the right technique on its own merits, not just a workaround — it
simulates exactly what a technician would do from their own workstation with RSAT, without needing
a second domain-joined machine this lab doesn't have.
