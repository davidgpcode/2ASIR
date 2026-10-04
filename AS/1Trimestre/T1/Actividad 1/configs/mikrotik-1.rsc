# 2026-10-04 18:16:10 by RouterOS 7.24.2
# system id = n8d4WnhkaDG
#
/interface ethernet set [ find default-name=ether1 ] disable-running-check=no
/interface ethernet set [ find default-name=ether2 ] disable-running-check=no
/interface ethernet set [ find default-name=ether3 ] disable-running-check=no
/interface ethernet set [ find default-name=ether4 ] disable-running-check=no
/interface ethernet set [ find default-name=ether5 ] disable-running-check=no
/interface ethernet set [ find default-name=ether6 ] disable-running-check=no
/user group add name=backup policy=ssh,read,test,!local,!telnet,!ftp,!reboot,!write,!policy,!winbox,!password,!web,!sniff,!sensitive,!api,!romon,!rest-api
/ip address add address=10.10.10.22/24 interface=ether1 network=10.10.10.0
/ip dhcp-client add interface=ether1 name=client1
/snmp set enabled=yes
