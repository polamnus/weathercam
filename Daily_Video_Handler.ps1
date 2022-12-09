<#
	Author: Adam Mikolajczyk
	Email: ajm15@cornell.edu
	Description: Creates a daily time lapse video based on 5 minute camera still frame snapshots. Uploads to FTP server while doing some basic file handling on the FTP server to prevent pile-up.
	I create two versions of the time laspse, one high quality version suitable for archival and one lower quality version for possible web hosting platforms.
	Requires: ImageMagic utility bundle's identify.exe and ffmpeg.exe
#>

AKIA2E7CXHIJAMEI6I6Z
uAlC51g+KfUO3ewnmGjZ4RiH0D3PmcpKH4UuRxqh

#path to ffmpeg
$ffmpeg = "ffmpeg.exe"

#Establish staging area to work with still frame pictures
$staging = "D:\temp\"
#create staging folder if necessary, remove content of staging folder if necessary
if (!(test-path $staging)){new-item -itemtype directory $staging}
if (test-path $staging\*.jpg){remove-item $staging\*.jpg}

#As this is meant to run after midnight, it needs to handle yesterday's folder and files
$Yesterday = '\\SERVERNAME\media\pictures\weathercam\'+((Get-Date).AddDays(-1).ToString('yyyyMMdd'))

#Get list of all of yesterday's files sorted by last write time
$Pictures = GCI $Yesterday\*Camera01.jpg | ?{$_.Length -gt 0} | sort-object -property LastWriteTime

#Since FFMPEG needs a numerically indexed file naming scheme, we are copying the files in chronological order to the staging area in the format #####.jpg
For ($i=0; ($i -lt ($Pictures.count)); $i++){copy-item -path ($Yesterday + "\" + ($Pictures[$i].Name)) -destination (${Staging} + ("{0:D5}" -f $i) + ".jpg") -force}

#Create the arguments to be fed to FFMPEG for botht the HQ and streaming versions of the video
$web_arguments = "-framerate 15 -y -v quiet -i $staging\%05d.JPG -c`:v libx264 -crf 20 -r 15 -vf scale=640:-1 ${Yesterday}Cam01Day_web.mp4"
$arguments = "-framerate 15 -y -v quiet -i $staging\%05d.JPG -c`:v libx264 -crf 20 -r 15 ${Yesterday}Cam01Day.mp4"

#Process the video creation
Start-Process -FilePath $ffmpeg -Argumentlist $arguments -Wait
Start-Process -FilePath $ffmpeg -Argumentlist $web_arguments -Wait

#Remove the content from the staging area once complete
remove-item $staging\*.jpg

#Since I have two cameras, here I'm starting the whole process over again using the still-frame pictures of the second camera
#Establish staging area to work with still frame pictures
$staging = "D:\temp\"
if (!(test-path $staging)){new-item -itemtype directory $staging}
if (test-path $staging\*.jpg){remove-item $staging\*.jpg}

#As this is meant to run after midnight, it needs to handle yesterday's folder and files
$Yesterday = '\\SERVERNAME\media\pictures\weathercam\'+((Get-Date).AddDays(-1).ToString('yyyyMMdd'))

#Get list of all of yesterday's files sorted by last write time
$Pictures = GCI $Yesterday\*Camera02.jpg | ?{$_.Length -gt 0} | sort-object -property LastWriteTime

#Since FFMPEG needs a numerically indexed file naming scheme, we are copying the files in chronological order to the staging area in the format #####.jpg
For ($i=0; ($i -lt ($Pictures.count)); $i++){copy-item -path ($Yesterday + "\" + ($Pictures[$i].Name)) -destination (${Staging} + ("{0:D5}" -f $i) + ".jpg") -force}

#Create the arguemtns to be fed to FFMPEG for both the HQ and streaming versions of the video
$web_arguments = "-framerate 15 -y -v quiet -i $staging\%05d.JPG -c`:v libx264 -crf 20 -r 15 -vf scale=640:-1 ${Yesterday}Cam02Day_web.mp4"
$arguments = "-framerate 15 -y -v quiet -i $staging\%05d.JPG -c`:v libx264 -crf 20 -r 15 ${Yesterday}Cam02Day.mp4"

#Process the video creation
Start-Process -FilePath $ffmpeg -Argumentlist $arguments -Wait
Start-Process -FilePath $ffmpeg -Argumentlist $web_arguments -Wait

#Remvoe the content from the staging area once complete
remove-item $staging\*.jpg

#FTP Section
#We are now going to FTP the web content versions of yesterday's videos to the FTP server for web hosting
$LocalFile01 = "${Yesterday}Cam01Day_Web.mp4"
$FileName01 = ((Get-Date).AddDays(-1).ToString('yyyyMMdd'))+'Cam01Day_web.mp4'
$LocalFile02 = "${Yesterday}Cam02Day_Web.mp4"
$FileName02 = ((Get-Date).AddDays(-1).ToString('yyyyMMdd'))+'Cam02Day_web.mp4'
$ftp = 'ftp://ftp.SOME_FTP_SERVER.com/'
$user = 'ftp_user'
$pass = 'ftp_password'

#Upload the files via FTP to the server for web hosting purposes
$wc = New-Object System.Net.WebClient
$wc.Credentials = New-Object System.Net.NetworkCredential($user,$pass)
$uri01 = New-Object System.Uri($ftp+$FileName01)
$uri02 = New-Object System.Uri($ftp+$FileName02)
$wc.UploadFile($uri01,$LocalFile01)
$wc.UploadFile($uri02,$LocalFile02)

$uri=[system.URI] $ftp
$ftp=[system.net.ftpwebrequest]::Create($uri)
$ftp.Credentials=New-Object System.Net.NetworkCredential($user,$pass)

#Get a list of files in the current directory.
#Use ListDirectoryDetails instead if you need date, size and other additional file information.
$ftp.Method=[system.net.WebRequestMethods+ftp]::ListDirectory
$ftp.UsePassive=$true
try
	{
	 $response=$ftp.GetResponse()
	 $strm=$response.GetResponseStream()
	 $reader=New-Object System.IO.StreamReader($strm,'UTF-8')
	 $list=$reader.ReadToEnd()
	 $lines=$list.Split("`n")
 	}
catch
	{
		 $_|fl * -Force
	}

#Create an array containing the names of all of the files already on the FTP server
$FileListarray = @()
foreach ($line in $lines)
	{
		if ($line.contains('.mp4'))
			{
				#TRIM the file_name because if it contains blank spaces you will get errors when creating the file
				$file_name = $line.ToString().Trim()
				$FileListArray += $file_name
			}
	}
$FileListarray = $FileListArray | Sort-Object -Descending

#If there are more than one week's worth of files (more than 14 files, 7 for each camera) we want to delete the oldest so as not let the files pile up on the server
If ($FileListArray.Count -gt 14)
	{
		$i = 15
		For ($i=15; $i -le ($FileListArray.Count); $i++)
			{
				$file = 'ftp://ftp.SOME_FTP_SERVER.com/'+($FileListArray[($i-1)])
				$ftpuri=[system.URI] $file
 				$request = [system.Net.FtpWebRequest]::Create($ftpuri)
 				$request.Credentials = New-Object System.Net.NetworkCredential($user,$pass)
 				$request.Method = [System.Net.WebRequestMethods+FTP]::DeleteFile
 				$response = $request.GetResponse()
 				#Next line for debugging
				#"Deleted from FTP: " $FileListArray[($i-1)] -f $response.StatusDescription
 				$response.Close()
			}
	}
