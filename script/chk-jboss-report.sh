echo "***************************************************	Server Hostname, OS, Kernel" >> prov_chk.txt
hostnamectl status|egrep 'hostname|System|Kernel|Arch' >> prov_chk.txt

echo "***************************************************	CPU " >> prov_chk.txt
for i in `grep proc /proc/cpuinfo | wc -l`;do echo CPUs $i;done >> prov_chk.txt

echo "***************************************************	RAM " >> prov_chk.txt
for i in `free -h|grep Mem|awk '{print $2}'`;do echo RAM $i;done >> prov_chk.txt

echo "***************************************************	Disks " >> prov_chk.txt
vgs >> prov_chk.txt

echo "***************************************************   App File System " >> prov_chk.txt
lsblk | grep jbossvg >> prov_chk.txt

echo "***************************************************   App Folders " >> prov_chk.txt
df -h | egrep "jboss|tomcat|web|was|dump" | grep -v ix >> prov_chk.txt

echo "***************************************************   App Folders Permissions " >> prov_chk.txt
df -h | egrep "jboss|tomcat|web|was|dump" | grep -v ix| awk '{print $6}'| xargs -n1 ls -ldtra >> prov_chk.txt

echo "***************************************************   RPMS required " >> prov_chk.txt
rpm -qa | egrep "CnAdminMenu|rpm-build|openjdk|openssl|nmap|telnet|tcpdump|wget|lsof|nmon|perl|python" >> prov_chk.txt

echo "***************************************************   Admin Menu " >> prov_chk.txt
ls -ld /usr/local/bin/admin >> prov_chk.txt


