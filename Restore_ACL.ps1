
$Forest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
$ForestSchemaClasses = $Forest.Schema.FindAllClasses(
    [System.DirectoryServices.ActiveDirectory.SchemaClassType]::Structural
)



$Domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain()
$ActiveDirectorySite = [System.DirectoryServices.ActiveDirectory.ActiveDirectorySite]::GetComputerSite()

$DomainController = $Domain.FindDomainController(
    $ActiveDirectorySite.Name
    , [System.DirectoryServices.ActiveDirectory.LocatorOptions]::WriteableRequired
)

$DomainSearcher = $DomainController.GetDirectorySearcher()
$DomainSearcher.Filter = "(&(objectClass=User)(SamAccountName=test))"
$CurrentUserSearchResult = $DomainSearcher.FindOne()
$CurrentUserDirectoryEntry = $CurrentUserSearchResult.GetDirectoryEntry()

$ForestSchemaUserClass = $ForestSchemaClasses `
| Where-Object { $_.name -eq ($CurrentUserDirectoryEntry.Properties["objectClass"][-1]) }

$DefaultACL = $ForestSchemaUserClass.DefaultObjectSecurityDescriptor

$CurrentUserDirectoryEntry.ObjectSecurity.SetAccessRuleProtection($false, $true)
$AccessRulesToRemove = $CurrentUserDirectoryEntry.ObjectSecurity.GetAccessRules($true, $false, [System.Security.Principal.SecurityIdentifier])
foreach ($AccessRuleToRemove in $AccessRulesToRemove) {
    Try {
        $ReturnValue = $CurrentUserDirectoryEntry.ObjectSecurity.RemoveAccessRule($AccessRuleToRemove)
        If (-not $ReturnValue) {
            $CurrentUserDirectoryEntry.ObjectSecurity.RemoveAccess(
                [System.Security.Principal.IdentityReference]$AccessRuleToRemove.IdentityReference,
                $AccessRuleToRemove.AccessControlType
            )
        }
    }
    Catch {
        Write-Warning -Message ([string]::format("{0}", $GLOBAL:ERROR[0]))
    }
}
foreach ($AccessRuleToAdd in $DefaultACL.Access) {
    $CurrentUserDirectoryEntry.ObjectSecurity.AddAccessRule($AccessRuleToAdd)
}

# $CurrentUserDirectoryEntry.ObjectSecurity.GetAccessRules($true,$false,[System.Security.Principal.NTAccount])

$CurrentUserDirectoryEntry.CommitChanges()
