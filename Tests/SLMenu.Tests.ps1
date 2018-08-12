param()
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

[string[]]$PSFileExtensions = '.ps1', '.psm1'

[string[]]$ExcludedRules = @(
    'PSUseBOMForUnicodeEncodedFile' # this makes no sense for utf-8 files (which SHOULD NOT have the BOM)
    'PSShouldProcess'
)

Describe 'SLMenu Script Analyzer' {
    foreach ($File in @(Get-ChildItem -Path "$here\..\SLMenu" -File -Recurse)) {
        if ($File.Extension -iin $PSFileExtensions) {
            $Name = $File.Name
            Context "File '$Name'" {
                [string[]]$FailedRules = Invoke-ScriptAnalyzer -Path $File.FullName -ExcludeRule $ExcludedRules |
                    ForEach-Object {
                        "$Name`: line $($_.Line) col $($_.Column)`r`n $($_.RuleName):$($_.Message)"
                    }
                It "Should pass all script analyzer rules" {
                    $FailedRules | Should -BeNullOrEmpty
                }
            }
        }
    }
}
