# Ticket 2026-07-22_01 — Unlock a locked account (Thomas Weber)

**Ticket ID:** 2026-07-22_01
**Date:** 2026-07-22
**Category:** AD
**Environment:** Real — `corp.adlab.local` on Azure (DC01)

## Request

**Requester (simulated):** Laurent Girard, IT Manager, reporting that Thomas Weber cannot log on.

## Approval

**Not applicable — no approval required.** Unlocking an account after confirming the cause is
routine help-desk action, not a change that needs prior sign-off.

## Actions taken

**Unplanned finding first:** on returning to the lab this morning, `tweber` — locked out by
`seed-ad.ps1` on 2026-07-21 — was **already unlocked**, with no action taken. The VM had been
deallocated overnight, so many hours passed between the lockout and this session — far longer
than the Account Lockout Duration configured in Lab 01 (Windows' suggested default, accepted at
the time). A lockout is not permanent: it clears itself once the duration elapses, which is
exactly the behaviour that distinguishes **locked** (temporary, self-clearing) from **disabled**
(permanent until an admin acts). Had the account been disabled instead, it would still have been
disabled this morning — nothing about "disabled" clears with time.

To still perform the hands-on unlock, `tweber` was deliberately re-locked using the same
credential-loop approach as the seed script:

```powershell
$threshold = (Get-ADDefaultDomainPasswordPolicy).LockoutThreshold
$wrong = ConvertTo-SecureString "definitely-not-the-password" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential("CORP\tweber", $wrong)
for ($i = 0; $i -le $threshold; $i++) {
    try { Start-Process cmd.exe -Credential $cred -ArgumentList "/c exit" -ErrorAction SilentlyContinue } catch { }
}
```

Confirmed locked (`LockedOut : True`), then unlocked via ADUC: Thomas Weber → Properties →
Account tab → ticked **"Unlock account"** only — no other Account option ticked, since the cause
was a known, deliberate test and Thomas Weber's real password was never at risk.

## Validation

```powershell
Get-ADUser -Identity tweber -Properties LockedOut
```
Before: `LockedOut : True`. After ticking "Unlock account" and clicking OK: `LockedOut : False`,
confirmed by a fresh query (not just the dialog closing without error).

## Evidence

- `evidence/2026-07-22_01_tweber-locked-before.png` — **What:** Thomas Weber's Account tab with
  "Unlock account" unticked and the terminal showing `LockedOut : True`. **Why:** establishes the
  starting state before the fix.
- `evidence/2026-07-22_01_tweber-unlock-checkbox.png` — **What:** the same dialog with "Unlock
  account" now ticked, about to be applied. **Why:** documents the actual administrative action
  taken, not just its result.
- `evidence/2026-07-22_01_tweber-unlocked-after.png` — **What:** a fresh `Get-ADUser` query
  showing `LockedOut : False`. **Why:** proves the fix against the directory itself, not the
  dialog's own state. All three redacted (VM public IP, time of day).

## Result & user confirmation

`tweber` unlocked and confirmed via official query. Thomas Weber can log on again (simulated
confirmation).

## Regulatory relevance

The self-clearing behaviour observed here is a concrete instance of the "detection" angle noted
in `labs/02-user-lifecycle.md`: a lockout is a signal worth noticing, not just an inconvenience to
clear. Distinguishing a routine, self-explained lockout (this ticket) from a pattern that would
warrant investigation is itself part of the ICT risk management posture DORA expects. See
[`../../REGULATORY-CONTEXT.md`](../../REGULATORY-CONTEXT.md).

## What I learned

I expected to unlock a still-locked account and instead found it had already cleared itself
overnight — the lockout duration had simply run out while the VM was off. That was actually a
better lesson than the planned one: it proved locked and disabled are genuinely different states,
not just different words, since only one of them fixes itself with time. I also learned that the
"Unlock account" checkbox sits on the same Account tab as "Account is disabled" — they are
independent settings — and that whether to also force a password change on unlock depends on
*why* the lockout happened, not a fixed rule: a real forgotten-password case usually gets a reset
too, a known test like this one doesn't need anything beyond the unlock itself.
