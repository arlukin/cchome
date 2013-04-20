#!/bin/sh -x

#
# This script install python 2.7 on CentOS 5.7 in /opt/python27
# It will keep the current (2.4xx) python version and run 2.7 parallell.
#

# Step 1: Verify that you are root
if [ `whoami` != 'root' ]
then
    echo "You need to be root, to run this script."
    exit
fi

# Step 2: Install the necessary libraries in order to compile Python
yum install -y gcc gcc-c++ compat-gcc-34-c++ openssl-devel zlib* tcl-devel tk-devel wget

# Step 3: Download Python
mkdir -p /tmp/python2.7install
cd /tmp/python2.7install
wget http://python.org/ftp/python/2.7.2/Python-2.7.2.tgz
tar -zxvf Python-2.7.2.tgz || { echo 'tar extract failed' ; exit 1; }

# Compile and install
cd Python-2.7.2
./configure --prefix=/opt/python27 --with-threads --enable-shared
make
make install
echo "/opt/python27/lib" > /etc/ld.so.conf.d/python27.conf
/sbin/ldconfig

# Test if it works
/opt/python27/bin/python2.7 -V
