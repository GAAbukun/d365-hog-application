# One-time switch (elevated): replace package link HOGsbaSubBillActivity with HOGApplication.
# The old package's metadata stays in d365-sba-activities; only the link in PackagesLocalDirectory is removed.
$ErrorActionPreference = 'Stop'
$pld  = 'C:\AosService\PackagesLocalDirectory'
$repo = 'C:\Repos\d365-hog-application\Metadata\HOGApplication'

Get-Service -Name W3SVC, DynamicsAxBatch -ErrorAction SilentlyContinue | Stop-Service -Force

$old = Get-Item "$pld\HOGsbaSubBillActivity" -ErrorAction SilentlyContinue
if ($old) {
    if ($old.LinkType -ne 'SymbolicLink') { throw "$pld\HOGsbaSubBillActivity is not a link - stopping, nothing changed." }
    $old.Delete()   # removes the link only, not the target folder
}
if (-not (Test-Path "$pld\HOGApplication")) {
    New-Item -ItemType SymbolicLink -Path "$pld\HOGApplication" -Target $repo | Out-Null
}

Get-Service -Name W3SVC, DynamicsAxBatch -ErrorAction SilentlyContinue | Start-Service
Get-Item "$pld\HOGApplication" | Select-Object FullName, LinkType, Target
