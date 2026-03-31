function Global:Invoke-StreamTest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Action
    )

    switch ($Action) {
        'warning' { Write-Warning "Test warning message"; "output after warning" }
        'error'   { Write-Error "Test error message" }
        'verbose' { Write-Verbose "Test verbose message" -Verbose; "output after verbose" }
        'debug'   { Write-Debug "Test debug message" -Debug; "output after debug" }
        'info'    { Write-Information "Test information message" -InformationAction Continue; "output after info" }
        'throw'   { throw "Test terminating error" }
        'normal'  { "Normal output" }
    }
}
