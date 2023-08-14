#!/bin/bash
sudo apt update
sudo sed -i 's/#$nrconf{restart} = '"'"'i'"'"';/$nrconf{restart} = '"'"'a'"'"';/g' /etc/needrestart/needrestart.conf

sudo apt install python3-pip python3-dev build-essential libssl-dev libffi-dev python3-setuptools -y

sudo apt install python3-venv -y
git clone https://username:github-token@github.com/username/repo.git
cd notes-deployment
python3 -m venv notesdeploymentenv
source notesdeploymentenv/bin/activate

pip install wheel
pip install gunicorn flask
sudo ufw allow 5000
pip3 install flask_sqlalchemy
pip3 install flask_login
sudo apt-get install build-dep python-psycopg2
pip install psycopg2-binary
python main.py