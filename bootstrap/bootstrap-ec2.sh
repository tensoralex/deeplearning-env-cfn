#!/bin/bash -x
source ~/.bashrc
# Based on  https://github.com/fastai/courses/blob/master/setup/install-gpu.sh 
# Integrated with Cloud Formation template

InstanceType=$1
DLImage=$2
custifsid=$4
region=$5
stackname=$6
theanodev=$7

echo
echo "--------------------"
echo Instancetype $InstanceType
echo Imagetype $DLImage
echo custifsid $custifsid
echo Current user `whoami`
echo "--------------------"

export AWS_DEFAULT_REGION=$region

export curuser=`whoami`

if [ "x${DLImage}" == "xubuntuBootstrapAMI" ]; then

sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade

sudo apt-get --assume-yes install tmux build-essential gcc g++ make binutils
sudo apt-get --assume-yes install software-properties-common

# download and install GPU drivers
wget "http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/cuda-repo-ubuntu1604_8.0.44-1_amd64.deb" -O "cuda-repo-ubuntu1604_8.0.44-1_amd64.deb"

sudo dpkg -i cuda-repo-ubuntu1604_8.0.44-1_amd64.deb
sudo apt-get update
sudo apt-get -y install cuda
sudo modprobe nvidia
nvidia-smi

# install Anaconda for current user
mkdir downloads
cd downloads
wget "https://repo.continuum.io/archive/Anaconda2-4.2.0-Linux-x86_64.sh" -O "Anaconda2-4.2.0-Linux-x86_64.sh"
bash "Anaconda2-4.2.0-Linux-x86_64.sh" -b

echo "export PATH=\"$HOME/anaconda2/bin:\$PATH\"" >> ~/.bashrc
export PATH="$HOME/anaconda2/bin:$PATH"
conda install -y bcolz
conda upgrade -y --all

# install and configure theano
pip install theano
echo "[global]
device = "$theanodev"
floatX = float32

[cuda]
root = /usr/local/cuda" > ~/.theanorc

# install and configure keras
pip install keras==1.2.2
mkdir ~/.keras
echo '{
    "image_dim_ordering": "th",
    "epsilon": 1e-07,
    "floatx": "float32",
    "backend": "theano"
}' > ~/.keras/keras.json

# install cudnn libraries
wget "http://files.fast.ai/files/cudnn.tgz" -O "cudnn.tgz"
tar -zxf cudnn.tgz
cd cuda
sudo cp lib64/* /usr/local/cuda/lib64/
sudo cp include/* /usr/local/cuda/include/

pip install awscli

sudo apt-get -y install python-pip
sudo pip install https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-latest.tar.gz

fi

if [ "x${DLImage}" == "xawsDeepLearningAMI" ]; then
	sudo ln -s /opt/aws/bin/cfn-signal /usr/local/bin/cfn-signal
	#sudo pip install -U bcolz
fi


# configure jupyter and prompt for password
jupyter notebook -y --generate-config
jupass=`python -c "from notebook.auth import passwd; print(passwd('$3'))"`
echo "c.NotebookApp.password = u'"$jupass"'" >> $HOME/.jupyter/jupyter_notebook_config.py
echo "c.NotebookApp.ip = '*'
c.NotebookApp.open_browser = False" >> $HOME/.jupyter/jupyter_notebook_config.py


if [ "x${custifsid}" == "xCREATE-NEW-EFS"  ]; then
	#Looking up new EFS filesystem  
	export efsid=`aws efs describe-file-systems --output text --query "FileSystems[?Name=='$stackname'].FileSystemId"`
else
  export efsid=$custifsid
fi


mkdir -p $HOME/efs
echo EFS directory is $HOME/efs

if [ "x${curuser}" == "xubuntu" ]; then
	echo "Installing nfs for ubuntu.."
   sudo apt-get --assume-yes install nfs-common
fi

if [ "x${curuser}" == "xec2-user" ]; then
	echo "Installing nfs for Amazon linux.."
	sudo yum install -y nfs-utils
fi

sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 ${efsid}.efs.${region}.amazonaws.com:/ $HOME/efs

# setting up automount
sudo bash -c 'echo '${efsid}'.efs.'${region}'.amazonaws.com:/ '$HOME'/efs nfs4 rw,relatime,vers=4.1,rsize=1048576,wsize=1048576,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,nofail >> /etc/fstab'

sudo bash -c 'chown -R '$curuser':'$curuser' '$HOME'/efs'
cd $HOME/efs
# clone the fast.ai course repo 

if [ ! -d "courses" ]; then
	echo "Clonning fastai notebookes..."
git clone https://github.com/fastai/courses.git
fi

nohup jupyter notebook &
df -hP