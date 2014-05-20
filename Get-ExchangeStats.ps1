## Get-Exchange-Stats.ps1   ##
## Written By: Andrew Jackson   ##
## Version: .02A                ##
## This script was written to provide metrics

## Variables
# Variables - User Input
$servers = (Get-Content .\servers.txt)
$dblist = (Get-Content .\dblist.txt)

#---DO NOT MODIFY BELOW THIS LINE---#

## Module Import
# Import Format-HumanReadable Module for calculating sizes
Import-Module -Name ".\modules\Format-HumanReadable\Format-HumanReadable.psd1"

## Functions
# Function - Get-DatabaseStatistics for all databases
function Get-DatabaseStatistics {
    $Databases = Get-MailboxDatabase -Status
    foreach($Database in $Databases) {
        $DBSize = $Database.DatabaseSize
        $MBCount = @(Get-MailboxStatistics -Database $Database.Name).Count
        $DBEdb = $Database.EdbFilePath
        $DBLog = $Database.LogFolderPath
        $MBAvg = Get-MailboxStatistics -Database $Database.Name | %{$_.TotalItemSize.value.ToMb()} | Measure-Object -Average
        New-Object PSObject -Property @{
            Server = $Database.Server.Name
            DatabaseName = $Database.Name
            LastFullBackup = $Database.LastFullBackup
            MailboxCount = $MBCount
            "DatabaseSize" = Format-HumanReadable $DBSize.ToKB()
            "AverageMailboxSize (MB)" = [math]::round($MBAvg.Average, 2)
            "WhiteSpace" = Format-HumanReadable $Database.AvailableNewMailboxSpace.ToKB()
            "EdbFilePath" = $DBEdb
            "DBLog" = $DBLog
        }
    }
}

# Function - Get MountPoints via WmiObject
function Get-MountPoints {
    foreach ($server in $servers){
        $volumes = Get-WmiObject -computer $server win32_volume | Where-object {$_.DriveLetter -eq $null}
        foreach ($volume in $volumes){
            $FreePerc = [math]::round((Format-HumanReadable $volume.FreeSpace) / (Format-HumanReadable $volume.Capacity)*100)
            $Alert = if (((Format-HumanReadable $volume.FreeSpace) / (Format-HumanReadable $volume.Capacity)*100) -lt 10) {'Y'} else {'N'}
            New-Object PSObject -Property @{
            Server = $volume.SystemName
            LUN = $volume.Label
            Capacity = Format-HumanReadable $volume.Capacity
            FreeSpace = Format-HumanReadable $volume.FreeSpace
            Free = Echo $FreePerc"%"
            Alert = $Alert
            Path = $volume.Name
            }
        }
    }
}

# Execute Functions
Get-DatabaseStatistics -Filter {Server -eq "USEPX2PMXMBX11"}


Foreach ($server in $servers) {
    $servername = @()
    $servername = $server.ToString().Split(".") | Select -First 1

    Write-Host $servername Database Statistics
    $serverdatabases = Get-DatabaseStatistics | Where {$_.Server -like $servername}

    $dbmounted = Foreach ($db in $serverdatabases) {
        $dbpath = @()
        $dbpath = Split-Path $db.EdbFilePath.ToString() -Parent | Split-Path -Parent
        $dbpath = Write-Output $dbpath\
        $dbmount = Get-MountPoints | Where {$_.Server -eq $servername -and $_.Path -eq $dbpath}

        $dbmount >> $env:TEMP\dbmount.txt
    }

    Write-Host "Database Statistics for Server:"$servername "Database:" $db.DatabaseName
        $db | Select DatabaseName, DatabaseSize, WhiteSpace, MailboxCount, "AverageMailboxSize (MB)", LastFullBackup | FT
    Write-Host "Mount Statistics for Server:"$servername
        $dbmount | Select LUN, FreeSpace, Free, Capacity | FT

    Write-Host $servername Mount Points
    Get-MountPoints | Where {$_.Server -like $servername}
}


Get-MountPoints
