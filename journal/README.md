# Lab journal — real Active Directory on Azure

Audit-grade record of hands-on work performed against a **real** Active Directory forest
(`corp.adlab.local`), built on Azure infrastructure. Each exercise is documented as a ticket
following the change-control style used in regulated environments: request, approval, actions,
evidence, confirmation.

**Why this exists:** proof of practical AD skills for a junior IAM role in a regulated
environment. The git history provides timestamped evidence for every ticket.

## How this journal works

1. One ticket per exercise in [`tickets/`](tickets/), named `YYYY-MM-DD_NN_short-title.md`
   (see [`tickets/_TEMPLATE.md`](tickets/_TEMPLATE.md)).
2. Evidence goes in [`evidence/`](evidence/) and is referenced by filename in the ticket.
   **Every item carries a caption: what it shows and why it was captured** (which claim it
   proves).
3. **Only actions actually performed are documented.** Skipped steps are stated as skipped.
   A blocked exercise gets a ticket describing what was tried and what failed - that is a real
   artifact.
4. After each ticket: `git commit` with a meaningful message.
5. Written the same day the work is done. Evidence captured a week later is reconstructed, not
   recorded.

## Redaction rules

This repository may become public. Never commit:

- Subscription ID, tenant ID, or directory ID
- The VM's public IP address
- Passwords, including the DSRM password, in any form
- Screenshots showing personal browser tabs, bookmarks, or e-mail

Recording the *type* of subscription, or that a DSRM password was set, is enough.

## Relationship to the other repositories

| Repo | What it is |
|---|---|
| `iam_guide` | Browser simulator plus the original lab track (A1-A14). Fictional data. Where the exercises were designed and rehearsed. |
| **this repo** | The same track executed against a real forest on real infrastructure. |
| `microsoft_entra_id_hands_on` | Real Entra ID tenant, oriented to the SC-300 exam. Cloud identity, kept separate. |

Where an exercise was done in both the simulator and here, the ticket notes the differences.
Those differences are the most interesting content in this journal.

## Ticket index

| Ticket ID | Date | Category | Title | Status |
|---|---|---|---|---|
| [2026-07-20_00](tickets/2026-07-20_00_azure-setup.md) | 2026-07-20 | Infrastructure | Azure account, guardrails, resource group | Done |
| [2026-07-21_01](tickets/2026-07-21_01_dc01-build.md) | 2026-07-21 | Infrastructure | Build DC01, promote to DC, seed the lab company | Done |
