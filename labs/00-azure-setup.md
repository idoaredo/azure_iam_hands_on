# Lab 00 — Azure account, guardrails, and the resource group

**Do this before creating any VM.** It takes about fifteen minutes and it is the difference
between a controlled lab and a surprise bill.

## Objective

Have a subscription you understand, a budget alert that will warn you, and a single resource
group that can be deleted in one action at the end.

## Why this matters beyond the lab

In a regulated environment nobody hands you a subscription without a cost boundary and an
owner. Setting the boundary before creating the resource is the same instinct as scoping a
policy to a named group instead of "All users": you decide the blast radius up front.

## Steps

### 1. Confirm what kind of credit you have

Azure portal → **Subscriptions** → open your subscription → **Overview**.

Record two things for the ticket:
- The **subscription name and type** (Free Trial / Azure for Students / Pay-As-You-Go).
- The **credit expiry date**. On a free account this is 30 days from activation, and it is
  the deadline the whole plan runs against.

> If the subscription shows as Pay-As-You-Go with a credit attached, the credit still expires
> on its own date — spending past it starts charging a real payment method. Know which you
> have.

### 2. Set the budget alert (before anything exists)

**Cost Management + Billing** → **Cost Management** → **Budgets** → **Add**.

- Scope: the subscription
- Amount: `100` USD, monthly
- Alert conditions: **50%** and **90%** of budget
- Alert recipient: your e-mail

A budget does not stop spending. It tells you early enough to act, which is all you need
given that the real risk here is a forgotten VM rather than a runaway service.

### 3. Create the resource group

**Resource groups** → **Create**.

- Name: `rg-adlab`
- Region: `brazilsouth` (or your chosen region — keep everything in one)

Everything in this project goes in this group. At the end, deleting the group removes the
VMs, disks, NICs, IPs, and virtual network in a single operation.

### 4. Note your own public IP

Your machine has two addresses. The **private** one (`192.168.x.x` or similar) exists only
inside your home network and nobody outside can see it. The **public** one belongs to your
router, is assigned by your ISP, and is what Azure sees when you connect — every device in
your house shares it. It is the public one you need here.

Find it at <https://ifconfig.me>, or search for "what is my IP".

**Why it matters:** when Azure creates a VM with RDP enabled, it opens port 3389 to
`0.0.0.0/0` — the entire internet. That is not a theoretical exposure: automated scanners
sweep cloud IP ranges continuously, and a new VM typically starts receiving login attempts
within minutes, trying `administrator`, `admin`, and common passwords. On a domain controller,
which holds the credentials for the whole domain, that is unacceptable even in a lab. Setting
the rule's source to your address means Azure drops everything else before it ever reaches
Windows.

**This address changes** — residential ISPs hand out dynamic addresses that rotate when you
reboot the router, when the lease renews, or on their own schedule. It is also different if
you switch networks (phone hotspot, another location).

When that happens the symptom is that **RDP simply stops connecting** and times out. It looks
like a dead VM, and it is a stale firewall rule. Re-check your IP and update the rule's source
before investigating anything else — this is the first thing to check, not the last.

## Validation

- [ ] Subscription type and credit expiry date written down
- [ ] Budget alert exists and shows in the Budgets list
- [ ] `rg-adlab` exists and is empty
- [ ] Your current public IP noted

## Evidence for the ticket

- Screenshot of the **Budgets** blade showing the created budget.
- Screenshot of the empty resource group.

Capture only the portal window. The subscription ID and your tenant ID are identifiers you do
not need in a public repository — crop them out or blur them. Recording the *type* of
subscription is enough.

## Traps

- **Creating resources outside `rg-adlab`.** Azure remembers the last group you used, but it
  is easy to accept a different default. Check the field on every create blade.
- **Choosing a different region per resource.** A VM in one region and a virtual network in
  another cannot be connected. Pick the region once.
- **Assuming the budget will stop the spend.** It will not. It is an alarm, not a brake.
