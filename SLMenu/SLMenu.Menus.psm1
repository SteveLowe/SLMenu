Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Show-SLMenuYesNo {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "")]
    param (
        [string]$Title = '',
        [string]$Message = '',
        [switch]$ClearAfter,
        [switch]$DefaultNo
    )
    # $true = Yes
    # $false = No
    $MenuItems = @(
        New-SLMenuItem -Key 'y' -ExtraKeys 'Y' -Name 'Yes' -Data $true
        New-SLMenuItem -Key 'n' -ExtraKeys 'N' -Name 'No' -Data $false
    )

    $MenuArgs = @{
        Title = $Title
        MenuItems = $MenuItems
        Message = $Message
        Inline = $true
        Position = ([int]$DefaultNo.ToBool())
        FlushInput = $true
        ClearAfter = $ClearAfter
    }
    $Response = Show-SLMenu @MenuArgs
    [bool]$Result = $Response.Data

    return $Result
} # End Show-SLMenuYesNo
