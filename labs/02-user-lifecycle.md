# Lab 02 — User account lifecycle (A2–A6)

**Prerequisite:** Lab 01 complete — `corp.adlab.local` promoted, seeded (`scripts/seed-ad.ps1`).

## Objective

Perform the core administration tasks a junior AD admin does every week — create an account,
unlock one, reset a password, disable one, edit attributes — against the real directory, and be
able to explain *why* each behaves the way it does, not just how to click through it.

## Why this matters

This is the actual day-one workload of the role you're targeting. None of it is exotic; all of
it is asked about in interviews specifically because it's easy to do by rote and hard to explain
correctly under a follow-up question ("why does disabling not delete the object?").

## Concepts before the clicks

- **`sAMAccountName` vs `UserPrincipalName` vs `DistinguishedName`.** Three different identifiers
  for the same object, none interchangeable. `sAMAccountName` (e.g. `mwolter`) is the legacy
  logon name, still required, capped at 20 characters. `UserPrincipalName` (`mwolter@corp.adlab.local`)
  is the modern, e-mail-shaped logon name and the one Entra ID cares about. `DistinguishedName`
  is the object's actual *position* in the directory (`CN=Marc Wolter,OU=Sales,DC=corp,DC=adlab,DC=local`)
  — it changes if the object moves; the other two don't.
- **Locked out ≠ disabled.** A lockout is automatic and temporary — the directory's own defence
  against a password-guessing attack, and it clears itself after the lockout duration (or an
  admin clears it early). Disabled is a deliberate, indefinite administrative decision. Confusing
  the two in an interview is a classic tell.
- **`PasswordExpired : True` after a reset is correct, not a bug.** Ticking "must change password
  at next logon" sets `pwdLastSet` to `0`. `Get-ADUser` reports a `pwdLastSet` of `0` as
  `PasswordExpired : True` — that is the system telling you the *next* logon will force a change,
  not that something failed.
- **Disable vs delete.** Disabling preserves the SID, group memberships, and every attribute —
  reversible, auditable, and exactly what you do to a leaver during any retention/legal-hold
  window. Delete is permanent and takes the SID with it, which is why a "delete and recreate with
  the same name" never restores the old access (see the domain SID note in ticket
  [2026-07-16_01](../../iam_guide/lab-journal/tickets/2026-07-16_01_console-tour-domain-facts.md)).
- **`GivenName`/`Surname` do not rebuild `DisplayName`.** All three are independent attributes.
  Changing someone's legal surname leaves their `DisplayName` (what shows in the GAL, in Outlook,
  everywhere users actually see a name) untouched until you set it explicitly.

## Cast for this lab

- **A2 / A5 subject (new):** you will create **Marc Wolter**, Sales Representative, in the
  `Sales` OU — then disable him later in this same guide, so the exercise has a natural arc:
  join, then leave.
- **A3 subject (seeded):** `tweber` (Thomas Weber) — already locked out by `seed-ad.ps1`.
- **A4 subject (seeded):** `cdubois` (Claire Dubois) — already flagged for a password change by
  `seed-ad.ps1`.
- **A6 subject (seeded):** `jbennett` (James Bennett) — untouched by any other exercise, safe to
  edit freely.

## A2 — Create a user in the correct OU

**GUI:** ADUC → right-click the `Sales` OU → New → User. First name `Marc`, last name `Wolter`,
`sAMAccountName` and UPN `mwolter`, set a password, untick "User must change password at next
logon" for now (we will practise that flow deliberately with `cdubois` in A4). Title `Sales
Representative`, Department `Sales`.

**PowerShell equivalent:**
```powershell
New-ADUser -Name "Marc Wolter" -GivenName "Marc" -Surname "Wolter" -DisplayName "Marc Wolter" `
  -SamAccountName "mwolter" -UserPrincipalName "mwolter@corp.adlab.local" `
  -Path "OU=Sales,DC=corp,DC=adlab,DC=local" `
  -Title "Sales Representative" -Department "Sales" `
  -AccountPassword (ConvertTo-SecureString "LabP@ssw0rd!2026" -AsPlainText -Force) -Enabled $true
```

**Verify and read the DN:**
```powershell
Get-ADUser -Identity mwolter -Properties DistinguishedName,UserPrincipalName | Format-List
```
The DN should read `CN=Marc Wolter,OU=Sales,DC=corp,DC=adlab,DC=local` — it names the OU he is
actually in. Compare this with `jpetit` (`Get-ADUser -Identity jpetit -Properties DistinguishedName`),
whose DN reads `OU=Contractors` even though his `Department` attribute says `Finance` — the DN
never lies about location, even when the department attribute would mislead you.

## A3 — Unlock a locked account

**Find every locked account domain-wide:**
```powershell
Search-ADAccount -LockedOut
```
`tweber` should appear. This is the same query a help-desk queue would run first thing.

**Unlock it — GUI:** ADUC → find `Thomas Weber` → right-click → Properties → Account tab →
tick "Unlock account" → OK.

**Unlock it — PowerShell:**
```powershell
Unlock-ADAccount -Identity tweber
```

**Verify:**
```powershell
Get-ADUser -Identity tweber -Properties LockedOut
```

## A4 — Reset a password, with change at next logon

**Confirm the fixture first:**
```powershell
Get-ADUser -Identity cdubois -Properties PasswordExpired,pwdLastSet
```
`PasswordExpired` should already read `True` — that's what `seed-ad.ps1`'s
`-ChangePasswordAtLogon $true` did.

**Reset the password — GUI:** ADUC → `Claire Dubois` → right-click → Reset Password → set a new
password → **tick "User must change password at next logon"** → OK.

**Reset — PowerShell (two steps, deliberately):**
```powershell
Set-ADAccountPassword -Identity cdubois -Reset `
  -NewPassword (ConvertTo-SecureString "NewLabP@ss2026!" -AsPlainText -Force)
Set-ADUser -Identity cdubois -ChangePasswordAtLogon $true
```
Note it's two cmdlets: `Set-ADAccountPassword` only sets the password.
`-ChangePasswordAtLogon` is a separate attribute — a common half-finished reset in real life is
setting the password but forgetting this flag, so the user's old (or the temp) password never
actually expires.

**Verify:** `PasswordExpired` should read `True` again — correct, expected, not a failure.

## A5 — Disable an account and move it to Disabled Accounts

Marc Wolter's contract has ended.

**GUI:** ADUC → `Marc Wolter` → right-click → Disable Account → then right-click again → Move…
→ select `Disabled Accounts`.

**PowerShell:**
```powershell
Disable-ADAccount -Identity mwolter
Move-ADObject -Identity "CN=Marc Wolter,OU=Sales,DC=corp,DC=adlab,DC=local" `
  -TargetPath "OU=Disabled Accounts,DC=corp,DC=adlab,DC=local"
```

**Verify — the object still exists, just disabled and relocated:**
```powershell
Get-ADUser -Identity mwolter -Properties Enabled,DistinguishedName
```
`Enabled : False`, DN now under `OU=Disabled Accounts`. Nothing about the account (SID, group
memberships, attributes) was destroyed — that reversibility is the entire point of disable vs
delete.

## A6 — Edit attributes with Set-ADUser

James Bennett gets a title change and, separately, a legal name change.

```powershell
Set-ADUser -Identity jbennett -Title "Senior Systems Administrator" -Description "Promoted 2026"
Set-ADUser -Identity jbennett -Surname "Bennett-Hoffmann"
```

**Verify — and see the DisplayName gap:**
```powershell
Get-ADUser -Identity jbennett -Properties Title,Surname,DisplayName
```
`Surname` is now `Bennett-Hoffmann`, but `DisplayName` still reads `James Bennett` — `Set-ADUser
-Surname` does not touch it. Fix it explicitly if the scenario calls for it:
```powershell
Set-ADUser -Identity jbennett -DisplayName "James Bennett-Hoffmann"
```

## Regulatory relevance

A2's "correct OU from day one" and A5's "disable, don't delete" both map directly to DORA Article
9(4)(c) — access limited to what a role legitimately needs, from creation to departure. See
[`../REGULATORY-CONTEXT.md`](../REGULATORY-CONTEXT.md) for the full mapping and sources.

## Compare with the simulator

Every one of these behaviours — `PasswordExpired` reading `True` after a deliberate reset,
`GivenName`/`Surname` not rebuilding `DisplayName`, disable preserving the object — is something
the `iam_guide` AD-Guide simulator was specifically built (and in one case, fixed) to model
correctly. Seeing it here confirms the simulator was teaching the real thing, not inventing a
plausible-sounding rule.

## Evidence for the ticket

- `Get-ADUser -Identity mwolter -Properties DistinguishedName,UserPrincipalName` right after
  creation (A2), and again after A5 showing the new DN and `Enabled : False`.
- `Search-ADAccount -LockedOut` before and after unlocking `tweber` (A3).
- `Get-ADUser -Identity cdubois -Properties PasswordExpired` after the reset (A4).
- `Get-ADUser -Identity jbennett -Properties Title,Surname,DisplayName` showing the
  Surname/DisplayName gap (A6).

Redact nothing in these — no personal data, no IPs, no secrets. The lab password
(`LabP@ssw0rd!2026` / `NewLabP@ss2026!`) is a shared lab convenience, not a real credential; still
avoid typing it into a captured screenshot if you can crop the field.

## Traps

- Typing `Get-AddUser` instead of `Get-ADUser`, or omitting the `=` in a DN string
  (`DCadlab` vs `DC=adlab`) — PowerShell will not guess; it errors immediately and unambiguously.
- Forgetting the `-ChangePasswordAtLogon` step after `Set-ADAccountPassword` — the reset "worked"
  but the forced-change behaviour silently didn't.
- Assuming `-Surname` updates `DisplayName`. It never does, in this lab or in production.
