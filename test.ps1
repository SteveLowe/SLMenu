[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Scope="Function")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingCmdletAliases", "", Scope="Function")]
[CmdletBinding()]
param ()
if ($PSBoundParameters.ContainsKey('Debug') -and $PSBoundParameters['Debug'].ToBool()) { $DebugPreference = [System.Management.Automation.ActionPreference]::Continue }
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module .\SLMenu\SLMenu.psd1 -Force

# run python -m grip to do local test of readme

function Main {
    #Write-Host 'Test Start'

    $MenuItems = @(
      New-SLMenuItem -Key '1' -Name 'Do Something' -Data { }
      New-SLMenuItem -Key '2' -Name 'Start Services' -Data { }
      New-SLMenuItem -Separator
      New-SLMenuItemQuit
    )
    Show-SLMenuExecute -MenuItems $MenuItems -Title 'Test Menu'

    Write-SLLineState
    Write-SLLineText 'Service 1'
    Start-Sleep -Milliseconds 128
    Write-SLLineState -OK -Next

    Write-SLLineState
    Write-SLLineText 'Service 2'
    Start-Sleep -Milliseconds 256
    Write-SLLineState -OK -Next

    Write-SLLineState
    Write-SLLineText 'Service 3'
    Start-Sleep -Seconds 1
    Write-SLLineState -Warn -Next
    Write-Host ' Not enough Foo' -Foregroundcolor 'Yellow'

    Write-SLLineState
    Write-SLLineText 'Service 4'
    Start-Sleep -Milliseconds 512
    Write-SLLineState -Fail -Next
    Write-Host ' Bar not found' -Foregroundcolor 'Yellow'

    Write-Host ''
    Pause

    Clear
    $IncludeTwo = $true

    $MenuItems = New-SLMenuItemList
    $MenuItems.Add( (New-SLMenuItem -Key '1' -Name 'Item 1' -Data 1) )
    if ($IncludeTwo) {
      $MenuItems.Add( (New-SLMenuItem -Key '2' -Name 'Item 2' -Data 2) )
    }
    $MenuItems.Add( (New-SLMenuItem -Separator) )
    $MenuItems.Add( (New-SLMenuItemQuit -Name 'Back') )

    Show-SLMenu -MenuItems $MenuItems -Title 'Test Menu'

    #'End of Test'
}

Main
