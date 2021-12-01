@echo off
setlocal enabledelayedexpansion

conda update -n base -c defaults conda

::DO_NOT_CHANGE::
::============================================::
set "cvVersion=master"
echo Activating OpenCV-master
::============================================::
echo "Creating python environments"
::create python3 virtual environments
CALL conda create -y -f -n OpenCV-master-py3 python=3.6 anaconda
CALL conda install -y -n OpenCV-master-py3 numpy scipy matplotlib scikit-image scikit-learn ipython
CALL pip install dlib
::============================================::
CALL conda activate OpenCV-master-py3
::////////////////////////////////////////////::
set envsDir=%USERPROFILE%\.conda\envs\OpenCV-master-py3\python.exe\..\..
cd C:\dependencies\Win64\Opencv\opencv-master
CALL pip install pySerial pyqt5 sockets
CALL deactivate
::============================================::
::Copy OpenCV pre compiled release
copy C:\dependencies\Win64\Opencv\opencv-master\opencv\build\lib\python3\Release\cv2.cp36-win_amd64.pyd %USERPROFILE%\anaconda3\envs\OpenCV-master-py3\python.exe\..\..\OpenCV-master-py3\Lib\site-packages\
::xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx::
cd ..
cd ..
cd ..
