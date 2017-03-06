function Reset-TervisEndiciaSuspendedAccount {
    param (
        [Parameter(Mandatory)]$NewPassPhrase
    )

    $RequestID = Get-Random -Minimum 1111111111 -Maximum 9999999999
    
    $EndiciaAccount = Get-PasswordstateCredential -PasswordID 3620
    $EndiciaAccountPassword = $EndiciaAccount.GetNetworkCredential().password
    
    $EndiciaAccountChallengeAnswer = Get-PasswordstateCredential -PasswordID 4088
    $ChallengeAnswer = $EndiciaAccountChallengeAnswer.GetNetworkCredential().password

    $Response = Reset-SuspendedAccountRequestXML -RequesterID lcon -RequestID $RequestID -AccountID $EndiciaAccount.UserName -ChallengeAnswer $ChallengeAnswer -NewPassPhrase $NewPassPhrase
    $SuspendedAccountRequestXML = [xml]$Response.Content
    $SuspendedAccountRequestXML.Envelope.Body.ResetSuspendedAccountResponse.ResetSuspendedAccountRequestResponse
}
