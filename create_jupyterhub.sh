#!/bin/bash
# install anaconda 

username=sample_username
admin_user=ubuntu
user_group='jupyterhub-user'


sudo apt-get update
sudo -i
wget https://repo.anaconda.com/archive/Anaconda3-2019.07-Linux-x86_64.sh
bash Anaconda3-2019.07-Linux-x86_64.sh -p /opt/anaconda3 -f -b
echo 'export PATH=/opt/anaconda3/bin:$PATH' >> ~/.bash_profile

apt-get -y install python3-pip
apt-get -y install npm nodejs
npm install -g configurable-http-proxy
conda install jupyterhub -y
mkdir /etc/jupyterhub
cd /etc/jupyterhub
jupyterhub --generate-config

# edit config
addgroup $user_group
usermod -a -G $user_group $username


echo "c.JupyterHub.authenticator_class = 'jupyterhub.auth.PAMAuthenticator'
c.PAMAuthenticator.admin_users = set(['$admin_user'])
c.PAMAuthenticator.group_whitelist = set(['$user_group'])" >> jupyterhub_config.py
IP=$(ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
cd /etc/init.d
wget https://gist.githubusercontent.com/lambdalisue/f01c5a65e81100356379/raw/ecf427429f07a6c2d6c5c42198cc58d4e332b425/jupyterhub -O jupyterhub
chmod +x /etc/init.d/jupyterhub

echo "
[Unit]
Description=Jupyterhub
After=syslog.target network.target

[Service]
User=root
Environment="PATH=/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/opt/anaconda3/bin"
ExecStart=/opt/anaconda3/bin/jupyterhub -f /etc/jupyterhub/jupyterhub_config.py

[Install]
WantedBy=multi-user.target
" >> /etc/systemd/system/jupyterhub.service
systemctl daemon-reload
systemctl enable jupyterhub
systemctl start jupyterhub

# environment setup
conda init bash
conda create -p /mnt/conda_env/delwp -y
# need to add group write permission to pkgs under conda install and conda_env
