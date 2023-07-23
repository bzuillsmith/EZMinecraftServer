# EZ Minecraft Server

Powershell scripts to download and install the latest version of the minecraft and start it up.

## How to use
Edit the `run-server.ps1` file and change the first line to the folder where you would like Minecraft to be stored:

    $localMinecraftServerPath` = "C:\My\Path\To\Server\Files";

The script will peform the following steps:

1. Checks if Java is installed. If not, downloads the Java 19 JDK and installs it
2. Checks the Minecraft website to see what the latest version is
3. Checks if you've installed the latest server version. If not, downloads it
4. Checks the eula. If it doesn't exist, does a first run and opens the eula to allow you to accept it
5. Runs the server

> NOTE: Currently it starts a fresh server with each new download. It does not copy the world data from a previous version if you had one. You will need to do this manually.