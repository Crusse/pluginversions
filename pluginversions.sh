#/bin/bash

validOpts=':i:r:e:'

printUsage() {
  echo "Usage: $( basename "$0" ) [OPTIONS] <URLs input file>"
  echo "  -i  Crawl interval, in minutes. How often to fetch each site."
  echo "  -e  Email address to send reports to."
}

if [[ $# == 0 ]] ; then
  printUsage
  exit 1
fi

OPTIND=1
while getopts "$validOpts" opt ; do
  if [[ "$opt" == '?' ]] ; then
    printUsage
    exit 1
  fi
done

crawlInterval=1440
email=""

OPTIND=1
while getopts "$validOpts" opt ; do
  case "$opt" in
    i) crawlInterval=$OPTARG;;
    e) email="$OPTARG";;
    :) echo "Option -$OPTARG requires an argument"
       exit 1;;
  esac
done

shift $(( OPTIND - 1 ))

if (( $crawlInterval < 1 )) ; then echo "Crawl interval (-i) must be larger than 0"; exit 1; fi

urlsFile="$1"
if [[ ! -f "$urlsFile" ]] ; then
  echo "The file \"$urlsFile\" does not exist"
  exit 1
fi

while true ; do
  
  report="Plugin versions:\n\n"

  while read -r url ; do

    versionStr=""

    gravityFormsVer="$( wget -q -O - "${url}/wp-content/plugins/gravityforms/change_log.txt" | grep -m 1 '^Version' | sed -E 's/^Version[^[:digit:]]//' )"
    if [[ "$gravityFormsVer" != "" ]] ; then
      versionStr+="Gravity Forms ${gravityFormsVer}\n"
    fi

    wwPubVer="$( wget -q -O - "${url}/wp-content/plugins/astewwpub_wp/CHANGELOG.txt" | grep -E -m 1 '^[[:digit:]]+\.[[:digit:]]+' )"
    if [[ "$wwPubVer" != "" ]] ; then
      versionStr+="AsteWWPub_WP ${wwPubVer}\n"
    fi

    if [[ "$versionStr" = "" ]] ; then
      continue
    fi

    report+="${url}\n------------------\n"
    report+="$versionStr"
    report+="\n"
  done < "$urlsFile"

  if [[ "$email" ]] ; then
    echo -e "$report" | mail -s "WordPress plugin versions $( date )" "$email"
    echo "Report sent to $email"
  else
    echo -e "$report"
  fi
  
  sleep $(( crawlInterval * 60 ))
done

exit 0

