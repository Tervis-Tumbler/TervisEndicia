﻿#requires -modules TervisPowerShellJobs,EndiciaPowerShell

function Get-TervisEndiciaAccountStatus {
    $EndiciaAccount = Get-PasswordstatePassword -AsCredential -ID 3620
    $RequestID = Get-Random -Minimum 1111111111 -Maximum 9999999999    
    Get-AccountStatus -ResponseVersion 1 -RequesterID lcon -RequestID $RequestID -AccountID $EndiciaAccount.Username -PassPhrase $EndiciaAccount.GetNetworkCredential().password
}

function Reset-TervisEndiciaSuspendedAccount {
    param (
        [Parameter(Mandatory)]$NewPassPhrase
    )

    $RequestID = Get-Random -Minimum 1111111111 -Maximum 9999999999
    
    $EndiciaAccount = Get-PasswordstatePassword -AsCredential -ID 3620
    $EndiciaAccountPassword = $EndiciaAccount.GetNetworkCredential().password
    
    $EndiciaAccountChallengeAnswer = Get-PasswordstatePassword -AsCredential -ID 4088
    $ChallengeAnswer = $EndiciaAccountChallengeAnswer.GetNetworkCredential().password
    Reset-SuspendedAccountRequestXML -RequesterID lcon -RequestID $RequestID -AccountID $EndiciaAccount.UserName -ChallengeAnswer $ChallengeAnswer -NewPassPhrase $NewPassPhrase
}

function New-Settings1xmlFile {
    param (
        [Parameter(Mandatory)]$ComputerName,
        [Parameter(Mandatory)]$UserName
    )
    $EndiciaAccount = Get-PasswordstatePassword -AsCredential -ID 3620
    
    $ElsAccountNumber = $EndiciaAccount.UserName
    $ElsPassPhrase = $EndiciaAccount.GetNetworkCredential().password
    $ElsReturnLabelAccountNumber = $EndiciaAccount.UserName
    $ElsReturnLabelPassPhrase = $EndiciaAccount.GetNetworkCredential().password
    
    Invoke-ProcessTemplateFile -TemplateFile $PSScriptRoot\Settings.xml.pstemplate |
    Out-File "\\$ComputerName\C$\Users\$UserName\AppData\Roaming\Endicia\Professional\Profiles\Profile 001\Settings.xml"

    Invoke-ProcessTemplateFile -TemplateFile $PSScriptRoot\Settings1.xml.pstemplate |
    Out-File "\\$ComputerName\C$\Users\$UserName\AppData\Roaming\Endicia\Professional\Profiles\Profile 001\Settings1.xml"
}

function Copy-EndiciaSettingsXMLToAllUsersOnComputer {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]$ComputerName,
        [Parameter(Mandatory)]$EndiciaSettingsFile
    )

    $UserProfiles = Get-ChildItem -Path \\$ComputerName\C$\Users\ -Exclude Public,Default,Default.migrated

    foreach ($UserProfile in $UserProfiles) {        
        $EndiciaSettingsPath = Join-Path -Path $UserProfile.FullName -ChildPath "AppData\Roaming\Endicia\Professional\Profiles\Profile 001\"
        if (Test-Path -Path $EndiciaSettingsPath) {
            Write-Verbose "Copying settings to $EndiciaSettingsPath"
            Copy-Item -Path $EndiciaSettingsFile -Destination $EndiciaSettingsFile -Force
        }
    }
}

function Copy-EndiciaSettingsXMLToEndiciaEndpoints {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]$EndiciaSettingsFile    
    )

    $EndiciaEndpoints = Get-ADGroupMember -Identity Resource_EndiciaEndpoints
    foreach ($Computer in $EndiciaEndpoints) {
        Write-Verbose "$($Computer.Name)"
        Copy-EndiciaSettingsXMLToAllUsersOnComputer -ComputerName $Computer.Name -EndiciaSettingsFile $EndiciaSettingsFile
    }
}

function Get-TervisComputersWithEndiciaInstalled {
    param (        
        [Parameter(Mandatory)]$OU
    )

    $ComputersInOU = Get-ADComputer `
        -SearchBase $OU `
        -Filter *

    Start-ParallelWork -Parameters $ComputersInOU -ScriptBlock {
        param ($Parameter)        
        $EndiciaInstalled = Test-Path -Path "\\$($Parameter.Name)\c$\Program Files (x86)\Endicia\Professional\Endicia Professional.exe"
        if ($EndiciaInstalled) {
            $Parameter.Name
        }
    }
}

function Update-TervisEndiciaEndpointsSecurityGroup {
    [CmdletBinding()]
    param (        
        [Parameter(Mandatory)]$OU
    )
    
    Write-Verbose "Getting computers with Endicia installed in $OU"
    $EndiciaEndpoints = Get-TervisComputersWithEndiciaInstalled -OU $OU
    foreach ($ComputerName in $EndiciaEndpoints) {
        Write-Verbose "Adding $ComputerName to Resource_EndiciaEndpoints"
        $ComputerObject = Get-ADComputer -Identity $ComputerName
        Add-ADGroupMember -Identity Resource_EndiciaEndpoints -Members $ComputerObject
    }    
}