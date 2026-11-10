# Group 11 - ReserveIT: Activity 4 verification.
# Logs in as each a4_* account, runs allowed and denied operations, and prints PASS or FAIL.
# Prerequisites: 01_roles.sql, 02_privileges.sql and 04_cluster_hardening.sql were run, and the 4 passwords were set with \password.
# Run from PowerShell:   powershell -ExecutionPolicy Bypass -File .\03_verify.ps1
# Passwords are typed when asked (hidden), kept only in memory, and never written to a file.

$psql = "psql"          # if psql is not recognized, use: "C:\Program Files\PostgreSQL\18\bin\psql.exe"
$dbHost = "localhost"
$db = "ReserveIT"

function Read-Secret($label) {
    $s = Read-Host "Password for $label" -AsSecureString
    $b = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($s)
    try { [Runtime.InteropServices.Marshal]::PtrToStringBSTR($b) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($b) }
}

$pw = @{}
foreach ($a in "a4_app", "a4_report", "a4_entry", "a4_audit") { $pw[$a] = Read-Secret $a }

# Tx = $true wraps the statement in BEGIN ... ROLLBACK so nothing is ever saved or damaged
$tests = @(
    @{ A = "a4_app";    D = $db;        Tx = $true;  E = "Allowed"; S = "SELECT * FROM room LIMIT 1" },
    @{ A = "a4_app";    D = $db;        Tx = $true;  E = "Allowed"; S = "INSERT INTO department (department_name) VALUES ('Test Dept')" },
    @{ A = "a4_app";    D = $db;        Tx = $true;  E = "Denied";  S = "DELETE FROM reservation WHERE reservation_id = 1" },
    @{ A = "a4_app";    D = $db;        Tx = $true;  E = "Denied";  S = "DROP TABLE room" },
    @{ A = "a4_app";    D = $db;        Tx = $true;  E = "Denied";  S = "CREATE USER test_user WITH PASSWORD '123'" },
    @{ A = "a4_app";    D = $db;        Tx = $false; E = "Denied";  S = "CREATE DATABASE testdb" },
    @{ A = "a4_app";    D = "postgres"; Tx = $true;  E = "Denied";  S = "SELECT 1" },
    @{ A = "a4_report"; D = $db;        Tx = $true;  E = "Allowed"; S = "SELECT * FROM reservation LIMIT 1" },
    @{ A = "a4_report"; D = $db;        Tx = $true;  E = "Denied";  S = "SELECT password_hash FROM app_user" },
    @{ A = "a4_report"; D = $db;        Tx = $true;  E = "Denied";  S = "UPDATE room SET capacity = 1 WHERE room_id = 1" },
    @{ A = "a4_entry";  D = $db;        Tx = $true;  E = "Allowed"; S = "INSERT INTO reservation (user_id, room_id, reservation_date, start_time, end_time, purpose) VALUES (1, 1, '2027-01-15', '09:00', '10:00', 'Test')" },
    @{ A = "a4_entry";  D = $db;        Tx = $true;  E = "Denied";  S = "UPDATE reservation SET status = 'CANCELLED' WHERE reservation_id = 1" },
    @{ A = "a4_entry";  D = $db;        Tx = $true;  E = "Denied";  S = "SELECT * FROM penalty" },
    @{ A = "a4_audit";  D = $db;        Tx = $true;  E = "Allowed"; S = "SELECT email, role FROM staff LIMIT 1" },
    @{ A = "a4_audit";  D = $db;        Tx = $true;  E = "Denied";  S = "DELETE FROM reservation WHERE reservation_id = 1" }
)

$pass = 0; $fail = 0; $n = 0
foreach ($t in $tests) {
    $n++
    $env:PGPASSWORD = $pw[$t.A]
    if ($t.Tx) { $sql = "BEGIN; $($t.S); ROLLBACK;" } else { $sql = $t.S }
    $out = & $psql -h $dbHost -U $t.A -d $t.D -v ON_ERROR_STOP=1 -q -A -t -c $sql 2>&1 | Out-String
    if ($LASTEXITCODE -eq 0) { $got = "Allowed" } else { $got = "Denied" }
    if ($got -eq $t.E) { $r = "PASS"; $pass++ } else { $r = "FAIL"; $fail++ }
    $msg = ($out -replace "\s+", " ").Trim()
    if ($msg.Length -gt 90) { $msg = $msg.Substring(0, 90) }
    Write-Host ("{0,2}. {1} | {2,-9} | expected {3,-7} got {4,-7} | {5}" -f $n, $r, $t.A, $t.E, $got, $t.S)
    if ($msg) { Write-Host ("       " + $msg) }
}
Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
Write-Host ""
Write-Host "Result: $pass PASS, $fail FAIL"
