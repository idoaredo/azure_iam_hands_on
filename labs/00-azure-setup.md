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

You will restrict RDP to it in the next lab. Find it at <https://ifconfig.me> or by searching
"what is my IP".

**This changes** when your ISP reassigns it or you move networks. When RDP stops working
later, this is the first thing to re-check — not a broken VM.

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
