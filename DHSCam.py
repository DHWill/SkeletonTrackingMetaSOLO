#!/usr/bin/env python
# MIT License

# Copyright (c) 2017 Jetsonhacks

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including withoulimitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

from os import devnull
import sys
import cv2
import numpy as np
from numpy.lib.polynomial import RankWarning
from pose_engine import Keypoint, KeypointType, PoseEngine
import time
import threading
import socket
#import os
import subprocess

class ThreadedCap:
    def __init__(self, param1, param2):
        self.cap = cv2.VideoCapture(param1, param2)
        self.thread = threading.Thread(target=self._read)
        self.thread.daemon = True
        self.thread.start()

    def _read(self):
        while(True):
            ret, frame = self.cap.read()
            if (not ret):
                print("No return")

            if (frame.size > 0):
                self.ret = ret
                self.frame = frame
            else:
                print("Frame empty")

    def read(self):
        return self.ret, self.frame

    def isOpened(self):
        return self.cap.isOpened()

#--------------------------------------------------------------------------------------_
myIp = subprocess.check_output("ifconfig | grep eth0 -A1 |grep -Eo 'inet (addr:)?([0-9]*\.)\{3\}[0-9]*' | grep -Eo '([0-9]*\.)\{3\}[0-9]*' | grep -v hostname -i | head -n1", shell=True)

def call_gstreamer():
    subprocess.run(["sudo", "/content/nvargus.sh"])
    time.sleep(0.5)
    ip = subprocess.check_output("ifconfig | grep eth0 -A1 |grep -Eo 'inet (addr:)?([0-9]*\.)\{3\}[0-9]*' | grep -Eo '([0-9]*\.)\{3\}[0-9]*' | grep -v hostname -i | head -n1", shell=True)
    subprocess.run(["/content/gst.sh",  ip, "5014",  "0"], shell=False)


def gstreamer_thread():
    subprocess.run(["killall", "gst-launch-1.0"])
    gst_thread = threading.Thread(target=call_gstreamer)
    gst_thread.daemon = True
    return gst_thread
    

engine = PoseEngine(
    '/dependencies/models/mobilenet/posenet_mobilenet_v1_075_353_481_quant_decoder_edgetpu.tflite')
try:
    portIn = 5014
    widthIn = 192
    heightIn = 108
    framerateIn = 30
    oflowWidthIn = 192
    oflowHeightIn = 108
    widthOut = 3
    heightOut = 3
    ipOut = "127.0.0.1"
    portOut = 5011
    if(len(sys.argv) == 11):
        portIn, widthIn, heightIn, framerateIn, oflowWidthIn, oflowHeightIn, widthOut, heightOut, ipOut, portOut = sys.argv[
            1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5], sys.argv[6], sys.argv[7], sys.argv[8], str(sys.argv[9]), sys.argv[10]
        print("arguments parsed")
    else:
        print("not enough arguments")
    print("TryingCap")
    
    #subprocess.check_call(["sudo",  "/content/gst.sh",  "172.17.0.1", "5014",  "0"], stdout=subprocess.DEVNULL, stderr=subprocess.STDOUT)
    gst_thread = gstreamer_thread()
    gst_thread.start()
    time.sleep(2)
    cap = ThreadedCap(("udpsrc port="+str(portIn)+" ! application/x-rtp, encoding-name=(string)RAW, sampling=(string)RGB, depth=(string)8, width=(string)"+str(widthIn)+", height=(string)"+str(heightIn)+",framerate=" +
                      str(framerateIn)+"/1 ! rtpvrawdepay ! queue ! videoconvert ! video/x-raw, format=BGR, width="+str(oflowWidthIn)+", height="+str(oflowHeightIn)+" ! appsink"), cv2.CAP_GSTREAMER)  # UDP CAMERA ON JETSON
    print("cap created")
    fourcc = 0xff
    
    cap_send = cv2.VideoCapture(
        "videotestsrc ! video/x-raw,framerate=30/1 ! videoscale ! videoconvert ! appsink", cv2.CAP_GSTREAMER)
    print("cap send created")

    pipeline = "appsrc ! videoconvert ! videoscale ! video/x-raw,width="+widthOut+",height="+heightOut + \
        ",format=RGB,stream-format=RGB-stream ! queue ! rtpvrawpay mtu=65500 ! udpsink host=" + \
        str(ipOut)+" port="+portOut+" sync=false async=true"
    print("pipeline concatenated")
    print(pipeline)

    out_send = cv2.VideoWriter(pipeline, cv2.CAP_GSTREAMER, fourcc, int(
        framerateIn), (int(oflowWidthIn), int(oflowHeightIn)), True)  # 3x3
    print("out send created")
except Exception as e:
    print("error on opening caps: "+str(e))
    exit(0)

if not cap_send.isOpened():
    print("cap send not opened")
    exit(0)
if not out_send.isOpened():
    print("out send not opened")
    exit(0)
#--------------------------------------------------------------------------------------
#poseBuffer = np.zeros((4, 10, 50))
poseBuffer = []
def calcRaiseHands(_poses, _rgb, bump):
    lastScore = 0
    skeletonthresh = 0.01
    confidentPose = []
    poses = []
    for pose in _poses:
        pose = pose[0]
        ls = pose[KeypointType.LEFT_SHOULDER]
        rs = pose[KeypointType.RIGHT_SHOULDER]
        lw = pose[KeypointType.LEFT_ELBOW]
        rw = pose[KeypointType.RIGHT_ELBOW]
        
        lk = pose[KeypointType.LEFT_KNEE].point
        rk = pose[KeypointType.RIGHT_KNEE].point

        if (rk.y < 300 or lk.y < 300):
            continue

        if not (ls.score > 0.1 or rs.score > 0.1 or rw.score > 0.1 or lw.score >0.1):
            continue

        ls = ls.point
        rs = rs.point
        lw = lw.point
        rw = rw.point
          
        print(rk.y)
        if((lw.y - 5 < ls.y) and (rw.y - 5 < rs.y)):
            lw = (int(lw[0]/engine._input_width*_rgb.shape[1]), int(lw[1]/engine._input_height*_rgb.shape[0]))
            rw = (int(rw[0]/engine._input_width*_rgb.shape[1]), int(rw[1]/engine._input_height*_rgb.shape[0]))
            lop = np.average(_rgb[-1+int(lw[1]):2+int(lw[1]), -1+int(lw[0]):2+int(lw[0]),2])
            rop = np.average(_rgb[-1+int(rw[1]):2+int(rw[1]), -1+int(rw[0]):2+int(rw[0]),2])
            if ((rop > 10) and (lop > 10)):
                #print("Hands Up")
                bump+=2
                #SendMessage()
            else:
                 print("OPF", lop, rop)
                 bump= max(bump-1, 0)

    if(bump > 5):
        SendMessage()
        print("HANDS_UP")
        bump = 0
    return bump, confidentPose, poses
#--------------------------------------------------------------------------------------_
def drawDebug(_frame2, _rgb, _poses):
    for pose in _poses:
        if pose.score < 0.1: continue
        #print('\nPose Score: ', pose.score)
        for label, keypoint in pose.keypoints.items():
            cv2.circle(_frame2, (int(keypoint.point[0]/engine._input_width*_frame2.shape[1]), int(keypoint.point[1]/engine._input_height*_frame2.shape[0])), 2, [0, 255, 0])
            #print(label.name, keypoint.point[0], keypoint.point[1], keypoint.score)

    cv2.imshow("IMSk", _frame2)
    cv2.imshow("OF", _rgb)
#--------------------------------------------------------------------------------------_

lastFrame = 0
def opticalFlow():
    if cap.isOpened():
        ret, frame1 = cap.read()
        prvs = cv2.cvtColor(frame1, cv2.COLOR_BGR2GRAY)
        hsv = np.zeros_like(frame1)
        hsv[..., 1] = 255
        _bump = 0
        First = True
        while(True):
            if(cap.isOpened()):
                ret, frame2 = cap.read()
            else:
                print("DEAD")

            cont = np.array_equal(frame2, frame1)
            if np.array_equal(frame2, frame1) and not First:
                gst_thread = gstreamer_thread()
                time.sleep(1)
                gst_thread.start()
                time.sleep(10)
                continue

            First = False
            frame1 = frame2

            s = time.time()
            poses, inference_time = engine.DetectPosesInImage(frame2)
            next = cv2.cvtColor(frame2, cv2.COLOR_BGR2GRAY)
            flow = cv2.calcOpticalFlowFarneback(prvs, next,  # None, 0.5, 3, 15, 3, 5, 1.2, 0)
                                                # options, defaults
                                                None,  # output
                                                0.5,  # pyr_scale, 0.5 , 0.8
                                                3,  # levels, 3 , 10 , 15
                                                # min(frames[0].shape[:2]) // 5,  # winsize, 15 , 6
                                                10,
                                                5,  # iterations, 3 , 10
                                                10,  # poly_n, 5 , 7
                                                1.5,  # poly_sigma, 1.2 , 1.5
                                                cv2.OPTFLOW_FARNEBACK_GAUSSIAN)  # flags, 0 , cv2.OPTFLOW_FARNEBACK_GAUSSIAN

            mag, ang = cv2.cartToPolar(flow[..., 0], flow[..., 1])
            #print(hsv)
            hsv[..., 0] = ang*180/np.pi/2
            #print(hsv)
            hsv[..., 2] = cv2.normalize(mag, None, 0, 255, cv2.NORM_MINMAX)

            rgb = cv2.cvtColor(hsv, cv2.COLOR_HSV2BGR)
            out_send.write(rgb)

            _bump, armLocations, _poses = calcRaiseHands(poses, hsv, _bump)
            drawDebug(frame2, hsv, poses)



            k = cv2.waitKey(10) & 0xff
            if k == 27:  # EXIT
                break
            elif k == ord('s'):  # SCREENSHOT
                cv2.imwrite('opticalfb.png', frame2)
                cv2.imwrite('opticalhsv.png', rgb)
            prvs = next

        cap.release()
        cap_send.release()
        out_send.release()
        cv2.destroyAllWindows()
        exit(0)



def SendMessage():
    interfaces = socket.getaddrinfo(
        host=socket.gethostname(), port=None, family=socket.AF_INET)
    allips = [ip[-1][0] for ip in interfaces]

    msg = b'DHS---EVERYONEFLY---'

    for ip in allips:
        print(f'sending on {ip}')
        #######temp#####
        # ip = '192.168.0.105'
        ip = myIp
        sock = socket.socket(
            socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)  # UDP
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
        sock.bind((ip, 0))
        sock.sendto(msg, ("255.255.255.255", 5007))
        sock.close()

if __name__ == '__main__':
    try:
        opticalFlow()
        exit(0)
    except Exception as e:
        print("error on optical flow: "+str(e))
        exit(0)
