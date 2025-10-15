Import-Module ActiveDirectory

$Forest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()

$Report = @()
Foreach ($Domain in $Forest.Domains) {
    $Report += Get-ADUser -Filter * -Properties adminCount, ntSecurityDescriptor -server $Domain.PDCRoleOwner.name `
    | Where-Object {
        $_.adminCount -eq 1 -or
        $_.ntSecurityDescriptor.AreAccessRulesProtected -eq $true
    } `
    | Select-Object Name, DistinguishedName, adminCount, Enabled, @{Name = 'IsProtected'; Expression = { $_.ntSecurityDescriptor.AreAccessRulesProtected } }
}
 
$Report | Export-Csv "ProtectedOrAdminCount.csv" -NoTypeInformation -Delimiter ';' -Encoding UTF8BOM