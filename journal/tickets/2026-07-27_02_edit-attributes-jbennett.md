# Ticket 2026-07-27_02 — Edit attributes with Set-ADUser (James Bennett)

**Ticket ID:** 2026-07-27_02
**Date:** 2026-07-27
**Category:** AD
**Environment:** Real — `corp.adlab.local` on Azure (DC01)

## Request

**Requester (simulated):** Laurent Girard, IT Manager — James Bennett promoted; also a legal
surname change to record.

## Approval

**Not applicable — no approval required.** Routine attribute update, not a directory-structure
or access change.

## Actions taken

```powershell
Set-ADUser -Identity jbennett -Title "Senior Systems Administrator" -Description "Promoted 2026"
Set-ADUser -Identity jbennett -Surname "Bennett-Hoffmann"
```

## Validation

```powershell
Get-ADUser -Identity jbennett -Properties Title,Surname,DisplayName
```
```
DisplayName       : James Bennett
DistinguishedName : CN=James Bennett,OU=Information Technology,DC=corp,DC=adlab,DC=local
Name              : James Bennett
Surname           : Bennett-Hoffmann
Title             : Senior Systems Administrator
```
`Title` and `Surname` changed as requested. `DisplayName` — and the `Name`/`DistinguishedName`
(the `cn`) — did **not**, confirming they are separate attributes from `Surname`.

Fixed `DisplayName` explicitly:
```powershell
Set-ADUser -Identity jbennett -DisplayName "James Bennett-Hoffmann"
Get-ADUser -Identity jbennett -Properties Title,Surname,DisplayName
```
```
DisplayName       : James Bennett-Hoffmann
DistinguishedName : CN=James Bennett,OU=Information Technology,DC=corp,DC=adlab,DC=local
Name              : James Bennett
```
`DisplayName` now correct — but `Name`/`DistinguishedName` (the `cn`, the ADUC list's "Name"
column, and part of the object's DN) **still** reads `James Bennett`. Setting `DisplayName` does
not touch it either. Changing the object's actual name in the tree requires a separate rename
action entirely:
```powershell
Rename-ADObject -Identity "CN=James Bennett,OU=Information Technology,DC=corp,DC=adlab,DC=local" `
  -NewName "James Bennett-Hoffmann"
```
(Not executed in this ticket — noted for completeness; the ADUC list continuing to show "James
Bennett" after both `Set-ADUser` calls is the finding this ticket documents, not a defect to fix.)

## Evidence

- `evidence/2026-07-27_02_jbennett-title-set.png` — **What:** ADUC's Organization tab showing the
  new Job Title, and the object list already reflecting the new `Description` ("Promoted 2026")
  next to the still-unchanged "James Bennett" name. **Why:** confirms the first `Set-ADUser` call
  took effect immediately in the GUI.
- `evidence/2026-07-27_02_jbennett-displayname-gap.png` — **What:** both `Get-ADUser` queries (before
  and after the `DisplayName` fix) in one terminal capture, alongside ADUC's General tab showing
  Last name "Bennett-Hoffmann" and Display name "James Bennett-Hoffmann" — while the list and the
  `Name`/`DistinguishedName` fields still read "James Bennett" in both queries. **Why:** proves,
  in a single capture, that `Surname`, `DisplayName`, and `Name`/`cn` are three independent
  attributes, none of which updates the others. VM public IP and time of day redacted in both.

## Result & user confirmation

Title, description and surname updated; display name corrected explicitly. The object's `cn`/RDN
was deliberately left as "James Bennett" to document the finding — a full rename was out of scope
for this ticket.

## Regulatory relevance

Keeping HR-facing attributes (title, department) accurate and current is part of the same
least-privilege thread as the rest of this lab — access reviews and delegation scoping (A13) rely
on `Department`/`Title` being trustworthy, so an admin who only fixes `DisplayName` and assumes
the directory is now consistent would be wrong three different ways. See
[`../../REGULATORY-CONTEXT.md`](../../REGULATORY-CONTEXT.md).

## What I learned

The main takeaway is to be careful with the kind of change you make, especially through the
shell: a single command only touches exactly the attribute you name, so it's easy to miss that
other, seemingly linked attributes (like DisplayName) don't update along with it. The GUI,
showing several related fields on the same screen, makes it easier to notice when something was
left inconsistent.
