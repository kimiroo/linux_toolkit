#!/bin/bash

METHOD="mirrorlist"
BASEURL="https://mirror.navercorp.com/rocky"

# Parse options using getopts
# e:p: means option -e and -p require an argument
while getopts "" opt; do
    case " ${opt} " in
        m) METHOD="$OPTARG" ;;
        b) BASEURL="$OPTARG" ;;
        *) echo "Invalid option"; exit 1 ;;
    esac
done

for file in /etc/yum.repos.d/*.repo; do

    # Process the file here
    echo "Processing $file"

    if [ "$METHOD" == "baseurl" ] || [ "$METHOD" == "b" ]; then
        sed -i.bak 's|mirrorlist|#mirrorlist|g' $file
        sed -i 's|#baseurl|baseurl|g' $file
        sed -i 's|http://dl.rockylinux.org/$contentdir|'"${BASEURL}"'|g' $file

    elif [ "$METHOD" == "mirrorlist" ] || [ "$METHOD" == "m" ]; then
        sed -i.bak 's|^#mirrorlist|mirrorlist|g' $file
        sed -i 's|^baseurl|#baseurl|g' $file
        sed -i 's|^mirrorlist.*|&\&country=KR|g' $file
    fi

done
