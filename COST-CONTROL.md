# Cost control — read this before creating anything

The credit is an **Azure free account: USD 200, activated 17/07/2026, expiring 16/08/2026**.
Two things follow from that, and they shape the whole project:

1. **The clock, not the balance, is the binding constraint.** The credit expires on 16/08
   whether or not it is spent. The plan is therefore built around a schedule, not a budget.
2. **The real numbers (below) are comfortable.** Even the worst realistic case — both VMs
   running non-stop for the whole remaining window, on Premium SSD — lands under half the
   credit. The habits below are still worth keeping, because they are the same discipline the
   job itself expects, not because the math is tight.

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

Not zero, and in this lab **larger than the compute cost** once you are deallocating
regularly — the disk and the IP are the actual dominant line items, not the VM:

- **Managed disk** — charged as long as it exists, running or not. A 128 GiB Standard SSD
  (`E10`) runs about $10.78/month; the **Premium SSD** (`P10`) Azure often pre-selects by
  default costs **$21.68/month** for the same size, with no benefit for this workload.
  **Change the disk type to Standard SSD when creating the VM.** It is the single most
  effective cost lever available and it costs nothing to use.
- **Public IP** (Standard SKU, static) — about $0.005/hour (~$3.65/month if left allocated
  the whole time).
- Snapshots, if you take any — skip them unless you have a specific reason.

It is fine to leave the disks provisioned between sessions; it is not fine to leave the VM
compute running, since that is the one meter that scales with hours rather than sitting flat.

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

**Region:** the operator is based in Luxembourg, so **Belgium Central** was chosen over the
more commonly suggested `brazilsouth` or `eastus` — it gives the best RDP latency for the
operator's actual location, which matters more than a small price difference given how many
hours are spent inside that remote session. Keep every resource in this one region; a VM and
a virtual network in different regions cannot connect.

## Real prices (Belgium Central, pay-as-you-go, checked 2026-07-20 via the Azure Retail
Prices API — reverify before relying on this if it has been a while)

| Item | Price |
|---|---|
| `Standard_B2s` Windows compute | $0.056 / hour |
| Standard SSD 128 GiB (`E10`) | ~$10.78 / month (incl. mount fee) |
| Premium SSD 128 GiB (`P10`) | $21.68 / month |
| Standard static public IP | $0.005 / hour (~$3.65 / month if always allocated) |

## Estimated total for the remaining plan (20/07 → 15/08, DC01 + CLIENT01 from Phase 3)

| Scenario | Estimated total |
|---|---|
| **Realistic** — Standard SSD, ~3 h/day compute, deallocated the rest | **~$26** |
| **Worst case** — Premium SSD, both VMs left running the entire time they exist | **~$87** |

Both are comfortably inside the $200 credit. The deallocate habit and the Standard SSD choice
are worth keeping anyway — they are the same operational discipline expected on the job, not
a requirement for staying solvent here.

## End of the project

On the last day, after the evidence is captured and committed:

**Delete the resource group.** Not the VMs individually — the whole group. Then confirm in
Cost Management that the daily spend drops to zero. A resource you forgot about is only
discovered by the bill.

Capture the evidence **before** deleting. A screenshot of a domain that no longer exists is
still valid evidence; a domain you deleted before capturing is a week of work with nothing to
show for it.
