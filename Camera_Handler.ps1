<#
	Author: Adam Mikolajczyk
	Email: ajm15@cornell.edu
	This script interacts with two cameras. The first is an HK-Vision and the second is an Amcrest. They require different API calls to obtain the still-frame snapshot.
#>
#Don't Forget These!
AKIA2E7CXHIJBXQJCI57
TLED36OQjhkdM0ZtuLICPojV7O7iBj3Ui0fTDWwg
#Define the still frame snapshot files and URLs to obtain them
$LocalFile1 = 'C:\temp\camera01_snap.jpg'
$LocalFile2 = 'C:\temp\camera02_snap.jpg'
$URL1 = "http://Camera01_IP_Address:8166/Streaming/channels/1/picture"
$URL2 = "http://Camera02_IP_Address/cgi-bin/snapshot.cgi"

#create the web calls - edit the credentials as necessary
$wc1 = New-Object System.Net.WebClient
$wc1.Credentials = New-Object System.Net.NetworkCredential("tasker","vVneVk8kNNZf")
$wc2 = New-Object System.Net.WebClient
$wc2.Credentials = New-Object System.Net.NetworkCredential("tasker","vVneVk8kNNZf")

#remove the existing temporary files if they're there
If (test-path $LocalFile1){remove-item $LocalFile1}
If (test-path $LocalFile2){remove-item $LocalFile2}

#make the HTTP calls and obtain the files
$wc1.DownloadFile($URL1, $LocalFile1)
$wc2.DownloadFile($URL2, $LocalFile2)

#define the FTP username/password
$user = 'ftp_user@my_ftp_server.com'
$pass = 'ftp_password'

#create holding variables for the FTP data and server
$FileName1 = 'camera01_snap.jpg'
$FileName2 = 'camera02_snap.jpg'
$ftp = 'ftp://ftp.my_ftp_server.com/'

#prepare to make the FTP calls herem we are going to need two of then, one for each file
$wc1 = New-Object System.Net.WebClient
$wc1.Credentials = New-Object System.Net.NetworkCredential($user,$pass)
$uri1 = New-Object System.Uri($ftp+$FileName1)
$wc1.UploadFile($uri1,$LocalFile1)
$wc2 = New-Object System.Net.WebClient
$wc2.Credentials = New-Object System.Net.NetworkCredential($user,$pass)
$uri2 = New-Object System.Uri($ftp+$FileName2)
$wc2.UploadFile($uri2,$LocalFile2)

#handle my local file server to archive the snapshots locally
$BaseFolder = '\\SERVERNAME\media\pictures\weathercam\'
$DailyFolder = $BaseFolder+(get-date -f yyyyMMdd)+'\'

#we create a daily folder to hold all snaps from a single day
If (!(test-path $DailyFolder)) {New-Item -itemtype directory -path $DailyFolder}

#name the files with the time and date stamps as well as appending the source camera
$destfile1 = $DailyFolder + (Get-date -f yyyyMMdd_HHmm) + '_camera01.jpg'
$destfile2 = $DailyFolder + (Get-date -f yyyyMMdd_HHmm) + '_camera02.jpg'

#some sanity checking and error handling here.
#first we need to look at the daily folder and figure out which file is the most recently created then obtain it's name
$mostrecent1 = Get-Childitem -path $DailyFolder | ?{$_.Name -like "*_camera01.jpg"} |sort LastWriteTime | select -last 1
$mostrecent1 = "$DailyFolder\" + $mostrecent1.Name

#We use the dos command fc.exe to make sure we're not copying in the same exact file, this was necessary in the event that the still frame hasn't updated for whatever reason.
#if we don't do this we can end up with repeating frames in the time-lapse later
&fc.exe /b "c:\temp\$filename1" $mostrecent1 > $null
if (!$?){copy-item -path c:\temp\camera01_snap.jpg -destination $destfile1}

#same file compare process for the 2nd camera
$mostrecent2 = Get-Childitem -path $DailyFolder | ?{$_.Name -like "*_camera02.jpg"} |sort LastWriteTime | select -last 1
$mostrecent2 = "$DailyFolder\" + $mostrecent2.Name
&fc.exe /b "c:\temp\$filename2" $mostrecent2 > $null
if (!$?){copy-item -path c:\temp\camera02_snap.jpg -destination $destfile2}
