# Azure IAM hands-on — real Active Directory lab

Building a real Active Directory forest on Azure infrastructure, and running a structured
administration track against it, documented as an audit-grade journal.

**Not a simulator.** Real Windows Server, real domain controller, real directory, real
evidence. The forest is `corp.adlab.local`, running on a VM in Azure.

## Why

The target role is **junior IAM, Active Directory focused, in a regulated environment**.
That job is on-premises AD work: unlock an account, reset a password, move an object between
OUs, fix a group membership, read a GPO result. This repository is that work, performed and
documented.

## Constraint that shapes everything

The lab runs on an **Azure free account: USD 200, valid for 30 days**. The credit expires on
the deadline whether or not it is spent, so the project is scheduled against the calendar, not
the balance.

Read [`COST-CONTROL.md`](COST-CONTROL.md) **before creating any resource**. The one habit that
matters: *deallocate the VMs from the portal at the end of every session* - shutting Windows
down from inside the guest still bills for the reserved compute.

## Structure

```
azure_iam_hands_on/
├── COST-CONTROL.md     # read first - guardrails, sizing, teardown
├── PLAN.md             # the 30-day schedule, phased against the credit expiry
├── labs/               # step-by-step build and exercise guides
│   ├── 00-azure-setup.md
│   └── 01-domain-controller.md
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

- `mwilson` is locked out - for the locked-vs-disabled exercise
- `lthompson` must change password at next logon
- `dperez` is a **Finance** contractor sitting in the **Contractors** OU - so the DN proves it
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

Scaffold complete. Lab 00 and Lab 01 written. Nothing executed yet.

---

*Training lab. All user data is fictional.*
