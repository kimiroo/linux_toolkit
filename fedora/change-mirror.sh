for file in /etc/yum.repos.d/*.repo; do
    if [ "$(basename "$file")" = 'fedora-cisco-openh264.repo' ]; then
        continue
    fi

    # Process the file here
    echo "Processing $file"

    sed -i.bak 's|metalink|#metalink|g' $file
    sed -i 's|#baseurl|baseurl|g' $file
    sed -i 's|http://download.example/pub/fedora|https://mirror-icn.yuki.net.uk/fedora|g' $file
done
