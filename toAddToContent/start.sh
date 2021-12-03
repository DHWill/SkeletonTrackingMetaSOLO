#!/bin/bash
timer=0
jetsonHardwareDelay=2
# TIMERS. TO SKIP STARTING SOMETHING, SET THE CORRESPONDING TIMER TO 0
packLogs=1
loadArtwork=1
loadFixTouch=1
startAutoDimmer=1
loadCameraFeed=0
# THIS IDEALLY SHOULD START AFTER ARTWORK IS LOADED
loadSensor=6
loadOpticalFlow=4
loadMic=0
broadcastSensor=0
broadcastMic=0

defaultArtworkID=0

# GET LOCALHOST IP
localhostip="$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v hostname -i | head -n1)"
myip=$localhostip

#TOOLKIT DEFAULT PORTS
mysensorport=5006
mynetworkport=5007
mycamport=5008
mymicport=5009
myopticalflowport=5011
mylargeopticalflowport=5012

#THESE MIGHT CHANGE
mycam=0 #video0/video1/video2 for usb cameras, 0/1 for CSI cameras (jetson)
#Now we have automation in sensor.sh to automatically identify these two below
mysensordevice=ttyTHS2 #hidraw1 or other number for USB (CIC), ttyTHS2 for uart (jetson)
mymicdevice=ttyTHS2 #hidraw1 or other number for USB (CIC), ttyTHS2 for uart (jetson)

#TOOLKIT IP FOR NETWORK MESSAGES
networkTargetIP=$localhostip

#BROADCASTING DEVICES OVER NETWORK
ipcamera=$myip
ip2=
ip3=
ip4=
mysensorbroadcastdevice=$mysensordevice
mymicbroadcastdevice=$mymicdevice
mysensorbroadcastport=$mysensorport
mymicbroadcastport=$mymicport

# PLEASE DO NOT MODIFY ANYTHING BELOW (unless you really know what you are doing)
#sudo usermod -a -G dialout $USER
cpuArchitecture=$(lscpu | grep -i architecture | xargs | cut -d " " -f 2)
echo cpuArchitecture = $cpuArchitecture

# CHANGE SCREEN RESOLUTION (just in case)
#displayTarget=$(xrandr --listactivemonitors | tr " " "\n" | tail -1)
#echo Setting display to $displayTarget
#xrandr --output $displayTarget --size 1920x1920 --scale 1x1

/content/restartArt.sh
/content/updateDate.sh &

if [[ "$cpuArchitecture" == "aarch64" ]]; then ( (
    sleep $(( $timer + $jetsonHardwareDelay))
    #sets up UART pins baud rate
    /bin/stty -F /dev/ttyTHS2 115200 &>/dev/null
) & ) fi

# remove auto suspend usb devices
for myUSBDevice in /sys/bus/usb/devices/*/power/control; do
    echo $myUSBDevice
    echo on > $myUSBDevice
done

sudo /content/adminScript.sh


if [ -f "/demoApp/Content/SetArtworkConfigNow.py" ]; then (
    python3 /demoApp/Content/SetArtworkConfigNow.py $defaultArtworkID
) fi

# start backlight dimming if Jetson
if [[ "$cpuArchitecture" == "aarch64" ]]; then (
    if [ $startAutoDimmer -ge 1 ]; then (
            python3 /content/autoDim/autoDimmer.py &
            python3 /Scripts/DHS_Stat-Collector/__main__.py &
    ) fi
) fi

if [ $loadFixTouch -ge 1 ]; then ( (
    sleep $(( $timer + $loadFixTouch))
    echo "Starting to fix touch . . ."
    until "$(($(/content/fixtouch.sh >/dev/null) + 10))"; do
	    echo "Fix touch closed with exit code $?.  Respawning.." >&2
	    sleep 2
    done

) & ) fi

if [ "$1" ] # if first argument is not null, use it as ip
then
    myip=$1
    #echo "ip received=$myip"
fi

if [ $loadArtwork -ge 1 ]; then ( (
    sleep $(( $timer + $loadArtwork ))
    echo Starting artwork . . .

    until "$(($(/content/artwork.sh >/dev/null) + 10))"; do
	    echo "Artwork closed with exit code $?.  Respawning.." >&2
	    sleep 4
    done

) & ) fi

#remove cursor
xsetroot -cursor /content/emptycursor /content/emptycursor


if [ $loadCameraFeed -ge 1 ]; then ( (
    sleep $(( $timer + $loadCameraFeed ))
    echo Starting camera feed . . .

    until "$(($(/content/gst.sh $ipcamera $mycamport $mycam >/dev/null) + 10))"; do
	    echo "Camera feed closed with exit code $?.  Respawning.." >&2
	    sleep 4
    done

) & ) fi

if [ $loadSensor -ge 1 ]; then ( (
    sleep $(( $timer + $loadSensor ))
    echo Starting sensor . . .

    until "$(($(/content/sensor.sh $myip $mysensorport $mysensordevice >/dev/null) + 10))"; do
	    echo "Sensor closed with exit code $?.  Respawning.." >&2
	    sleep 4
    done

) & ) fi

if [ $loadOpticalFlow -ge 1 ]; then ( (
    sleep $(( $timer + $loadOpticalFlow ))
    echo Starting optical flow . . .

    if [[ "$cpuArchitecture" == "x86_64" ]]; then
        source ~/OpenCV-master-py3/bin/activate #same as workoncv-master on the terminal
        until "$(($(ipython /dependencies/DHSCam.py 5014 192 108 30 192 108 3 3 $myip $myopticalflowport >/dev/null) + 10))"; do
    	    echo "Optical flow closed with exit code $?.  Respawning.." >&2
    	    sleep 4
        done
    else
    if [[ "$cpuArchitecture" == "aarch64" ]]; then
        if [[ "$(python3 --version)" == *"3."* ]]; then
            echo "I have python 3"
            until "$(($(python3 /dependencies/DHSCam.py 5014 192 108 30 192 108 3 3 $myip $myopticalflowport >/dev/null) + 10))"; do
    	        echo "Optical flow closed with exit code $?.  Respawning.." >&2
        	    sleep 4
            done
        else
            echo "I don't have python 3"
            until "$(($(python3 /dependencies/DHSCam.py 5014 192 108 30 192 108 3 3 $myip $myopticalflowport >/dev/null) + 10))"; do
    	        echo "Optical flow closed with exit code $?.  Respawning.." >&2
        	    sleep 4
            done
        fi
    fi
    fi
) & ) fi

if [ $loadMic -ge 1 ]; then ( (
    sleep $(( $timer + $loadMic ))
    echo Starting mic . . .

    until "$(($(/content/mic.sh $myip $mymicport $mymicdevice >/dev/null) + 10))"; do
	    echo "Mic closed with exit code $?.  Respawning.." >&2
	    sleep 4
    done

) & ) fi



if [ $broadcastSensor -ge 1 ]; then ( (
    if [ "$ip2" ]
    then
        sleep $(( $timer + $broadcastSensor ))
        echo Broadcasting sensor to $ip2 . . .

        until "$(($(/content/./sensor.sh $ip2 $mysensorbroadcastport $mysensorbroadcastdevice >/dev/null) + 10))"; do
            echo "Sensor broadcast $ip2 closed with exit code $?.  Respawning.." >&2
            sleep 8
        done
    fi
) & ) fi
if [ $broadcastSensor -ge 1 ]; then ( (
    if [ "$ip3" ]
    then
        sleep $(( $timer + $broadcastSensor ))
        echo Broadcasting sensor to $ip3 . . .

        until "$(($(/content/./sensor.sh $ip3 $mysensorbroadcastport $mysensorbroadcastdevice >/dev/null) + 10))"; do
            echo "Sensor broadcast $ip3 closed with exit code $?.  Respawning.." >&2
            sleep 8
        done
    fi
) & ) fi
if [ $broadcastSensor -ge 1 ]; then ( (
    if [ "$ip4" ]
    then
        sleep $(( $timer + $broadcastSensor ))
        echo Broadcasting sensor to $ip4 . . .

        until "$(($(/content/./sensor.sh $ip4 $mysensorbroadcastport $mysensorbroadcastdevice >/dev/null) + 10))"; do
            echo "Sensor broadcast $ip4 closed with exit code $?.  Respawning.." >&2
            sleep 8
        done
    fi
) & ) fi


if [ $broadcastMic -ge 1 ]; then ( (
    if [ "$ip2" ]
    then
        sleep $(( $timer + $broadcastMic ))
        echo Broadcasting mic to $ip2 . . .

        until "$(($(/content/./mic.sh $ip2 $mymicbroadcastport $mymicbroadcastdevice >/dev/null) + 10))"; do
	        echo "Mic broadcast $ip2 closed with exit code $?.  Respawning.." >&2
	        sleep 8
        done
    fi
) & ) fi
if [ $broadcastMic -ge 1 ]; then ( (
    if [ "$ip3" ]
    then
        sleep $(( $timer + $broadcastMic ))
        echo Broadcasting mic to $ip3 . . .

        until "$(($(/content/./mic.sh $ip3 $mymicbroadcastport $mymicbroadcastdevice >/dev/null) + 10))"; do
	        echo "Mic broadcast $ip3 closed with exit code $?.  Respawning.." >&2
	        sleep 8
        done
    fi
) & ) fi
if [ $broadcastMic -ge 1 ]; then ( (
    if [ "$ip4" ]
    then
        sleep $(( $timer + $broadcastMic ))
        echo Broadcasting mic to $ip4 . . .

        until "$(($(/content/./mic.sh $ip4 $mymicbroadcastport $mymicbroadcastdevice >/dev/null) + 10))"; do
	        echo "Mic broadcast $ip4 closed with exit code $?.  Respawning.." >&2
	        sleep 8
        done
    fi
) & ) fi



if [ $packLogs -ge 1 ]; then ( (
    sleep $(( $timer + $packLogs ))
    echo Packaging Logs into USB . . .
    
#    /content/./clearUSBs.sh
#    sleep 2
    /content/./packLogs.sh
#    until "$(($(/content/./packLogs.sh) + 10))"; do
	#echo "Packaging logs closed with exit code $?.  Respawning.." >&2
#	sleep 4
#    done

) & ) fi



echo initialization routine finished >&2

while true; do
	sleep 10
done

echo initialization script exited with error code $?. >&2
