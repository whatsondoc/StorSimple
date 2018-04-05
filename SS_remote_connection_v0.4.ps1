#REQUIRES -RunAsAdministrator

<# PREAMBLE:

This script will help you connect to a Microsoft Azure StorSimple device using remote PowerShell, with user prompts.

For a HTTPS connection, there is some work required in advance of running this script. This artcile has more details:
https://azure.microsoft.com/en-us/documentation/articles/storsimple-remote-connect/#prepare-the-host-for-remote-management

We haven't opted to use the hosts' file and device Serial Number for a connection identity, rather the user is prompted for a device password.

Author: Ben H. Watson
Date: March 2016

Twitter: @WhatsOnStorage
Blog: https://whatsonstorage.azurewebsites.net

#>


####################
# Global Variables # }> You should not typically need to change these variables 
####################
$configName = "SSAdminConsole"
$username = "ssadmin"


#############
# Functions #
#############

function set-protocol {

$needsChecking = $true
do { 
    $selection = read-host "`n`nWhich protocol shall we use to connect to our StorSimple device? 

Please choose from either http or https"

if ($selection -eq "http") { $needsChecking = $false }
if ($selection -eq "https") { $needsChecking = $false }

} while ($needsChecking -eq $true)


if ($selection -eq "http") { write-host "`nWe'll be connecting over HTTP - this is insecure"; connect-sshttp } 
if ($selection -eq "https") { write-host "`nWe'll be connecting over HTTPS - this is secure"; connect-sshttps }

}

#
#
#

function connect-sshttp {
# Confirming the device IP address we'll be connecting to:
$deviceIP = read-host "`nPlease enter the device's IP address that you're looking to connect to: "

# Adding the host (^^ device IP, as stated above ^^) to the local machnine's TrustedHosts file (unless it already exists there, in which case we skip):
$isTrustThere = get-item WSMan:\localhost\Client\TrustedHosts
if ( $isTrustThere.Value -match "$deviceIP" -or "*" ) { echo "" } 
else { set-item WSMan:\localhost\Client\TrustedHosts "$deviceIP" -Concatenate -Force -ErrorAction SilentlyContinue }


# Specifying the device password as a secure string:
$password = read-host "`nPlease enter your device administrator password: " -AsSecureString


write-host "`nConnecting to $deviceIP...`n"

# Creating a credentials variable using the standard username ($username) password secure string ($password):
$deviceCreds = new-object -TypeName System.Management.Automation.PSCredential -ArgumentList $username, $password

# Emptying the password variable:
$password = @(); foreach ($num in 1..1000) { $password += $num }; $password = $null

# Establishing the remote PowerShell connection using the details supplied:
Enter-PSSession -ComputerName $deviceIP -Credential $deviceCreds -ConfigurationName $configName -ErrorVariable conErr -ErrorAction SilentlyContinue

# Emptying the credentials variable:
$deviceCreds = @(); foreach ($num in 1..1000) { $deviceCreds += $num }; $deviceCreds = $null

# Only displayed if we error out on the connection attempt:
if ($conErr) 
{ Write-Host "`nWe could not establish a connection to $deviceIP - please check https://azure.microsoft.com/en-us/documentation/articles/storsimple-remote-connect/ for more details.

The following is the error returned: `n`n$conErr" 

read-host "`n`nBEING HELD AT A RED SIGNAL:  Press enter to close" }

}

#
#
#

function connect-sshttps {
# Ensuring the admin has installed the certificate:
Write-Verbose "As we're using HTTPS, we need the device certificate on this machine."

do {
$confirmation = Read-Host "Have you downloaded the certificate from the Azure portal & installed it on this machine? Yes/No"
if ($confirmation -eq "No") { write-host "`nThe script is now terminating - please install the certificate before rerunning."; exit }
}
while (!($confirmation -eq "Yes"))

# Confirming the device IP address we'll be connecting to:
$deviceIP = read-host "`nPlease enter the device's IP address that you're looking to connect to: "

# Adding the host (^^ device IP, as stated above ^^) to the local machnine's TrustedHosts file (unless it already exists there, in which case we skip):
$isTrustThere = get-item WSMan:\localhost\Client\TrustedHosts
if ( $isTrustThere.Value -notmatch "$deviceIP" -or "*" ) { echo "" } 
else { set-item WSMan:\localhost\Client\TrustedHosts "$deviceIP" -Concatenate -Force }

# Specifying the device password as a secure string:
$password = read-host "`nPlease enter your device administrator password: " -AsSecureString


write-host "`nConnecting to $deviceIP...`n"

# Creating a credentials variable using the standard username ($username) password secure string ($password):
$deviceCreds = new-object -TypeName System.Management.Automation.PSCredential -ArgumentList $username, $password

# Emptying the password variable:
$password = @(); foreach ($num in 1..1000) { $password += $num }; $password = $null

# Requesting the device Serial Number:
# $deviceSN = read-host "`nPlease enter (or paste) the device Serial Number: "

# Establishing the secure remote PowerShell connection using the details supplied:
Enter-PSSession -ComputerName $deviceIP -UseSSL -Credential $deviceCreds -ConfigurationName $configName -ErrorVariable conErr -ErrorAction SilentlyContinue

# Emptying the credentials variable:
$deviceCreds = @(); foreach ($num in 1..1000) { $deviceCreds += $num }; $deviceCreds = $null

# Only displayed if we error out on the connection attempt:
if ($conErr) 
{ Write-host "`nWe could not establish a connection to $deviceIP - please check https://azure.microsoft.com/en-us/documentation/articles/storsimple-remote-connect/ for more details.

The following is the error returned: `n`n$conErr" 

read-host "`n`nBEING HELD AT A RED SIGNAL:  Press enter to close" }
}

##############
# Script Run #
##############

set-protocol