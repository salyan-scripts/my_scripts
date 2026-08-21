#!/bin/bash
waydroid session stop 2>/dev/null; 
sudo killall -9 waydroid 2>/dev/null; 
sudo systemctl stop waydroid-container
