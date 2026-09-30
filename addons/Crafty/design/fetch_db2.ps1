# fetch_db2.ps1 -- pull current-patch DB2 CSVs from wago.tools and load into MySQL
# with typed columns derived from WoWDBDefs definitions.
#
# Usage:
#   $env:MYSQL_PWD = "secret"
#   .\fetch_db2.ps1 -Branch mop      # populates wow_classic     (core + battle pets), latest build
#   .\fetch_db2.ps1 -Branch tbc      # populates wow_anniversary (core only), latest build
#   .\fetch_db2.ps1 -Branch mop -Build 5.5.4.68159   # pin a specific build instead of latest
#
# Prereqs:
#   - edit $MysqlExe below to your mysql.exe path (or have it on PATH)
#   - server has local_infile enabled: SET GLOBAL local_infile = 1;
#   - $env:MYSQL_PWD set to your MySQL password
#
# Schema: each table's columns are typed from its WoWDBDefs .dbd definition,
# matched to the resolved build. Columns the definition doesn't name (Field_*
# residue) are kept as TEXT. If a table's .dbd has no block for the build, the
# table is NOT loaded untyped -- it surfaces in the PROBLEMS report instead.

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("mop","tbc")]
    [string]$Branch,

    [string]$Build = ""
)

$ErrorActionPreference = "Stop"

$env:MYSQL_PWD = "apr0902"

# ---- per-branch config -------------------------------------------------------
$Config = @{
    mop = @{
        Db          = "wow_classic"
        Product     = "wow_classic"
        IncludePets = $true
    }
    tbc = @{
        Db          = "wow_anniversary"
        Product     = "wow_anniversary"
        IncludePets = $false
    }
}

$Cfg     = $Config[$Branch]
$Db      = $Cfg.Db
$Product = $Cfg.Product

$User      = "root"
# mysql.exe full path. Change if yours differs.
$MysqlExe  = "C:\Program Files\MySQL\MySQL Server 9.7\bin\mysql.exe"
$UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36"
$DbdBase   = "https://raw.githubusercontent.com/wowdev/WoWDBDefs/master/definitions"

if (-not $env:MYSQL_PWD) { throw "Set `$env:MYSQL_PWD before running." }

# Resolve the latest build for this product unless one was passed explicitly.
if (-not $Build) {
    $latest = Invoke-RestMethod -Uri "https://wago.tools/api/builds/$Product/latest" -UserAgent $UserAgent
    $Build = $latest.version
    if (-not $Build) { throw "Could not resolve latest build for $Product." }
}

# ---- table sets --------------------------------------------------------------
$CoreTables = @(
    "Item","ItemSparse","ItemEffect","ItemClass","ItemSubClass",
    "SpellName","Spell","SpellEffect","SpellMisc", "SpellCooldowns", "SpellCategories", "SpellCategory", "SpellReagents", 
    "SkillLine","SkillLineAbility", "SkillRaceClassInfo",
    "Faction","FactionGroup",
    "Map","ChrClasses","ChrRaces",
    "CreatureDisplayInfo","Creature"
)
$PetTables = @(
    "BattlePetSpecies","BattlePetAbility","BattlePetAbilityEffect",
    "BattlePetAbilityTurn","BattlePetState","BattlePetSpeciesState",
    "BattlePetBreedQuality","BattlePetBreedState"
)
$VerifyTables = @(
    "QuestV2"
)

$Tables = $CoreTables + $VerifyTables
if ($Cfg.IncludePets) { $Tables += $PetTables }

# =============================================================================
# DBD PARSER
# =============================================================================

function Convert-DbdTypeToSql {
    param([string]$BaseType, [int]$Size, [bool]$Unsigned)
    switch ($BaseType) {
        "float"     { return "DOUBLE" }
        "string"    { return "TEXT" }
        "locstring" { return "TEXT" }
        "int" {
            switch ($Size) {
                8       { return $(if ($Unsigned) { "TINYINT UNSIGNED" }  else { "TINYINT" }) }
                16      { return $(if ($Unsigned) { "SMALLINT UNSIGNED" } else { "SMALLINT" }) }
                32      { return $(if ($Unsigned) { "INT UNSIGNED" }      else { "INT" }) }
                64      { return $(if ($Unsigned) { "BIGINT UNSIGNED" }   else { "BIGINT" }) }
                default { return $(if ($Unsigned) { "INT UNSIGNED" }      else { "INT" }) }
            }
        }
        default { return "TEXT" }
    }
}

function ConvertTo-BuildNumber {
    param([string]$B)
    $seg = $B -split "\."
    if ($seg.Count -ne 4) { return $null }
    $s = ""
    foreach ($p in $seg) { $s += ("{0:D6}" -f [int]$p) }
    return [decimal]$s
}

function Test-BuildInRange {
    param([string]$Build, [string]$Low, [string]$High)
    $b = ConvertTo-BuildNumber $Build
    $l = ConvertTo-BuildNumber $Low
    $h = ConvertTo-BuildNumber $High
    if ($null -eq $b -or $null -eq $l -or $null -eq $h) { return $false }
    return ($b -ge $l -and $b -le $h)
}

function Get-DbdColumnTypes {
    param([string[]]$Lines)
    $types = @{}
    $inCols = $false
    foreach ($raw in $Lines) {
        $line = $raw.TrimEnd("`r")
        if ($line -eq "COLUMNS") { $inCols = $true; continue }
        if ($inCols) {
            if ($line.Trim() -eq "") { break }
            $l = ($line -split "//")[0].Trim()
            if ($l -eq "") { continue }
            $parts = $l -split "\s+"
            if ($parts.Count -lt 2) { continue }
            $typeTok = $parts[0]
            $name    = $parts[-1]
            $baseType = ($typeTok -replace "<.*>","")
            $name = $name.TrimEnd("?")
            $types[$name.ToLower()] = $baseType
        }
    }
    return $types
}

function Get-DbdBuildBlock {
    param([string[]]$Lines, [string]$Build)
    $blocks = @()
    $cur = @()
    foreach ($raw in $Lines) {
        $line = $raw.TrimEnd("`r")
        if ($line.Trim() -eq "") {
            if ($cur.Count) { $blocks += ,$cur; $cur = @() }
        } else {
            $cur += $line
        }
    }
    if ($cur.Count) { $blocks += ,$cur }

    foreach ($blk in $blocks) {
        $isVersion = $false
        $match = $false
        foreach ($line in $blk) {
            if ($line -match "^BUILD ") {
                $isVersion = $true
                $spec = $line.Substring(6).Trim()
                foreach ($item in ($spec -split ",\s*")) {
                    $it = $item.Trim()
                    if ($it -match "-") {
                        $ends = $it -split "-"
                        if (Test-BuildInRange $Build $ends[0].Trim() $ends[1].Trim()) { $match = $true }
                    } elseif ($it -eq $Build) {
                        $match = $true
                    }
                }
            }
        }
        if ($isVersion -and $match) { return ,$blk }
    }
    return $null
}

function Parse-DbdColumnLine {
    param([string]$Line)
    $l = ($Line -split "//")[0].Trim()
    if ($l -eq "") { return $null }
    $isId = $false
    # Annotations are wrapped in $...$ at the start, e.g. $id$ or $noninline,id$.
    # Single-quoted patterns so PowerShell does not interpolate $ or parse [^...].
    if ($l -match '^\$([^$]*)\$') {
        $ann = $matches[1]
        if (($ann -split ',\s*') -contains "id") { $isId = $true }
        $l = $l -replace '^\$[^$]*\$',""
    }
    $array = 0
    if ($l -match '\[(\d+)\]') { $array = [int]$matches[1]; $l = $l -replace '\[\d+\]',"" }
    $size = 0; $unsigned = $false
    if ($l -match '<([^>]+)>') {
        $sz = $matches[1]
        if ($sz -match '^u') { $unsigned = $true; $sz = $sz.Substring(1) }
        if ($sz -match '^\d+$') { $size = [int]$sz }
        $l = $l -replace '<[^>]+>',""
    }
    $name = $l.Trim().TrimEnd("?")
    if ($name -eq "") { return $null }
    return [pscustomobject]@{ Name=$name; Size=$size; Unsigned=$unsigned; Array=$array; IsId=$isId }
}

# Returns a hashtable: csvcolname(lower) -> @{ Sql; IsId }, or $null if no block.
function Get-DbdSchemaMap {
    param([string]$DbdText, [string]$Build)
    $lines = $DbdText -split "`n"
    $colTypes = Get-DbdColumnTypes -Lines $lines
    $block    = Get-DbdBuildBlock  -Lines $lines -Build $Build
    if (-not $block) { return $null }

    $map = @{}
    foreach ($line in $block) {
        if ($line -match "^BUILD " -or $line -match "^LAYOUT " -or $line -match "^COMMENT") { continue }
        $col = Parse-DbdColumnLine $line
        if (-not $col) { continue }
        $base = $colTypes[$col.Name.ToLower()]
        if (-not $base) { $base = "int" }
        $sql = Convert-DbdTypeToSql -BaseType $base -Size $col.Size -Unsigned $col.Unsigned
        if ($col.Array -gt 0) {
            for ($i = 0; $i -lt $col.Array; $i++) {
                $map["$($col.Name)_$i".ToLower()] = @{ Sql=$sql; IsId=$false }
            }
        } else {
            $map[$col.Name.ToLower()] = @{ Sql=$sql; IsId=$col.IsId }
        }
    }
    return $map
}

# Generate CREATE TABLE column defs in CSV-header order using the schema map.
function Build-CreateColumns {
    param([string]$Header, [hashtable]$SchemaMap)
    $cols = $Header.TrimEnd("`r") -split ","
    $defs = @()
    $idCol = $null
    foreach ($c in $cols) {
        $cn = $c.Trim()
        $key = $cn.ToLower()
        if ($SchemaMap.ContainsKey($key)) {
            $defs += "``$cn`` $($SchemaMap[$key].Sql)"
            if ($SchemaMap[$key].IsId) { $idCol = $cn }
        } else {
            $defs += "``$cn`` TEXT"
        }
    }
    $out = $defs -join ", "
    if ($idCol) { $out += ", PRIMARY KEY (``$idCol``)" }
    return $out
}

# Fetch a table's .dbd text; returns $null on miss.
function Get-DbdText {
    param([string]$Table)
    try {
        return (Invoke-WebRequest -Uri "$DbdBase/$Table.dbd" -UserAgent $UserAgent).Content
    } catch {
        return $null
    }
}

# =============================================================================
# RUN
# =============================================================================

Write-Host "Branch:  $Branch"
Write-Host "Product: $Product"
Write-Host "Build:   $Build"
Write-Host "Target:  $Db"
Write-Host ""

New-Item -ItemType Directory -Force -Path csv | Out-Null

$Problems = @()

function Invoke-Mysql {
    param([string[]]$MysqlArgs, [string]$StdinText = $null)
    $errFile = [System.IO.Path]::GetTempFileName()
    try {
        if ($null -ne $StdinText) {
            $StdinText | & $MysqlExe @MysqlArgs 2> $errFile
        } else {
            & $MysqlExe @MysqlArgs 2> $errFile
        }
        $code = $LASTEXITCODE
        if ($code -ne 0) {
            $err = (Get-Content $errFile -Raw)
            throw "mysql exit ${code}: $err"
        }
    } finally {
        Remove-Item $errFile -ErrorAction SilentlyContinue
    }
}

function Run-Sql($sql) {
    Invoke-Mysql -MysqlArgs @("--local-infile=1","-u",$User,$Db) -StdinText $sql
}

# Run a query script and return the LAST non-empty stdout line (trimmed).
# Throws on mysql error. Returning the last line makes multi-statement scripts
# safe: only the final SELECT's output is used even if earlier lines print.
function Get-SqlScalar($sql) {
    $errFile = [System.IO.Path]::GetTempFileName()
    try {
        $out = ($sql | & $MysqlExe -N -B --local-infile=1 -u $User $Db 2> $errFile)
        if ($LASTEXITCODE -ne 0) {
            $err = (Get-Content $errFile -Raw)
            throw "mysql exit ${LASTEXITCODE}: $err"
        }
        $lines = @($out) | Where-Object { "$_".Trim() -ne "" }
        if ($lines.Count -eq 0) { return "" }
        return ("$($lines[-1])").Trim()
    } finally {
        Remove-Item $errFile -ErrorAction SilentlyContinue
    }
}

foreach ($T in $Tables) {
    Write-Host "== $T =="
    $csv = "csv\$T.csv"
    $url = "https://wago.tools/db2/$T/csv?build=$Build"

    # 1. download CSV
    try {
        Invoke-WebRequest -Uri $url -OutFile $csv -UserAgent $UserAgent
    } catch {
        $Problems += [pscustomobject]@{ Table = $T; Reason = "download failed: $($_.Exception.Message)" }
        Write-Host "  PROBLEM: download failed"
        continue
    }
    if ((Get-Item $csv).Length -eq 0) {
        $Problems += [pscustomobject]@{ Table = $T; Reason = "empty file returned" }
        Write-Host "  PROBLEM: empty file"
        continue
    }

    $header = (Get-Content $csv -First 1)

    # 2. fetch + parse the .dbd schema for this build
    $dbdText = Get-DbdText -Table $T
    if (-not $dbdText) {
        $Problems += [pscustomobject]@{ Table = $T; Reason = "no .dbd definition file found" }
        Write-Host "  PROBLEM: no .dbd definition"
        continue
    }
    $schema = Get-DbdSchemaMap -DbdText $dbdText -Build $Build
    if (-not $schema) {
        $Problems += [pscustomobject]@{ Table = $T; Reason = "no schema block for build $Build in .dbd" }
        Write-Host "  PROBLEM: no schema for build $Build"
        continue
    }

    # 3. build typed CREATE in CSV-header order, then load
    $cols = Build-CreateColumns -Header $header -SchemaMap $schema
    $abs  = (Resolve-Path $csv).Path -replace '\\','/'

    # Load in one session with strict mode so a value that does not fit a typed
    # column fails the load loudly instead of being silently clamped or zeroed.
    $loadScript = @"
SET SESSION sql_mode = 'STRICT_ALL_TABLES';
DROP TABLE IF EXISTS ``$T``;
CREATE TABLE ``$T`` ($cols);
LOAD DATA LOCAL INFILE '$abs'
INTO TABLE ``$T``
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;
"@

    try {
        Invoke-Mysql -MysqlArgs @("--local-infile=1","-u",$User,$Db) -StdinText $loadScript
    } catch {
        $Problems += [pscustomobject]@{ Table = $T; Reason = "load failed (strict): $($_.Exception.Message)" }
        Write-Host "  PROBLEM: load failed (strict mode caught a bad/oversized value)"
        continue
    }

    # Verify row count with a clean, separate query (no fragile inline parsing).
    try {
        $loaded = [int](Get-SqlScalar "SELECT COUNT(*) FROM ``$T``;")
    } catch {
        $loaded = -1
    }

    if ($loaded -lt 0) {
        $Problems += [pscustomobject]@{ Table = $T; Reason = "loaded but row count could not be verified" }
        Write-Host "  PROBLEM: row-count verify failed"
    } elseif ($loaded -eq 0) {
        $Problems += [pscustomobject]@{ Table = $T; Reason = "loaded 0 rows" }
        Write-Host "  PROBLEM: 0 rows"
    } else {
        Write-Host "  loaded (typed, $loaded rows)."
    }
}

# ---- report 1: problems with queued tables -----------------------------------
Write-Host ""
Write-Host "==== PROBLEMS (queued tables that did not come over) ===="
if ($Problems.Count -eq 0) {
    Write-Host "  none"
} else {
    foreach ($p in $Problems) { Write-Host "  $($p.Table) -- $($p.Reason)" }
}

# ---- report 2: orphans (in the database but not in the queue) ----------------
Write-Host ""
Write-Host "==== ORPHANS (in $Db but not in your queue) ===="
try {
    $errFile = [System.IO.Path]::GetTempFileName()
    $dbTables = (& $MysqlExe -N -B -u $User $Db -e "SHOW TABLES;" 2> $errFile)
    Remove-Item $errFile -ErrorAction SilentlyContinue
    $queueLower = $Tables | ForEach-Object { $_.ToLower() }
    $orphans = $dbTables | Where-Object { $_ -and ($queueLower -notcontains $_.ToLower()) }
    if (-not $orphans) {
        Write-Host "  none"
    } else {
        foreach ($o in $orphans) { Write-Host "  $o" }
    }
} catch {
    Write-Host "  (could not list database tables: $($_.Exception.Message))"
}

Write-Host ""
Write-Host "Done."
