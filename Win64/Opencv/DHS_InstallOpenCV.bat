@echo off

cd C:\dependencies\Win64\Opencv
echo "___1"
python main.py > log.txt
echo "___2"
installOpenCV_modified.bat >> log.txt
echo "___3"
python modifyBatchScripy.py >> log.txt
echo "___4"
finalScript.bat >> log.txt
echo "___5"

set installationPath=C:\dependencies\Win64\Opencv\opencv-master\Installation\x64\vc15\bin
if exist "%installationPath%" (
    echo "path exists"
    if "%PATH:C:\dependencies\Win64\Opencv\opencv-master\Installation\x64\vc15\bin=%"=="%PATH%" (
        echo "*****env path does not contain installation path yet*****"
        echo\
        echo "1- OPEN YOUR SYSTEM ENVIRONMENT VARIABLES"
        echo "2- EDIT THE VAR 'PATH' (AT THE BOTTOM, UNDER SYSTEM VARS)"
        echo "3- ADD THE FOLLOWING LINE (verify if folder exists first):"
        echo %installationPath% 
    ) else (
        echo "env path already set"
    )
) else (
    echo "path does not exist. check that you are trying to install it under C:\dependencies\Win64\Opencv"
)

echo\
set libPath=C:\dependencies\Win64\Opencv\opencv-master\Installation\x64\vc15\staticlib
if exist "%libPath%" (
    echo "path exists"
    if "%OPENCV_DIR%"=="" (
        echo "*****path variable not defined*****"
        echo "1- OPEN YOUR USER ENVIRONMENT VARIABLES"
        echo "2- ADD NEW VAR WITH NAME 'OPENCV_DIR' (AT THE TOP, UNDER USER VARS), AND THE FOLLOWING PATH (verify if folder exists first)"
        echo %libPath%
    ) else (
        echo "path variable is defined"
        echo "if it does not work, make sure path is correct"
        echo "1- OPEN YOUR USER ENVIRONMENT VARIABLES"
        echo "2- ADD NEW VAR WITH NAME 'OPENCV_DIR' (AT THE TOP, UNDER USER VARS), AND THE FOLLOWING VALUE (verify if folder exists first)"
        echo %libPath%
    )
) else (
    echo "path does not exist. check that you are trying to install it under C:\dependencies\Win64\Opencv"
)

echo\
set /p dummyVar="One finished, press enter to exit"