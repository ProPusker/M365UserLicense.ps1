
[CmdletBinding(DefaultParameterSetName='AllUsers')]
param(
    [Parameter(ParameterSetName='AllUsers')]
    [switch]$AllUsers,

    [Parameter(ParameterSetName='FileInput')]
    [ValidateScript({Test-Path $_ -PathType Leaf})]
    [string]$InputFile,

    [Parameter(ParameterSetName='ManualInput')]
    [ValidateCount(1, 1000)]
    [string[]]$UserPrincipalName,

    [Parameter(Mandatory=$false)]
    [string]$OutputPath,

    [Parameter(Mandatory=$false)]
    [switch]$IncludeServicePlans,

    [Parameter(Mandatory=$false)]
    [ValidateSet('Interactive', 'DeviceCode', 'ManagedIdentity')]
    [string]$AuthMethod = 'Interactive'
)

begin {
    # Configure TLS security
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # Initialize error handling
    $ErrorActionPreference = 'Stop'
    $script:ErrorMessages = @()

    function Connect-GraphWithAuth {
        param(
            [string]$AuthMethod
        )

        try {
            $requiredScopes = @(
                'User.Read.All',
                'Organization.Read.All'
            )

            switch ($AuthMethod) {
                'ManagedIdentity' {
                    Connect-MgGraph -Identity -NoWelcome
                }
                'DeviceCode' {
                    Connect-MgGraph -UseDeviceCode -Scopes $requiredScopes -NoWelcome
                }
                default {
                    Connect-MgGraph -Scopes $requiredScopes -NoWelcome
                }
            }
        }
        catch {
            Write-Error "Authentication failed: $_"
            exit 1
        }
    }

    function Get-LicenseDetails {
        param(
            [Microsoft.Graph.PowerShell.Models.MicrosoftGraphUser]$User,
            [switch]$IncludeServicePlans
        )

        $licenseInfo = @()
        foreach ($license in $User.AssignedLicenses) {
            $sku = Get-MgSubscribedSku -All | Where-Object { $_.SkuId -eq $license.SkuId }
            
            $licenseData = [ordered]@{
                UserPrincipalName = $User.UserPrincipalName
                SkuId             = $license.SkuId
                SkuPartNumber     = $sku.SkuPartNumber
                DisabledPlans     = $license.DisabledPlans -join ';'
            }

            if ($IncludeServicePlans) {
                $licenseData['ServicePlans'] = ($sku.ServicePlans | 
                    Select-Object ServicePlanId, ServicePlanName | 
                    ConvertTo-Json -Compress)
            }

            $licenseInfo += [PSCustomObject]$licenseData
        }

        if (-not $licenseInfo) {
            $licenseInfo = [PSCustomObject]@{
                UserPrincipalName = $User.UserPrincipalName
                SkuId             = 'None'
                SkuPartNumber     = 'Unlicensed'
                DisabledPlans     = $null
            }
        }

        return $licenseInfo
    }
}

process {
    try {
        # Connect to Microsoft Graph
        Connect-GraphWithAuth -AuthMethod $AuthMethod

        # Get tenant information
        $organization = Get-MgOrganization
        $tenantId = $organization.Id
        Write-Verbose "Connected to tenant: $($organization.DisplayName) ($tenantId)"

        # Process user selection
        $users = switch ($PSCmdlet.ParameterSetName) {
            'AllUsers' {
                Write-Verbose "Retrieving all users..."
                Get-MgUser -All -Property 'UserPrincipalName,AssignedLicenses'
            }
            'FileInput' {
                Write-Verbose "Processing input file: $InputFile"
                $upns = Import-Csv $InputFile | Select-Object -ExpandProperty UserPrincipalName
                Get-MgUser -Filter "userPrincipalName in ('$($upns -join "','")')" -All
            }
            'ManualInput' {
                Write-Verbose "Processing manual input..."
                Get-MgUser -Filter "userPrincipalName in ('$($UserPrincipalName -join "','")')" -All
            }
        }

        # Process licenses
        $results = foreach ($user in $users) {
            Get-LicenseDetails -User $user -IncludeServicePlans:$IncludeServicePlans
        }

        # Handle output
        if ($OutputPath) {
            $extension = [System.IO.Path]::GetExtension($OutputPath).ToLower()
            switch ($extension) {
                '.csv' { $results | Export-Csv -Path $OutputPath -NoTypeInformation }
                '.json' { $results | ConvertTo-Json -Depth 3 | Out-File $OutputPath }
                default { Write-Error "Unsupported file format: $extension" }
            }
            Write-Host "Results exported to: $OutputPath" -ForegroundColor Green
        }
        else {
            return $results
        }
    }
    catch {
        Write-Error "Processing failed: $_"
        $script:ErrorMessages += $_
    }
    finally {
        if ($OutputPath -and (Test-Path $OutputPath)) {
            Write-Verbose "Output file created: $((Get-Item $OutputPath).Length) bytes"
        }
        
        # Cleanup and disconnect
        Disconnect-MgGraph -ErrorAction SilentlyContinue
    }
}

end {
    if ($script:ErrorMessages) {
        Write-Warning "Completed with $($script:ErrorMessages.Count) error(s)"
        $script:ErrorMessages | ForEach-Object { Write-Verbose "Error: $_" -Verbose }
    }
    else {
        Write-Verbose "Completed successfully"
    }
}
