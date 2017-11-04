<#
	Author: Adam Mikolajczyk
	Email: ajm15@cornell.edu
	Description: This takes a previous month's worth of still-frame camera shots and stitches them together using FFMPEG into a single time-lapse video.
	This presumes two cameras but could be adapted for any number.
	Requires: identify.exe, a component of ImageMagic tools (opensource)
	Note: This does NOT send the monthly file to an FTP server as the daily script does, but that could be added fairly easily.
#>

#Create references to your tools and folders
$ffmpeg = "C:\Temp\ffmpeg.exe"
$staging = "\\SERVERNAME\media\pictures\weathercam\ffmpeg\temp\"
$identify = "C:\Temp\identify.exe"

#Clear the staging area or create it if it doesn't exist
If (test-path $staging){remove-item -path $staging -recurse}
new-item -itemtype directory -path $staging

#Get the numerical identifier of last month and year, include special handling if current month is January and last month is December
$LastMonth = (Get-Date).AddMonths(-1).ToString('MM')
If ($LastMonth -eq 12) {$Year = (get-date).AddYears(-1).ToString('yyyy')} Else {$Year = (get-date -F yyyy)}

#Get list of all daily folders from last month
$Folders = GCI '\\SERVERNAME\media\pictures\weathercam\' | where-object {$_.PSIsContainer -and ($_.Name -like "${Year}${LastMonth}*")} | Sort -property Name | Select FullName
$Count = 0
$i = 0

<#
Since the camera shifts over to night vision mode at sundown, this creates an undesirable effect on the time-lapse video. So we are only incorporating daylight pictures in our video.
To accomplish that, we use the imagemagic tool identify.exe to look at the color pallate of the image in question. Night vision changes the pallate enough to make a determination and
remove night vision still-frames from the video.
#>
ForEach ($Folder in $Folders)
	{
		$Count = 0
		$path = $Folder.Fullname
		$images = gci -path $path\*camera01.jpg | where-object {((&$identify -format '%r' $_) -eq "DirectClass sRGB ")} | Sort-Object -property LastWriteTime
		For ($Count; $Count -lt $Images.Count; $Count = $Count+2)
			{
				$Name = $Images[$Count].Name
				#Remember, we have to feed FFMPEG a file name format that is strictly numerical, so we copy our files as #####.jpg
				$format = "{0:D5}" -f $i
				copy-item "$path\$name" "$Staging\$format.jpg"
				write-debug "Copying $path\$name to $Staging\$format.jpg"
				$i++
			}
	}

#Prep for creating the movie files, we are once again creating a lower quality web-friendly version and a high quality archival version
$outfile = "\\SERVERNAME\media\pictures\weathercam\${Year}${LastMonth}_MonthlyCAM01.mp4"
$outfile_web = "\\SERVERNAME\media\pictures\weathercam\${Year}${LastMonth}_web_MonthlyCAM01.mp4"
$arguments = "-framerate 30 -i $staging\%05d.JPG -c`:v libx264 -crf 20 -r 30 -vf scale=640:-1 $outfile_web"
$web_arguments = "-framerate 30 -i $staging\%05d.JPG -c`:v libx264 -crf 20 -r 30 $outfile"
Start-Process -FilePath $ffmpeg -Argumentlist $arguments -Wait
Start-Process -FilePath $ffmpeg -Argumentlist $web_arguments -Wait
remove-item $staging*.jpg

#Repeath whole process for second camera
ForEach ($Folder in $Folders)
	{
		$Count = 0
		$path = $Folder.Fullname
		$images = gci -path $path\*camera02.jpg | where-object {([int](&$identify -format '%k' $_) -gt 1024)} | Sort-Object -property LastWriteTime
		For ($Count; $Count -lt $Images.Count; $Count = $Count+2)
			{
				$Name = $Images[$Count].Name
				$format = "{0:D5}" -f $i
				copy-item "$path\$name" "$Staging\$format.jpg"
				write-debug "Copying $path\$name to $Staging\$format.jpg"
				$i++
			}
	}
	
$outfile = "\\SERVERNAME\media\pictures\weathercam\${Year}${LastMonth}_MonthlyCAM02.mp4"
$outfile_web = "\\SERVERNAME\media\pictures\weathercam\${Year}${LastMonth}_web_MonthlyCAM02.mp4"
$arguments = "-framerate 30 -i $staging\%05d.JPG -c`:v libx264 -crf 20 -r 30 -vf scale=640:-1 $outfile_web"
$web_arguments = "-framerate 30 -i $staging\%05d.JPG -c`:v libx264 -crf 20 -r 30 $outfile"
Start-Process -FilePath $ffmpeg -Argumentlist $arguments -Wait
Start-Process -FilePath $ffmpeg -Argumentlist $web_arguments -Wait
remove-item $staging*.jpg
