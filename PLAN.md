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
- [x] Lab 01 — DC01 built and promoted, RDP locked to your IP — ticket [2026-07-21_01](journal/tickets/2026-07-21_01_dc01-build.md)
- [x] `seed-ad.ps1` run, domain populated (8 OUs, 11 users, 7 groups — English/French roster)

Ticket to write: the build itself. It is the most portfolio-relevant single artifact here —
"I built a forest" is a stronger claim than any individual administration task.

### Phase 2 — Core AD administration (23/07 – 02/08)

Full step-by-step guides now written — [`labs/02-user-lifecycle.md`](labs/02-user-lifecycle.md),
[`labs/03-ous-and-groups.md`](labs/03-ous-and-groups.md),
[`labs/04-agdlp-remediation.md`](labs/04-agdlp-remediation.md). These are the day-one duties of
the job you are targeting, re-run against the real directory instead of the simulator.

- [x] A2 — create a user (**Marc Wolter**, Sales) in the correct OU; explain sAMAccountName vs
      UPN vs DN — ticket [2026-07-21_02](journal/tickets/2026-07-21_02_create-user-mwolter.md)
- [x] A3 — unlock `tweber`; locked vs disabled — ticket [2026-07-22_01](journal/tickets/2026-07-22_01_unlock-tweber.md)
      *(the account had already self-cleared overnight — the lockout duration expired while the VM sat deallocated, which turned out to be the clearest possible proof that locked ≠ disabled)*
- [x] A4 — reset `cdubois`'s password with change at next logon — ticket [2026-07-22_02](journal/tickets/2026-07-22_02_reset-password-cdubois.md)
- [x] A5 — disable **Marc Wolter** and move to Disabled Accounts — ticket [2026-07-27_01](journal/tickets/2026-07-27_01_disable-mwolter.md)
- [x] A6 — `Set-ADUser` on `jbennett` — ticket [2026-07-27_02](journal/tickets/2026-07-27_02_edit-attributes-jbennett.md)
      *(went further than planned: Surname, DisplayName, and the cn/Name/RDN turned out to be three independent attributes, not two)*
- [x] A7 — create the **Marketing** OU, move `dfoster` in; discover deletion protection is on by
      default (proven against a disposable OU) — see `labs/03-ous-and-groups.md`, ticket
      [2026-08-13_01](journal/tickets/2026-08-13_01_ous-and-groups-marketing.md)
- [x] A8/A9 — create **Marketing Team** (Security, Global), add/remove `dfoster` — ticket
      [2026-08-13_01](journal/tickets/2026-08-13_01_ous-and-groups-marketing.md)
- [x] A11 — create **Marketing Distribution List**; compare Security vs Distribution side by side —
      ticket [2026-08-13_01](journal/tickets/2026-08-13_01_ous-and-groups-marketing.md)
- [x] A10 — **AGDLP remediation**: the FS-Finance-* groups hold users directly on purpose, and the
      3-ReadWrite/1-ReadOnly split means the naive "nest one group everywhere" fix is itself
      wrong — see `labs/04-agdlp-remediation.md` for the access-tier-aware correction, ticket
      [2026-08-13_02](journal/tickets/2026-08-13_02_agdlp-remediation-finance.md)

### Phase 3 — Policy, delegation, lifecycle (03/08 – 10/08)

The part that separates a help-desk operator from someone who understands the directory.

- [x] A12 (core) — GPO: create/link two real GPOs (screen lock, drive mapping) to Sales, verify
      with `Get-GPO`/`Get-GPInheritance`, tested with **Group Policy Modeling** instead of
      `gpresult` (no `CLIENT01` yet) — ticket [2026-08-02_01](journal/tickets/2026-08-02_01_gpo-fundamentals-jml.md),
      guide `labs/05-gpo-fundamentals.md`. Includes a Joiner/Leaver-lite tie-in (Charlotte Perrin).
      *(Remaining for the full A12: `gpresult /r` against a real domain-joined client, and
      GPO enable/disable — needs `CLIENT01`, deferred to whenever that gets built)*
- [x] A13 — Delegation of Control: "reset user passwords" on one OU to `IT Support` — ticket
      [2026-08-14_01](journal/tickets/2026-08-14_01_delegation-of-control-sales.md)
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
