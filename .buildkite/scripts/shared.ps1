#!/usr/bin/env powershell

#Requires -Version 5

class HabShared {
  static [String]install_base_habitat_binary([String]$Version, [String]$Channel) {
      if($Version.Equals("latest")) {
          # Get the latest version available from bintray
          $current_protocols = [Net.ServicePointManager]::SecurityProtocol
          $latestVersionURI = ""
          try {
              [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
              $latestVersionURI = (Invoke-WebRequest "https://bintray.com/habitat/$Channel/hab-x86_64-windows/_latestVersion" -UseBasicParsing).BaseResponse.ResponseUri.AbsoluteUri
          }
          finally {
              [Net.ServicePointManager]::SecurityProtocol = $current_protocols
          }
          
          $uriArray = $latestVersionURI.Split("/")
          $targetVersion = $uriArray[$uriArray.Length-1]
          Write-Host "--- Latest version is $targetVersion"
      }
      else {
          $targetVersion = $Version
          Write-Host "--- Targeting version $targetVersion"
      }
      
      $bootstrapDir = "C:\hab-" + "$targetVersion"
      
      $downloadUrl = "https://api.bintray.com/content/habitat/$Channel/windows/x86_64/hab-$targetVersion-x86_64-windows.zip?bt_package=hab-x86_64-windows"
      
      # download a hab binary to build hab from source in a studio
      Write-Host "--- Downloading from $downloadUrl"
      $current_protocols = [Net.ServicePointManager]::SecurityProtocol
      try {
          [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
          Invoke-WebRequest -UseBasicParsing -Uri "$downloadUrl" -OutFile hab.zip
      }
      finally {
          [Net.ServicePointManager]::SecurityProtocol = $current_protocols
      }
      Write-Host "--- Extracting to $bootstrapDir"
      New-Item -ItemType directory -Path $bootstrapDir -Force
      Expand-Archive -Path hab.zip -DestinationPath $bootstrapDir -Force
      Remove-Item hab.zip -Force
      $baseHabExe = (Get-Item "$bootstrapDir\hab-$targetVersion-x86_64-windows\hab.exe").FullName

      return $baseHabExe
  }

  static [void]import_keys([String]$HabExe) {
      # Write-Host "--- :key: Downloading 'core' public keys from Builder"
      # Invoke-Expression "$HabExe origin key download core"
      # # Write-Host "--- :closed_lock_with_key: Downloading latest 'core' secret key from Builder"
      # Invoke-Expression "$HabExe origin key download --auth=$Env:HAB_AUTH_TOKEN --secret core"
      Write-Host "--- Making a fakey fake origin key for now"
      Invoke-Expression "$HabExe origin key generate core"
      $Env:HAB_CACHE_KEY_PATH = "C:\hab\cache\keys"
      $Env:HAB_ORIGIN = "core"
  }
}
