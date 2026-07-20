# The plan — deadline 16/08/2026

The credit expires on its date regardless of how much is left. The schedule below is therefore
built around that deadline, with the expensive and irreversible parts early and the optional
parts last.

| | Date | |
|---|---|---|
| Credit activated | **2026-07-17** | Azure sign-up credit, USD 200 |
| Planning started | 2026-07-20 (Mon) | 3 days already gone |
| **Credit expires** | **2026-08-16** (Sun) | Hard stop |
| **Teardown deadline** | **2026-08-15** (Sat) | Everything deleted by this day |

**27 days remain.** The schedule below is calendar dates, not "day N" — the three days already
spent are not coming back, and a plan that quietly assumes 30 will overrun.

> Expiry falls on a **Sunday**. Do not plan work for 16/08: treat 15/08 as the last day the
> lab exists. When the credit runs out Azure disables the resources, but deleting the resource
> group yourself is the only way to be certain nothing survives into a paid subscription if
> you ever upgrade.

## Phases

### Phase 1 — Foundation (20/07 – 22/07, Mon–Wed)

Get the domain standing. Nothing else can start until this works, so it goes first and gets
whatever time it needs.

- [x] Lab 00 — subscription, budget alert, resource group — ticket [2026-07-20_00](journal/tickets/2026-07-20_00_azure-setup.md)
- [ ] Lab 01 — DC01 built and promoted, RDP locked to your IP
- [ ] `seed-ad.ps1` run, domain populated

Ticket to write: the build itself. It is the most portfolio-relevant single artifact here —
"I built a forest" is a stronger claim than any individual administration task.

### Phase 2 — Core AD administration (23/07 – 02/08)

The track from `iam_guide`'s PROGRESS.md, re-run against the real directory. These are the
day-one duties of the job you are targeting.

- [ ] A2 — create a user in the correct OU; explain sAMAccountName vs UPN vs DN
      *(check `dperez` — Finance department, Contractors OU — the DN follows the OU)*
- [ ] A3 — unlock an account; `Search-ADAccount -LockedOut`; locked vs disabled
- [ ] A4 — password reset with change at next logon; note `PasswordExpired : True` afterwards
- [ ] A5 — disable and move to Disabled Accounts; disable vs delete
- [ ] A6 — `Set-ADUser` attributes; note GivenName/Surname do not rebuild DisplayName
- [ ] A7 — create an OU, move objects in; discover deletion protection is on by default
- [ ] A8/A9 — groups: scope, members, `Get-ADGroupMember`
- [ ] A10 — **AGDLP remediation**: the FS-Finance-* groups hold users directly on purpose;
      restructure into user -> Global -> Domain Local -> Permission
- [ ] A11 — Security vs Distribution group

### Phase 3 — Policy, delegation, lifecycle (03/08 – 10/08)

The part that separates a help-desk operator from someone who understands the directory.

- [ ] A12 — GPO: link/unlink, enable/disable, `gpresult /user <sam> /r`, LSDOU order
      *(requires CLIENT01 — create it now, deallocate it when not in use)*
- [ ] A13 — Delegation of Control: "reset user passwords" on one OU to `IT Support`
- [ ] L1 / L2 / L3 — Joiner, Mover, Leaver end to end
      *(the Mover trap: old access must be REMOVED, not only new access added)*
- [ ] A14 — written AD vs Entra comparison

### Phase 4 — Hybrid, if time allows (11/08 – 14/08)

Optional. Do it only if Phase 3 is genuinely finished — a half-configured sync is worse
evidence than no sync.

- [ ] Entra Connect installed on DC01, syncing to the tenant from `microsoft_entra_id_hands_on`
- [ ] Prove source of authority: change an attribute on-prem, watch it appear in the cloud,
      then try to edit the synced user in the cloud and be refused

> This touches the SC-300 tenant. Do not let it disturb the P2 trial timing planned there.

### Phase 5 — Teardown (by 15/08 — Saturday, hard deadline)

**Do not skip and do not leave to the last hour.**

- [ ] Every ticket written and committed, with evidence
- [ ] Final captures taken (a screenshot of a domain that no longer exists is still valid
      evidence; a domain deleted before capture is a month of work with nothing to show)
- [ ] `README.md` updated with what was actually completed
- [ ] **Delete the resource group `rg-adlab`**
- [ ] Confirm in Cost Management that daily spend has dropped to zero

## Rules that keep this on schedule

**Deallocate at the end of every session.** Portal, not guest shutdown. See
[`COST-CONTROL.md`](COST-CONTROL.md).

**One ticket per exercise, written the same day.** Evidence captured a week later is
reconstructed, not recorded — and the whole value of the journal is that it is contemporaneous.

**A blocked exercise is not a blocked project.** If something will not work, write the ticket
describing what you tried and what the error was, mark it blocked, and move on. A documented
failure is a real artifact; a stalled month is not.

**Phase 4 is the first thing to cut.** If the schedule slips, the hybrid sync is what gets
dropped — not the teardown, and not the tickets.
