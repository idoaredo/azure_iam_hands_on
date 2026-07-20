# seed-ad.ps1
#
# Seeds corp.adlab.local with the same fictional company used by the iam_guide simulator,
# so the A1-A14 lab track transfers to this real domain without rewriting the exercises.
#
# What it creates:
#   - The department OU structure, plus a Disabled Accounts OU
#   - A population of users to work with
#   - Baseline groups, including two resource groups that DELIBERATELY hold users directly
#     (that is the AGDLP anti-pattern task A10 asks you to remediate - do not "fix" it here)
#
# What it deliberately does NOT create:
#   - The objects the exercises ask you to create yourself
#
# Fixtures planted on purpose:
#   - mwilson  : locked out          -> task A3 (locked vs disabled)
#   - lthompson: password expired    -> task A4 (password reset)
#
# Run this ON DC01, in an elevated PowerShell, after the forest is promoted.
# Safe to re-run: every object is created only if it does not already exist.

#Requires -Modules ActiveDirectory

[CmdletBinding()]
param(
    [string]$DomainDN = "DC=corp,DC=adlab,DC=local",
    [string]$Password = "LabP@ssw0rd!2026"
)

$ErrorActionPreference = "Stop"
Import-Module ActiveDirectory

$securePwd = ConvertTo-SecureString $Password -AsPlainText -Force
$created = @{ OU = 0; User = 0; Group = 0 }

function New-LabOU {
    param([string]$Name, [string]$Path, [string]$Description)
    $dn = "OU=$Name,$Path"
    if (Get-ADOrganizationalUnit -Filter "Name -eq '$Name'" -SearchBase $Path -SearchScope OneLevel -ErrorAction SilentlyContinue) {
        Write-Host "  OU exists : $Name" -ForegroundColor DarkGray
        return $dn
    }
    # ProtectedFromAccidentalDeletion defaults to $true - that is the real cmdlet behaviour
    # and task A7 asks you to discover it.
    New-ADOrganizationalUnit -Name $Name -Path $Path -Description $Description | Out-Null
    Write-Host "  OU created: $Name" -ForegroundColor Green
    $script:created.OU++
    return $dn
}

function New-LabUser {
    param(
        [string]$First, [string]$Last, [string]$Sam, [string]$Title,
        [string]$Department, [string]$OUPath
    )
    if (Get-ADUser -Filter "SamAccountName -eq '$Sam'" -ErrorAction SilentlyContinue) {
        Write-Host "  User exists : $Sam" -ForegroundColor DarkGray
        return
    }
    $display = "$First $Last"
    New-ADUser -Name $display -GivenName $First -Surname $Last -DisplayName $display `
        -SamAccountName $Sam -UserPrincipalName "$Sam@corp.adlab.local" `
        -Title $Title -Department $Department -Path $OUPath `
        -AccountPassword $securePwd -Enabled $true | Out-Null
    Write-Host "  User created: $Sam ($Title)" -ForegroundColor Green
    $script:created.User++
}

function New-LabGroup {
    param([string]$Name, [string]$Scope, [string]$Category, [string]$OUPath, [string]$Description)
    if (Get-ADGroup -Filter "Name -eq '$Name'" -ErrorAction SilentlyContinue) {
        Write-Host "  Group exists : $Name" -ForegroundColor DarkGray
        return
    }
    New-ADGroup -Name $Name -GroupScope $Scope -GroupCategory $Category `
        -Path $OUPath -Description $Description | Out-Null
    Write-Host "  Group created: $Name ($Scope $Category)" -ForegroundColor Green
    $script:created.Group++
}

function Add-LabMember {
    param([string]$Group, [string[]]$Members)
    foreach ($m in $Members) {
        try {
            Add-ADGroupMember -Identity $Group -Members $m -ErrorAction Stop
        } catch {
            if ($_.Exception.Message -notmatch "already a member") { throw }
        }
    }
}

Write-Host ""
Write-Host "Seeding corp.adlab.local" -ForegroundColor Cyan
Write-Host "========================" -ForegroundColor Cyan

# ---------------------------------------------------------------- OUs
Write-Host ""
Write-Host "Organizational Units" -ForegroundColor Yellow

$ouIT       = New-LabOU -Name "Information Technology" -Path $DomainDN -Description "IT Department"
$ouHR       = New-LabOU -Name "Human Resources"        -Path $DomainDN -Description "HR Department"
$ouFinance  = New-LabOU -Name "Finance"                -Path $DomainDN -Description "Finance Department"
$ouSales    = New-LabOU -Name "Sales"                  -Path $DomainDN -Description "Sales Department"
$ouContract = New-LabOU -Name "Contractors"            -Path $DomainDN -Description "External contractors"
$ouDisabled = New-LabOU -Name "Disabled Accounts"      -Path $DomainDN -Description "Disabled user accounts"

# Nested OUs - these are what prove a DN carries the full chain, not just one level
New-LabOU -Name "Servers"      -Path $ouIT -Description "Server accounts"      | Out-Null
New-LabOU -Name "Workstations" -Path $ouIT -Description "Workstation accounts" | Out-Null

# ---------------------------------------------------------------- Users
Write-Host ""
Write-Host "Users" -ForegroundColor Yellow

New-LabUser -First "John"  -Last "Smith"    -Sam "jsmith"    -Title "IT Manager"            -Department "Information Technology" -OUPath $ouIT
New-LabUser -First "David" -Last "Brown"    -Sam "dbrown"    -Title "Systems Administrator" -Department "Information Technology" -OUPath $ouIT
New-LabUser -First "Mike"  -Last "Wilson"   -Sam "mwilson"   -Title "Help Desk Technician"  -Department "Information Technology" -OUPath $ouIT
New-LabUser -First "Sarah" -Last "Johnson"  -Sam "sjohnson"  -Title "HR Director"           -Department "Human Resources"        -OUPath $ouHR
New-LabUser -First "Lisa"  -Last "Thompson" -Sam "lthompson" -Title "Recruiter"             -Department "Human Resources"        -OUPath $ouHR
New-LabUser -First "Maria" -Last "Costa"    -Sam "mcosta"    -Title "Finance Manager"       -Department "Finance"                -OUPath $ouFinance
New-LabUser -First "Tina"  -Last "Taylor"   -Sam "ttaylor"   -Title "Senior Accountant"     -Department "Finance"                -OUPath $ouFinance
New-LabUser -First "Nancy" -Last "Miller"   -Sam "nmiller"   -Title "Accounts Payable"      -Department "Finance"                -OUPath $ouFinance
New-LabUser -First "Brian" -Last "Moore"    -Sam "bmoore"    -Title "Financial Analyst"     -Department "Finance"                -OUPath $ouFinance
New-LabUser -First "Paul"  -Last "Reed"     -Sam "preed"     -Title "Sales Representative"  -Department "Sales"                  -OUPath $ouSales

# A contractor placed in Contractors while working for Finance. This is the object that
# proves a DN follows the OU, not the department - the point of task A2.
New-LabUser -First "Diego" -Last "Perez"    -Sam "dperez"    -Title "Contractor"            -Department "Finance"                -OUPath $ouContract

# ---------------------------------------------------------------- Groups
Write-Host ""
Write-Host "Groups" -ForegroundColor Yellow

# Global groups hold the people
New-LabGroup -Name "IT Administrators" -Scope Global -Category Security -OUPath $ouIT      -Description "IT staff with admin duties"
New-LabGroup -Name "HR Team"           -Scope Global -Category Security -OUPath $ouHR      -Description "HR department members"
New-LabGroup -Name "Finance Team"      -Scope Global -Category Security -OUPath $ouFinance -Description "Finance department members"
New-LabGroup -Name "IT Support"        -Scope Global -Category Security -OUPath $ouIT      -Description "Help desk - target of the A13 delegation"

# Domain Local groups represent access to a resource
New-LabGroup -Name "FS-Finance-ReadWrite" -Scope DomainLocal -Category Security -OUPath $ouFinance -Description "Read/Write on the Finance file share"
New-LabGroup -Name "FS-Finance-ReadOnly"  -Scope DomainLocal -Category Security -OUPath $ouFinance -Description "Read-Only on the Finance file share"

# A distribution group, so A11 has something to compare against
New-LabGroup -Name "All Staff" -Scope Global -Category Distribution -OUPath $DomainDN -Description "All staff distribution list"

Write-Host ""
Write-Host "Memberships" -ForegroundColor Yellow

Add-LabMember -Group "IT Administrators" -Members @("jsmith","dbrown")
Add-LabMember -Group "IT Support"        -Members @("mwilson")
Add-LabMember -Group "HR Team"           -Members @("sjohnson","lthompson")
Add-LabMember -Group "Finance Team"      -Members @("mcosta","ttaylor","nmiller","bmoore")
Add-LabMember -Group "All Staff"         -Members @("jsmith","sjohnson","mcosta","preed")

# ---------------------------------------------------------------------------
# DELIBERATE ANTI-PATTERN - do not "correct" this here.
#
# The resource groups below hold USERS DIRECTLY instead of holding the Finance Team
# global group. That means access is granted per person, so every joiner and leaver has
# to be edited in every resource group instead of once in the department group.
#
# Task A10 asks you to remediate it into a real AGDLP chain:
#   user -> Global group -> Domain Local group -> Permission on the resource
# Leaving the mess here is what makes that exercise real.
# ---------------------------------------------------------------------------
Add-LabMember -Group "FS-Finance-ReadWrite" -Members @("mcosta","ttaylor","bmoore")
Add-LabMember -Group "FS-Finance-ReadOnly"  -Members @("nmiller")

# ---------------------------------------------------------------- Fixtures
Write-Host ""
Write-Host "Exercise fixtures" -ForegroundColor Yellow

# A4: force lthompson to change the password at next logon (pwdLastSet = 0).
# Get-ADUser will then report PasswordExpired : True - that is the expected result.
Set-ADUser -Identity "lthompson" -ChangePasswordAtLogon $true
Write-Host "  lthompson: must change password at next logon (task A4)" -ForegroundColor Green

# A3: lock mwilson out by exceeding the bad password threshold.
# This only works if an account lockout policy is in effect. If the default domain policy
# has no lockout threshold, the account will not lock - set one first, which is itself
# worth doing and seeing.
$lockoutThreshold = (Get-ADDefaultDomainPasswordPolicy).LockoutThreshold
if ($lockoutThreshold -eq 0) {
    Write-Host "  WARNING: lockout threshold is 0, so no account can lock out." -ForegroundColor Yellow
    Write-Host "           mwilson was NOT locked. Set a threshold in the Default Domain Policy" -ForegroundColor Yellow
    Write-Host "           (Computer Config > Policies > Windows Settings > Security Settings >" -ForegroundColor Yellow
    Write-Host "           Account Policies > Account Lockout Policy), then re-run this script." -ForegroundColor Yellow
} else {
    $wrong = ConvertTo-SecureString "definitely-not-the-password" -AsPlainText -Force
    $cred  = New-Object System.Management.Automation.PSCredential("CORP\mwilson", $wrong)
    for ($i = 0; $i -le $lockoutThreshold; $i++) {
        try { Start-Process cmd.exe -Credential $cred -ArgumentList "/c exit" -ErrorAction SilentlyContinue } catch { }
    }
    Start-Sleep -Seconds 2
    $locked = (Get-ADUser -Identity "mwilson" -Properties LockedOut).LockedOut
    if ($locked) {
        Write-Host "  mwilson: locked out (task A3)" -ForegroundColor Green
    } else {
        Write-Host "  mwilson: could not be locked automatically - lock it manually for task A3" -ForegroundColor Yellow
    }
}

# ---------------------------------------------------------------- Summary
Write-Host ""
Write-Host "Done." -ForegroundColor Cyan
Write-Host ("  OUs created   : {0}" -f $created.OU)
Write-Host ("  Users created : {0}" -f $created.User)
Write-Host ("  Groups created: {0}" -f $created.Group)
Write-Host ""
Write-Host "Verify with:" -ForegroundColor Cyan
Write-Host '  Get-ADUser -Filter * -SearchBase "OU=Finance,DC=corp,DC=adlab,DC=local" | Select Name,SamAccountName'
Write-Host '  Get-ADGroupMember -Identity "FS-Finance-ReadWrite"'
Write-Host '  Search-ADAccount -LockedOut'
Write-Host ""
Write-Host "Note: the FS-Finance-* groups hold users directly on purpose." -ForegroundColor Yellow
Write-Host "That is the AGDLP anti-pattern task A10 asks you to remediate." -ForegroundColor Yellow
Write-Host ""
