```markdown
# Microsoft 365 License Export Tool

![PowerShell](https://img.shields.io/badge/PowerShell-7+-blue.svg)
![Microsoft Graph](https://img.shields.io/badge/Microsoft%20Graph-API-0078D4.svg)

A modern PowerShell script to export Microsoft 365 user license assignments using Microsoft Graph API with enhanced security and enterprise-grade features.

## Features

- ✅ **Modern Authentication** (Interactive, Device Code, Managed Identity)
- 📊 **Multiple Output Formats** (CSV/JSON)
- 🔍 **Detailed License Breakdown** (Including service plans)
- 🚀 **Enterprise Scalability** (Handles 100k+ users)
- 🔒 **Zero Password Storage** (Modern auth flows)
- 📁 **Batch Processing** (From CSV files)
- 📈 **Usage Analytics Ready** (Structured JSON output)

## Table of Contents
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Authentication](#authentication)
- [Usage](#usage)
- [Parameters](#parameters)
- [Output](#output)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)
- [License](#license)

---

## Prerequisites

1. **PowerShell 7+** ([Download](https://aka.ms/install-powershell))
2. **Microsoft Graph Modules**:
   ```powershell
   Install-Module Microsoft.Graph.Authentication, Microsoft.Graph.Users -Scope CurrentUser
   ```
3. **Azure AD Permissions**:
   - User.Read.All
   - Organization.Read.All

---

## Installation

1. **Clone Repository**:
   ```bash
   git clone https://github.com/yourrepo/m365-license-export.git
   cd m365-license-export
   ```

2. **Or Download Script**:
   ```powershell
   iwr -Uri https://raw.githubusercontent.com/yourrepo/m365-license-export/main/Get-M365Licenses.ps1 -OutFile Get-M365Licenses.ps1
   ```

---

## Authentication Methods

| Method | Best For | Required Setup |
|--------|----------|----------------|
| **Interactive** | Manual runs | None |
| **Device Code** | Headless environments | None |
| **Managed Identity** | Azure automation | [Enable System Identity](https://learn.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/qs-configure-portal-windows-vm) |

---

## Usage

### Basic Examples

**1. Export All Users (CSV):**
```powershell
.\Get-M365Licenses.ps1 -AllUsers -OutputPath All_Licenses.csv
```

**2. Export Specific Users (JSON):**
```powershell
.\Get-M365Licenses.ps1 -UserPrincipalName "user1@contoso.com","user2@contoso.com" -OutputPath licenses.json
```

**3. Process from CSV File:**
```powershell
.\Get-M365Licenses.ps1 -InputFile .\users.csv -OutputPath output.csv -IncludeServicePlans
```

**4. Automation with Managed Identity:**
```powershell
.\Get-M365Licenses.ps1 -AllUsers -AuthMethod ManagedIdentity -OutputPath /reports/licenses_$(Get-Date -Format yyyyMMdd).csv
```

---

## Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `-AllUsers` | Process all tenant users | `-AllUsers` |
| `-InputFile` | CSV file with UPNs | `-InputFile .\users.csv` |
| `-OutputPath` | Output file path | `-OutputPath "C:\reports\licenses.json"` |
| `-IncludeServicePlans` | Add service plan details | `-IncludeServicePlans` |
| `-AuthMethod` | Authentication method | `-AuthMethod DeviceCode` |

---

## Output

**CSV Format:**
```csv
UserPrincipalName,SkuId,SkuPartNumber,DisabledPlans,ServicePlans
user@contoso.com,6fd2c87f-b296-42f0-b197-1e91e994b900,ENTERPRISEPACK,"","[{'ServicePlanId':'bea4c11e-220a-4e6d-8eb8-8ea15d019f90','ServicePlanName':'RMS_S_ENTERPRISE'}]"
```

**JSON Format:**
```json
[
  {
    "UserPrincipalName": "user@contoso.com",
    "SkuId": "6fd2c87f-b296-42f0-b197-1e91e994b900",
    "SkuPartNumber": "ENTERPRISEPACK",
    "ServicePlans": [
      {
        "ServicePlanId": "bea4c11e-220a-4e6d-8eb8-8ea15d019f90",
        "ServicePlanName": "RMS_S_ENTERPRISE"
      }
    ]
  }
]
```

---

## Troubleshooting

**Common Issues:**

1. **Authentication Errors**:
   - Ensure correct Azure AD permissions
   - For Managed Identity: Verify system identity is enabled

2. **"User Not Found" Errors**:
   - Check UPN spelling in CSV/input
   - Verify user exists in Azure AD

3. **Permission Denied**:
   ```powershell
   Connect-MgGraph -Scopes "User.Read.All Organization.Read.All" -Force
   ```

4. **Large Tenant Timeouts**:
   ```powershell
   $ProgressPreference = 'SilentlyContinue'
   ```

---

## FAQ

**Q: How is this different from MSOL-based scripts?**<br>
A: Uses modern Microsoft Graph API with better security and future-proofing.

**Q: Can I automate this in Azure?**<br>
A: Yes! Use Managed Identity authentication in Azure Automation.

**Q: Is my credential data safe?**<br>
A: No credentials are stored - uses OAuth token caching.

**Q: Does it work with 100k+ user tenants?**<br>
A: Yes, implements Graph pagination and batch processing.

---

**Acknowledgments**  
Microsoft Graph Documentation Team  
Azure Identity Client Library Maintainers
``` 
