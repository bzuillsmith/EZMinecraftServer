$localMinecraftServerPath = "E:\Minecraft\Server";

$javaVersionCheckResult = & java --version; # Keep for next command to work
if (-not $?) {
    Write-Host "Java is not installed. Installing jdk from 'https://download.oracle.com/java/19/latest/jdk-19_windows-x64_bin.exe'";
    & Invoke-WebRequest -OutFile "$env:Temp\jdk-19_windows-x64_bin.exe" -Uri https://download.oracle.com/java/19/latest/jdk-19_windows-x64_bin.exe;
    Write-Host "Installing jdk-19_windows-x64_bin.exe..."
    & "$env:Temp\jdk-19_windows-x64_bin.exe" /s # Other possible options: /L=1033 /v"/qn INSTALLDIR=C:\Program Files\Java\jdk-19";
    Write-Host "... complete"
}

Write-Host "Fetching minecraft"
# Some kind of firewall or rate limiter only allows a few requests before blocking requests basic headers. Need these look more legitimate.
$Headers = @{
    "User-Agent"="OSS Setup Script"
    "Accept"="text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8"
    "Accept-Encoding"="gzip, deflate, br"
    "Accept-Language"="en-US,en;q=0.9"
    "Cache-Control"="no-cache"
    "Pragma"="no-cache"
}
$serverDownloadPageContent = Invoke-WebRequest -Headers $Headers -TimeoutSec 10 -Uri https://www.minecraft.net/en-us/download/server
$foundDownload = $serverDownloadPageContent -match '<a href="(.*)".*>minecraft_server\.(\d+\.\d+\.\d+)\.jar'
if ($foundDownload) {
    $minecraftServerDownloadUrl = $matches[1];
    $version = $matches[2];
    Write-Host "Found download link for Minecraft server version $version at $minecraftServerDownloadUrl";
} else {
    Write-Host "Could not find download link on https://www.minecraft.net/en-us/download/server";
    exit 1;
}

$currentVersionPath = "$localMinecraftServerPath\$version";
# Create the directory if it doesn't exist
if (-not (Test-Path $currentVersionPath -PathType Container)) {
    Write-Host "Creating directory $currentVersionPath";
    New-Item -ItemType Directory -Force -Path $currentVersionPath;
}
$serverJarPath = "$currentVersionPath\server.jar";
$serverJarExists = Test-Path $serverJarPath -PathType Leaf;
if (-not $serverJarExists) {
    Write-Host "Downloading Minecraft server version $version from $minecraftServerDownloadUrl...";
    Invoke-WebRequest -OutFile $serverJarPath -Uri $minecraftServerDownloadUrl;
    Write-Host "... complete";
} else {
    Write-Host "Minecraft server version $version already downloaded";
}


Set-Location $currentVersionPath;

$eulaPath = "eula.txt";
$eulaExists = Test-Path $eulaPath -PathType Leaf;
if (-not $eulaExists)
{
    Start-Process "java" -Wait -ArgumentList "-Xmx1024M -Xms1024M -jar server.jar nogui";
    Invoke-Expression ".\eula.txt"
    Read-Host "Opening eula. Change 'false' to 'true' to accept. When finished, press any key to continue..."
} else {
    Write-Host "EULA already created. Ready to start server";
}
Write-Host "Starting Minecraft server version $version at $serverJarPath";
Write-Host "Press Ctrl+C to stop the server";
& java -Xmx1024M -Xms1024M -jar server.jar nogui;