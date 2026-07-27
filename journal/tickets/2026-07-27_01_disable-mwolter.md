# Ticket 2026-07-27_01 — Disable an account and move it to Disabled Accounts (Marc Wolter)

**Ticket ID:** 2026-07-27_01
**Date:** 2026-07-27
**Category:** Lifecycle
**Environment:** Real — `corp.adlab.local` on Azure (DC01)

## Request

**Requester (simulated):** Laurent Girard, IT Manager, on behalf of Sales — Marc Wolter's contract
has ended.

## Approval

**Approver (simulated):** Laurent Girard, IT Manager.
**Four-eyes note:** offboarding action reviewed before execution.

## Actions taken

**Before state confirmed:**
```powershell
Get-ADUser -Identity mwolter -Properties Enabled,DistinguishedName
```
`Enabled : True`, DN under `OU=Sales`.

**Disable and move, via ADUC:** right-click Marc Wolter → **Disable Account**, then right-click
again → **Move…** → `Disabled Accounts`.

This closes the small arc started in ticket
[2026-07-21_02](2026-07-21_02_create-user-mwolter.md), where Marc Wolter was created for the A2
exercise — created there, offboarded here.

## Validation

Same query, run again in the same session, right after the before-state query:
```powershell
Get-ADUser -Identity mwolter -Properties Enabled,DistinguishedName
```
```
DistinguishedName : CN=Marc Wolter,OU=Disabled Accounts,DC=corp,DC=adlab,DC=local
Enabled           : False
```
Both queries sit in the same terminal capture — same `ObjectGUID` and `SID` before and after,
confirming this is the same object, not a delete-and-recreate: disabling and moving preserved
identity end to end.

## Evidence

- `evidence/2026-07-27_01_mwolter-enabled-before.png` — **What:** the Sales OU with Marc Wolter
  still present, and the terminal confirming `Enabled : True` under `OU=Sales`. **Why:** the
  starting state, before any action.
- `evidence/2026-07-27_01_mwolter-disabled-after.png` — **What:** the `Disabled Accounts` OU now
  containing Marc Wolter, and both terminal queries (before and after) visible together in the
  same capture. **Why:** proves the object moved and was disabled, with the same `ObjectGUID`/SID
  in both queries proving it is the same object, not a new one. VM public IP and time of day
  redacted in both.

## Result & user confirmation

Marc Wolter disabled and relocated. The object still exists — nothing was deleted. Access is
revoked immediately; the account remains available for audit or reactivation if the offboarding
were reversed (e.g. a rehire).

## Regulatory relevance

DORA Art. 9(4)(c) and 9(4)(e) both apply here: access no longer matches a "legitimate and
approved function" the moment someone leaves, and disabling (rather than deleting) keeps the
change reversible and auditable — the object, its SID, and its history all survive, which is what
an auditor would expect to be able to inspect later. See
[`../../REGULATORY-CONTEXT.md`](../../REGULATORY-CONTEXT.md).

## What I learned

This is the credential-revocation step of offboarding a departing employee. What stood out is
that compliance doesn't want the record erased — it wants it kept, disabled, so there's still a
trace of who had access and when. Deleting would remove exactly the evidence an audit or
investigation might later need.
