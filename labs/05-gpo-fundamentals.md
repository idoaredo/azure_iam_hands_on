# Lab 05 — GPO fundamentals and the Joiner/Leaver tie-in (A12 + JML-lite)

**Prerequisite:** Lab 04 complete. `CLIENT01` does not exist yet (Phase 3 proper) — this lab uses
**Group Policy Modeling** instead of a real logon, which is the correct tool for exactly this
situation: confirming policy before a machine or user is available to test against.

## Objective

Create two of the most common GPOs a Level 1 technician will meet in a real job, link them to a
department OU, verify the link, and prove — with evidence, not assumption — that the policy
follows the OU: it applies to a newly joined user immediately, and stops applying the moment that
user is offboarded and moved out.

## Why this matters

"Basic knowledge of Active Directory and Group Policy" and "assist with onboarding and offboarding
activities" are two separate line items on paper. In practice they are the same skill: policy
scope is decided by where an object sits in the tree, which is exactly what the Joiner/Mover/Leaver
lifecycle manipulates. This lab makes that connection concrete instead of leaving it conceptual.

## Concepts before the clicks

- **A GPO does nothing until it is linked.** Creating one only defines settings; linking it to a
  domain, an OU, or a site is what puts it in scope for anything.
- **Policy follows the OU, not the person.** A user inherits whatever is linked to the OU they are
  in at the moment policy is evaluated — move them, and what applies to them changes with no
  per-user configuration at all.
- **Group Policy Modeling vs `gpresult`.** `gpresult /r` reads real, cached results from a machine
  a user has actually logged into — it needs that logon to have already happened. **Group Policy
  Modeling** (GPMC → right-click → Group Policy Modeling Wizard) simulates what *would* apply to a
  user/computer combination without requiring any prior logon — the right tool when the client
  doesn't exist yet, or before a change is rolled out.

## Part 1 — Two common GPOs, linked to Sales

**GPO 1 — Screen Lock Policy.** GPMC → right-click **Sales** OU → *Create a GPO in this domain, and
Link it here...* → name `Screen Lock Policy - Sales`. Edit it:
`User Configuration → Policies → Administrative Templates → Control Panel → Personalization`
- **Enable screen saver** → Enabled
- **Screen saver timeout** → Enabled, `900` seconds
- **Password protect the screen saver** → Enabled

Bonus, worth knowing even if not configured: `Computer Configuration → Policies → Windows Settings
→ Security Settings → Local Policies → Security Options → Interactive logon: Machine inactivity
limit` — a newer, more robust alternative that locks the session directly, independent of whether
a screen saver is running.

**GPO 2 — Drive Mapping.** Another GPO on the same OU, `Drive Mapping - Sales`. Edit it:
`User Configuration → Preferences → Windows Settings → Drive Maps → New → Mapped Drive`
- Action: Update, Letter: `Z:`, Location: `\\DC01\NETLOGON`

`NETLOGON` is a real share that exists on every domain controller — this mapping will genuinely
connect once a domain-joined client exists, not just in theory.

## Part 2 — Verify the link, not just the existence

```powershell
Get-GPO -Name "Screen Lock Policy - Sales"
Get-GPO -Name "Drive Mapping - Sales"
Get-GPInheritance -Target "OU=Sales,DC=corp,DC=adlab,DC=local"
```
`Get-GPInheritance` confirms both are linked to Sales with nothing blocking inheritance — the
existence of a GPO and its actual scope are two different questions, and only the second one
decides who is affected.

## Part 3 — Group Policy Modeling as the test

GPMC → **Group Policy Modeling** → right-click → **Group Policy Modeling Wizard** → target an
existing Sales user. The report's **Applied GPOs** section should list both GPOs.

## Part 4 — Joiner and Leaver, same lifecycle as tickets 2026-07-21_02 / 2026-07-27_01

**Joiner:**
```powershell
New-ADUser -Name "Charlotte Perrin" -GivenName "Charlotte" -Surname "Perrin" -DisplayName "Charlotte Perrin" `
  -SamAccountName "cperrin" -UserPrincipalName "cperrin@corp.adlab.local" `
  -Path "OU=Sales,DC=corp,DC=adlab,DC=local" `
  -Title "Sales Coordinator" -Department "Sales" `
  -AccountPassword (ConvertTo-SecureString "LabP@ssw0rd!2026" -AsPlainText -Force) -Enabled $true
```
Run the Modeling Wizard again for `cperrin`: both GPOs already apply — nothing was configured for
her individually, only her OU placement decided it.

**Leaver:**
```powershell
Disable-ADAccount -Identity cperrin
Move-ADObject -Identity "CN=Charlotte Perrin,OU=Sales,DC=corp,DC=adlab,DC=local" `
  -TargetPath "OU=Disabled Accounts,DC=corp,DC=adlab,DC=local"
```
Run Modeling a third time, targeting the `Disabled Accounts` OU: **Applied GPOs is empty.** Moving
someone out of Sales does not just tidy up the directory — it genuinely removes the policies that
used to reach them.

## Evidence for the ticket

- Screen Lock GPO created and linked, with settings visible
- The Machine inactivity limit dialog, explored as a bonus fact
- Drive Mapping GPO with the `Z:` → `\\DC01\NETLOGON` mapping
- `Get-GPO` + `Get-GPInheritance` output confirming both links
- Modeling report for an existing Sales user, both GPOs applied
- Modeling report for the new joiner, both GPOs already applied
- ADUC showing the joiner disabled and moved
- Modeling report for the Disabled Accounts OU, Applied GPOs empty

## Interview-ready summary

*"I don't have a domain-joined client in my home lab yet, so instead of `gpresult` I used Group
Policy Modeling — it simulates what policies would apply to a user or computer without needing a
prior logon, which is exactly the tool for confirming a policy before rollout. I linked two common
GPOs — a screen lock and a drive mapping — to a department OU, then ran an end-to-end joiner/leaver
test: created a user in that OU and confirmed both policies applied immediately, then disabled and
moved the account on offboarding and confirmed the same modeling tool showed zero policies applying
from the new location. That's the practical reason the OU an account sits in matters — it's not
just organisation, it's what decides which policies reach that person."*

## Regulatory relevance

Same DORA Art. 9(4)(c) thread as the rest of this lab: policy scope tied to OU placement is how
"access limited to what is required" gets enforced consistently at machine/session level, not just
at the permissions level. See [`../REGULATORY-CONTEXT.md`](../REGULATORY-CONTEXT.md).
