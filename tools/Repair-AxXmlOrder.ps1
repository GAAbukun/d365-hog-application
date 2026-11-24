<#
.SYNOPSIS
  Puts the child elements of hand-written AOT XML files into the order the D365 metadata
  serializer (DataContractSerializer) expects, and reports elements it doesn't know.

.DESCRIPTION
  The metadata deserializer silently ignores an element that comes after a later one in
  the contract order. Visual Studio always writes the right order; hand-written files may
  not. The order is taken by reflection from the metadata assemblies in PackagesLocalDirectory\Bin:
  base type members first, then members without Order alphabetically, then by Order.

.EXAMPLE
  .\Repair-AxXmlOrder.ps1 -Path C:\Repos\d365-hog-application\Metadata\HOGApplication\HOGApplication -WhatIf
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][string]$Path,
    [string]$Bin = 'C:\AosService\PackagesLocalDirectory\Bin'
)

foreach ($d in 'Microsoft.Dynamics.AX.Metadata.dll', 'Microsoft.Dynamics.AX.Metadata.Core.dll') {
    [void][Reflection.Assembly]::LoadFrom((Join-Path $Bin $d))
}
Add-Type -AssemblyName System.Runtime.Serialization

$metaAsms = [AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.GetName().Name -like 'Microsoft.Dynamics.AX.Metadata*' }
$typeByName = @{}
foreach ($a in $metaAsms) {
    try { $types = $a.GetTypes() } catch { $types = $_.Exception.Types | Where-Object { $_ } }
    foreach ($t in $types) {
        if ($t.IsClass -and -not $t.IsAbstract -or $t.IsClass) {
            if (-not $typeByName.ContainsKey($t.Name)) { $typeByName[$t.Name] = $t }
        }
    }
}

$dcAttr = [System.Runtime.Serialization.DataContractAttribute]
$dmAttr = [System.Runtime.Serialization.DataMemberAttribute]
$memberCache = @{}

function Get-ContractMembers([Type]$type) {
    if ($memberCache.ContainsKey($type)) { return $memberCache[$type] }
    $chain = @()
    $t = $type
    while ($t -and $t -ne [object]) { $chain = ,$t + $chain; $t = $t.BaseType }
    $list = New-Object System.Collections.Generic.List[object]
    foreach ($lvl in $chain) {
        $flags = [Reflection.BindingFlags]'Instance,Public,NonPublic,DeclaredOnly'
        $members = @($lvl.GetProperties($flags)) + @($lvl.GetFields($flags))
        $level = foreach ($m in $members) {
            $a = [Attribute]::GetCustomAttribute($m, $dmAttr)
            if ($a) {
                $mt = if ($m -is [Reflection.PropertyInfo]) { $m.PropertyType } else { $m.FieldType }
                [pscustomobject]@{ Name = $(if ($a.Name) { $a.Name } else { $m.Name }); Order = $a.Order; Type = $mt }
            }
        }
        $sorted = @($level | Where-Object { $_.Order -lt 0 } | Sort-Object { $_.Name } -CaseSensitive) +
                  @($level | Where-Object { $_.Order -ge 0 } | Sort-Object Order, Name)
        foreach ($s in $sorted) { if ($s) { $list.Add($s) } }
    }
    $memberCache[$type] = $list
    return $list
}

function Get-ItemType([Type]$collType) {
    $t = $collType
    while ($t -and $t -ne [object]) {
        if ($t.IsGenericType) { return $t.GetGenericArguments()[-1] }
        $t = $t.BaseType
    }
    foreach ($i in $collType.GetInterfaces()) {
        if ($i.IsGenericType -and $i.GetGenericTypeDefinition() -eq [Collections.Generic.IEnumerable`1]) { return $i.GetGenericArguments()[0] }
    }
    return $null
}

$script:issues = New-Object System.Collections.Generic.List[string]
$script:changed = $false
$xsi = 'http://www.w3.org/2001/XMLSchema-instance'

function Repair-Element([Xml.XmlElement]$el, [Type]$type, [string]$where) {
    $it = $el.GetAttribute('type', $xsi)
    if ($it -and $typeByName.ContainsKey($it)) { $type = $typeByName[$it] }
    elseif ($typeByName.ContainsKey($el.LocalName) -and $type -and -not $typeByName[$el.LocalName].IsAssignableFrom($type)) {
        if ($type.IsAssignableFrom($typeByName[$el.LocalName])) { $type = $typeByName[$el.LocalName] }
    }
    if (-not $type) { return }
    $children = @($el.ChildNodes | Where-Object { $_ -is [Xml.XmlElement] })
    if ($children.Count -eq 0) { return }

    $isContract = [Attribute]::GetCustomAttribute($type, $dcAttr) -ne $null
    $isCollection = (-not $isContract) -and ($type -ne [string]) -and ([Collections.IEnumerable].IsAssignableFrom($type))
    if ($isCollection) {
        $itemType = Get-ItemType $type
        foreach ($c in $children) {
            $ct = $itemType
            if ($typeByName.ContainsKey($c.LocalName) -and ($null -eq $ct -or $ct.IsAssignableFrom($typeByName[$c.LocalName]))) { $ct = $typeByName[$c.LocalName] }
            Repair-Element $c $ct "$where/$($c.LocalName)"
        }
        return
    }
    if (-not $isContract) { return }

    $members = Get-ContractMembers $type
    $index = @{}; for ($i = 0; $i -lt $members.Count; $i++) { $index[$members[$i].Name] = $i }

    foreach ($c in $children) {
        if (-not $index.ContainsKey($c.LocalName)) { $script:issues.Add("UNKNOWN  $where/$($c.LocalName) (not a member of $($type.Name))"); continue }
        Repair-Element $c $members[$index[$c.LocalName]].Type "$where/$($c.LocalName)"
    }

    $keyed = for ($i = 0; $i -lt $children.Count; $i++) {
        $k = if ($index.ContainsKey($children[$i].LocalName)) { $index[$children[$i].LocalName] } else { 100000 + $i }
        [pscustomobject]@{ Node = $children[$i]; Key = $k; Pos = $i }
    }
    $sorted = @($keyed | Sort-Object Key, Pos)
    $same = $true
    for ($i = 0; $i -lt $children.Count; $i++) { if (-not [object]::ReferenceEquals($sorted[$i].Node, $children[$i])) { $same = $false; break } }
    if (-not $same) {
        $script:issues.Add("REORDER  $where ($($type.Name))")
        $script:changed = $true
        foreach ($c in $children) { [void]$el.RemoveChild($c) }
        foreach ($s in $sorted) { [void]$el.AppendChild($s.Node) }
    }
}

$files = Get-ChildItem $Path -Recurse -Filter *.xml | Where-Object { $_.Directory.Name -like 'Ax*' -and $_.Directory.Name -ne 'AxLabelFile' }
foreach ($file in $files) {
    $doc = New-Object Xml.XmlDocument
    $doc.PreserveWhitespace = $false
    $doc.Load($file.FullName)
    $root = $doc.DocumentElement
    if (-not $typeByName.ContainsKey($root.LocalName)) { Write-Warning "$($file.Name): no type $($root.LocalName)"; continue }
    $script:issues.Clear(); $script:changed = $false
    Repair-Element $root $typeByName[$root.LocalName] $root.LocalName
    foreach ($i in $script:issues) { "$($file.Directory.Name)\$($file.Name): $i" }
    if ($script:changed -and $PSCmdlet.ShouldProcess($file.FullName, 'Rewrite in contract order')) {
        $settings = New-Object Xml.XmlWriterSettings
        $settings.Indent = $true; $settings.IndentChars = "`t"; $settings.Encoding = New-Object Text.UTF8Encoding $false
        $w = [Xml.XmlWriter]::Create($file.FullName, $settings)
        $doc.Save($w); $w.Close()
    }
}
