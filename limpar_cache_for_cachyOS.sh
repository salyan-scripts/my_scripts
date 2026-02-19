#!/bin/bash 
sudo clear ;
free -h ;
sudo sync ;
sudo swapoff -a ;
sudo systemctl daemon-reload ;
sudo systemctl restart systemd-zram-setup@zram0.service ;
sudo sysctl -w vm.drop_caches=1 ;
sudo sync ;
free -h ;
