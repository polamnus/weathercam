# weathercam
Scripts I use to capture data from my weather camera and concatenate those into time lapse videos.

These scripts are ones I use to grab still frame pictures from two IP cameras on my property. The first script captures the snapshots
as JPG images every five minutes and uploads them to an FTP server for web hosting. It also copies them to a local NAS.

Every day shortly after midnight, the daily script runs and compiles a time-lapse of the previous day. I create two videos, one higher
quality for archival purposes and one lower quality for web hosting/streaming.

After the end of every month, anohter script runs which does the same operation to the previous month's still frame shots. So as to keep
the video easier on the eyes, I use the imagemagic package's identify.exe tool to filter out any shots taken while night vision was on.

After the first of the year I run the same process to create an annual video.

Note: I'm not an expert on FFMPEG and I've come up with the various arguemtns with trial and error. I'd be eager to hear from someone
more well-versed on FFMPEG to know if my arguments could be improved.

AKIA2E7CXHIJGAKC2NXM
