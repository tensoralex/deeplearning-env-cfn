# Deep Learning sandbox Cloud Formation Template
## deeplearning-env-cfn

> Includes 2 variants of DL environment, EFS persistent storage, Spot Instances support. Completely fits under free tier when using t2.micro and less than 5GB of EFS space.

#### Currently has a choice of two environments:
1.	ubuntuBootstrapAMI – Bootstraps environment based on Ubuntu 16.04, Anaconda 2-4.2.0, Cuda 8.0.44, Keras 1.2.2 and Theano
Root volume – 16Gb, Data – EFS mounted under /home/ubuntu/efs
Compatible to run [fast.ai courses](https://github.com/fastai/courses) notebooks.

2.	awsDeepLearningAMI – Amazon Deep Learning AMI 2.2_Jun2017 
Root volume – 50Gb, Data – EFS mounted under /home/ec2-user/efs

Allows to start spot instances. Allows to use user AMIs. In case of custom AMIs – EFS is not mounted automatically and Jupyter password parameter is ignored.
Regions to AMIs mapping:
-	us-east-1  
..- awsDeepLearningAMI: ami-e47723f2
..- ubuntuBootstrapAMI: ami-80861296
-	us-west-2 
..- awsDeepLearningAMI: ami-c6dfb2a6
..- ubuntuBootstrapAMI: ami-efd0428f
-	eu-west-1
..- awsDeepLearningAMI: ami-df0a1ab9
..- ubuntuBootstrapAMI:  ami-a8d2d7ce
