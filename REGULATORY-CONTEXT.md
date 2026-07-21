# Regulatory context — why a Luxembourg bank would care about this lab

This is not a compliance or legal assessment — it's a map from the AD/IAM administration tasks
in this repo to the actual regulatory principles a Luxembourg-supervised bank operates under. The
goal is interview readiness: being able to say *why* a task matters to the business, not just how
to perform it.

## The two frameworks

**DORA — Digital Operational Resilience Act** (EU Regulation 2022/2554, directly applicable,
in force since 17 January 2025). Applies to banks, insurers, investment firms, and their ICT
third-party providers across the EU, Luxembourg included. Five pillars: ICT risk management,
ICT-incident reporting, digital operational resilience testing, ICT third-party risk, and
information-sharing. The pillar that matters for this repo is the first one.

**CSSF — Commission de Surveillance du Secteur Financier**, Luxembourg's financial regulator.
Predates DORA and continues to apply alongside it. The core circular for internal governance and
IT is **Circular CSSF 12/552** ("Central administration, internal governance and risk
management"), amended repeatedly since 2012. **Circular CSSF 13/554** deals specifically with
access to intragroup IT resources — the closest CSSF text to "how you administer a user account."

## The mapping

| Lab task | Regulatory hook | Why it applies |
|---|---|---|
| **A2** — create a user in the correct OU | DORA Art. 9(4)(c) | Access must be scoped to "what is required for legitimate and approved functions" **from the moment the account is created** — correct OU/attributes from day one is not administrative tidiness, it's the starting point of least privilege. |
| **A3** — unlock, but notice the pattern | DORA ICT risk management — detection | A lockout is a signal, not just an inconvenience. A pattern of lockouts (one account, many attempts, odd hours) is exactly the kind of anomaly an ICT risk detection process exists to catch — unlocking without asking "why was this account being hammered" misses the point. |
| **A5** — disable, don't delete, on a leaver | DORA Art. 9(4)(c) + Art. 9(4)(e) | Access that outlives "legitimate and approved function" is the textbook violation Art. 9(4)(c) exists to prevent. Disabling (not deleting) is also what makes the action a **controlled, reversible, auditable change** — Art. 9(4)(e) requires changes to be "recorded, tested, assessed, approved, implemented and verified in a controlled manner." |
| **A10** — AGDLP remediation | DORA Art. 9(4)(c) + CSSF 12/552 (segregation of duties) | The whole exercise **is** "access limited to what is required" made concrete — the naive fix in Lab 04 would have silently broadened access, which is precisely the failure mode these frameworks are trying to prevent. |
| **A13** — Delegation of Control | CSSF 12/552 (segregation of duties, dedicated IT/security-officer roles) | Delegating "reset passwords on this OU" instead of handing out Domain Admin is segregation of duties in miniature — the same principle CSSF 12/552 applies at the institution level (risk-taking and control of that risk must not sit with the same person) applies at the OU level too. |
| **Every ticket** (request → approval → actions → evidence → confirmation) | DORA Art. 9(4)(e) | This is, almost verbatim, what Art. 9(4)(e) asks for: changes "recorded, tested, assessed, approved, implemented and verified in a controlled manner." The journal format in this repo was designed independently of DORA, then turned out to already match it — worth saying exactly that in an interview. |

## One line worth having ready

*"I try to treat every AD change the way DORA Article 9 and CSSF 12/552 describe — access scoped
to what the role actually needs, changes that are approved and evidenced before they happen, and
duties split so no one person both grants and controls the same access. The ticket format in this
repo isn't decoration, it's that principle applied to a home lab."*

## Sources

- [DORA Article 9 — Protection and prevention](https://www.digital-operational-resilience-act.com/Article_9.html)
- [Microsoft Learn — What is DORA?](https://learn.microsoft.com/en-us/compliance/dora/dora-what-is-dora)
- [CSSF — Circular CSSF 12/552 (official, as amended)](https://www.cssf.lu/en/Document/circular-cssf-12-552/)
- [CSSF 12/552 — salient elements summary (CSSF)](https://www.cssf.lu/wp-content/uploads/cssf12_552_salient_elements.pdf)
- [Lexology — CSSF circular on IT services management and outsourcing](https://www.lexology.com/library/detail.aspx?g=3a275c3f-fb3a-4263-9be2-af56cabc7241)
- [Lexology — CSSF rules on intragroup IT resource access (Circular 13/554 context)](https://www.lexology.com/library/detail.aspx?g=1cc9e13f-6f92-428b-a06d-97490c151e33)

Verify current text before quoting either framework in an interview or a real compliance
context — both are amended periodically (12/552 alone has ten amendments since 2012), and this
document reflects what was confirmed at the time these labs were written.
