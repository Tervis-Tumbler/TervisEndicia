function Reset-TervisEndiciaSuspendedAccount {
    param (
        [Parameter(Mandatory)]$NewPassPhrase
    )

    $RequestID = Get-Random -Minimum 1111111111 -Maximum 9999999999
    
    $EndiciaAccount = Get-PasswordstateCredential -PasswordID 3620
    $EndiciaAccountPassword = $EndiciaAccount.GetNetworkCredential().password
    
    $EndiciaAccountChallengeAnswer = Get-PasswordstateCredential -PasswordID 4088
    $ChallengeAnswer = $EndiciaAccountChallengeAnswer.GetNetworkCredential().password
    Reset-SuspendedAccountRequestXML -RequesterID lcon -RequestID $RequestID -AccountID $EndiciaAccount.UserName -ChallengeAnswer $ChallengeAnswer -NewPassPhrase $NewPassPhrase
}

function New-Settings1xmlFile {
    param (
        [Parameter(Mandatory)]$ComputerName,
        [Parameter(Mandatory)]$UserName
    )
    $EndiciaAccount = Get-PasswordstateCredential -PasswordID 3620
    
    $ElsAccountNumber = $EndiciaAccount.UserName
    $ElsPassPhrase = $EndiciaAccount.GetNetworkCredential().password
    $ElsReturnLabelAccountNumber = $EndiciaAccount.UserName
    $ElsReturnLabelPassPhrase = $EndiciaAccount.GetNetworkCredential().password
    
    Invoke-ProcessTemplateFile -TemplateFile $PSScriptRoot\Settings.xml.pstemplate |
    Out-File "\\$ComputerName\C$\Users\$UserName\AppData\Roaming\Endicia\Professional\Profiles\Profile 001\Settings.xml"

    Invoke-ProcessTemplateFile -TemplateFile $PSScriptRoot\Settings1.xml.pstemplate |
    Out-File "\\$ComputerName\C$\Users\$UserName\AppData\Roaming\Endicia\Professional\Profiles\Profile 001\Settings1.xml"
}