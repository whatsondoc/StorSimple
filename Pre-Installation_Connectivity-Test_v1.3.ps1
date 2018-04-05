##################################################
#                                                #
#{ CONNECTIVITY TEST FOR STORSIMPLE DEPLOYMENTS }#
#                                                #
##################################################
#
## Author: Ben H. Watson
## Twitter: @WhatsOnStorage
## Blog: http://whatsonstorage.azurewebsites.net
## Date: November 2015
#
#
# A quick 'n' dirty script which is intended to be run on a Windows machine (supporting PowerShell) that sits in the relevant network segment
# where StorSimple's Cloud-enabled ports will reside. 
#
# It'd be most applicable if run on a laptop, connected using an RJ45 cable to the switch port that StorSimple's Data0 interface is due to be 
# plugged into, and using the IP address, subnet mask & default gateway allocated for StorSimple.
#
# The subnet mask and default gateway are not values that we set of specify in the script, rather they should be set accordingly on your Windows machine.
#
# REQUIREMENTS:
#
# Must be run on a Windows 8, 10, 2012 Server or similar
# Ensure PowerShell v4 onwards is used
# Please be of sane mind and able to type correctly
#
# Lastly, please provide any feedback you feel necessary, and any suggestions that would improve the script/experience/deliverables.                                


# Setting some variables:

$date = (get-date -f HH-mm----dd-MM-yyyy)
$ourlogdirroot = "C:\"
$ourlogdirraw = "temp"
$ourlogfileraw = "StorSimple-Pre_Installation-Check-$date.txt"
$ourlog = "C:\temp\StorSimple-Pre_Installation-Check-$date.txt"

if (ls $ourlogdirroot | ? {$_.Name -eq "$ourlogdirraw"}) { write-host "`n`n Log file path will be:  $ourlog" } else { $ourlogdir = Read-host "`n`nNo temp directory here, in which directory shall we create the log (please include a trailing slash, e.g. C:\temp\): "; mkdir $ourlogdir >$null; $logfile = "$ourlogfileraw"; $ourlog = $ourlogdir+$logfile }

# We've just specified the directory in which our log will be created

# Checking to see whether the machine running the script is Windows 7, as the script won't function properly due to the lack of test-netconnection cmdlet (and Windows 7 will never be able to support this).

if ((get-wmiobject win32_operatingsystem).Caption -match "Microsoft Windows 7") { write-host "`n`nUnfortunately, you're on a version of Windows that doesn't allow the latest & greatest PowerShell cmdlets (e.g. test-netconnection) to be used. `n`r`n`rPlease execute this script from a machine that runs Windows 8 or later. The script will terminate here`n"; break }

# $error = @()
# Leaving an option to specify an error variable array - untaken as of December 2015.


# Environmental-specific variables:

# Source IP address that will be used for Data0 on StorSimple. This script can be copied and run to test connectivity for IPs 
# allocated for controller fixed IPs too.
$ipaddress = Read-Host "`n`n What is the IP address that will be assigned to Data0 on our StorSimple device? > "

echo "IP Address: $ipaddress " >> $ourlog

$dnserver = Read-Host "`n`n What DNS will be used for our StorSimple device? > "
echo "DNS: $dnserver " >> $ourlog
# For example: 
    # If using a public Google DNS: $dnserver = "8.8.8.8", 
    # or 
    # Internal DNS, something like: $dnserver = "10.1.12.86"

$ntpserver = Read-Host "`n`n What NTP server will be used for our StorSimple device? > "
echo "NTP server: $ntpserver " >> $ourlog
# For example: 
    # If using a public NTP server: $ntpserver = "time.windows.com"
    # or
    # Internal NTP, something like: $ntpserver = "10.1.8.160"


$beacon1 = "portquiz.net"
echo "Beacon server: $beacon1 " >> $ourlog
# Could change this to another known internet address, however portquiz.net is frequently used for connectivity tests


# Known key addresses:

$host1  = "microsoft.com"
$host2  = "windowsazure.com"
$host3  = "windowsupdate.microsoft.com"
$host4  = "updatemicrosoft.com"
$host5  = "windowsupdate.com"
$host6  = "download.microsoft.com"
$host7  = "wustat.microsoft.com"
$host8  = "ntservicepack.microsoft.com"
$host9  = "crl.microsoft.com"
$host10 = "deploy.akamaitechnologies.com"
$host11 = "partners.extranet.microsoft.com"
$host12 = "accesscontrol.windows.net"
$host13 = "storsimple.windowsazure.com"
$host14 = "servicebus.windows.net"
# $host15 = "mtc-tvp.ne.storsimple.windowsazure.com"
# Hashing out this host (Dec 2015) as connectivity returns as null?
$host16 = "bhwgeneral.blob.core.windows.net"
$host17 = "wuspod01rp1users.accesscontrol.windows.net"
$host18 = "pod01-cis1.wus.storsimple.windowsazure.com"
$host19 = "wuspod01cis1sbns95jfo.servicebus.windows.net"

# Create the StorSimple Manager service, then enter the address in here. You can also add the storage account that you create as $host21.
# You will also need to add $host20 to the $reshosts & $httpshosts variable arrays below.
# $host20 = "<storsimple_maanger_service>.<geo>.storsimple.windowsazure.com"
# $host21 = "<storage_account_name>.blob.core.windows.net"


# DOMAINS: Preferable to wildcard firewall entries for these domains/subdomains (up to $host14 - hosts beyond this are known complete addresses) as some addresses are device-specific & automatically generated.
# Having wildcard entries for all key domains (up to $host19) means that whenever new services are added, e.g. storage accounts or devices, the rules will pass traffic rather than block/silently drop.



# Note to user:
Write-host "`n`n We're going to churn away in the background and do some work now. How about a nice cup of tea or coffee while this chugs away? `n`n"


# Testing connectivity over ports to known addresses:

Test-Connection -ComputerName $beacon1 -Source $ipaddress -ErrorAction SilentlyContinue -ErrorVariable +errorbeacon -WarningVariable +errorbeacon -OutVariable outputbeacon >> $ourlog
Test-NetConnection -ComputerName $beacon1 -TraceRoute -InformationLevel Detailed -ErrorAction SilentlyContinue -ErrorVariable +errorbeacon -WarningVariable +errorbeacon -OutVariable +outputbeacon >> $ourlog

$ports=@("80","443","9354")
foreach ($port in $ports) {
    test-netconnection -ComputerName $beacon1 -Port $port -InformationLevel Detailed -ErrorAction SilentlyContinue -ErrorVariable +errorport -WarningVariable +errorport -OutVariable outputport >> $ourlog
    }

# What we're doing in the above loop is essentially this:

# Port 80: HTTP
# Test-NetConnection -ComputerName $beacon1 -Port 80 -InformationLevel Detailed
# Port 443: HTTPS (SSL/TLS)
# Test-NetConnection -ComputerName $beacon1 -Port 443 -InformationLevel Detailed
# Port 9354: Azure Service Bus
# Test-NetConnection -ComputerName $beacon1 -Port 9354 -InformationLevel Detailed


# Testing DNS Resolution:
Test-connection -ComputerName $dnserver -ErrorAction SilentlyContinue -ErrorVariable +errorconndns -WarningVariable +errorconndns -OutVariable outconndns >> $ourlog
Test-netconnection -ComputerName $dnserver -TraceRoute -ErrorAction SilentlyContinue -ErrorVariable +errconndns -WarningVariable +errorconndns -OutVariable +outconndns -InformationLevel Detailed >> $ourlog


$reshosts = @($host1,$host2,$host3,$host4,$host5,$host6,$host7,$host8,$host9,$host10,$host11,$host12,$host13,$host14,$host15,$host16,$host17,$host18,$host19)
foreach ($reshost in $reshosts) { 
    Resolve-DnsName -Name $reshost -Server $dnserver -NoHostsFile -ErrorAction SilentlyContinue -ErrorVariable +errorresolvedns -OutVariable outputresolvedns >> $ourlog
    }

write-host "`n`n (Just a quick little note to let you know we've done some stuff, and are about to do a bit more. Almost done - thanks for waiting!)`n`n"

# What we're doing in the above loop is essentially this:

#Resolve-DnsName -Name $host1 -Server $dnserver -NoHostsFile -ErrorAction SilentlyContinue -ErrorVariable errordns -OutVariable outputdns >> $ourlog
#Resolve-DnsName -Name $host2 -Server $dnserver -NoHostsFile -ErrorAction SilentlyContinue -ErrorVariable errordns -OutVariable outputdns >> $ourlog
#Resolve-DnsName -Name $host3 -Server $dnserver -NoHostsFile -ErrorAction SilentlyContinue -ErrorVariable errordns -OutVariable outputdns >> $ourlog
#Resolve-DnsName -Name $host4 -Server $dnserver -NoHostsFile -ErrorAction SilentlyContinue -ErrorVariable errordns -OutVariable outputdns >> $ourlog

# And so on to the highest number $host variable we have

# Testing NTP 
# Hashing out the test-connection cmdlet for now, as a "Failed: Error due to lack of resources" message is being returned.
# The following w32tm command effectively checks whether we're good for time synchronisation

# test-connection -ComputerName $ntpserver -Source $ipaddress -ErrorAction SilentlyContinue -ErrorVariable errorconnntp -OutVariable outputconnntp >> $ourlog

w32tm /stripchart /computer:$ntpserver /samples:1 >> $ourlog
w32tm /stripchart /computer:$ntpserver /samples:1
write-host  "`n $currentime  ^--- Is this correct? ---^ `n`n"

# Testing connectivity to known key addresses:
# Excluding $host10 - deploy.akamaitechnologies.com - as traffic goes over port 80 only from the fixed controller IPs

$httpshosts = @($host15,$host16,$host17,$host18)
foreach ($httpshost in $httpshosts) { 
    Test-NetConnection -ComputerName $httpshost -Port 443 -ErrorAction SilentlyContinue -ErrorVariable +errorconn443 -WarningVariable +errorconn443 -OutVariable +outputconn443 -InformationLevel Detailed >> $ourlog
    }

$sbhosts = @($host19)
foreach ($sbhost in $sbhosts) {
test-netconnection -ComputerName $sbhost -port 9354 -ErrorAction SilentlyContinue -ErrorVariable +errorconn9354 -WarningVariable +errorconn9354 -OutVariable +outputconn9354 -InformationLevel Detailed >> $ourlog
}

Write-host "`n So, we've been hard at work running some tests. Let's take a look at some of the results: `n"

function get-examresults-wh
{
$success=0
$failure=0

# Connecting to our beacon: 
if ($errorbeacon.count -lt 1)
     { write-host "Connecting to $beacon1 from $ipaddress : PASS"; $success = $success + 1 }
else { write-host "Connecting to $beacon1 from $ipaddress : FAIL"; $failure = $failure + 1 }
# Connecting to our beacon via required ports:
if ($errorport.count -lt 1)
     { write-host "Connecting to $beacon1 over the required ports 80, 443 & 9354: PASS"; $success = $success + 1 }
else { write-host "Connecting to $beacon1 over the required ports 80, 443 & 9354: FAIL"; $failure = $failure + 1 }
# Connecting to our DNS:
if ($errorconndns.count -lt 1)
     { write-host "Connecting to $dnserver over required port 53: PASS"; $success = $success + 1 }
else { write-host "Connecting to $dnserver over required port 53: FAIL"; $failure = $failure + 1 }
# Resolving key addresses using specified DNS:
if ($errorresolvedns.count -lt 1)
     { write-host "Resolving key addresses using $dnserver : PASS"; $success = $success + 1 }
else { write-host "Resolving key addresses using $dnserver : FAIL"; $failure = $failure + 1 }
# Connecting to our NTP server:
if ($errorconnntp.count -lt 1)
     { write-host "Connecting to $ntpserver from $ipaddress : PASS"; $success = $success + 1 }
else { write-host "Connecting to $ntpserver from $ipaddress : FAIL"; $failure = $failure + 1 }
# Connecting to our known host addresses over port 443:
if ($errorconnhttps.count -lt 1)
     { write-host "Connecting to our known host addresses over port 443: PASS"; $success = $success + 1 }
else { write-host "Connecting to our known host addresses over port 443: FAIL"; $failure = $failure + 1 }

write-host "
`n`nThe value of success is (out of a maximum of 6): $success"

write-host "`n`nThe value of failure is (out of a maximum of 6): $failure"
}
get-examresults-wh

if  ($failure -eq 0) { write-host -ForegroundColor Green "`n`n We have a full complement of passes - should be ready to go with a StorSimple deployment!" }
if  ($failure -eq 1) { write-host -ForegroundColor Red -BackgroundColor Black "`n`n We have a failure area - please refer to $ourlog for guidance on where to troubleshoot" }
if  ($failure -gt 1) { write-host -ForegroundColor Red -BackgroundColor Black "`n`n We have some failure areas - please refer to $ourlog for guidance on where to troubleshoot" }

# If we have errors, here they are:

write-host "`n"
$errors = @($errorbeacon,$errorport,$errorresolvedns,$errorconnntp,$errorconnhttps)
foreach ($error in $errors) { $error }

function get-examresults-echointolog
{
$successerf=0
$failureerf=0
# Connecting to our beacon: 
if ($errorbeacon.count -lt 1)
     { echo "Connecting to $beacon1 from $ipaddress : PASS"; $successerf = $successerf + 1 }
else { echo "Connecting to $beacon1 from $ipaddress : FAIL"; $failureerf = $failureerf + 1 }
# Connecting to our beacon via required ports:
if ($errorport.count -lt 1)
     { echo "Connecting to $beacon1 over the required ports 80, 443 & 9354: PASS"; $successerf = $successerf + 1 }
else { echo "Connecting to $beacon1 over the required ports 80, 443 & 9354: FAIL"; $failureerf = $failureerf + 1 }
# Connecting to our DNS:
if ($errorconndns.count -lt 1)
     { echo "Connecting to $dnserver over required port 53: PASS"; $successerf = $successerf + 1 }
else { echo "Connecting to $dnserver over required port 53: FAIL"; $failureerf = $failureerf + 1 }
# Resolving key addresses using specified DNS:
if ($errorresolvedns.count -lt 1)
     { echo "Resolving key addresses using $dnserver : PASS"; $successerf = $successerf + 1 }
else { echo "Resolving key addresses using $dnserver : FAIL"; $failureerf = $failureerf + 1 }
# Connecting to our NTP server:
if ($errorconnntp.count -lt 1)
     { echo "Connecting to $ntpserver from $ipaddress : PASS"; $successerf = $successerf + 1 }
else { echo "Connecting to $ntpserver from $ipaddress : FAIL"; $failureerf = $failureerf + 1 }
# Connecting to our known host addresses over port 443:
if ($errorconnhttps.count -lt 1)
     { echo "Connecting to our known host addresses over port 443: PASS"; $successerf = $successerf + 1 }
else { echo "Connecting to our known host addresses over port 443: FAIL"; $failureerf = $failureerf + 1 }

echo "
`n`nThe value of success is (out of a maximum of 6): $successerf"
echo "
`n`nThe value of failure is (out of a maximum of 6): $failureerf"
}
get-examresults-echointolog | Out-File -FilePath $ourlog -Append -NoClobber

write-host "`n`n"

# Q: Why did the penguin cross the road?
# A: He only got halfway, a Window met him in the middle and they shared an embracing cuddle, whilst traffic stopped around them, everybody smiling and cheering. They lived happily ever after.
##############################################################################END OF SCRIPT#########################################################(AND JOKE)##################################