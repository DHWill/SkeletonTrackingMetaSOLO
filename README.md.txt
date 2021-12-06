Overwrite the files in "toAddToContent" in /content/

https://coral.ai/docs/accelerator/get-started/#1-install-the-edge-tpu-runtime

https://coral.ai/software/#pycoral-api

install pyCoral for 3.6 Armv8
python3 -m pip install --extra-index-url https://github.com/google-coral/pycoral/releases/download/v2.0.0/pycoral-2.0.0-cp36-cp36m-linux_aarch64.whl pycoral

install EdgeTPU for Python 3.6 Linux
https://dl.google.com/coral/edgetpu_api/edgetpu-2.14.1-py3-none-any.whl

Make sure the /etc/udev/rules.d is installed for the edgeTPU for permissions (0666)
