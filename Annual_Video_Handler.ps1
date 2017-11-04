<#
	Author: Adam Mikolajczyk
	Emai: ajm15@cornell.edu
	Description: Processes a year's worth of still frame camera shots into time lapse videos. This does not include FTP shipping to server as the daily script does!
	Requirement: Imagemagic tool identify.exe and ffmpeg.exe are required, both are opensource
#>

#Establish place holder constants
$ffmpeg = "C:\Temp\ffmpeg.exe"
$staging = "\\SERVERNAME\media\pictures\weathercam\ffmpeg\temp2\"
$identify = "C:\Temp\identify.exe"

#Clear staging folder if necessary
remove-item $staging*.jpg

#Obtain the numerical identifier of last year
$LastYear = (Get-Date).AddYears(-1).ToString('yyyy')

#Obtian a list of all daily camera folders from the previous year
$Folders = GCI '\\SERVERNAME\media\pictures\weathercam\' | where-object {$_.PSIsContainer -and ($_.Name -like "${LastYear}*")} | Sort -property Name | Select FullName
$Count = 0
$i = 0

<#
Just like in the monthly script, we want to filter out all of the night-vision still frame shots or our video will be very unpleasant to watch due to the switching. We use identify.exe
to look at the color pallate of each jpg and only include those taken in daylight mode. We then copy them using a new naming convention since ffmpeg.exe needs a simple numerical #####.jpg format.
#>
ForEach ($Folder in $Folders)
	{
		$Count = 0
		$path = $Folder.Fullname
		$images = gci -path $path\*.jpg | where-object {((&$identify -format '%r' $_) -eq "DirectClass sRGB ")} | Sort-Object -property LastWriteTime
		For ($Count; $Count -lt $Images.Count; $Count = $Count+6)
			{
				#Change name to a simple number as we copy to staging so FFMPEG can process it later
				$Name = $Images[$Count].Name
				$format = "{0:D5}" -f $i
				copy-item "$path\$name" "$Staging\$format.jpg"
				$i++
			}
	}

#Setup arguemtns to be used in creating the videos, we are creating two, one for web streaming and one for archival
$outfile = "\\SERVERNAME\media\pictures\weathercam\${Year}_Annual.mkv"
$outfile_web = "\\SERVERNAME\media\pictures\weathercam\${Year}_web_Annual.mkv"
$arguments = "-framerate 30 -i $staging\%05d.JPG -c`:v libx264 -preset slow -vf `"fps=30,format=yuv420p`" -tune stillimage $outfile"
$arguments_web = "-f image2 -r 30 -i $staging\%05d.JPG -vcodec libx264 -profile:v high444 -refs 16 -crf 0 -preset slow -vf scale=640:-1 $outfile_web"

#Create the videos...this can take a long time!
Start-Process -FilePath $ffmpeg -Argumentlist $arguments_web -Wait
Start-Process -FilePath $ffmpeg -Argumentlist $arguments -Wait

#clean up our staging folder when complete
remove-item $staging*.jpg