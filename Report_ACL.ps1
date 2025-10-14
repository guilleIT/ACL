Import-Module ActiveDirectory

Get-ADUser -Filter * -Properties adminCount, ntSecurityDescriptor |
Where-Object {
    $_.adminCount -eq 1 -or
    $_.ntSecurityDescriptor.AreAccessRulesProtected -eq $true
} |
Select-Object Name, DistinguishedName, adminCount,
    @{Name='IsProtected';Expression={$_.ntSecurityDescriptor.AreAccessRulesProtected}} |
Export-Csv "C:\Reports\ProtectedOrAdminCount.csv" -NoTypeInformation