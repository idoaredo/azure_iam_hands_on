# Cost control — read this before creating anything

The credit is an **Azure free account: USD 200, valid for 30 days**. Two things follow from
that, and they shape the whole project:

1. **The clock, not the balance, is the binding constraint.** The credit expires on day 30
   whether or not it is spent. The plan is therefore built around a schedule, not a budget.
2. **A VM left running by accident is the only way to actually run out of money.** Two
   Windows Server VMs left on 24/7 for the full month would consume most of the credit for
   nothing, because you are asleep for a third of it.

## The single most important habit

**Stop (deallocate) the VMs from the Azure portal when you finish for the day.**

Shutting Windows down from inside the VM is **not** enough:

| State | Shown in portal | Compute charged? |
|---|---|---|
| Running | `Running` | Yes |
| Shut down from inside the guest OS | `Stopped` | **Yes — still reserved** |
| Stopped from the portal / CLI | `Stopped (deallocated)` | No |

Only `Stopped (deallocated)` releases the compute. This distinction catches almost everyone
once; it is worth knowing before it costs you a week of credit.

## What still costs money when the VM is deallocated

Small, but not zero:

- **Managed disks** — charged as long as they exist, running or not.
- **Public IP** (Standard SKU, static) — charged while reserved.
- Snapshots, if you take any.

For this lab that is on the order of a few dollars a month, not a few dollars a day. It is
fine to leave the disks; it is not fine to leave the VMs running.

## Guardrails to put in place on day 1 (before creating a VM)

1. **Budget alert** on the subscription at USD 50 and USD 100 (Cost Management → Budgets).
   It does not stop anything — it e-mails you. That is enough if you act on it.
2. **Auto-shutdown** on every VM, at a time you are certain to be done (Operations →
   Auto-shutdown). Free, built in, and it is the backstop for the night you forget.
3. **One resource group for everything** (`rg-adlab`). Deleting that single group at the end
   removes every resource in one action — no orphans quietly billing.

## Sizing

| VM | Size | Why |
|---|---|---|
| DC01 (domain controller) | `Standard_B2s` (2 vCPU, 4 GiB) | The practical minimum for Windows Server 2022 running AD DS + DNS. `B1s` (1 GiB) will thrash. |
| CLIENT01 (member) | `Standard_B2s` | Only needed from the "join a client to the domain" exercise onward. Create it late, delete it early. |

Use **Windows Server 2022** for the client machine too, not Windows 10/11. A member server
joins the domain and demonstrates the same thing, and it avoids the client-OS licensing
rules that Azure applies to Windows client images.

**Region:** pick one and keep everything in it. `brazilsouth` gives the best RDP latency from
Brazil, which matters because you will spend hours in that session. Cheaper regions exist
(`eastus` is usually lowest), but a laggy remote desktop wastes more of your 30 days than the
price difference saves.

Prices move and vary by region — check the Azure pricing calculator for the real number
rather than trusting any figure written here. The shape to remember: a B2s Windows VM costs
roughly ten times more per month running 24/7 than it does at three hours a day.

## Order-of-magnitude budget

| Pattern | Rough monthly cost |
|---|---|
| 2 VMs, 24/7 | Most of the credit |
| 2 VMs, ~3 h/day | A small fraction of it |
| Disks + IP only (VMs deallocated) | A few dollars |

The intended pattern is the middle row: work in sessions, deallocate at the end of each one.

## End of the project

On the last day, after the evidence is captured and committed:

**Delete the resource group.** Not the VMs individually — the whole group. Then confirm in
Cost Management that the daily spend drops to zero. A resource you forgot about is only
discovered by the bill.

Capture the evidence **before** deleting. A screenshot of a domain that no longer exists is
still valid evidence; a domain you deleted before capturing is a week of work with nothing to
show for it.
