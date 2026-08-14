# IAM AD hands-on — real Active Directory lab

Building a real Active Directory forest on Azure infrastructure, and running a structured
administration track against it, documented as an audit-grade journal.

**Not a simulator.** Real Windows Server, real domain controller, real directory, real
evidence. The forest is `corp.adlab.local`, running on a VM in Azure.

## Why

The target role is **junior IAM, Active Directory focused, in a regulated environment**.
That job is on-premises AD work: unlock an account, reset a password, move an object between
OUs, fix a group membership, read a GPO result. This repository is that work, performed and
documented.

The regulated environment in question is a Luxembourg bank, so [`REGULATORY-CONTEXT.md`](REGULATORY-CONTEXT.md)
maps the AD tasks in this repo to the actual frameworks such a bank operates under — DORA and the
CSSF circulars — so the "why does this matter to the business" answer is ready, not improvised.

## Constraint that shapes everything

The lab runs on an **Azure free account: USD 200, activated 17/07/2026, expiring 16/08/2026**.
The credit expires on that date whether or not it is spent, so the project is scheduled against
the calendar, not the balance.

Read [`COST-CONTROL.md`](COST-CONTROL.md) **before creating any resource**. The one habit that
matters: *deallocate the VMs from the portal at the end of every session* - shutting Windows
down from inside the guest still bills for the reserved compute.

## Structure

```
iam_ad_hands_on/
├── COST-CONTROL.md     # read first - guardrails, sizing, teardown
├── PLAN.md             # the schedule, phased against the 16/08 credit expiry
├── REGULATORY-CONTEXT.md  # DORA / CSSF mapping for each exercise
├── labs/               # step-by-step build and exercise guides
│   ├── 00-azure-setup.md
│   ├── 01-domain-controller.md
│   ├── 02-user-lifecycle.md
│   ├── 03-ous-and-groups.md
│   ├── 04-agdlp-remediation.md
│   └── 05-gpo-fundamentals.md
├── scripts/
│   └── seed-ad.ps1     # populates the domain with the lab company
└── journal/            # the portfolio artifact
    ├── tickets/        # one per exercise, change-control format
    └── evidence/       # captures, each with a what/why caption
```

## The lab company

`seed-ad.ps1` creates the same fictional company used by the `iam_guide` simulator, so the
A1-A14 exercise track transfers to this real domain without rewriting it. It plants fixtures
on purpose:

- `tweber` is locked out - for the locked-vs-disabled exercise
- `cdubois` must change password at next logon
- `jpetit` is a **Finance** contractor sitting in the **Contractors** OU - so the DN proves it
  follows the OU, not the department
- The `FS-Finance-*` resource groups hold **users directly**, which is the AGDLP anti-pattern
  the group-design exercise asks you to remediate

## Related repositories

| Repo | Scope |
|---|---|
| `iam_guide` | Browser simulators (AD + Entra) and the original lab track. Fictional. Where the exercises were designed. |
| **this repo** | Real on-premises AD on Azure infrastructure. |
| `microsoft_entra_id_hands_on` | Real Entra ID tenant, SC-300 oriented. Cloud identity. |

"Azure AD" is the former name of **Entra ID** and is cloud identity - it is not what this
repository builds. AD DS running on an Azure VM is the classic on-premises directory that
happens to be hosted in the cloud. Both matter for a hybrid environment; they are different
products, and the distinction is worth being able to state.

## Status

**Complete and torn down.** Every exercise A2 through A14, plus the full L1/L2/L3
joiner/mover/leaver cycle, was executed against the real domain and documented in
`journal/tickets/`. See [`PLAN.md`](PLAN.md) for the phase-by-phase breakdown.

- **Phase 1** — forest built, DC01 promoted, domain seeded
- **Phase 2** — user lifecycle (A2-A6), OUs and groups (A7-A9, A11), AGDLP remediation (A10)
- **Phase 3** — GPO fundamentals (A12), delegation of control (A13), full joiner/mover/leaver
  cycle (L1-L3), written AD vs Entra ID comparison (A14)
- **Phase 4** (hybrid, Entra Connect) — cut, as planned, to protect the teardown deadline
- **Phase 5** — resource group `rg-adlab` torn down on 2026-08-14, ahead of the 16/08 credit expiry

The domain no longer exists. Every claim in this repository is backed by a ticket and evidence
captured while it did.

---

*Training lab. All user data is fictional.*
