# Lab 01 — Build DC01 and promote it to a domain controller

**Prerequisite:** Lab 00 complete (`rg-adlab` exists, budget alert set, your public IP noted).

## Objective

A running Windows Server 2022 VM, promoted to the first domain controller of a new forest
`corp.adlab.local`, reachable over RDP from your machine only.

## Why this matters

This is the exercise that separates "I have read about Active Directory" from "I have built
one". Promoting a server to a DC creates the forest, the domain, the schema, the DNS zone and
the default policies in one operation — and it is the moment the concepts stop being abstract.

## Concepts before the clicks

- **A domain controller is a role, not a product.** The same Windows Server becomes a DC by
  installing the AD DS role and promoting it. Before promotion it is an ordinary server with a
  local account database; after promotion it holds a copy of the directory.
- **The DC must be its own DNS server.** AD DS depends on DNS to publish the service records
  clients use to find the domain. The promotion installs and configures DNS for you — which is
  why the VM's DNS setting must point at itself afterwards, not at the Azure resolver.
- **The forest is created once.** `corp.adlab.local` will be a new forest, so this VM holds
  all five FSMO roles. In the simulator these were split across DC01 and DC02; here you will
  see them all on one server, which is what a single-DC forest looks like.

## Steps

### 1. Create the VM

**Virtual machines** → **Create** → **Azure virtual machine**.

Basics:
- Resource group: `rg-adlab`
- Name: `DC01`
- Region: the one from Lab 00
- Image: **Windows Server 2022 Datacenter — x64 Gen2**
- Size: `Standard_B2s`
- Username: `labadmin` (avoid `admin` and `administrator` — Azure rejects them)
- Password: store it in your password manager now, not in a text file

Inbound ports:
- Select **RDP (3389)** so the VM is reachable, then fix the exposure in step 2 before you
  connect. Azure creates the rule open to the internet by default.

Disks: default (Premium SSD or Standard SSD are both fine at this size).

Networking: accept the new virtual network Azure proposes. Note its name — **CLIENT01 must go
on this same virtual network later**, or the two machines will not see each other and domain
join will fail with DNS errors that look like something else.

### 2. Lock RDP down to your IP — do this before connecting

**This is the one step in the lab with a real security consequence.** A Windows Server with
3389 open to `0.0.0.0/0` starts receiving automated login attempts within minutes of being
created. On a domain controller that is an unacceptable exposure even in a lab.

VM → **Networking** → inbound port rule for RDP → **Source**: change from `Any` to
**My IP address** → Save.

> If RDP stops working days later, check this rule first. A changed home IP looks exactly
> like a broken VM.

### 3. Set a static private IP

VM → **Networking** → network interface → **IP configurations** → `ipconfig1` → Assignment:
**Static** → Save. The VM restarts.

A domain controller whose address changes breaks DNS for every client that points at it. In
Azure the private IP is stable in practice but assigned dynamically by default; making it
static removes the question.

### 4. Install the AD DS role

Connect over RDP. In **Server Manager** → **Manage** → **Add Roles and Features** →
Role-based installation → this server → check **Active Directory Domain Services** → accept
the required features → Install.

Equivalent in PowerShell, which is worth running instead if you want the practice:

```powershell
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
```

### 5. Promote to domain controller

Server Manager shows a flag notification: **Promote this server to a domain controller**.

- Deployment: **Add a new forest**
- Root domain name: `corp.adlab.local`
- Forest and domain functional level: **Windows Server 2016** (or higher if offered)
- DNS server: leave checked
- DSRM password: record it in your password manager — it is the recovery password, and it is
  not the same as the admin password
- NetBIOS name: accept `CORP`

The server restarts. After it comes back, your RDP login changes from the local account to
`CORP\labadmin`.

PowerShell equivalent:

```powershell
Install-ADDSForest -DomainName "corp.adlab.local" -DomainNetbiosName "CORP" -InstallDNS
```

### 6. Point the VM's DNS at itself

Back in the Azure portal: virtual network → **DNS servers** → **Custom** → enter DC01's
private IP → Save. Then restart DC01's network interface (or the VM).

Without this, domain-joined machines ask the Azure resolver for the domain's service records,
which it does not have, and the join fails.

## Validation

Run these on DC01 and keep the output for the ticket:

```powershell
Get-ADDomain
Get-ADForest
Get-ADDomainController
```

Check:
- [ ] `Get-ADDomain` returns `corp.adlab.local` with NetBIOS `CORP`
- [ ] All five FSMO roles are held by DC01 (three from `Get-ADDomain`, two from `Get-ADForest`)
- [ ] `Get-ADDomainController` shows DC01 as a global catalog
- [ ] Active Directory Users and Computers opens and shows the default containers and the
      `Domain Controllers` OU

## Compare with the simulator

You have already read this exact output in `iam_guide`. Two things to check deliberately:

1. **The five FSMO roles still need two cmdlets** — three domain-level from `Get-ADDomain`,
   two forest-level from `Get-ADForest`. Same rule, real directory.
2. **`Builtin`, `Computers` and `Users` are containers; `Domain Controllers` is an OU.** In
   ADUC, turn on **View → Advanced Features** and compare the icons and the object types. This
   is the distinction the simulator got wrong until it was fixed — confirm it here, in the real
   console, and the ticket becomes the authoritative version of that finding.

## Evidence for the ticket

- `Get-ADDomain` and `Get-ADForest` output in one capture (proves the domain exists and the
  FSMO split).
- ADUC open, showing the tree with the default containers and `Domain Controllers`.

Application window only. No subscription ID, no tenant ID, no public IP of the VM.

## Traps

- **Deallocate the VM when you stop for the day.** From the portal, not from inside Windows.
  See [`../COST-CONTROL.md`](../COST-CONTROL.md).
- **Do not delete the VM to save money** — you would rebuild the forest from scratch.
  Deallocating keeps the disk and the domain intact.
- **`.local` is fine for a lab and wrong for production.** Real deployments use a subdomain of
  a domain the organisation owns (`ad.contoso.com`), because `.local` collides with mDNS.
  Worth being able to say why in an interview.
- **DSRM password is not the admin password.** It is asked for exactly once, and needed at the
  worst possible moment.
