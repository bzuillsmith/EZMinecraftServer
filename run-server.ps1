# Store the original path
$originalPath = Get-Location

$defaultPath = Join-Path -Path $env:LOCALAPPDATA -ChildPath "Minecraft\Server" # Define the default path using AppData\Local
$localMinecraftServerPath = Read-Host -Prompt "Enter the path where the Minecraft server files will be stored (Default: $defaultPath)"
if ([String]::IsNullOrEmpty($localMinecraftServerPath)) {
    $localMinecraftServerPath = $defaultPath
}

# Check if Java is installed
try {
    & java --version; # Check if Java is installed
    $javaInstalled = $true
    Write-Host "Java is already installed."
} catch {
    $javaInstalled = $false
}

if (-not $javaInstalled) {
    $installJavaChoice = Read-Host "Java is not installed. Do you want to install it now? (Y/N)"
    if ($installJavaChoice -eq 'Y' -or $installJavaChoice -eq 'y') {
        Write-Host "Installing JDK from 'https://download.oracle.com/java/21/latest/jdk-21_windows-x64_bin.exe'..."
        & Invoke-WebRequest -OutFile "$env:Temp\jdk-21_windows-x64_bin.exe" -Uri https://download.oracle.com/java/21/latest/jdk-21_windows-x64_bin.exe
        Write-Host "Running JDK installer..."
        & "$env:Temp\jdk-21_windows-x64_bin.exe" /s # Other possible options: /L=1033 /v"/qn INSTALLDIR=C:\Program Files\Java\jdk-21"
        Write-Host "Java has been installed. Please restart this PowerShell session and re-run the script to continue."
        # Change the current location back to the original path
        Set-Location $originalPath
        exit
    } else {
        Write-Host "Java installation is required to run the Minecraft server. Exiting the script."
        # Change the current location back to the original path
        Set-Location $originalPath
        exit
    }
}

Write-Host "Fetching minecraft"
# Some kind of firewall or rate limiter only allows a few requests before blocking requests basic headers. Need these look more legitimate.
$Headers = @{
    "User-Agent"="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36"
    "Accept"="text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7"
    "Accept-Encoding"="gzip, deflate, br"
    "Accept-Language"="en-US,en;q=0.9,fr;q=0.8"
    "Referer" = "https://www.minecraft.net/"
    "Cache-Control"="no-cache"
    "Pragma"="no-cache"
}
try {
    $serverDownloadPageContent = Invoke-WebRequest -Headers $Headers -TimeoutSec 10 -Uri https://www.minecraft.net/en-us/download/server
    $foundDownload = $serverDownloadPageContent -match '<a href="(.*jar)".*>minecraft_server\.(\d+\.\d+\.\d+)\.jar'
    if ($foundDownload) {
        $minecraftServerDownloadUrl = $matches[1];
        $version = $matches[2];
        Write-Host "Found download link for Minecraft server version $version at $minecraftServerDownloadUrl";
    } else {
        Write-Host "Could not find download link on https://www.minecraft.net/en-us/download/server";
        exit 1;
    }
} catch {
    Write-Host "Failed to fetch Minecraft server download page";
    # Change the current location back to the original path
    Set-Location $originalPath
    exit 1;
}

try {
    $currentVersionPath = "$localMinecraftServerPath\$version"; # Define the path for the current version of the Minecraft server
    # Create the directory if it doesn't exist
    if (-not (Test-Path $currentVersionPath -PathType Container)) {
        Write-Host "Creating directory $currentVersionPath";
        New-Item -ItemType Directory -Force -Path $currentVersionPath;
    }
} catch {
    Write-Host "Failed to create directory $currentVersionPath";
    # Change the current location back to the original path
    Set-Location $originalPath
    exit 1;
}

try {
    $serverJarPath = "$currentVersionPath\server.jar"; # Define the path for the server.jar file
    $serverJarExists = Test-Path $serverJarPath -PathType Leaf;
    if (-not $serverJarExists) {
        Write-Host "Downloading Minecraft server version $version from $minecraftServerDownloadUrl...";
        Invoke-WebRequest -OutFile $serverJarPath -Uri $minecraftServerDownloadUrl;
        Write-Host "... complete";
    } else {
        Write-Host "Minecraft server version $version already downloaded";
    }
} catch {
    Write-Host "Failed to download Minecraft server version $version from $minecraftServerDownloadUrl";
    # Change the current location back to the original path
    Set-Location $originalPath
    exit 1;
}

Set-Location $currentVersionPath; # Change the current location to the path of the current version

try {
    $eulaPath = "eula.txt"; # Define the path for the EULA file
    $eulaExists = Test-Path $eulaPath -PathType Leaf;
    if (-not $eulaExists)
    {
        Start-Process "java" -Wait -ArgumentList "-Xmx1024M -Xms1024M -jar server.jar nogui"; # Start the server to generate the EULA file
        Start-Process "notepad" $eulaPath
    Read-Host "Please change 'false' to 'true' in the eula.txt file to accept. When finished, press any key to continue..." # Prompt the user to accept the EULA
    } else {
        Write-Host "EULA already created. Ready to start server"; # If the EULA file already exists, the server is ready to start
    }
} catch {
    Write-Host "Failed to create EULA file";
    # Change the current location back to the original path
    Set-Location $originalPath
    exit 1;
}

try {
    Write-Host "Starting Minecraft server version $version at $serverJarPath"; # Start the server
    Write-Host "Press Ctrl+C to stop the server"; # Inform the user how to stop the server
    & java -Xmx1024M -Xms1024M -jar server.jar nogui; # Run the server
} catch {
    Write-Host "Failed to start Minecraft server version $version at $serverJarPath";
    # Change the current location back to the original path
    Set-Location $originalPath
    exit 1;
}

