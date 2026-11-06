# PAWPAW (Group 03) - 03_verify.ps1  (Windows PowerShell version of 03_verify.sh)
# Usage:  .\03_verify.ps1            (prompts for the 3 account passwords; nothing is saved)
param(
  [string]$Db = 'group3_Pawpaw',
  [string]$DbHost = 'localhost',
  [int]$Port = 5432
)

$accounts = 'pawpaw_app','pawpaw_report','pawpaw_auditor'
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

$A = 'pawpaw_app'; $R = 'pawpaw_report'; $U = 'pawpaw_auditor'

# Application runtime
Test-Op $A ALLOW "read pet" "SELECT * FROM pet LIMIT 1"
Test-Op $A ALLOW "insert service (identity seq)" "INSERT INTO service(service_name,price) VALUES ('zz_test',1)"
Test-Op $A ALLOW "insert appointment_service (trigger fires)" "INSERT INTO user_account(username,password_hash,role) VALUES ('zz','h','Staff'); INSERT INTO owner(name) VALUES ('o'); INSERT INTO pet(owner_id,name,species) SELECT max(owner_id),'p','dog' FROM owner; INSERT INTO appointment(pet_id,appointment_date,appointment_time) SELECT max(pet_id),CURRENT_DATE,'09:00' FROM pet; INSERT INTO appointment_service(appointment_id,service_id) SELECT max(appointment_id),(SELECT min(service_id) FROM service) FROM appointment"
Test-Op $A ALLOW "update appointment" "UPDATE appointment SET status=status"
Test-Op $A ALLOW "delete prescription" "DELETE FROM prescription WHERE false"
Test-Op $A ALLOW "insert audit_log" "INSERT INTO audit_log(action_type,table_name) VALUES ('LOGIN','user_account')"
Test-Op $A DENY  "update audit_log (append-only)" "UPDATE audit_log SET action_description='x'"
Test-Op $A DENY  "delete audit_log" "DELETE FROM audit_log"
Test-Op $A DENY  "delete pet" "DELETE FROM pet WHERE false"
Test-Op $A DENY  "read auth_session" "SELECT * FROM auth_session"
Test-Op $A DENY  "DROP TABLE" "DROP TABLE pet"
Test-Op $A DENY  "CREATE TABLE in public" "CREATE TABLE zz(x int)"
Test-Op $A DENY  "CREATE DATABASE" "CREATE DATABASE zzdb" -NoTx
Test-Op $A DENY  "CREATE ROLE" "CREATE ROLE zzr"
# Read-only
Test-Op $R ALLOW "read appointment" "SELECT * FROM appointment LIMIT 1"
Test-Op $R DENY  "insert pet" "INSERT INTO pet(owner_id,name,species) VALUES (1,'a','b')"
Test-Op $R DENY  "update service" "UPDATE service SET price=price"
Test-Op $R DENY  "delete vaccination" "DELETE FROM vaccination"
Test-Op $R DENY  "read user_account (hashes)" "SELECT * FROM user_account"
Test-Op $R DENY  "read audit_log" "SELECT * FROM audit_log"
# Auditor
Test-Op $U ALLOW "read audit_log" "SELECT * FROM audit_log"
Test-Op $U DENY  "update audit_log" "UPDATE audit_log SET action_description='x'"
Test-Op $U DENY  "read user_account" "SELECT * FROM user_account"
Test-Op $U DENY  "read pet" "SELECT * FROM pet"
# Cross-database
Test-Op $A DENY  "connect to unrelated DB (postgres)" "SELECT 1" -database postgres -NoTx

Remove-Item Env:PGPASSWORD
Write-Host '----'
Write-Host "PASS=$($script:pass) FAIL=$($script:fail)"
