# HealthBridge (Group 4) - 03_verify.ps1
# Usage:  .\03_verify.ps1      (prompts for the postgres password; nothing is saved)
# Every test runs inside BEGIN ... ROLLBACK, so no data is changed.
param(
  [string]$Db = 'grp03_projectdb',
  [string]$Bin = 'C:\Program Files\PostgreSQL\18\bin'
)

$psql = Join-Path $Bin 'psql.exe'
$s = Read-Host 'Password for postgres' -AsSecureString
$env:PGPASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($s))
$script:pass = 0; $script:fail = 0

function Test-Op($role, $exp, $desc, $sql, [switch]$NoTx) {
  $cmd = if ($NoTx) { $sql } else { "BEGIN; $sql; ROLLBACK;" }
  $out = & $psql -X -q -h localhost -U postgres -d $Db -v ON_ERROR_STOP=1 -c "SET ROLE $role;" -c $cmd 2>&1 | Out-String
  $actual = if ($LASTEXITCODE -eq 0) { 'ALLOW' } else { 'DENY' }
  if ($actual -eq $exp) { $r = 'PASS'; $script:pass++ } else { $r = 'FAIL'; $script:fail++ }
  $color = if ($r -eq 'PASS') { 'Green' } else { 'Red' }
  Write-Host ("{0} | {1,-9} | exp={2,-5} act={3,-5} | {4}" -f $r, $role, $exp, $actual, $desc) -ForegroundColor $color
  if ($actual -eq 'DENY') {
    $line = ($out -split "`n" | Where-Object { $_ -match 'ERROR|FATAL' } | Select-Object -First 1)
    if ($line) { Write-Host "       -> $($line.Trim())" -ForegroundColor DarkGray }
  }
}

# Staff
Test-Op hb_staff ALLOW 'read patients'                     'SELECT * FROM patients LIMIT 1'
Test-Op hb_staff ALLOW 'update appointments'               'UPDATE appointments SET status = status'
Test-Op hb_staff ALLOW 'delete medical_notes'              'DELETE FROM medical_notes WHERE false'
Test-Op hb_staff ALLOW 'read doctors (reference data)'     'SELECT * FROM doctors LIMIT 1'
Test-Op hb_staff DENY  'update doctors'                    'UPDATE doctors SET first_name = first_name'
Test-Op hb_staff DENY  'delete specialties'                'DELETE FROM specialties WHERE false'
Test-Op hb_staff DENY  'DROP TABLE'                        'DROP TABLE patients'
Test-Op hb_staff DENY  'CREATE TABLE in public'            'CREATE TABLE zz(x int)'
Test-Op hb_staff DENY  'CREATE DATABASE'                   'CREATE DATABASE zzdb' -NoTx
Test-Op hb_staff DENY  'CREATE ROLE'                       'CREATE ROLE zzr'
# Application login (inherits hb_staff)
Test-Op hb_app   ALLOW 'read appointments (inherits staff)' 'SELECT count(*) FROM appointments'
Test-Op hb_app   DENY  'update doctors'                    'UPDATE doctors SET first_name = first_name'
# Admin
Test-Op hb_admin ALLOW 'read patients'                     'SELECT * FROM patients LIMIT 1'
Test-Op hb_admin ALLOW 'update doctors'                    'UPDATE doctors SET first_name = first_name'
Test-Op hb_admin DENY  'DROP TABLE (not the owner)'        'DROP TABLE patients'

# Cross-database
& $psql -U postgres -h localhost -t -c "SELECT 'hb_app can connect to postgres DB: ' || has_database_privilege('hb_app','postgres','CONNECT');"

Remove-Item Env:PGPASSWORD
Write-Host '----'
Write-Host "PASS=$($script:pass) FAIL=$($script:fail)"
