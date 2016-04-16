#requires -Modules Pester
$ErrorActionPreference = 'Stop'
try {
    Set-Location -Path $env:APPVEYOR_BUILD_FOLDER

    $timestamp = Get-Date -uformat "%Y%m%d-%H%M%S"
    $resultsFile = "Results_${timestamp}.xml"

    Import-Module -Name Pester -Force
    Import-Module -Name PSScriptAnalyzer -Force

    $TestResults = Invoke-Pester -Path '.\Tests' -OutputFormat NUnitXml -OutputFile ".\$resultsFile" -PassThru

    (New-Object -TypeName System.Net.WebClient).UploadFile("https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)", (Resolve-Path -Path ".\$resultsFile"))

    if ($TestResults.FailedCount -gt 0) {
        throw "Build failed."
    }
}
catch {
    throw $_
}
