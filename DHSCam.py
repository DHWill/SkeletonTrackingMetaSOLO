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

import sys
import cv2
import numpy as np
from pose_engine import Keypoint, KeypointType, PoseEngine
import time
import threading


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

    def read(self):
        return self.ret, self.frame

    def isOpened(self):
        return self.cap.isOpened()

#--------------------------------------------------------------------------------------_
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
        # python DHSCam.py 5014 192 108 30 192 108 3 3 127.0.0.1 5011
        # exit(0)
    # cap = cv2.VideoCapture("nvarguscamerasrc sensor_id=0 ! video/x-raw(memory:NVMM), width=192, height=108 ! nvvidconv ! video/x-raw, width=192, height=108, framerate=30/1 ! videoconvert ! video/x-raw, format=BGR, width=192, height=108, framerate=30/1 ! appsink", cv2.CAP_GSTREAMER) #CSI CAMERA ON JETSON
    # cap = cv2.VideoCapture("v4l2src device=/dev/video1 ! videoconvert ! videoscale ! queue ! video/x-raw,framerate=30/1,width=192,height=108,format=RGB,stream-format=RGB-stream ! deinterlace ! videoconvert ! video/x-raw, format=(string)BGR ! appsink", cv2.CAP_GSTREAMER) #USB CAMERA ON JETSON
    # cap = cv2.VideoCapture("udpsrc port=5014 ! application/x-rtp, encoding-name=(string)RAW, sampling=(string)RGB, depth=(string)8, width=(string)192, height=(string)108,framerate=30/1 ! rtpvrawdepay ! queue ! videoconvert ! video/x-raw, format=BGR, width=192, height=108 ! appsink", cv2.CAP_GSTREAMER) #UDP CAMERA ON JETSON
    print("TryingCap")
    cap = ThreadedCap(("udpsrc port="+str(portIn)+" ! application/x-rtp, encoding-name=(string)RAW, sampling=(string)RGB, depth=(string)8, width=(string)"+str(widthIn)+", height=(string)"+str(heightIn)+",framerate=" +
                      str(framerateIn)+"/1 ! rtpvrawdepay ! queue ! videoconvert ! video/x-raw, format=BGR, width="+str(oflowWidthIn)+", height="+str(oflowHeightIn)+" ! appsink"), cv2.CAP_GSTREAMER)  # UDP CAMERA ON JETSON
    #cap.set(cv2.CAP_PROP_BUFFERSIZE, 3)
    print("cap created")
    fourcc = 0xff
    # cv2.VideoWriter_fourcc(*'MJPG')
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
def calcRaiseHands(_poses):
    lastScore = 0
    bump = 0
    for pose in _poses:
        if pose.score < 0.1: continue
        for label, keypoint in pose.keypoints.items():
            pass
            #if(label.name == "LEFT_ELBOW"):
            #    _lElbow = keypoint
            #if(label.name == "RIGHT_ELBOW"):
            #    _rElbow = keypoint
            #if(label.name == "LEFT_WRIST"):
            #    _lWrist = keypoint
            #if(label.name == "RIGHT_WRIST"):
            #    _rWrist = keypoint
            #try:
            #    if((_lWrist[0].y < _lElbow[0].y) & (_rWrist[0].y < _rElbow[0].y)):
            #        #print(_lWrist[0].y)
            #        bump += 1
            #except:
            #    pass
    lastScore = pose.score
    if(bump > 3):
        print("BONGO")
        bump = 0
#--------------------------------------------------------------------------------------_
def drawDebug(_frame2, _poses):
    for pose in _poses:
        if pose.score < 0.1: continue
        print('\nPose Score: ', pose.score)
        for label, keypoint in pose.keypoints.items():
            cv2.circle(_frame2, (int(keypoint.point[0]/engine._input_width*_frame2.shape[1]), int(keypoint.point[1]/engine._input_height*_frame2.shape[0])), 2, [0, 255, 0])
            print(label.name, keypoint.point[0], keypoint.point[1], keypoint.score)
            
    cv2.imshow("", _frame2)
#--------------------------------------------------------------------------------------_
def opticalFlow():
    if cap.isOpened():
        ret, frame1 = cap.read()
        prvs = cv2.cvtColor(frame1, cv2.COLOR_BGR2GRAY)
        hsv = np.zeros_like(frame1)
        hsv[..., 1] = 255
        while(cap.isOpened()):
            ret, frame2 = cap.read()
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
            hsv[..., 0] = ang*180/np.pi/2
            hsv[..., 2] = cv2.normalize(mag, None, 0, 255, cv2.NORM_MINMAX)

            rgb = cv2.cvtColor(hsv, cv2.COLOR_HSV2BGR)
            out_send.write(rgb)

            drawDebug(frame2, poses)
            
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


if __name__ == '__main__':
    try:
        opticalFlow()
        exit(0)
    except Exception as e:
        print("error on optical flow: "+str(e))
        exit(0)
