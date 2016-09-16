#!/bin/bash
if [[ -z $1 ]]
then
  echo ""
  echo "$(basename $0) Checks a given URL and provides transaction data."
  echo "Usage: $(basename $0) <URL>"
  echo ""
  exit -1
else
  echo -e "\c"
fi

localip="Local IP:\t\t%{local_ip}\n"
localport="Local Port:\t\t%{local_port}\n"
content="Content Type:\t\t%{content_type}\n"
httpcode="HTTP Code:\t\t%{http_code}\n"
connect="HTTP Connects:\t\t%{http_connect}\n"
connects="Connect Count:\t\t%{num_connects}\n"
redirects="Redirect Count:\t\t%{num_redirects}\n"
redirecturl="Redirect URL:\t\t%{redirect_url}\n"
sizedl="Download Size:\t\t%{size_download} bytes\n"
sizehd="Header Size:\t\t%{size_header} bytes\n"
sizerq="Request Size:\t\t%{size_request} bytes\n"
sizeup="Upload Size:\t\t%{size_upload} bytes\n"
dlspeed="Download Speed Avg\t%{speed_download}\n"
upspeed="Upload Speed Avg\t%{speed_upload}\n"
lookuptime="Look-up Time:\t\t%{time_namelookup}\n"
connecttime="ConnectTime:\t\t%{time_connect}\n"
prexfer="PreXfer time:\t\t%{time_pretransfer}\n"
timeredir="Redirect Time:\t\t%{time_redirect}\n"
startxfer="BeginXfer time:\t\t%{time_starttransfer}\n"
totaltime="Total time:\t\t%{time_total}\n"
urleffect="Last URL:\t\t%{url_effective}\n"

formattedOutput="$localip$localport\
$content$httpcode$connect$connects$lookuptime$redirects$redirecturl\
$sizedl$sizehd$sizerq$sizeup$dlspeed$upspeed$urleffect\
$connecttime$prexfer$timeredir$startxfer$totaltime"

curl -w "$formattedOutput" -o /dev/null -s $1 | sort

