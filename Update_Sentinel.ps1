param(
    [Parameter(Mandatory = $true)]$WorkspaceName,
    [Parameter(Mandatory = $true)]$SubscriptionId,
    [Parameter(Mandatory = $true)]$TeamName,
    [Parameter(Mandatory = $true)]$TenantId,
    [Parameter(Mandatory = $true)]$ClientId,
    [Parameter(Mandatory = $true)]$ClientSecret,
    [Parameter(Mandatory = $true)]$ResourceGroupName
)

Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force -AllowClobber 
Import-Module -Name Az.Resources -Force

#Importing Az.SecurityInsights module.
Install-Module -Name Az.SecurityInsights -RequiredVersion 2.0.0-preview -AllowPrerelease -Force
Import-Module -Name Az.SecurityInsights -Force
Install-Module -Name Az.OperationalInsights -Force
Import-Module -Name Az.OperationalInsights -Force


$SecureStringPwd = $ClientSecret | ConvertTo-SecureString -AsPlainText -Force
$pscredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ClientId, $SecureStringPwd 
Connect-AzAccount -ServicePrincipal -Credential $pscredential -Tenant $TenantId
Set-AzContext -Subscription $SubscriptionId

Write-Host "Logging in and authenticating using Service Principal"

  $context = Get-AzContext
  $userProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
  $profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList ($userProfile)
  $token = $profileClient.AcquireAccessToken($context.Subscription.TenantId)
  $authHeader = @{
    'Content-Type'  = 'application/json' 
    'Authorization' = 'Bearer ' + $token.AccessToken 
  }
    
  $SubscriptionId = (Get-AzContext).Subscription.Id
  $baseUrl = "https://management.azure.com/subscriptions/$($SubscriptionId)/resourceGroups/$($ResourceGroupName)/providers/Microsoft.OperationalInsights/workspaces/$($WorkspaceName)/providers/Microsoft.SecurityInsights/"
  $apiVersion = "?api-version=2024-01-01-preview"

  $installedUrl = $baseUrl + "contentPackages" + $apiVersion + "&%24expand=SolutionV2"
  $installedSolutions = (Invoke-RestMethod -Method "Get" -Uri $installedUrl -Headers $authHeader ).value

  $allSolutionsUrl = $baseUrl + "contentProductPackages" + $apiVersion
  $allSolutions = (Invoke-RestMethod -Method "Get" -Uri $allSolutionsUrl -Headers $authHeader ).value

  $rgUrl = "https://management.azure.com/subscriptions/$($SubscriptionId)/resourcegroups/$($ResourceGroupName)?api-version=2021-04-01"
  $rgData = (Invoke-RestMethod -Method "Get" -Uri $rgUrl -Headers $authHeader )

  $count = 0

  foreach ($solution in $installedSolutions) {
    Write-Host "Updating " + $solution.properties.displayName
    $count = $count + 1
    if ($count -eq 10) {
      break;
    } 

    $foundSolution = $allSolutions | Where-Object { $_.properties.ContentId -eq $solution.properties.id }

    if ($null -ne $foundSolution) {
      $solutionUrl = $baseUrl + "contentProductPackages/" + $foundSolution.name + $apiVersion
      $solutionData = (Invoke-RestMethod -Method "Get" -Uri $solutionUrl -Headers $authHeader )
      $installedVersion = $solution.properties.version
      $newVersion = $foundSolution.properties.version

      if (([Version] $newVersion) -gt ([Version] $installedVersion)) {
        $packagedContent = $solutionData.properties.packagedContent 
        #Some of the post deployment instruction contains invalid characters and since this is not displayed anywhere 
        #get rid of them. 
        foreach ($resource in $packagedContent.resources) { 
          if ($null -ne $resource.properties.mainTemplate.metadata.postDeployment ) {
            $resource.properties.mainTemplate.metadata.postDeployment = $null 
          } 
        }
        $installBody = @{"properties" = @{ 
            "parameters" = @{ 
              "workspace"          = @{"value" = $WorkspaceName } 
              "workspace-location" = @{"value" = $rgData.location } 
            } 
            "template"   = $packagedContent 
            "mode"       = "Incremental" 
          } 
        } 
        $newGuid = (New-Guid).Guid
        $deploymentName = ("PowerShellSolutionUpdater" + $newGuid ) 
        if ($deploymentName.Length -ge 64) { 
          $deploymentName = $deploymentName.Substring(0, 64) 
        } 
        $installURL = "https://management.azure.com/subscriptions/$($SubscriptionId)/resourcegroups/$($ResourceGroupName)/providers/Microsoft.Resources/deployments/" + $deploymentName + "?api-version=2021-04-01" 
        try { 
          Invoke-RestMethod -Uri $installURL -Method Put -Headers $authHeader -Body ($installBody | ConvertTo-Json -EnumsAsStrings -Depth 50 -EscapeHandling EscapeNonAscii) 
        } 
        catch { 
          $errorReturn = $_ 
          Write-Host $errorReturn 
        }
        
      }
    }
    else {
      Write-Host "Unable to find a match for " + $solution.properties.displayName
    }
  }
