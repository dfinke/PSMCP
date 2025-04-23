function Global:Invoke-Addition {
    <#
        .SYNOPSIS
        A simple function to add two numbers.
        .PARAMETER Number1
        The first number to add.
        .PARAMETER Number2
        The second number to add.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [double]$Number1,

        [Parameter(Mandatory = $true)]
        [double]$Number2
    )

    return $Number1 + $Number2
}