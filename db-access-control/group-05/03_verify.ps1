# SHIORI Cafe (Group 5) - 03_verify.ps1
# Usage:  .\03_verify.ps1      (prompts for the postgres password; nothing is saved)
# Every test runs inside BEGIN ... ROLLBACK, so no data is changed.
param(
  [string]$Db = 'grp10_shioricafedb',
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
  Write-Host ("{0} | {1,-25} | exp={2,-5} act={3,-5} | {4}" -f $r, $role, $exp, $actual, $desc) -ForegroundColor $color
  if ($actual -eq 'DENY') {
    $line = ($out -split "`n" | Where-Object { $_ -match 'ERROR|FATAL' } | Select-Object -First 1)
    if ($line) { Write-Host "       -> $($line.Trim())" -ForegroundColor DarkGray }
  }
}

$A = 'shioricafe_app_login'; $R = 'shioricafe_readonly_login'

# Application runtime
Test-Op $A ALLOW 'read category'            'SELECT * FROM shioricafe_schema.category LIMIT 1'
Test-Op $A ALLOW 'update reservation'       'UPDATE shioricafe_schema.reservation SET status = status'
Test-Op $A ALLOW 'insert category'          'INSERT INTO shioricafe_schema.category(category_name) VALUES ($$zz_test$$)'
Test-Op $A DENY  'delete category'          'DELETE FROM shioricafe_schema.category WHERE false'
Test-Op $A DENY  'delete payment_transaction' 'DELETE FROM shioricafe_schema.payment_transaction WHERE false'
Test-Op $A DENY  'DROP TABLE'               'DROP TABLE shioricafe_schema.category'
Test-Op $A DENY  'CREATE TABLE in schema'   'CREATE TABLE shioricafe_schema.zz(x int)'
Test-Op $A DENY  'CREATE DATABASE'          'CREATE DATABASE zzdb' -NoTx
Test-Op $A DENY  'CREATE ROLE'              'CREATE ROLE zzr'
# Read-only
Test-Op $R ALLOW 'read reservation'         'SELECT * FROM shioricafe_schema.reservation LIMIT 1'
Test-Op $R DENY  'insert category'          'INSERT INTO shioricafe_schema.category(category_name) VALUES ($$zz_test$$)'
Test-Op $R DENY  'update menu_item'         'UPDATE shioricafe_schema.menu_item SET current_price = current_price'
Test-Op $R DENY  'delete order'             'DELETE FROM shioricafe_schema."order" WHERE false'
Test-Op $R DENY  'read customer (personal data)' 'SELECT * FROM shioricafe_schema.customer'
Test-Op $R DENY  'read staff (credentials)' 'SELECT * FROM shioricafe_schema.staff'

# Cross-database
& $psql -U postgres -h localhost -t -c "SELECT 'shioricafe_app_login can connect to postgres DB: ' || has_database_privilege('shioricafe_app_login','postgres','CONNECT');"

Remove-Item Env:PGPASSWORD
Write-Host '----'
Write-Host "PASS=$($script:pass) FAIL=$($script:fail)"
