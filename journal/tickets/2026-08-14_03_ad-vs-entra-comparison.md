# Ticket 2026-08-14_03 — AD vs Entra ID, written comparison (A14)

**Ticket ID:** 2026-08-14_03
**Date:** 2026-08-14
**Category:** Hybrid
**Environment:** N/A — written comparison only, no infrastructure touched

## Request

**Requester (simulated):** Laurent Girard, IT Manager — before any hybrid work is considered
(Entra Connect, Phase 4), put in writing what's actually different between the two directories, not
just "one is cloud and one isn't."

## Approval

**Approver (simulated):** Laurent Girard, IT Manager. No infrastructure change, so no four-eyes
requirement beyond normal ticket review.

## Scope note — hands-on vs conceptual

The AD side of every point below was directly proven in this lab track (tickets cited inline). The
Entra ID side is **conceptual knowledge from SC-300 study material, not hands-on work performed in
this lab** — the operator's hands-on Entra exposure so far has been limited to exploring tenant
structure in `microsoft_entra_id_hands_on`, not configuring Conditional Access, dynamic groups, or
Administrative Units. That asymmetry is intentional to record here rather than hide: it's the
honest boundary between "I did this" and "I know this from studying for the exam."

## The five axes

### 1. Protocols

**AD (hands-on):** Kerberos for domain logon authentication, LDAP for every directory read/write.
Every `Get-ADUser`/`dsacls`/`Get-ADGroupMember` command run across this entire lab talks LDAP under
the hood, wrapped by Active Directory Web Services (ADWS) — directly experienced as a real failure
mode in ticket [2026-08-13_01](2026-08-13_01_ous-and-groups-marketing.md), where a stale ADWS cache
caused a confusing `Move-ADObject` error right after creating a new OU.

**Entra ID (conceptual):** OAuth 2.0 and OpenID Connect for modern authentication, SAML for
federating legacy applications, Microsoft Graph API for programmatic access to the directory. No
Kerberos in a pure cloud tenant — Kerberos only re-enters the picture through Azure AD Kerberos
trust for hybrid scenarios accessing on-prem resources.

### 2. OU vs flat directory

**AD (hands-on):** a real hierarchical tree. Ticket [2026-08-13_01](2026-08-13_01_ous-and-groups-marketing.md)
(A7) proved an OU does exactly two jobs and nothing else — it's where Group Policy links, and where
administrative control gets delegated (ticket [2026-08-14_01](2026-08-14_01_delegation-of-control-sales.md),
A13). It never grants a permission by itself.

**Entra ID (conceptual):** no OU concept at all — it's a flat collection of users and groups.
Administrative Units exist as a partial substitute for scoping *administrative roles* (e.g. "this
Helpdesk Administrator can only manage users in this AU"), but they don't carry the second half of
what an AD OU does — there's nothing in Entra ID that a Group Policy links to, because Group Policy
itself doesn't exist there.

### 3. GPO vs Conditional Access

**AD (hands-on):** ticket [2026-08-02_01](2026-08-02_01_gpo-fundamentals-jml.md) (A12) built two
real GPOs (screen lock, drive mapping) linked to the `Sales` OU. Enforcement is purely structural —
a GPO applies to whatever is located under the OU/domain/site it's linked to (optionally narrowed
by Security Filtering), verified with Group Policy Modeling instead of `gpresult` since no
domain-joined client exists yet in this lab.

**Entra ID (conceptual):** Conditional Access has no location in a tree to link to — it evaluates a
condition at sign-in time (which user or group, which device, which application, which network
location, real-time sign-in risk) and produces an action (block, require MFA, require a compliant
device). GPO answers "where does this object sit"; Conditional Access answers "what's true about
this sign-in right now." They're not two implementations of the same idea — they're different
enforcement philosophies, static placement vs dynamic runtime evaluation.

### 4. Group scope

**AD (hands-on):** ticket [2026-08-13_02](2026-08-13_02_agdlp-remediation-finance.md) (A10) lived
the full AGDLP chain — Global groups as the people-roster, Domain Local groups as where a
permission actually attaches, and the real, Windows-enforced rule that a Domain Local group can
never be nested inside a Global group (`A global group cannot have a local group as a member`,
hit directly while building this ticket).

**Entra ID (conceptual):** security groups carry no AD-style scope model — there's no Domain
Local/Global/Universal distinction, because there's no concept of "which domain can this group be
used in." The complexity moves elsewhere: **dynamic membership**, where a group's members are
computed automatically from a rule against user attributes (e.g. `department -eq "Finance"`)
instead of being manually maintained — something on-prem AD has no native equivalent for.

### 5. Source of authority

**Neither side hands-on** — this lab never built Entra Connect (Phase 4 was cut for time, see
[`../../PLAN.md`](../../PLAN.md)). From SC-300 study material: in a hybrid setup, the on-prem AD is
normally the source of authority for any synced object. Entra Connect pushes changes upward, and
Microsoft blocks editing core attributes of a synced object directly on the cloud side — attempting
it returns an error stating the attribute is managed on-premises. This is stated here as the
textbook answer, not as something verified against a real sync in this environment.

## Result & user confirmation

Comparison written and reviewed. The asymmetry between the AD column (hands-on, cited against real
tickets) and the Entra column (conceptual, from exam study) is deliberate and stated up front rather
than smoothed over — an honest gap is more useful in an interview than a confident answer for
something never actually configured.

## Regulatory relevance

Not applicable — no infrastructure or access change in this ticket.

## What I learned

Writing this out surfaced a pattern that repeats across all five axes: AD's model is fundamentally
about **structural location** — where an object sits in a tree, which domain a group can be used
in — while Entra ID's model is about **runtime evaluation** — what's true about this sign-in right
now, what a dynamic rule currently computes. That's a more useful way to hold the two systems in
mind than a feature-by-feature checklist, and it also explains why a straight port of AD habits
into Entra ID doesn't work: there's no tree to place things in, so the thinking has to shift from
"where do I put this" to "what condition should trigger this."
