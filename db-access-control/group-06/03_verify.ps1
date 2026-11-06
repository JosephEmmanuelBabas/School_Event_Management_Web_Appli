# Car Rental - 03_verify.ps1  (Windows PowerShell version of 03_verify.sh)
# Usage:  .\03_verify.ps1            (prompts for the 3 account passwords; nothing is saved)
param(
  [string]$Db = 'car_rental_db',
  [string]$DbHost = 'localhost',
  [int]$Port = 5432
)

$accounts = 'carrental_app','carrental_report','carrental_auditor'
$pw = @{}
foreach ($a in $accounts) {
  $s = Read-Host "Password for $a" -AsSecureString
  $pw[$a] = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($s))
}

$script:pass = 0; $script:fail = 0

function Test-Op($acct, $exp, $desc, $sql, [string]$database = $Db, [switch]$NoTx) {
  $env:PGPASSWORD = $pw[$acct]
  $cmd = if ($NoTx) { $sql } else { "BEGIN; $sql; ROLLBACK;" }
  $out = & psql -X -q -h $DbHost -p $Port -U $acct -d $database -v ON_ERROR_STOP=1 -c $cmd 2>&1 | Out-String
  $actual = if ($LASTEXITCODE -eq 0) { 'ALLOW' } else { 'DENY' }
  if ($actual -eq $exp) { $r = 'PASS'; $script:pass++ } else { $r = 'FAIL'; $script:fail++ }
  $color = if ($r -eq 'PASS') { 'Green' } else { 'Red' }
  Write-Host ("{0} | {1,-14} | exp={2,-5} act={3,-5} | {4}" -f $r, $acct, $exp, $actual, $desc) -ForegroundColor $color
  if ($actual -eq 'DENY') {
    $line = ($out -split "`n" | Where-Object { $_ -match 'ERROR|FATAL' } | Select-Object -First 1)
    if ($line) { Write-Host "       -> $($line.Trim())" -ForegroundColor DarkGray }
  }
}

$A = 'carrental_app'; $R = 'carrental_report'; $U = 'carrental_auditor'

Test-Op $A ALLOW "read rental" "SELECT * FROM rental LIMIT 1"
Test-Op $A ALLOW "insert vehicle_category (sequence)" "INSERT INTO vehicle_category(category_name) VALUES ('zz_test')"
Test-Op $A ALLOW "update vehicle" "UPDATE vehicle SET status=status"
Test-Op $A ALLOW "row lock rental (FOR UPDATE)" "SELECT rental_id FROM rental WHERE false FOR UPDATE"
Test-Op $A ALLOW "delete vehicle (only allowed DELETE)" "DELETE FROM vehicle WHERE false"
Test-Op $A DENY "update audit_log (append-only)" "UPDATE audit_log SET action_description='x'"
Test-Op $A DENY "delete audit_log" "DELETE FROM audit_log"
Test-Op $A DENY "delete rental" "DELETE FROM rental WHERE false"
Test-Op $A DENY "delete customer" "DELETE FROM customer WHERE false"
Test-Op $A DENY "update vehicle_category (not updated by app)" "UPDATE vehicle_category SET category_name=category_name"
Test-Op $A DENY "TRUNCATE rental" "TRUNCATE rental"
Test-Op $A DENY "DROP TABLE" "DROP TABLE rental"
Test-Op $A DENY "CREATE TABLE in public" "CREATE TABLE zz(x int)"
Test-Op $A DENY "CREATE DATABASE" "CREATE DATABASE zzdb" -NoTx
Test-Op $A DENY "CREATE ROLE" "CREATE ROLE zzr"
Test-Op $R ALLOW "read vehicle" "SELECT * FROM vehicle LIMIT 1"
Test-Op $R ALLOW "read customer names (approved columns)" "SELECT first_name, last_name FROM customer LIMIT 1"
Test-Op $R DENY "read customer password_hash" "SELECT password_hash FROM customer LIMIT 1"
Test-Op $R DENY "SELECT * on customer" "SELECT * FROM customer LIMIT 1"
Test-Op $R DENY "read driver license number" "SELECT license_number FROM driver_license LIMIT 1"
Test-Op $R DENY "read staff password_hash" "SELECT password_hash FROM staff LIMIT 1"
Test-Op $R DENY "insert vehicle_category" "INSERT INTO vehicle_category(category_name) VALUES ('x')"
Test-Op $R DENY "update rental" "UPDATE rental SET rental_status=rental_status"
Test-Op $R DENY "delete vehicle" "DELETE FROM vehicle WHERE false"
Test-Op $R DENY "read audit_log" "SELECT * FROM audit_log"
Test-Op $U ALLOW "read audit_log" "SELECT * FROM audit_log LIMIT 1"
Test-Op $U DENY "update audit_log" "UPDATE audit_log SET action_description='x'"
Test-Op $U DENY "delete audit_log" "DELETE FROM audit_log"
Test-Op $U DENY "read customer" "SELECT * FROM customer LIMIT 1"
Test-Op $U DENY "read vehicle" "SELECT * FROM vehicle LIMIT 1"
Test-Op $A DENY "connect to unrelated DB (postgres)" "SELECT 1" -database postgres -NoTx

Remove-Item Env:PGPASSWORD
Write-Host '----'
Write-Host "PASS=$($script:pass) FAIL=$($script:fail)"
