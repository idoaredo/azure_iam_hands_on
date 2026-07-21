# Ticket 2026-07-21_02 — Create a user in the correct OU (Marc Wolter)

**Ticket ID:** 2026-07-21_02
**Date:** 2026-07-21
**Category:** AD
**Environment:** Real — `corp.adlab.local` on Azure (DC01)

## Request

**Requester (simulated):** HR, on behalf of a new Sales hire.
New employee **Marc Wolter** joins as Sales Representative. Standard user account, correct OU,
no group membership requested yet.

## Approval

**Approver (simulated):** Laurent Girard, IT Manager.
**Four-eyes note:** account creation reviewed and approved before execution.

## Actions taken

1. PowerShell, from DC01:
```powershell
New-ADUser -Name "Marc Wolter" -GivenName "Marc" -Surname "Wolter" -DisplayName "Marc Wolter" `
  -SamAccountName "mwolter" -UserPrincipalName "mwolter@corp.adlab.local" `
  -Path "OU=Sales,DC=corp,DC=adlab,DC=local" `
  -Title "Sales Representative" -Department "Sales" `
  -AccountPassword (ConvertTo-SecureString "LabP@ssw0rd!2026" -AsPlainText -Force) -Enabled $true
```

## Validation

```powershell
Get-ADUser -Identity mwolter -Properties DistinguishedName,UserPrincipalName | Format-List
```
```
DistinguishedName : CN=Marc Wolter,OU=Sales,DC=corp,DC=adlab,DC=local
Enabled           : True
GivenName         : Marc
Name              : Marc Wolter
SamAccountName    : mwolter
Surname           : Wolter
UserPrincipalName : mwolter@corp.adlab.local
```
The DN confirms he is filed under `OU=Sales`, matching the request — the object's real location,
not just the `Department` attribute.

## Evidence

- `evidence/2026-07-21_02_mwolter-created.png` — **What:** ADUC showing Marc Wolter in the Sales
  OU, alongside the PowerShell terminal with the `Get-ADUser` output confirming the DN, UPN, and
  SamAccountName. **Why:** proves the account was created in the correct OU with the right
  identifiers. VM public IP and time of day redacted.

## Result & user confirmation

Account created and confirmed. No group membership assigned yet — out of scope for this ticket.

## Regulatory relevance

DORA Art. 9(4)(c) — access should be scoped to what the role legitimately needs from the moment
the account exists. Creating the account in the correct OU from day one, rather than fixing it
later, is that principle applied at creation time.

## What I learned

There are three separate identifiers for the same user, not one: `sAMAccountName` (the short,
legacy login name), `UserPrincipalName` (the modern login, shaped like an e-mail address), and
`DistinguishedName` (the object's real location in the tree, read right to left). I first assumed
the UPN exists just to reuse the e-mail address, since every employee has one at work anyway —
that part is true as a practical convenience, but UPN and `mail` stay separate attributes
underneath, and nothing keeps them in sync automatically if one changes later.
