function Global:Invoke-Greet {
    <#
        .SYNOPSIS
        A simple function to greet a user.
        .PARAMETER Name
        The name of the user to greet.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    "Hello, $Name!"
}