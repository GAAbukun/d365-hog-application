# Conventions

| ID | File | Scope |
|---|---|---|
| C-00 | [documentation.md](documentation.md) | Standard document set, IDs, markers, ADRs, evidence (all projects) |
| C-01 | [d365-finops/01-naming-and-extensions.md](d365-finops/01-naming-and-extensions.md) | Packages, prefixes, extension naming, Chain of Command, data entities, BP checks, repository layout |
| C-02 | [d365-finops/02-testing.md](d365-finops/02-testing.md) | SysTest, ATL, test packages, functional test cases, Azure DevOps Test Plans, RSAT and Task recorder status |
| C-03 | [d365-finops/03-alm-and-source-control.md](d365-finops/03-alm-and-source-control.md) | Git, branching, build and package, platform status, GitHub vs Azure DevOps, migration |

## Change log

| Date | Change | Projects to refresh |
|---|---|---|
| 24.11.2026 | C-01 §1/§2, C-02: Dynamics solutions of a customer are pooled in one shared package `<CCC>Application` (PascalCase after the customer prefix); per-solution packages dropped. Rule is Dynamics-only; other ERP systems keep their own package rules. | d365-hog-application (snapshot refreshed), d365-sba-activities, d365-pma-indirectCostAssignment |
| 07.11.2026 | Initial version, moved from d365-sba-activities (researched 07.11.2026). Customer-specific values moved to `customers/`. | d365-sba-activities (snapshot taken), d365-pma-indirectcosts (not yet adopted) |
