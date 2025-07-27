import urllib3

URLS = [
    'https://http.krfoss.org/pack/pve.sh',
    'https://http.krfoss.org/pack/pbs.sh',
    'https://http.krfoss.org/pack/cm.sh',
    'https://http.krfoss.org/pack/centos.sh',
    'https://http.krfoss.org/pack/rocky.sh',
    'https://http.krfoss.org/pack/almalinux.sh',
    'https://http.krfoss.org/pack/archlinux.sh',
    'https://http.krfoss.org/pack/archlinux-arm.sh'
]

http = urllib3.PoolManager()

for url in URLS:
    req = http.request('GET', url, preload_content=False)
    filename = url.split('/')[-1]
    with open(filename, 'wb') as out:
        while True:
            data = req.read()
            if not data:
                break
            out.write(data)
    req.release_conn()