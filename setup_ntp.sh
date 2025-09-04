timedatectl set-ntp no

apt install chrony -y

sed -i.ori '/pool ntp.ubuntu.com/i\server time.kriss.re.kr iburst\nserver time2.kriss.re.kr iburst\n' /etc/chrony/chrony.conf

systemctl restart chrony