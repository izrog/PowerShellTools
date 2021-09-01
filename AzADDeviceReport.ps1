#needs you to be conected to AzureAD
Connect-AzureAD
#get initial list of AZ AD Users
$list = Get-AzureADUser -Filter "AccountEnabled eq true" -All $True 

#CSV File Creation with a timestamp on the name
$timestamp = Get-Date -Format "MMddyyHHmm"
$FileName = "AZDeviceReport-$timestamp.csv"
"UPN,Department,OfficeLocation,Manager"|Out-File $FileName
$devHeaders = @()

#creates a hast table per user that later gets appended to the CSV file
$list |ForEach-Object {
    $oID = $_.ObjectId
    $manager = Get-AzureADUserManager -ObjectId $oID
    $devices = Get-AzureADUserRegisteredDevice -ObjectId $oID #uncomment for only windows devices |?{$_.DeviceOSType -eq "Windows"}
        
    $Values = [ordered]@{
        UPN = $_.UserPrincipalName
        Department = $_.Department
        OfficeLocation = $_.PhysicalDeliveryOfficeName
        Manager = $manager.DisplayName
    }
    #Seperates each device into its own column
    $i=1
    foreach($device in $devices){
        $Values.add("Device$i",$device.DisplayName)
        if (-not ($devHeaders -contains "Device$i")){
            Import-Csv $FileName | Select-Object *,"Device$i" | Export-Csv $FileName -NoTypeInformation
            $devHeaders += "Device$i"
        }else {

        }
        $i++
    }
    [pscustomobject]$Values | Export-Csv $FileName -Append -NoTypeInformation -Force    
}
