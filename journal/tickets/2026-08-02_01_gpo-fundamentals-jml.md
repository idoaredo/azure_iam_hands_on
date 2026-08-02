# Ticket 2026-08-02_01 — GPO fundamentals and a Joiner/Leaver tie-in

**Ticket ID:** 2026-08-02_01
**Date:** 2026-08-02
**Category:** Policy
**Environment:** Real — `corp.adlab.local` on Azure (DC01)

## Request

**Requester (simulated):** Laurent Girard, IT Manager — standardise two common policies for the
Sales department (screen lock, shared drive mapping), and confirm the offboarding process really
removes them from a departing user.

## Approval

**Approver (simulated):** Laurent Girard, IT Manager.
**Four-eyes note:** policy change reviewed before linking to a live OU.

## Actions taken

1. Created GPO **Screen Lock Policy - Sales**, linked to the `Sales` OU. Configured screen saver
   enabled, timeout, and password-protect under
   `User Configuration → Administrative Templates → Control Panel → Personalization`.
2. Explored (not configured) **Interactive logon: Machine inactivity limit** under
   `Computer Configuration → Security Options` — a newer alternative to the screen saver approach.
3. Created GPO **Drive Mapping - Sales**, linked to the same OU. Configured a Drive Maps
   preference: `Z:` → `\\DC01\NETLOGON`.
4. Verified both links with `Get-GPO` and `Get-GPInheritance`.
5. Ran **Group Policy Modeling** (no domain-joined client exists yet, so this replaces `gpresult`
   for this exercise) against an existing Sales user (`dfoster`) — both GPOs applied.
6. **Joiner:** created `cperrin` (Charlotte Perrin) directly in the `Sales` OU. Modeling confirmed
   both GPOs applied immediately, with no per-user configuration.
7. **Leaver:** disabled `cperrin` and moved her to `Disabled Accounts` (same pattern as ticket
   [2026-07-27_01](2026-07-27_01_disable-mwolter.md)).
8. Re-ran Modeling against the `Disabled Accounts` OU — **Applied GPOs came back empty**,
   confirming the policies no longer reach an account once it leaves the Sales OU.

## Validation

```powershell
Get-GPO -Name "Screen Lock Policy - Sales"
Get-GPO -Name "Drive Mapping - Sales"
Get-GPInheritance -Target "OU=Sales,DC=corp,DC=adlab,DC=local"
```
`GpoLinks : {Screen Lock Policy - Sales, Drive Mapping - Sales}`, `GpoInheritanceBlocked : No`.

Group Policy Modeling reports (GPMC → Group Policy Modeling) for `dfoster`, `cperrin`, and the
`Disabled Accounts` OU — the first two list both GPOs under **Applied GPOs**; the last lists none.

## Evidence

- `evidence/2026-08-02_01_gpo1-screenlock-created.png` — **What:** the Screen Lock GPO linked to
  Sales, with the screen saver settings (enabled, timeout, password-protect) visible in the
  editor. **Why:** proves the first policy was created and configured correctly.
- `evidence/2026-08-02_01_bonus-machine-inactivity-limit.png` — **What:** the "Machine inactivity
  limit" security option dialog, left unconfigured. **Why:** documents that this alternative
  approach to screen locking was looked at and understood, even though not used here.
- `evidence/2026-08-02_01_gpo2-drivemap-z.png` — **What:** the Drive Maps preference mapping `Z:`
  to `\\DC01\NETLOGON`. **Why:** proves the second policy, using a share that genuinely exists on
  any domain controller rather than a made-up path.
- `evidence/2026-08-02_01_verify-gpo-inheritance.png` — **What:** `Get-GPO` output for both GPOs
  plus `Get-GPInheritance` for the Sales OU listing both under `GpoLinks`. **Why:** proves the
  GPOs are not just created but actually linked and unblocked at that OU.
- `evidence/2026-08-02_01_modeling-dfoster-applied.png` — **What:** a Group Policy Modeling report
  for an existing Sales user, both GPOs listed under Applied GPOs. **Why:** proves the policies
  reach a real user in that OU, checked with the correct tool given no client machine exists yet.
- `evidence/2026-08-02_01_modeling-cperrin-joiner-applied.png` — **What:** the same modeling report
  for the newly created `cperrin`, same two GPOs applied. **Why:** proves policy followed the OU
  placement automatically, with zero per-user setup.
- `evidence/2026-08-02_01_cperrin-disabled-accounts.png` — **What:** ADUC showing `cperrin`
  disabled and relocated into `Disabled Accounts`. **Why:** the offboarding action itself.
- `evidence/2026-08-02_01_modeling-disabledou-empty.png` — **What:** a Group Policy Modeling report
  for the `Disabled Accounts` OU with an empty Applied GPOs section. **Why:** the payoff of the
  whole exercise — proves that moving a user out of Sales genuinely removes the policies that used
  to apply, not just that the object was relocated. All eight images redacted (VM public IP, time
  of day).

## Result & user confirmation

Both GPOs created, linked, and verified. End-to-end joiner/leaver test confirms policy scope is
tied to OU membership, not to the user account itself.

## Regulatory relevance

DORA Art. 9(4)(c) — the same "access limited to what is required" principle extends to policy
enforcement, not only permissions: an offboarded account losing its GPO scope the moment it leaves
the OU is the technical mechanism behind that requirement, not just a side effect. See
[`../../REGULATORY-CONTEXT.md`](../../REGULATORY-CONTEXT.md).

## What I learned

**On the two GPOs:** what stood out is the trade-off between depth and breadth of control — the
screen saver approach has several separate settings (enable, timeout, password-protect), while
Machine inactivity limit is one single, more blanket setting that achieves a similar result.

**On `Get-GPInheritance`:** a GPO links to an **OU** (or domain, or site) — never to a group. A
group's role is secondary: by default a GPO applies to everyone in the OU it's linked to
("Authenticated Users", visible in the Security Filters field), and a security group can be used
to *narrow* that down further via Security Filtering. This is not the same thing as RBAC — RBAC
assigns permissions to a role and then users to that role; a GPO's scope is decided by an object's
*location* in the directory tree, filtered by group membership only as an optional second step.

**On Group Policy Modeling:** it shows plainly what applies and what doesn't for a given user or
computer, and that scope can be widened (linking higher in the tree, e.g. domain-wide instead of
one OU) or narrowed (a smaller OU, or Security Filtering) depending on how broad the policy should
be.

**On the Joiner/Leaver test:** creating Charlotte Perrin directly inside Sales — an OU that already
had both GPOs linked — meant she fell under those policies automatically, with nothing configured
on her individually. Disabling and moving her out removed that scope just as automatically. Basic,
but a genuinely complete create → assign → offboard cycle.
