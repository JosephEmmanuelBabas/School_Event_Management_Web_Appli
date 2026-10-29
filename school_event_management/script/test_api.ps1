$base = "http://localhost:8080"

function Send-Api {
    param([string]$Method, [string]$Path, $Session, [hashtable]$Headers = @{},
          $Body = $null, [string]$ContentType = "")
    $p = @{ Uri = "$base$Path"; Method = $Method; WebSession = $Session
            Headers = $Headers; UseBasicParsing = $true }
    if ($null -ne $Body) { $p["Body"] = $Body }
    if ($ContentType) { $p["ContentType"] = $ContentType }
    try {
        $r = Invoke-WebRequest @p
                return [pscustomobject]@{ Status = [int]$r.StatusCode; Body = [string]$r.Content; Headers = $r.Headers }
    } catch {
        if ($null -eq $_.Exception.Response) { throw }
                return [pscustomobject]@{ Status = [int]$_.Exception.Response.StatusCode; Body = ""; Headers = @{} }
    }
}

function Show($Label, $Expected, $Result) {
    $mark = if ($Result.Status -eq $Expected) { "PASS" } else { "FAIL" }
    Write-Host ("{0}  {1}  (expected {2}, got {3})" -f $mark, $Label, $Expected, $Result.Status)
}

function Get-CsrfHeaders($Session) {
    $r = Send-Api GET "/api/auth/csrf" $Session
    $t = $r.Body | ConvertFrom-Json
    $h = @{}
    $h[$t.headerName] = $t.token
    return $h
}

function Invoke-Login($Session, [string]$User, [string]$Pass) {
    $h = Get-CsrfHeaders $Session
    return Send-Api POST "/api/auth/login" $Session $h @{ username = $User; password = $Pass } "application/x-www-form-urlencoded"
}

function Read-Plain($Prompt) {
    $s = Read-Host $Prompt -AsSecureString
    return [System.Net.NetworkCredential]::new("", $s).Password
}

$adminUser = Read-Host "Super Admin username"
$adminPass = Read-Plain "Super Admin password"
$orgUser   = Read-Host "Organizer username"
$orgPass   = Read-Plain "Organizer password"

Write-Host "`n=== Anonymous ==="
$anon = New-Object Microsoft.PowerShell.Commands.WebRequestSession
Show "GET venues without login" 401 (Send-Api GET "/api/venues" $anon)
Show "Login without CSRF token" 403 (Send-Api POST "/api/auth/login" $anon @{} @{ username = $adminUser; password = $adminPass } "application/x-www-form-urlencoded")
Show "Login with wrong password" 401 (Invoke-Login $anon $adminUser "definitely-wrong-password")

Write-Host "`n=== Super Admin ==="
$admin = New-Object Microsoft.PowerShell.Commands.WebRequestSession
Show "Admin login" 204 (Invoke-Login $admin $adminUser $adminPass)
$me = Send-Api GET "/api/auth/me" $admin
Show "Admin /me" 200 $me
Write-Host "      $($me.Body)"
Show "Admin can read venues" 200 (Send-Api GET "/api/venues" $admin)
$h = Get-CsrfHeaders $admin
Show "Admin cannot create venue" 403 (Send-Api POST "/api/venues" $admin $h '{"venueName":"Admin Venue","location":"X","capacity":10}' "application/json")
$h = Get-CsrfHeaders $admin
Show "Admin logout" 204 (Send-Api POST "/api/auth/logout" $admin $h)
Show "After logout, venues blocked" 401 (Send-Api GET "/api/venues" $admin)

Write-Host "`n=== Event Organizer ==="
$org = New-Object Microsoft.PowerShell.Commands.WebRequestSession
Show "Organizer login" 204 (Invoke-Login $org $orgUser $orgPass)
$h = Get-CsrfHeaders $org
$created = Send-Api POST "/api/venues" $org $h '{"venueName":"Test Gym","location":"Main Building","capacity":150}' "application/json"
Show "Create venue" 201 $created
$id = ($created.Body | ConvertFrom-Json).venueId
$h = Get-CsrfHeaders $org
Show "Duplicate venue name" 409 (Send-Api POST "/api/venues" $org $h '{"venueName":"Test Gym","location":"Elsewhere","capacity":20}' "application/json")
Show "Invalid venue (blank name, capacity -5)" 400 (Send-Api POST "/api/venues" $org $h '{"venueName":"","location":"X","capacity":-5}' "application/json")
Show "Update venue" 200 (Send-Api PUT "/api/venues/$id" $org $h '{"venueName":"Test Gym","location":"Main Building","capacity":200}' "application/json")
Show "Get venue" 200 (Send-Api GET "/api/venues/$id" $org)
Show "Delete venue" 204 (Send-Api DELETE "/api/venues/$id" $org $h)
Show "Get deleted venue" 404 (Send-Api GET "/api/venues/$id" $org)

Write-Host "`n=== Audit log ==="
$admin2 = New-Object Microsoft.PowerShell.Commands.WebRequestSession
Show "Admin login again" 204 (Invoke-Login $admin2 $adminUser $adminPass)
$audit = Send-Api GET "/api/audit-logs?size=5" $admin2
Show "Admin can read audit log" 200 $audit
$rows = ConvertFrom-Json $audit.Body
foreach ($r in $rows | Select-Object -First 3) {
    Write-Host ("      {0}  {1}  {2}  {3} #{4}" -f $r.logTimestamp, $r.username, $r.actionPerformed, $r.affectedTable, $r.affectedRecordId)
}
Show "Organizer cannot read audit log" 403 (Send-Api GET "/api/audit-logs" $org)


Write-Host "`n=== User management ==="
$suffix = Get-Random -Maximum 99999
$newUser = "tmpuser$suffix"
$newPass = "Temp-Password-$suffix"
$newPass2 = "Another-Pass-$suffix"

$admin3 = New-Object Microsoft.PowerShell.Commands.WebRequestSession
Show "Admin login (user tests)" 204 (Invoke-Login $admin3 $adminUser $adminPass)
$adminId = (ConvertFrom-Json (Send-Api GET "/api/auth/me" $admin3).Body).userId

$h = Get-CsrfHeaders $admin3
$createBody = @{ username = $newUser; password = $newPass; firstName = "Temp"; lastName = "User"; email = $null; roleName = "Event Organizer" } | ConvertTo-Json
$created = Send-Api POST "/api/users" $admin3 $h $createBody "application/json"
Show "Admin creates user" 201 $created
$newId = (ConvertFrom-Json $created.Body).userId

$h = Get-CsrfHeaders $admin3
$dupBody = @{ username = $newUser.ToUpper(); password = $newPass; firstName = "Dup"; lastName = "User"; email = $null; roleName = "Event Organizer" } | ConvertTo-Json
Show "Duplicate username, different case" 409 (Send-Api POST "/api/users" $admin3 $h $dupBody "application/json")

$h = Get-CsrfHeaders $admin3
$weakBody = @{ username = "weak$suffix"; password = "short"; firstName = "Weak"; lastName = "User"; email = $null; roleName = "Event Organizer" } | ConvertTo-Json
Show "Weak password rejected" 400 (Send-Api POST "/api/users" $admin3 $h $weakBody "application/json")

Show "Organizer cannot list users" 403 (Send-Api GET "/api/users" $org)

$list = Send-Api GET "/api/users" $admin3
Show "Admin can list users" 200 $list
$leak = if ($list.Body -match "(?i)password") { "FAIL" } else { "PASS" }
Write-Host "$leak  User list contains no password data"

Write-Host "--- self-service"
$tmp = New-Object Microsoft.PowerShell.Commands.WebRequestSession
Show "New user can log in" 204 (Invoke-Login $tmp $newUser $newPass)
$h = Get-CsrfHeaders $tmp
$wrong = @{ currentPassword = "not-the-password"; newPassword = $newPass2 } | ConvertTo-Json
Show "Change password, wrong current" 400 (Send-Api POST "/api/account/me/password" $tmp $h $wrong "application/json")
$right = @{ currentPassword = $newPass; newPassword = $newPass2 } | ConvertTo-Json
Show "Change password" 204 (Send-Api POST "/api/account/me/password" $tmp $h $right "application/json")
$profile = @{ firstName = "Renamed"; lastName = "Person"; email = $null } | ConvertTo-Json
Show "Update own profile" 200 (Send-Api PUT "/api/account/me" $tmp $h $profile "application/json")
Show "Old password no longer works" 401 (Invoke-Login (New-Object Microsoft.PowerShell.Commands.WebRequestSession) $newUser $newPass)
Show "New password works" 204 (Invoke-Login (New-Object Microsoft.PowerShell.Commands.WebRequestSession) $newUser $newPass2)

Write-Host "--- deactivation"
$h = Get-CsrfHeaders $admin3
$deact = @{ username = $newUser; firstName = "Renamed"; lastName = "Person"; email = $null; roleName = "Event Organizer"; accountStatus = "Inactive" } | ConvertTo-Json
Show "Admin deactivates user" 200 (Send-Api PUT "/api/users/$newId" $admin3 $h $deact "application/json")
Show "Deactivated user's open session is cut off" 401 (Send-Api GET "/api/venues" $tmp)
Show "Deactivated user cannot log in" 401 (Invoke-Login (New-Object Microsoft.PowerShell.Commands.WebRequestSession) $newUser $newPass2)

$h = Get-CsrfHeaders $admin3
$selfBody = @{ username = $adminUser; firstName = "System"; lastName = "Administrator"; email = $null; roleName = "Super Admin"; accountStatus = "Inactive" } | ConvertTo-Json
Show "Admin cannot deactivate self" 400 (Send-Api PUT "/api/users/$adminId" $admin3 $h $selfBody "application/json")

Write-Host "`n=== Events ==="
$day  = (Get-Date).AddDays(30).ToString("yyyy-MM-dd")
$past = (Get-Date).AddDays(-2).ToString("yyyy-MM-dd")

function New-EventBody($name, $date, $start, $end, $venueId) {
    @{ eventName = $name; description = "Script test"; eventDate = $date; startTime = $start; endTime = $end; venueId = $venueId } | ConvertTo-Json
}

$h = Get-CsrfHeaders $org
$v = Send-Api POST "/api/venues" $org $h (@{ venueName = "Event Hall $suffix"; location = "Test Wing"; capacity = 200 } | ConvertTo-Json) "application/json"
Show "Create venue for event tests" 201 $v
$venueId = (ConvertFrom-Json $v.Body).venueId

$e1 = Send-Api POST "/api/events" $org $h (New-EventBody "Assembly $suffix" $day "09:00" "11:00" $venueId) "application/json"
Show "Create event" 201 $e1
$e1Obj = ConvertFrom-Json $e1.Body
Write-Host "      status=$($e1Obj.eventStatus) organizer=$($e1Obj.organizerName) venue=$($e1Obj.venueName)"
$e1Id = $e1Obj.eventId

$e2 = Send-Api POST "/api/events" $org $h (New-EventBody "Rehearsal $suffix" $day "11:00" "12:00" $venueId) "application/json"
Show "Back-to-back event, same venue" 201 $e2
$e2Id = (ConvertFrom-Json $e2.Body).eventId

Show "Overlapping event, same venue" 409 (Send-Api POST "/api/events" $org $h (New-EventBody "Clash" $day "10:00" "12:00" $venueId) "application/json")
Show "End time before start time" 400 (Send-Api POST "/api/events" $org $h (New-EventBody "Backwards" $day "15:00" "14:00" $venueId) "application/json")
Show "Date in the past" 400 (Send-Api POST "/api/events" $org $h (New-EventBody "Old" $past "09:00" "10:00" $venueId) "application/json")
Show "Unknown venue" 400 (Send-Api POST "/api/events" $org $h (New-EventBody "Nowhere" $day "09:00" "10:00" 999999) "application/json")

$ha = Get-CsrfHeaders $admin3
Show "Admin can read events" 200 (Send-Api GET "/api/events" $admin3)
Show "Admin cannot create events" 403 (Send-Api POST "/api/events" $admin3 $ha (New-EventBody "Admin Event" $day "13:00" "14:00" $venueId) "application/json")

Show "Update event" 200 (Send-Api PUT "/api/events/$e1Id" $org $h (New-EventBody "Assembly $suffix (renamed)" $day "09:00" "10:30" $venueId) "application/json")
Show "Update into an overlap" 409 (Send-Api PUT "/api/events/$e2Id" $org $h (New-EventBody "Rehearsal $suffix" $day "10:00" "12:00" $venueId) "application/json")

$list = Send-Api GET "/api/events?status=Upcoming&search=Assembly&size=5" $org
Show "Filter by status and search" 200 $list
$rows = ConvertFrom-Json $list.Body
Write-Host "      matching events: $($rows.Count)  (expected at least 1)"

Show "Upcoming to Ongoing" 200 (Send-Api POST "/api/events/$e1Id/status" $org $h '{"status":"Ongoing"}' "application/json")
Show "Ongoing to Completed" 200 (Send-Api POST "/api/events/$e1Id/status" $org $h '{"status":"Completed"}' "application/json")
Show "Completed back to Upcoming" 400 (Send-Api POST "/api/events/$e1Id/status" $org $h '{"status":"Upcoming"}' "application/json")
Show "Editing a completed event" 400 (Send-Api PUT "/api/events/$e1Id" $org $h (New-EventBody "Too late" $day "09:00" "10:00" $venueId) "application/json")

Show "Cancel an event" 200 (Send-Api POST "/api/events/$e2Id/status" $org $h '{"status":"Cancelled"}' "application/json")
$e3 = Send-Api POST "/api/events" $org $h (New-EventBody "Reuses cancelled slot $suffix" $day "11:00" "12:00" $venueId) "application/json"
Show "Cancelled event releases its venue" 201 $e3
$e3Id = (ConvertFrom-Json $e3.Body).eventId

Show "Delete venue still used by events" 409 (Send-Api DELETE "/api/venues/$venueId" $org $h)
Show "Delete event 1" 204 (Send-Api DELETE "/api/events/$e1Id" $org $h)
Show "Delete event 2" 204 (Send-Api DELETE "/api/events/$e2Id" $org $h)
Show "Delete event 3" 204 (Send-Api DELETE "/api/events/$e3Id" $org $h)
Show "Get deleted event" 404 (Send-Api GET "/api/events/$e1Id" $org)
Show "Delete the test venue" 204 (Send-Api DELETE "/api/venues/$venueId" $org $h)

Write-Host "`n=== Schedules and staff ==="
$day2 = (Get-Date).AddDays(40).ToString("yyyy-MM-dd")

function New-ScheduleBody($name, $start, $end) {
    @{ activityName = $name; startTime = $start; endTime = $end } | ConvertTo-Json
}

$h = Get-CsrfHeaders $org
$v2 = Send-Api POST "/api/venues" $org $h (@{ venueName = "Schedule Hall $suffix"; location = "Test Wing"; capacity = 100 } | ConvertTo-Json) "application/json"
Show "Create venue for schedule tests" 201 $v2
$venue2 = (ConvertFrom-Json $v2.Body).venueId
$ev = Send-Api POST "/api/events" $org $h (New-EventBody "Sports Fest $suffix" $day2 "09:00" "12:00" $venue2) "application/json"
Show "Create event 09:00-12:00" 201 $ev
$evId = (ConvertFrom-Json $ev.Body).eventId

Write-Host "--- schedule entries"
$s1 = Send-Api POST "/api/events/$evId/schedules" $org $h (New-ScheduleBody "Opening" "09:00" "10:00") "application/json"
Show "Add entry inside the event" 201 $s1
$s1Id = (ConvertFrom-Json $s1.Body).scheduleId
Show "Entry before the event starts" 400 (Send-Api POST "/api/events/$evId/schedules" $org $h (New-ScheduleBody "Too early" "08:00" "09:30") "application/json")
Show "Entry after the event ends" 400 (Send-Api POST "/api/events/$evId/schedules" $org $h (New-ScheduleBody "Too late" "11:30" "12:30") "application/json")
Show "Entry with end before start" 400 (Send-Api POST "/api/events/$evId/schedules" $org $h (New-ScheduleBody "Backwards" "11:00" "10:00") "application/json")
$s2 = Send-Api POST "/api/events/$evId/schedules" $org $h (New-ScheduleBody "Parallel workshop" "09:30" "11:00") "application/json"
Show "Overlapping entries are allowed" 201 $s2
Show "Schedules of an unknown event" 404 (Send-Api GET "/api/events/999999/schedules" $org)
$sl = Send-Api GET "/api/events/$evId/schedules" $org
Show "List entries" 200 $sl
$entries = ConvertFrom-Json $sl.Body
foreach ($x in $entries) { Write-Host "      - $($x.activityName)  $($x.startTime)-$($x.endTime)" }
Show "Update an entry" 200 (Send-Api PUT "/api/events/$evId/schedules/$s1Id" $org $h (New-ScheduleBody "Opening ceremony" "09:00" "10:30") "application/json")
Show "Update an entry outside the event" 400 (Send-Api PUT "/api/events/$evId/schedules/$s1Id" $org $h (New-ScheduleBody "Opening ceremony" "08:00" "10:30") "application/json")
Show "Admin can read entries" 200 (Send-Api GET "/api/events/$evId/schedules" $admin3)
$ha = Get-CsrfHeaders $admin3
Show "Admin cannot add entries" 403 (Send-Api POST "/api/events/$evId/schedules" $admin3 $ha (New-ScheduleBody "Admin entry" "09:00" "10:00") "application/json")
Show "Shrink the event so entries fall outside" 400 (Send-Api PUT "/api/events/$evId" $org $h (New-EventBody "Sports Fest $suffix" $day2 "09:00" "10:00" $venue2) "application/json")
$s3 = Send-Api POST "/api/events/$evId/schedules" $org $h (New-ScheduleBody "Temporary" "11:00" "11:30") "application/json"
Show "Add a temporary entry" 201 $s3
$s3Id = (ConvertFrom-Json $s3.Body).scheduleId
Show "Delete the temporary entry" 204 (Send-Api DELETE "/api/events/$evId/schedules/$s3Id" $org $h)

Write-Host "--- staff"
$a1 = Send-Api POST "/api/events/$evId/assignments" $org $h (@{ staffName = "Juan Dela Cruz"; staffRole = "Usher" } | ConvertTo-Json) "application/json"
Show "Add staff without a status" 201 $a1
$a1Obj = ConvertFrom-Json $a1.Body
Write-Host "      status=$($a1Obj.assignmentStatus)  (expected Pending)"
$a1Id = $a1Obj.assignmentId
Show "Invalid staff status" 400 (Send-Api POST "/api/events/$evId/assignments" $org $h (@{ staffName = "Maria"; staffRole = "Guide"; assignmentStatus = "Maybe" } | ConvertTo-Json) "application/json")
Show "Blank staff name" 400 (Send-Api POST "/api/events/$evId/assignments" $org $h (@{ staffName = ""; staffRole = "Guide" } | ConvertTo-Json) "application/json")
Show "Confirm the assignment" 200 (Send-Api PUT "/api/events/$evId/assignments/$a1Id" $org $h (@{ staffName = "Juan Dela Cruz"; staffRole = "Usher"; assignmentStatus = "Confirmed" } | ConvertTo-Json) "application/json")
Show "List staff" 200 (Send-Api GET "/api/events/$evId/assignments" $org)
Show "Admin cannot add staff" 403 (Send-Api POST "/api/events/$evId/assignments" $admin3 $ha (@{ staffName = "Admin Pick" } | ConvertTo-Json) "application/json")

Write-Host "--- locked events"
Show "Event to Ongoing" 200 (Send-Api POST "/api/events/$evId/status" $org $h '{"status":"Ongoing"}' "application/json")
Show "Event to Completed" 200 (Send-Api POST "/api/events/$evId/status" $org $h '{"status":"Completed"}' "application/json")
Show "Cannot add entry to a completed event" 400 (Send-Api POST "/api/events/$evId/schedules" $org $h (New-ScheduleBody "Late" "09:00" "10:00") "application/json")
Show "Cannot add staff to a completed event" 400 (Send-Api POST "/api/events/$evId/assignments" $org $h (@{ staffName = "Late Hire" } | ConvertTo-Json) "application/json")
Show "Cannot delete entries of a completed event" 400 (Send-Api DELETE "/api/events/$evId/schedules/$s1Id" $org $h)
Show "Entries stay readable" 200 (Send-Api GET "/api/events/$evId/schedules" $org)

Write-Host "--- cleanup"
Show "Delete the event (entries and staff go with it)" 204 (Send-Api DELETE "/api/events/$evId" $org $h)
Show "Schedules of the deleted event" 404 (Send-Api GET "/api/events/$evId/schedules" $org)
Show "Delete the test venue" 204 (Send-Api DELETE "/api/venues/$venue2" $org $h)

Write-Host "`n=== Participants and attendance ==="
$day3 = (Get-Date).AddDays(50).ToString("yyyy-MM-dd")

function New-ParticipantBody($number, $first, $last, $grade) {
    @{ studentNumber = $number; firstName = $first; lastName = $last; gradeLevel = $grade } | ConvertTo-Json
}

$h = Get-CsrfHeaders $org
$stu1 = "STU-$suffix-A"
$stu2 = "STU-$suffix-B"

Write-Host "--- participants"
$p1 = Send-Api POST "/api/participants" $org $h (New-ParticipantBody $stu1 "Ana" "Cruz" "10") "application/json"
Show "Create participant" 201 $p1
$p1Id = (ConvertFrom-Json $p1.Body).participantId
$p2 = Send-Api POST "/api/participants" $org $h (New-ParticipantBody $stu2 "Ben" "Reyes" "11") "application/json"
Show "Create second participant" 201 $p2
$p2Id = (ConvertFrom-Json $p2.Body).participantId
Show "Duplicate student number, different case" 409 (Send-Api POST "/api/participants" $org $h (New-ParticipantBody $stu1.ToLower() "Dup" "Licate" "10") "application/json")
Show "Blank first name" 400 (Send-Api POST "/api/participants" $org $h (New-ParticipantBody "STU-$suffix-X" "" "Cruz" "10") "application/json")
Show "Student number too long" 400 (Send-Api POST "/api/participants" $org $h (New-ParticipantBody "123456789012345678901" "Long" "Number" "10") "application/json")
Show "Update participant" 200 (Send-Api PUT "/api/participants/$p1Id" $org $h (New-ParticipantBody $stu1 "Ana" "Cruz-Santos" "11") "application/json")
Show "Update into another student's number" 409 (Send-Api PUT "/api/participants/$p1Id" $org $h (New-ParticipantBody $stu2 "Ana" "Cruz-Santos" "11") "application/json")
$found = Send-Api GET "/api/participants?search=$stu1" $org
Show "Search participants" 200 $found
Write-Host "      matches: $([regex]::Matches($found.Body, '"participantId"').Count)  (expected 1)"
Show "Admin can read participants" 200 (Send-Api GET "/api/participants" $admin3)
$ha = Get-CsrfHeaders $admin3
Show "Admin cannot create participants" 403 (Send-Api POST "/api/participants" $admin3 $ha (New-ParticipantBody "STU-$suffix-Z" "Admin" "Pick" "10") "application/json")

Write-Host "--- attendance"
$v3 = Send-Api POST "/api/venues" $org $h (@{ venueName = "Attendance Hall $suffix"; location = "Test Wing"; capacity = 100 } | ConvertTo-Json) "application/json"
Show "Create venue for attendance tests" 201 $v3
$venue3 = (ConvertFrom-Json $v3.Body).venueId
$ev3 = Send-Api POST "/api/events" $org $h (New-EventBody "Pep Rally $suffix" $day3 "09:00" "12:00" $venue3) "application/json"
Show "Create event" 201 $ev3
$ev3Id = (ConvertFrom-Json $ev3.Body).eventId

Show "Cannot record before the event starts" 400 (Send-Api POST "/api/events/$ev3Id/attendance" $org $h (@{ participantId = $p1Id; attendanceStatus = "Present" } | ConvertTo-Json) "application/json")
Show "Event to Ongoing" 200 (Send-Api POST "/api/events/$ev3Id/status" $org $h '{"status":"Ongoing"}' "application/json")

$at1 = Send-Api POST "/api/events/$ev3Id/attendance" $org $h (@{ participantId = $p1Id; attendanceStatus = "Present" } | ConvertTo-Json) "application/json"
Show "Record Present" 201 $at1
$at1Id = (ConvertFrom-Json $at1.Body).attendanceId
$at2 = Send-Api POST "/api/events/$ev3Id/attendance" $org $h (@{ participantId = $p2Id; attendanceStatus = "Late" } | ConvertTo-Json) "application/json"
Show "Record Late" 201 $at2
$at2Id = (ConvertFrom-Json $at2.Body).attendanceId
Show "Duplicate record for the same participant" 409 (Send-Api POST "/api/events/$ev3Id/attendance" $org $h (@{ participantId = $p1Id; attendanceStatus = "Late" } | ConvertTo-Json) "application/json")
Show "Unknown participant" 400 (Send-Api POST "/api/events/$ev3Id/attendance" $org $h (@{ participantId = 999999; attendanceStatus = "Present" } | ConvertTo-Json) "application/json")
Show "Invalid status" 400 (Send-Api POST "/api/events/$ev3Id/attendance" $org $h (@{ participantId = $p1Id; attendanceStatus = "Maybe" } | ConvertTo-Json) "application/json")

$al = Send-Api GET "/api/events/$ev3Id/attendance" $org
Show "List attendance" 200 $al
$entries = ConvertFrom-Json $al.Body
foreach ($x in $entries) { Write-Host "      - $($x.studentNumber)  $($x.participantName)  $($x.attendanceStatus)" }

$sr = Send-Api GET "/api/events/$ev3Id/attendance/summary" $org
Show "Attendance summary" 200 $sr
$sum = ConvertFrom-Json $sr.Body
Write-Host "      present=$($sum.present) late=$($sum.late) absent=$($sum.absent) total=$($sum.totalRecorded)  (expected 1 / 1 / 0 / 2)"

Show "Change Late to Absent" 200 (Send-Api PUT "/api/events/$ev3Id/attendance/$at2Id" $org $h '{"attendanceStatus":"Absent"}' "application/json")
$sr2 = Send-Api GET "/api/events/$ev3Id/attendance/summary" $org
$sum2 = ConvertFrom-Json $sr2.Body
Write-Host "      present=$($sum2.present) late=$($sum2.late) absent=$($sum2.absent) total=$($sum2.totalRecorded)  (expected 1 / 0 / 1 / 2)"
Show "Admin can read attendance" 200 (Send-Api GET "/api/events/$ev3Id/attendance" $admin3)
Show "Admin cannot record attendance" 403 (Send-Api POST "/api/events/$ev3Id/attendance" $admin3 $ha (@{ participantId = $p1Id; attendanceStatus = "Present" } | ConvertTo-Json) "application/json")

Show "Cannot delete a participant with attendance" 409 (Send-Api DELETE "/api/participants/$p1Id" $org $h)
Show "Cannot delete an event with attendance" 409 (Send-Api DELETE "/api/events/$ev3Id" $org $h)
Show "Remove a mistaken record" 204 (Send-Api DELETE "/api/events/$ev3Id/attendance/$at2Id" $org $h)

Show "Event to Completed" 200 (Send-Api POST "/api/events/$ev3Id/status" $org $h '{"status":"Completed"}' "application/json")
$at2b = Send-Api POST "/api/events/$ev3Id/attendance" $org $h (@{ participantId = $p2Id; attendanceStatus = "Absent" } | ConvertTo-Json) "application/json"
Show "Completed events still accept corrections" 201 $at2b
$at2bId = (ConvertFrom-Json $at2b.Body).attendanceId

$ev4 = Send-Api POST "/api/events" $org $h (New-EventBody "Cancelled Rally $suffix" $day3 "13:00" "14:00" $venue3) "application/json"
Show "Create second event" 201 $ev4
$ev4Id = (ConvertFrom-Json $ev4.Body).eventId
Show "Cancel the second event" 200 (Send-Api POST "/api/events/$ev4Id/status" $org $h '{"status":"Cancelled"}' "application/json")
Show "Cannot record attendance for a cancelled event" 400 (Send-Api POST "/api/events/$ev4Id/attendance" $org $h (@{ participantId = $p1Id; attendanceStatus = "Present" } | ConvertTo-Json) "application/json")

Write-Host "--- cleanup"
Show "Delete first attendance record" 204 (Send-Api DELETE "/api/events/$ev3Id/attendance/$at1Id" $org $h)
Show "Delete second attendance record" 204 (Send-Api DELETE "/api/events/$ev3Id/attendance/$at2bId" $org $h)
Show "Delete event" 204 (Send-Api DELETE "/api/events/$ev3Id" $org $h)
Show "Delete cancelled event" 204 (Send-Api DELETE "/api/events/$ev4Id" $org $h)
Show "Delete first participant" 204 (Send-Api DELETE "/api/participants/$p1Id" $org $h)
Show "Delete second participant" 204 (Send-Api DELETE "/api/participants/$p2Id" $org $h)
Show "Delete the test venue" 204 (Send-Api DELETE "/api/venues/$venue3" $org $h)

Write-Host "`n=== Dashboard and reports ==="
$day4 = (Get-Date).AddDays(60).ToString("yyyy-MM-dd")

function Check($Label, $Condition) {
    $mark = if ($Condition) { "PASS" } else { "FAIL" }
    Write-Host "$mark  $Label"
}

Show "Anonymous cannot read the dashboard" 401 (Send-Api GET "/api/dashboard" $anon)
Show "Organizer cannot read the dashboard" 403 (Send-Api GET "/api/dashboard" $org)
Show "Organizer cannot read reports" 403 (Send-Api GET "/api/reports/attendance-by-event" $org)

$dash = Send-Api GET "/api/dashboard" $admin3
Show "Admin reads the dashboard" 200 $dash
$before = ConvertFrom-Json $dash.Body
Write-Host "      events: upcoming=$($before.events.upcoming) ongoing=$($before.events.ongoing) completed=$($before.events.completed) cancelled=$($before.events.cancelled) total=$($before.events.total)"
Write-Host "      users: active=$($before.users.active) inactive=$($before.users.inactive) suspended=$($before.users.suspended) total=$($before.users.total)"
Write-Host "      venues=$($before.venues) participants=$($before.participants) attendance=$($before.attendance.total)"
Write-Host "      recent activity rows: $($before.recentActivity.Count)  (at most 5)"

Write-Host "--- create test data"
$h = Get-CsrfHeaders $org
$rv = Send-Api POST "/api/venues" $org $h (@{ venueName = "Report Hall $suffix"; location = "Test Wing"; capacity = 100 } | ConvertTo-Json) "application/json"
Show "Create venue" 201 $rv
$rVenue = (ConvertFrom-Json $rv.Body).venueId
$re = Send-Api POST "/api/events" $org $h (New-EventBody "Report Event $suffix" $day4 "09:00" "12:00" $rVenue) "application/json"
Show "Create event" 201 $re
$rEvent = (ConvertFrom-Json $re.Body).eventId

$rPeople = @()
foreach ($spec in @(@("A", "Rita", "Lopez", "10"), @("B", "Sam", "Tan", "10"), @("C", "Tess", "Uy", "9"))) {
    $pr = Send-Api POST "/api/participants" $org $h (New-ParticipantBody "RPT-$suffix-$($spec[0])" $spec[1] $spec[2] $spec[3]) "application/json"
    Show "Create participant $($spec[0]) (grade $($spec[3]))" 201 $pr
    $rPeople += (ConvertFrom-Json $pr.Body).participantId
}

$mid = ConvertFrom-Json (Send-Api GET "/api/dashboard" $admin3).Body
Check "Dashboard counts the new venue, event and participants" ((($mid.venues - $before.venues) -eq 1) -and (($mid.events.upcoming - $before.events.upcoming) -eq 1) -and (($mid.participants - $before.participants) -eq 3))

Show "Event to Ongoing" 200 (Send-Api POST "/api/events/$rEvent/status" $org $h '{"status":"Ongoing"}' "application/json")
$rStatuses = @("Present", "Late", "Absent")
$rRecords = @()
for ($i = 0; $i -lt 3; $i++) {
    $ra = Send-Api POST "/api/events/$rEvent/attendance" $org $h (@{ participantId = $rPeople[$i]; attendanceStatus = $rStatuses[$i] } | ConvertTo-Json) "application/json"
    Show "Record $($rStatuses[$i])" 201 $ra
    $rRecords += (ConvertFrom-Json $ra.Body).attendanceId
}

$after = ConvertFrom-Json (Send-Api GET "/api/dashboard" $admin3).Body
Check "Dashboard counts one new Present, Late and Absent" ((($after.attendance.present - $before.attendance.present) -eq 1) -and (($after.attendance.late - $before.attendance.late) -eq 1) -and (($after.attendance.absent - $before.attendance.absent) -eq 1))
Check "Dashboard moved the event from Upcoming to Ongoing" ((($after.events.ongoing - $before.events.ongoing) -eq 1) -and (($after.events.upcoming - $before.events.upcoming) -eq 0))

Write-Host "--- reports"
$rep = Send-Api GET "/api/reports/attendance-by-event?from=$day4&to=$day4&venueId=$rVenue" $admin3
Show "Attendance report by event" 200 $rep
$n = 0
foreach ($row in (ConvertFrom-Json $rep.Body)) {
    $n++
    Write-Host "      $($row.eventName): present=$($row.present) late=$($row.late) absent=$($row.absent) total=$($row.totalRecorded) rate=$($row.attendanceRatePercent)  (expected 1 / 1 / 1 / 3 / 66.7)"
}
Check "Exactly one row for that venue and date" ($n -eq 1)

$none = Send-Api GET "/api/reports/attendance-by-event?from=$day4&to=$day4&venueId=$rVenue&status=Completed" $admin3
Show "Filter by status (nothing is Completed)" 200 $none
$n2 = 0
foreach ($row in (ConvertFrom-Json $none.Body)) { $n2++ }
Check "No rows for the Completed filter" ($n2 -eq 0)

$gr = Send-Api GET "/api/reports/attendance-by-grade?from=$day4&to=$day4" $admin3
Show "Attendance report by grade" 200 $gr
foreach ($g in (ConvertFrom-Json $gr.Body)) {
    Write-Host "      grade $($g.gradeLevel): present=$($g.present) late=$($g.late) absent=$($g.absent) rate=$($g.attendanceRatePercent)"
}
Write-Host "      (expected: grade 9 first with absent=1 rate=0, then grade 10 with present=1 late=1 rate=100)"

Show "Reversed date range" 400 (Send-Api GET "/api/reports/attendance-by-event?from=$day4&to=2000-01-01" $admin3)
Show "Unknown event status" 400 (Send-Api GET "/api/reports/attendance-by-event?status=Done" $admin3)

Write-Host "--- cleanup"
foreach ($attId in $rRecords) { Show "Delete attendance record" 204 (Send-Api DELETE "/api/events/$rEvent/attendance/$attId" $org $h) }
Show "Delete event" 204 (Send-Api DELETE "/api/events/$rEvent" $org $h)
foreach ($partId in $rPeople) { Show "Delete participant" 204 (Send-Api DELETE "/api/participants/$partId" $org $h) }
Show "Delete the test venue" 204 (Send-Api DELETE "/api/venues/$rVenue" $org $h)

Write-Host "`n=== Paging totals ==="
$day5 = (Get-Date).AddDays(70).ToString("yyyy-MM-dd")

function Get-Total($Res) { return [int](@($Res.Headers["X-Total-Count"])[0]) }
function Count-Items($Res, $Field) { return [regex]::Matches($Res.Body, "`"$Field`"").Count }

$h = Get-CsrfHeaders $org
$pgVenue = Send-Api POST "/api/venues" $org $h (@{ venueName = "Paging Hall $suffix"; location = "Test Wing"; capacity = 50 } | ConvertTo-Json) "application/json"
Show "Create venue" 201 $pgVenue
$pgVenueId = (ConvertFrom-Json $pgVenue.Body).venueId

$pgPeople = @()
foreach ($n in 1..3) {
    $r = Send-Api POST "/api/participants" $org $h (New-ParticipantBody "PG-$suffix-$n" "Page" "Student$n" "10") "application/json"
    Show "Create participant $n" 201 $r
    $pgPeople += (ConvertFrom-Json $r.Body).participantId
}
$pgEvents = @()
$slots = @(@("09:00", "10:00"), @("10:00", "11:00"), @("11:00", "12:00"))
foreach ($n in 0..2) {
    $r = Send-Api POST "/api/events" $org $h (New-EventBody "Paging Event $($n + 1) $suffix" $day5 $slots[$n][0] $slots[$n][1] $pgVenueId) "application/json"
    Show "Create event $($n + 1)" 201 $r
    $pgEvents += (ConvertFrom-Json $r.Body).eventId
}

Write-Host "--- participants"
$r1 = Send-Api GET "/api/participants?search=PG-$suffix&size=2&page=0" $org
Show "Participants page 1" 200 $r1
Check "Page 1 has 2 items and total 3" (((Count-Items $r1 "participantId") -eq 2) -and ((Get-Total $r1) -eq 3))
$r2 = Send-Api GET "/api/participants?search=PG-$suffix&size=2&page=1" $org
Check "Page 2 has 1 item and total 3" (((Count-Items $r2 "participantId") -eq 1) -and ((Get-Total $r2) -eq 3))
$r3 = Send-Api GET "/api/participants?search=PG-$suffix&size=2&page=5" $org
Check "A page beyond the end is empty, total still 3" (((Count-Items $r3 "participantId") -eq 0) -and ((Get-Total $r3) -eq 3))
$r4 = Send-Api GET "/api/participants?search=no-such-student-$suffix" $org
Check "A search with no matches has total 0" ((Get-Total $r4) -eq 0)
$r5 = Send-Api GET "/api/participants?search=PG-$suffix&gradeLevel=11" $org
Check "The grade filter also narrows the total" ((Get-Total $r5) -eq 0)

Write-Host "--- events"
$e1 = Send-Api GET "/api/events?venueId=$pgVenueId&size=2" $org
Show "Events page 1" 200 $e1
Check "Page 1 has 2 items and total 3" (((Count-Items $e1 "eventId") -eq 2) -and ((Get-Total $e1) -eq 3))
$e2 = Send-Api GET "/api/events?venueId=$pgVenueId&size=2&page=1" $org
Check "Page 2 has 1 item and total 3" (((Count-Items $e2 "eventId") -eq 1) -and ((Get-Total $e2) -eq 3))
$e3 = Send-Api GET "/api/events?venueId=$pgVenueId&status=Completed" $org
Check "Status filter changes the total (no Completed events)" ((Get-Total $e3) -eq 0)
$e4 = Send-Api GET "/api/events?venueId=$pgVenueId&from=$day5&to=$day5" $admin3
Check "Admin sees the same total for a date range" ((Get-Total $e4) -eq 3)
Show "Events with a reversed date range" 400 (Send-Api GET "/api/events?from=$day5&to=2000-01-01" $org)

Write-Host "--- audit log"
$a1 = Send-Api GET "/api/audit-logs?size=2" $admin3
Show "Audit log page" 200 $a1
Check "Audit page has 2 items and a total of at least 2" (((Count-Items $a1 "logId") -eq 2) -and ((Get-Total $a1) -ge 2))
Write-Host "      audit entries in total: $(Get-Total $a1)"

Write-Host "--- cleanup"
foreach ($ev in $pgEvents) { Show "Delete event" 204 (Send-Api DELETE "/api/events/$ev" $org $h) }
foreach ($pp in $pgPeople) { Show "Delete participant" 204 (Send-Api DELETE "/api/participants/$pp" $org $h) }
Show "Delete the test venue" 204 (Send-Api DELETE "/api/venues/$pgVenueId" $org $h)