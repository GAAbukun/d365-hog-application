# HOGApplication – shared Honegger application package

| | |
|---|---|
| **Customer** | Honegger AG |
| **Package / model** | `HOGApplication`, layer usr, publisher *AlfaPeople Switzerland* |
| **Why one shared package** | Microsoft: start with few packages (one platform, one application package) and split only for a different release cadence ([Development and continuous delivery FAQ](https://learn.microsoft.com/dynamics365/fin-ops-core/dev-itpro/dev-tools/continuous-delivery-faq)). Decided 23.11.2026. |
| **Dev environment** | VHD dev VM `dvhd10049vm` (10.0.49) |
| **Status** | 24.11.2026: `HOGpma` and `HOGsba` merged, model compiles (xppc 0 errors, xppbp 0 errors / 36 warnings). DB sync and functional test open. |

## Solutions in this package

| Prefix | Solution | Docs | Status |
|---|---|---|---|
| `HOGpma` | Indirect cost matrix (employment category × cost center → indirect component group) | d365-pma-indirectCostAssignment, `HOGIndirectCostAssignment-Spike.md` section H | Compiles; forms, security, tests open |
| `HOGsba` | Activity number on Subscription billing schedule lines | d365-sba-activities | Moved here 24.11.2026 from package `HOGsbaSubBillActivity` (same element and field names, data kept) |

## Elements (`HOGpma`)

| Type | Element | Purpose |
|---|---|---|
| Label file | `HOGpma` (en-US, de) | All `HOGpma` labels |
| EDT | `HOGpmaCostCenterCode`, `HOGpmaEmploymentCategoryCode` | Enum EDTs on `TableGroupAll` (Table / Group / All) |
| EDT | `HOGpmaCostCenterRelation`, `HOGpmaEmploymentCategoryRelation` | Relation fields of the matrix |
| EDT | `HOGpmaCostCenterGroupId`, `HOGpmaEmploymentCategoryGroupId` | Group IDs |
| EDT | `HOGpmaRefreshIndirectGroupOnPosting`, `HOGpmaCostCenterDimensionAttribute` | Parameters |
| Table | `HOGpmaIndirectCostMatrix` | The matrix (per company) |
| Table | `HOGpmaCostCenterGroup`, `HOGpmaCostCenterGroupMember` | Cost center groups (per company) |
| Table | `HOGpmaEmploymentCategoryGroup` | Employment category groups (global) |
| Table extension | `ProjParameters.HOGpma` | Refresh-on-posting checkbox, cost center dimension |
| Table extension | `BenefitEmploymentCategory.HOGpma` | Employment category group on the category |
| Class | `HOGpmaIndirectCostMatrixLookup` | Matrix lookup with transaction cache |
| Class (CoC) | `PSAComponentGroupAssignment_HOGpma_Extension` | Wraps `findAssignment`: resource rules → matrix → standard |
| Class (CoC) | `ProjJournalCheckPost_HOGpma_Extension` | Wraps `postTransLedger`: optional refresh during posting |
| Form extension | `ProjParameters.HOGpma` | Group *Indirect cost matrix* at the end of the *Journals* tab |

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
| DB sync, functional test | Sync from Visual Studio (`Projects/HOGApplication/HOGApplication.sln`); retest the `HOGsba` activity number |
| BP warnings (36) | Form refs (come with the forms), primary key editable/mandatory on matrix and member tables, TitleField1 and replacement key on group tables, DeleteAction relation; *Unknown label* / *strFmt* warnings to recheck after a Visual Studio build |
| Forms and menu items | Matrix, cost center groups (with members), employment category groups; menu extension under *Project management and accounting › Setup › Indirect costs* |
| `BenefitEmploymentCategory` form extension | Shows the employment category group on *Human resources › Setup › Employment categories* |
| Security | Privileges (view/maintain) for the new forms, added to the project setup duty |
| Data entities | Matrix and groups, for Excel/DMF import |
| Cost center validation | Matrix lines with cost center code *Table* are not yet checked against the dimension values (`VERIFY` in `HOGpmaIndirectCostMatrix.checkRelationExists`) |
| Test package `HOGApplicationTest` | SysTest for `HOGpmaIndirectCostMatrixLookup::findGroup` (search order) and the `findAssignment` precedence |
| `HGExtension` overlap | Honegger's own model isn't on the VM; check whether it wraps `findAssignment` or `postTransLedger` |
