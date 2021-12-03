#!/bin/bash
# GET LOCALHOST IP
localhostip="$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v hostname -i | head -n1)"

myip=$localhostip
myport=5008
mycam=0

killall gst-launch-1.0
#killall nvargus-daemon
#systemctl restart nvargus-daemon

#sudo /content/autosudoscript.sh
if [ "$1" ] # if first argument is not null, use it as ip
then
    myip=$1
    echo "ip received=$myip"
fi

if [ "$2" ] # if second argument is not null, use it as port
then
    myport=$2
    echo "port received=$myport"
fi

if [ "$3" ] # if third argument is not null, use it as cam stream name
then
    mycam=$3
    echo "cam received=$mycam"
fi

echo "ip=$myip"
echo "port=$myport"
echo "cam=$mycam"

#regular expression to check if value is a number
re='^[0-9]+$'
if [[ $mycam =~ $re ]]; then
	echo CSI camera
    gst-launch-1.0 -v nvarguscamerasrc sensor_id=$mycam ! 'video/x-raw(memory:NVMM),width=192,height=108,framerate=30/1' ! nvvidconv flip-method=2 ! 'video/x-raw,width=192,height=108' ! videoconvert ! 'video/x-raw,width=192,height=108,format=RGB,stream-format=RGB-stream' ! rtpvrawpay mtu=65500 ! udpsink host=$myip port=$myport sync=false async=true
#	echo CSI camera
#    gst-launch-1.0 -v nvarguscamerasrc sensor_id=$mycam ! 'video/x-raw(memory:NVMM),width=192,height=108,framerate=30/1' ! nvvidconv ! 'video/x-raw,width=192,height=108' ! videoconvert ! 'video/x-raw,width=192,height=108,format=RGB,stream-format=RGB-stream' ! rtpvrawpay mtu=65500 ! udpsink host=$myip port=$myport sync=false async=true
else
	echo USB camera
    gst-launch-1.0 -v v4l2src device=/dev/$mycam ! videoconvert ! videoscale ! queue ! video/x-raw,framerate=30/1,width=192,height=108,format=RGB,stream-format=RGB-stream ! deinterlace ! rtpvrawpay mtu=65500 ! udpsink host=$myip port=$myport sync=true async=true

# deepstream optical flow
#    gst-launch-1.0 -v -f udpsrc port=5014 ! "application/x-rtp, encoding-name=(string)RAW, sampling=(string)RGB, depth=(string)8, width=(string)192, height=(string)108" ! rtpvrawdepay ! queue ! videoconvert ! nvvideoconvert ! queue ! "video/x-raw(memory:NVMM),format=I420,width=192,height=108" ! nvvideoconvert ! m.sink_0 nvstreammux name=m batch-size=1 width=192 height=108 ! nvof preset-level=2 ! queue ! nvofvisual ! nvvideoconvert ! tee name=t t. ! queue ! videoconvert ! 'video/x-raw,width=192,height=108,format=RGB,stream-format=RGB-stream' ! rtpvrawpay mtu=65500 ! udpsink host=10.12.1.105 port=5008 sync=true async=true t. ! queue ! videoconvert ! videoscale ! 'video/x-raw,width=3,height=3,format=RGB,stream-format=RGB-stream' ! queue ! rtpvrawpay mtu=65500 ! udpsink host=10.12.1.105 port=5010 sync=true async=true

fi

#gst-launch-1.0 -v v4l2src device=/dev/$mycam ! videoconvert ! videoscale ! queue ! video/x-raw,framerate=30/1,width=192,height=108,format=RGB,stream-format=RGB-stream ! deinterlace ! rtpvrawpay mtu=65500 ! udpsink host=$myip port=$myport sync=true async=true

#gst-launch-1.0 -v v4l2src device=/dev/video5 ! videoconvert ! videoscale ! queue ! video/x-raw,framerate=30/1,width=192,height=108,format=RGB,stream-format=RGB-stream ! deinterlace ! rtpvrawpay mtu=65500 ! udpsink host=192.168.1.193 port=5008 sync=true async=true &

#gst-launch-1.0 -v nvarguscamerasrc ! nvvidconv ! 'video/x-raw, width=128, height=72, stream-format=(string)RGB-stream' ! rtpvrawpay mtu=60000 ! udpsink host=192.168.1.74 port=5008 sync=false &


#Preview rgb:
#gst-launch-1.0 -v v4l2src device=/dev/video3 ! videoconvert ! queue ! video/x-raw,framerate=30/1,width=1280,height=720 ! xvimagesink
