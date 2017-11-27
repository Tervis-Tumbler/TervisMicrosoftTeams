function ScratchFunctionsForMicrosoftTeams {
$ITComputers = get-Tervisadcomputer -Filter * | where distinguishedname -match "OU=Information Technology"


$ADComputer = $SAMAccounts | foreach {Find-TervisADUsersComputer -SAMAccountName $_ | where Enabled -eq $true}
$ADComputerWindow = $ADComputer | Sort Name | select -first 25 -Skip 0

Start-ParallelWork -Parameters $ADComputerWindow.Name -ScriptBlock {
    param($parameter)
    try {
        Install-TervisChocolatey -ComputerName $parameter
        Install-TervisChocolateyPackage -ComputerName $parameter -PackageName microsoft-teams
    } catch {throw "Not installed on $parameter"}
} -MaxConcurrentJobs 25 -Verbose

function Install-TervisChocolateyPackageParallel {
    param (
        [Parameter(Mandatory,ValueFromPipeline)]$ComputerName,
        [Parameter(Mandatory)]$PackageName,
        $Version,
        $PackageParameters,
        $Source,
        [switch]$Force
    )
    begin {
        $ComputerNames = @()
    }
    processs {
        $ComputerNames += $ComputerName
    }
    end {
        Start-ParallelWork -Parameters $ComputerName -OptionalParameters $PSBoundParameters -ScriptBlock {
            param($ComputerName)
            try {
                $Parameters = $PSBoundParameters | ConvertFrom-PSBoundParameters
                Install-TervisChocolatey -ComputerName $ComputerName
                Install-TervisChocolateyPackage -ComputerName $ComputerName -PackageName $Parameters.PackageName -Version $Parameters
            } catch {throw "Not installed on $ComputerName"}
        } -MaxConcurrentJobs 25 -Verbose
    }
}

choco update chocolatey -y

Install-TervisChocolateyPackage -PackageName microsoft-teams -Version 1.0.00.28451
$ITComputers | Install-TervisChocolateyPackage -PackageName microsoft-teams -Version 1.0.00.28451
$ITComputers | Install-TervisChocolatey

}