# Catering - 03_verify.ps1  (Windows PowerShell)
# Usage:  .\03_verify.ps1            (prompts for the 3 account passwords; nothing is saved)
# Optional, for unattended runs: set CATERING_API_PW, CATERING_REPORT_PW, CATERING_OPS_PW first.
param(
  [string]$Db = 'catering_management_db',
  [string]$DbHost = 'localhost',
  [int]$Port = 5432
)

$accounts = 'catering_api','catering_report','catering_ops'
$envName  = @{ catering_api='CATERING_API_PW'; catering_report='CATERING_REPORT_PW'; catering_ops='CATERING_OPS_PW' }
$pw = @{}
foreach ($a in $accounts) {
  $fromEnv = [Environment]::GetEnvironmentVariable($envName[$a])
  if ($fromEnv) { $pw[$a] = $fromEnv; continue }
  $s = Read-Host "Password for $a" -AsSecureString
  $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($s)
  try { $pw[$a] = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr) }
  finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
}

$script:pass = 0; $script:fail = 0

function Test-Op($acct, $exp, $desc, $sql, [string]$database = $Db, [switch]$NoTx) {
  $env:PGPASSWORD = $pw[$acct]
  $cmd = if ($NoTx) { $sql } else { "BEGIN; $sql; ROLLBACK;" }
  $out = & psql -X -q -h $DbHost -p $Port -U $acct -d $database -v ON_ERROR_STOP=1 -c $cmd 2>&1 | Out-String
  $actual = if ($LASTEXITCODE -eq 0) { 'ALLOW' } else { 'DENY' }
  if ($actual -eq $exp) { $r = 'PASS'; $script:pass++ } else { $r = 'FAIL'; $script:fail++ }
  $color = if ($r -eq 'PASS') { 'Green' } else { 'Red' }
  Write-Host ("{0} | {1,-15} | exp={2,-5} act={3,-5} | {4}" -f $r, $acct, $exp, $actual, $desc) -ForegroundColor $color
  if ($actual -eq 'DENY') {
    $line = ($out -split "`n" | Where-Object { $_ -match 'ERROR|FATAL' } | Select-Object -First 1)
    if ($line) { Write-Host "       -> $($line.Trim())" -ForegroundColor DarkGray }
  }
}

$A = 'catering_api'; $R = 'catering_report'; $O = 'catering_ops'

# ---- catering_api (Express backend) ------------------------------------------------------
Test-Op $A ALLOW "admin login lookup (SELECT admin)" "SELECT admin_id, username, password_hash FROM admin LIMIT 1"
Test-Op $A ALLOW "customer portal login (SELECT * incl. password_hash)" "SELECT * FROM customer LIMIT 1"
Test-Op $A ALLOW "insert package (identity, no sequence grant)" "INSERT INTO package(package_name, price_per_guest) VALUES ('zz_test', 0)"
Test-Op $A ALLOW "register customer (INSERT incl. password_hash)" "INSERT INTO customer(first_name,last_name,email,password_hash) VALUES ('z','z','zz@test.invalid','x')"
Test-Op $A ALLOW "update customer profile columns" "UPDATE customer SET first_name=first_name, last_name=last_name, email=email, phone=phone, address=address"
Test-Op $A ALLOW "update reservation" "UPDATE reservation SET status=status"
Test-Op $A ALLOW "row lock reservation (FOR UPDATE)" "SELECT reservation_id FROM reservation WHERE false FOR UPDATE"
Test-Op $A ALLOW "row lock cancellation (FOR UPDATE)" "SELECT cancellation_id FROM cancellation WHERE false FOR UPDATE"
Test-Op $A ALLOW "update payment" "UPDATE payment SET payment_status=payment_status"
Test-Op $A ALLOW "delete reservation_menu" "DELETE FROM reservation_menu WHERE false"
Test-Op $A ALLOW "delete reservation" "DELETE FROM reservation WHERE false"
Test-Op $A ALLOW "session upsert (connect-pg-simple)" "INSERT INTO session(sid,sess,expire) VALUES ('zz','{}',now()) ON CONFLICT (sid) DO UPDATE SET sess=EXCLUDED.sess"
Test-Op $A ALLOW "session prune (DELETE expired)" "DELETE FROM session WHERE expire < now()"
Test-Op $A ALLOW "session read" "SELECT sess FROM session LIMIT 1"
Test-Op $A DENY  "insert admin (only create-admin.js as owner)" "INSERT INTO admin(username,password_hash) VALUES ('zz','x')"
Test-Op $A DENY  "update admin" "UPDATE admin SET username=username"
Test-Op $A DENY  "delete admin" "DELETE FROM admin WHERE false"
Test-Op $A DENY  "update customer password_hash (column-level)" "UPDATE customer SET password_hash=password_hash"
Test-Op $A DENY  "update customer_id" "UPDATE customer SET customer_id=customer_id"
Test-Op $A DENY  "TRUNCATE reservation" "TRUNCATE reservation"
Test-Op $A DENY  "DROP TABLE" "DROP TABLE reservation"
Test-Op $A DENY  "ALTER TABLE" "ALTER TABLE reservation ADD COLUMN zz int"
Test-Op $A DENY  "CREATE TABLE in public" "CREATE TABLE zz(x int)"
Test-Op $A DENY  "CREATE DATABASE" "CREATE DATABASE zzdb" -NoTx
Test-Op $A DENY  "CREATE ROLE" "CREATE ROLE zzr"
Test-Op $A DENY  "connect to unrelated DB (postgres)" "SELECT 1" -database postgres -NoTx
Test-Op $A DENY  "connect to template1" "SELECT 1" -database template1 -NoTx

# ---- catering_report (read-only reporting) -----------------------------------------------
Test-Op $R ALLOW "read package" "SELECT * FROM package LIMIT 1"
Test-Op $R ALLOW "read reservation" "SELECT * FROM reservation LIMIT 1"
Test-Op $R ALLOW "read cancellation" "SELECT * FROM cancellation LIMIT 1"
Test-Op $R ALLOW "read customer names (approved columns)" "SELECT customer_id, first_name, last_name FROM customer LIMIT 1"
Test-Op $R ALLOW "read employee name/role (approved columns)" "SELECT employee_id, first_name, last_name, role FROM employee LIMIT 1"
Test-Op $R ALLOW "read payment amounts (approved columns)" "SELECT payment_id, payment_amount, payment_status, payment_method FROM payment LIMIT 1"
Test-Op $R DENY  "read customer password_hash" "SELECT password_hash FROM customer LIMIT 1"
Test-Op $R DENY  "read customer email" "SELECT email FROM customer LIMIT 1"
Test-Op $R DENY  "SELECT * on customer" "SELECT * FROM customer LIMIT 1"
Test-Op $R DENY  "read employee phone" "SELECT phone FROM employee LIMIT 1"
Test-Op $R DENY  "read payment reference_number" "SELECT reference_number FROM payment LIMIT 1"
Test-Op $R DENY  "SELECT * on payment" "SELECT * FROM payment LIMIT 1"
Test-Op $R DENY  "read admin" "SELECT * FROM admin LIMIT 1"
Test-Op $R DENY  "read session" "SELECT * FROM session LIMIT 1"
Test-Op $R DENY  "insert package" "INSERT INTO package(package_name, price_per_guest) VALUES ('x', 0)"
Test-Op $R DENY  "update reservation" "UPDATE reservation SET status=status"
Test-Op $R DENY  "delete cancellation" "DELETE FROM cancellation WHERE false"

# ---- catering_ops (read-only operations/staff) -------------------------------------------
Test-Op $O ALLOW "read reservation" "SELECT * FROM reservation LIMIT 1"
Test-Op $O ALLOW "read event_assignment" "SELECT * FROM event_assignment LIMIT 1"
Test-Op $O ALLOW "read inventory" "SELECT * FROM inventory LIMIT 1"
Test-Op $O ALLOW "read employee name/role/phone (approved columns)" "SELECT employee_id, first_name, last_name, role, phone FROM employee LIMIT 1"
Test-Op $O ALLOW "read customer names (approved columns)" "SELECT customer_id, first_name, last_name FROM customer LIMIT 1"
Test-Op $O DENY  "read payment" "SELECT * FROM payment LIMIT 1"
Test-Op $O DENY  "read cancellation" "SELECT * FROM cancellation LIMIT 1"
Test-Op $O DENY  "read admin" "SELECT * FROM admin LIMIT 1"
Test-Op $O DENY  "read session" "SELECT * FROM session LIMIT 1"
Test-Op $O DENY  "read customer email" "SELECT email FROM customer LIMIT 1"
Test-Op $O DENY  "read employee email" "SELECT email FROM employee LIMIT 1"
Test-Op $O DENY  "update inventory" "UPDATE inventory SET quantity=quantity"
Test-Op $O DENY  "insert event_assignment" "INSERT INTO event_assignment(reservation_id,employee_id,assignment_role) VALUES (1,1,'x')"

Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
Write-Host '----'
Write-Host "PASS=$($script:pass) FAIL=$($script:fail)"
if ($script:fail -gt 0) { exit 1 }
