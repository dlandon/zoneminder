#!/bin/bash
#
#
# Script to compile opencv with CUDA support.
#
logger "Compiling opencv with GPU Support" -tEventServer

# install cuda toolkit
logger "Installing cuda toolkit..." -tEventServer
cd ~
wget -q https://developer.nvidia.com/compute/cuda/10.1/Prod/local_installers/cuda-repo-ubuntu1804-10-1-local-10.1.168-418.67_1.0-1_amd64.deb
dpkg -i cuda-repo-ubuntu1804-10-1-local-10.1.168-418.67_1.0-1_amd64.deb
apt-key add /var/cuda-repo-10-1-local-10.1.168-418.67/7fa2af80.pub
apt-get update
apt-get -y upgrade -o Dpkg::Options::="--force-confold"
apt-get -y install cuda-toolkit-10-1
rm -r cuda-repo*

echo "export PATH=/usr/local/cuda/bin:$PATH" >/etc/profile.d/cuda.sh
echo "export LD_LIBRARY_PATH=/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64:/usr/local/lib:$LD_LIBRARY_PATH" >> /etc/profile.d/cuda.sh
echo "export CUDADIR=/usr/local/cuda" >> /etc/profile.d/cuda.sh
echo "export CUDA_HOME=/usr/local/cuda" >> /etc/profile.d/cuda.sh
mv /etc/ld.so.conf.d/cuda-10-1.conf  /etc/ld.so.conf.d/cuda-10-1.conf-orig
echo "/usr/local/cuda/lib64" > /etc/ld.so.conf.d/cuda.conf
ldconfig
logger "Cuda toolkit installed" -tEventServer

# compile opencv with cuda support
logger "Installing cuda support packages..." -tEventServer
apt-get -y install libjpeg-dev libpng-dev libtiff-dev libavcodec-dev libavformat-dev libswscale-dev
apt-get -y install libv4l-dev libxvidcore-dev libx264-dev libgtk-3-dev libatlas-base-dev gfortran
logger "Cuda support packages installed" -tEventServer

# get opencv source
logger "Downloading opencv source..." -tEventServer
cd ~
wget -q -O opencv.zip https://github.com/opencv/opencv/archive/4.2.0.zip
wget -q -O opencv_contrib.zip https://github.com/opencv/opencv_contrib/archive/4.2.0.zip
unzip opencv.zip
unzip opencv_contrib.zip
mv opencv-4.2.0 opencv
mv opencv_contrib-4.2.0 opencv_contrib

cd ~/opencv
mkdir build
cd build
logger "Opencv source downloaded" -tEventServer

# make opencv
logger "Compiling opencv..." -tEventServer

cmake -D CMAKE_BUILD_TYPE=RELEASE \
	-D CMAKE_INSTALL_PREFIX=/usr/local \
	-D INSTALL_PYTHON_EXAMPLES=OFF \
	-D INSTALL_C_EXAMPLES=OFF \
	-D OPENCV_ENABLE_NONFREE=ON \
	-D WITH_CUDA=ON \
	-D WITH_CUDNN=ON \
	-D OPENCV_DNN_CUDA=ON \
	-D ENABLE_FAST_MATH=1 \
	-D CUDA_FAST_MATH=1 \
	-D WITH_CUBLAS=1 \
	-D OPENCV_EXTRA_MODULES_PATH=~/opencv_contrib/modules \
	-D HAVE_opencv_python3=ON \
	-D PYTHON_EXECUTABLE=/usr/bin/python3 \
	-D BUILD_EXAMPLES=OFF ..

make -j$(nproc)
make install
ldconfig
logger "Opencv compiled" -tEventServer

# clean up/remove unnecessary packages
logger "Cleaning up..." -tEventServer
cd ~
rm -r opencv*
apt-get -y remove cuda-toolkit-10-1
apt-get -y remove libjpeg-dev libpng-dev libtiff-dev libavcodec-dev libavformat-dev libswscale-dev
apt-get -y remove libv4l-dev libxvidcore-dev libx264-dev libgtk-3-dev libatlas-base-dev gfortran
apt-get -y autoremove

# add opencv module
pip3 install opencv-contrib-python

logger "Opencv sucessfully compiled" -tEventServer