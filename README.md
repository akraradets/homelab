# HOME LAB
This is the document for what I have done in my home lab.
The plan is to use self-hosted services that I have to use inside and outside of my home.

This repository is public access.

## My network layout

I received a non-permanent public IP from my ISP.
This means, the provisioning IP is in the public range but rotated.

Inside, there are two networks. (1) The default 192.168.1.0/24 and (2) the 192.168.31.0/24 from Xiaomi Mesh wifi.
The network 192.168.31.0/24 is an intranet and can not be accessed from the outside.
Thus, all my services are in 192.168.1.0/24 network.

## Infrastructure

I am intending to use two machines. 
One TrueNAS and one PROXMOX.
TrueNAS machine will serve (1) NAS, of course, and (2) Virtual Machine service that serves LDAP, DNS, VPN, and Dashboard.
PROXMOX machine will serve (1) GPU server for Machine/Deep Learning development.
