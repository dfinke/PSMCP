<#
.SYNOPSIS
    Retrieves the current weather for a specified location.

.DESCRIPTION
    The Get-CurrentWeather function queries the wttr.in service to retrieve the current weather
    information for a specified location. The result is returned in a concise format.

.PARAMETER location
    The name of the location (city, country, etc.) for which to retrieve weather information.

.PARAMETER unit
    The temperature unit to use in the weather report. Valid values are 'celsius' and 'fahrenheit'.
#>
function Global:Get-CurrentWeather {
    param (
        [Parameter(Mandatory = $true)]
        [string]$location,
        [Parameter(Mandatory = $true)]
        [ValidateSet('celsius', 'fahrenheit')]
        [string]$unit
    )
    
    $paramUnit = "m"
    if ($unit -eq "fahrenheit") {
        $paramUnit = "u"
    }

    Invoke-RestMethod "https://wttr.in/$($location)?format=4&$paramUnit"
}