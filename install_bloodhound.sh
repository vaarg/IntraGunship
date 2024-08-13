#!/bin/bash

sudo apt install -y docker.io
sudo systemctl enable docker --now
sudo usermod -aG docker $USER
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian bookworm stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list 
curl -fsSL https://download.docker.com/linux/debian/gpg |
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo apt update
curl -L https://ghst.ly/getbhce | sudo docker compose -f - up

echo "Yehaaawww"
echo "Now run:"
echo "curl -L https://ghst.ly/getbhce | sudo docker compose -f - up"
