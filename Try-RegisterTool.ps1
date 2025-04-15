Import-Module d:\mygit\PSMCP\PSMCP.psm1 -Force

function script:reverse {
    <#
        .SYNOPSIS 
        Reverse the input text.
        .DESCRIPTION
        Reverse the input text.
        .PARAMETER text
        The text to reverse.
    #>
    param(
        [string]$text
    )

    $charArray = $text.ToCharArray()
    [array]::Reverse($charArray)
    return -join $charArray
}

function Invoke-Addition {
    <#
        .SYNOPSIS 
        Add two numbers.
        .DESCRIPTION
        Add two numbers.
        .PARAMETER a
        The first number.
        .PARAMETER b
        The second number.    
    #>

    param(
        [double]$a,
        [double]$b
    )

    return $a + $b
}

Clear-Host
$json = Register-Tool reverse, Invoke-Addition -MCP
$json | clip
$json
# $json | ConvertFrom-Json -Depth 5 -AsHashtable