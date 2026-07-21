# Lab 03 — Organizational Units and groups (A7–A9, A11)

**Prerequisite:** Lab 02 complete.

## Objective

Create a new OU and confirm the deletion-protection behaviour discovered in the simulator; create
and populate a security group; create a distribution group and be able to explain how the two
categories actually differ.

## Why this matters

An OU is where objects live and where policy attaches; a group is how permission is granted. New
admins routinely conflate the two — "just put them in the right OU" is not how access works. This
lab makes the distinction concrete.

## Concepts before the clicks

- **An OU does not grant permissions.** It exists for two things only: linking Group Policy, and
  delegating administrative control (A13). Access to a resource is granted through **groups**,
  never through OU membership.
- **`New-ADOrganizationalUnit` protects by default.** `ProtectedFromAccidentalDeletion` defaults to
  `$true` — one of the few AD defaults that is the *safe* one. `Remove-ADOrganizationalUnit`
  refuses until the flag is cleared. This is real cmdlet behaviour, confirmed on this exact domain
  during Lab 01's DC01 build (see ticket
  [2026-07-21_01](../journal/tickets/2026-07-21_01_dc01-build.md)), and it is also the finding
  that fixed a defect in the `iam_guide` simulator (see `iam_guide`'s ticket
  [2026-07-16_01](../../iam_guide/lab-journal/tickets/2026-07-16_01_console-tour-domain-facts.md)).
- **Group scope determines who can be a member and where the group can be used.** Global groups
  hold users from the local domain; Domain Local groups are where you attach permissions to a
  resource in this domain. This split is the raw material of A10 (Lab 04).
- **Security vs Distribution is a category, not a scope.** A Security group can be used both for
  permissions *and* for e-mail (if mail-enabled); a Distribution group can **only** be used for
  e-mail — Windows will not evaluate it during an access check at all, even if you try. This is
  worth demonstrating, not just stating.

## A7 — Create an OU, move an object in, and hit the deletion-protection wall

**Create the new department:**
```powershell
New-ADOrganizationalUnit -Name "Marketing" -Path "DC=corp,DC=adlab,DC=local" -Description "Marketing Department"
```

**Move an existing object into it** — Daniel Foster (Sales) transfers to Marketing:
```powershell
Move-ADObject -Identity "CN=Daniel Foster,OU=Sales,DC=corp,DC=adlab,DC=local" `
  -TargetPath "OU=Marketing,DC=corp,DC=adlab,DC=local"
Set-ADUser -Identity dfoster -Department "Marketing" -Title "Marketing Coordinator"
```
Note the attribute change is separate from the move — moving the object relocates it in the tree;
it does not touch `Department`, which is just a text attribute. Real AD does not keep these in
sync automatically.

**Now prove the deletion-protection default, using a disposable OU so `Marketing` is undisturbed:**
```powershell
New-ADOrganizationalUnit -Name "Temp Test OU" -Path "DC=corp,DC=adlab,DC=local"
Remove-ADOrganizationalUnit -Identity "OU=Temp Test OU,DC=corp,DC=adlab,DC=local"
```
The second command should be **refused** — protected by default. Clear the flag and remove it for
real:
```powershell
Set-ADOrganizationalUnit -Identity "OU=Temp Test OU,DC=corp,DC=adlab,DC=local" `
  -ProtectedFromAccidentalDeletion $false
Remove-ADOrganizationalUnit -Identity "OU=Temp Test OU,DC=corp,DC=adlab,DC=local" -Confirm:$false
```

## A8/A9 — Create a group, add and remove members

**Create a Security group, Global scope, in the new Marketing OU:**
```powershell
New-ADGroup -Name "Marketing Team" -GroupScope Global -GroupCategory Security `
  -Path "OU=Marketing,DC=corp,DC=adlab,DC=local" -Description "Marketing department members"
```

**Add Daniel Foster, then verify:**
```powershell
Add-ADGroupMember -Identity "Marketing Team" -Members dfoster
Get-ADGroupMember -Identity "Marketing Team"
```

**Remove and re-add, to see both directions of `Add`/`Remove-ADGroupMember`:**
```powershell
Remove-ADGroupMember -Identity "Marketing Team" -Members dfoster -Confirm:$false
Get-ADGroupMember -Identity "Marketing Team"   # empty
Add-ADGroupMember -Identity "Marketing Team" -Members dfoster
```

## A11 — Security vs Distribution group, demonstrated not just described

**Create the Marketing distribution list, alongside the security group already made above:**
```powershell
New-ADGroup -Name "Marketing Distribution List" -GroupScope Global -GroupCategory Distribution `
  -Path "OU=Marketing,DC=corp,DC=adlab,DC=local" -Description "Marketing announcements"
Add-ADGroupMember -Identity "Marketing Distribution List" -Members dfoster
```

**Compare the two side by side:**
```powershell
Get-ADGroup -Identity "Marketing Team" -Properties GroupCategory,GroupScope
Get-ADGroup -Identity "Marketing Distribution List" -Properties GroupCategory,GroupScope
```
Same scope (`Global`), different `GroupCategory` (`Security` vs `Distribution`) — that one
attribute is the entire difference between "can be granted a permission" and "can only receive
mail". A Distribution group has no SID that participates in an access token at logon; a Security
group does. That's the one-sentence interview answer: **security groups carry a security
identifier that Windows evaluates at access-check time; distribution groups don't, so they're
invisible to permissions no matter where you try to use them.**

## Regulatory relevance

Delegation and access-tier structure exist because of a principle CSSF Circular 12/552 states at
the institution level: risk-taking and control of that risk should not sit with the same person.
Scoping delegation to one OU (A13, next lab) instead of granting broad admin rights is that same
segregation-of-duties idea, applied at directory-object scale. See
[`../REGULATORY-CONTEXT.md`](../REGULATORY-CONTEXT.md).

## Compare with the simulator

The deletion-protection default (A7) is the exact behaviour that was **missing** from the
`iam_guide` AD-Guide simulator until it was fixed — `New-ADOrganizationalUnit` used to report
`Protected: False` by default there. Confirming it here, on the real cmdlet, is the other half of
that finding: the simulator was wrong, and now matches what you just did by hand.

## Evidence for the ticket

- `Get-ADOrganizationalUnit -Filter 'Name -eq "Marketing"'` showing the new OU exists.
- The `Remove-ADOrganizationalUnit` refusal message on `Temp Test OU`, followed by the successful
  removal after clearing the flag.
- `Get-ADGroupMember -Identity "Marketing Team"` showing `dfoster`.
- The side-by-side `Get-ADGroup` output for the Security vs Distribution comparison.

## Traps

- Moving an object does **not** update its `Department`/`Title` attributes — those are separate,
  manual edits (`Set-ADUser`), easy to forget after a `Move-ADObject`.
- Trying to grant a resource permission to a Distribution group "because it's easier" — Windows
  will not evaluate it; the access silently never applies, which is a worse failure mode than an
  obvious error.
- Deleting an OU without `-Recursive` when it still holds objects — refused with a clear message,
  which is preferable to production behaviour some other directory products have (silent cascade
  delete).
