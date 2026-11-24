# HOGApplication – shared Honegger application package

| | |
|---|---|
| **Customer** | Honegger AG |
| **Package / model** | `HOGApplication`, layer usr, publisher *AlfaPeople Switzerland* |
| **Why one shared package** | Microsoft: start with few packages (one platform, one application package) and split only for a different release cadence ([Development and continuous delivery FAQ](https://learn.microsoft.com/dynamics365/fin-ops-core/dev-itpro/dev-tools/continuous-delivery-faq)). Decided 23.11.2026. |
| **Dev environment** | VHD dev VM `dvhd10049vm` (10.0.49) |
| **Status** | 24.11.2026: `HOGpma` reduced to one matrix without groups (Honegger: keep the customization minimal); xppc 0 errors, xppbp 0 errors / 0 warnings. DB sync and UI test open. Later the same day: data entity for the rates of the standard indirect component groups (Excel import of the 97 rates), builds clean; DB sync and test open. The variant with cost center and employment category groups is kept on branch `v2/matrix-with-groups` for other customers. |

## Solutions in this package

| Prefix | Solution | Docs | Status |
|---|---|---|---|
| `HOGpma` | Indirect cost matrix (employment category × cost center → indirect component group) | d365-pma-indirectCostAssignment, `HOGIndirectCostAssignment-Spike.md` section H | Compiles, BP clean; DB sync, UI test, tests open |
| `HOGsba` | Activity number on Subscription billing schedule lines | d365-sba-activities | Moved here 24.11.2026 from package `HOGsbaSubBillActivity` (same element and field names, data kept) |

## Elements (`HOGpma`)

| Type | Element | Purpose |
|---|---|---|
| Label file | `HOGpma` (en-US, de) | All `HOGpma` labels |
| EDT | `HOGpmaRefreshIndirectGroupOnPosting`, `HOGpmaCostCenterDimensionAttribute` | Parameters |
| Table | `HOGpmaIndirectCostMatrix` | The matrix (per company): employment category, cost center, valid from → indirect component group. An empty category or cost center means all, as in the standard *Indirect cost assignment rules*. Standard EDTs `BenefitEmploymentCategoryId` and `DimensionValue`, no own key tables |
| Table extension | `ProjParameters.HOGpma` | Refresh-on-posting checkbox; which financial dimension is the cost center |
| Class | `HOGpmaIndirectCostMatrixLookup` | Reads category and cost center from the worker's employment, finds the best line (category + cost center → category → cost center → neither, latest valid-from), transaction cache |
| Class (CoC) | `PSAComponentGroupAssignment_HOGpma_Extension` | Wraps `findAssignment`: resource rules → matrix → standard |
| Class (CoC) | `ProjJournalCheckPost_HOGpma_Extension` | Wraps `postTransLedger`: optional refresh during posting |
| Form extension | `ProjParameters.HOGpma` | Group *Indirect cost matrix* at the end of the *Journals* tab |
| Form + menu item | `HOGpmaIndirectCostMatrix` | The matrix; cost center lookup on the cost center dimension. The **only** new menu item |
| Menu extension | `ProjectManagementAndAccounting.HOGpma` | *Setup › Indirect costs*, after *Indirect cost assignment rules* |
| Privilege | `HOGpmaIndirectCostMatrixMaintain`, `HOGpmaIndirectCostMatrixView` | Maintain / view the matrix |
| Duty extension | `ProjProjectMasterMaintain`, `ProjProjectContractMasterMaintain`, `ProjProjectAccountingProcessEnable` (maintain); `ProjProjectMasterInquire` (view) | The same duties that hold the standard indirect cost privileges |
| Data entity + staging table | `HOGpmaIndirectCostRateEntity` (public name `HOGpmaIndirectCostRate`), `HOGpmaIndirectCostRateStaging` | Import of the standard *Assigned indirect cost components* (`PSAIndirectCompoundingSetup`: group, date, component, calculation method, cost / revenue / invoice rate), for which the standard has no entity. Key: group + component + date. Fills the component name if empty. For a *Percent* line, selects *Base amount* as base of every rate type whose rate isn't 0 (same record as *Compounding rules* in the form), unless the component already has a base for that type. No menu item: *Data management*, Excel add-in, and *Open in Excel* on the standard form |
| Privilege, duty extension | `HOGpmaIndirectCostRateEntityMaintain`, `HOGpmaIndirectCostRateEntityView` in `ProjProjectJournalsMaintain.HOGpma` | The duty that holds the standard `PSAIndirectComponentGroupEntity` privileges |

## Elements (`HOGsba`)

| Type | Element | Purpose |
|---|---|---|
| Table extension | `SubBillScheduleLine.HOGsba`, `SubBillSalesLineConsolidated.HOGsba` | Activity number |
| Form extension | `SubBillScheduleTable.HOGsba` | Activity number on billing schedule lines |
| Class | `SubBillScheduleLine_HOGsba_Extension`, `HOGsbaSubBillScheduleTableEventHandler` | Validation, lookup, copy to the sales line |

## Build from the command line

`xppc`/`xppbp` as in d365-sba-activities doc 06 §5.1, with `$model = 'HOGApplication'`. Labels first: `LabelC.exe -metadata=$pld -output=$pld\HOGApplication -modelmodule=HOGApplication` (output is the **package folder**; LabelC adds `Resources`). Hand-written XML: run `tools/Repair-AxXmlOrder.ps1 -Path Metadata\HOGApplication\HOGApplication -WhatIf` before building. The metadata deserializer silently ignores elements that are out of order. After **deleting** elements, delete `PackagesLocalDirectory\HOGApplication\XppMetadata` before `xppc`; the compiler doesn't remove compiled metadata of deleted elements.

## Set up the package on a dev VM

The `Descriptor` (with all package references) is in this repo. On `dvhd10049vm` the package was set up on 24.11.2026 by renaming `HOGsbaSubBillActivity` (`tools/Switch-ToHOGApplication.ps1`). On a **new** VM, only link the package and build; steps 1–2 below are the original from-scratch procedure, kept for reference.

1. Visual Studio › Dynamics 365 › Model management › **Create model**: name `HOGApplication`, publisher *AlfaPeople Switzerland*, layer `usr`, **Create new package**, with the references listed in `Descriptor/HOGApplication.xml`. Don't create a project in the wizard.
2. Close Visual Studio. In an **elevated** PowerShell, stop the services, move the new `Descriptor` folder into this repo, replace the package folder with a link, and start the services:

```powershell
$repo = 'C:\Repos\d365-hog-application'
$pld  = 'C:\AosService\PackagesLocalDirectory'
Get-Service -Name W3SVC, DynamicsAxBatch -ErrorAction SilentlyContinue | Stop-Service -Force
Copy-Item "$pld\HOGApplication\Descriptor" "$repo\Metadata\HOGApplication\" -Recurse -Force
Remove-Item "$pld\HOGApplication" -Recurse -Force
New-Item -ItemType SymbolicLink -Path "$pld\HOGApplication" -Target "$repo\Metadata\HOGApplication" | Out-Null
Get-Service -Name W3SVC, DynamicsAxBatch -ErrorAction SilentlyContinue | Start-Service
```

3. Create the project under `Projects\HOGApplication\` (not inside `Metadata`) for model `HOGApplication`, and add the existing elements (Solution Explorer › Add › Existing item, or *Add to project* in Application Explorer).
4. Build with **Synchronize database** (new tables and table extensions). Turn on best-practice checks.

## Not done yet

| Item | Note |
|---|---|
| DB sync, functional test | Sync from Visual Studio. Rebuilds the matrix columns and removes `BenefitEmploymentCategory.HOGpmaEmploymentCategoryGroupId` (test data only). VERIFY whether the sync also drops the three deleted group tables or leaves them orphaned in the database. Then test the matrix form and an hour journal line |
| **Decision:** employment category key | `BenefitEmploymentCategory` is unique on *employment type (Employee / Contractor) + category*; the matrix stores the category only. Only matters if the same category code exists under both types |
| Test rate entity | DB sync (new staging table), then import a few rows of `Sozialkostengruppen.xlsx` with the Excel add-in; check the lines and *Compounding rules › Cost* in the standard form, and the SVA amount on a posted hour line |
| Matrix data entity (optional) | The matrix itself has no entity yet. Only if Honegger wants to import it too |
| Test package `HOGApplicationTest` | SysTest for `HOGpmaIndirectCostMatrixLookup::findGroup` (search order) and the `findAssignment` precedence |
| `HGExtension` overlap | Honegger's own model isn't on the VM; check whether it wraps `findAssignment` or `postTransLedger` |
