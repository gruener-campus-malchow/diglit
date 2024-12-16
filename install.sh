#!/usr/bin/env bash
set -eE
trap "echo install failed" ERR

echo "installing packages..."
sudo apt update
sudo apt install -y git lighttpd cmake qtwebengine5-dev

echo "building fbrowser..."
cd $HOME
git clone -q https://github.com/e1z0/Framebuffer-browser.git fb
mkdir fb/build
cd fb/build
cmake .. && make
cd
mkdir -p ~/.config/fbrowser
echo "BACKEND_DEV=fb" > ~/.config/fbrowser/config
echo "KEYBOARD_DEV=event0" >> ~/.config/fbrowser/config

echo "configuring local web server..."
sudo curl -s https://diglit.gcm.schule/diglit3-local -o /var/www/html/index.html
sudo curl -s https://diglit.gcm.schule/cracked-screen.png -o /var/www/html/cracked-screen.png
echo "export const token = 'enter token here'" > ~/diglit-token
sudo ln -s $(pwd)/diglit-token /var/www/html/token.js
sudo chmod o+x $(pwd)
cat << EOF | sudo tee -a /etc/lighttpd/conf-enabled/99-unconfigured.conf > /dev/null
\$HTTP["remoteip"] != "127.0.0.1" {
	url.access-deny = ("")
}
EOF
echo "restarting lighttpd..."
sudo service lighttpd restart

echo "installing diglit3.service..."
cat << EOF > diglit3.sh
#!/usr/bin/bash
cd $HOME/fb
./fbrowser http://127.0.0.1/
EOF
chmod +x diglit3.sh
cat << EOF | sudo tee /lib/systemd/system/diglit3.service > /dev/null
[Unit]
Description=GCM CIS diglit gen3
After=multi-user.target

[Service]
Type=idle
User=$(whoami)
ExecStart=$HOME/diglit3.sh

[Install]
WantedBy=multi-user.target
EOF
sudo chmod 644 /lib/systemd/system/diglit3.service

sudo systemctl daemon-reload
sudo systemctl enable diglit3.service

echo "installing crontab..."
cat << EOF | sudo tee /etc/cron.d/diglit3
0 9 * * * root /usr/bin/curl -s https://diglit.gcm.schule/diglit3-local -o /var/www/html/index.html
1 * * * * root /usr/sbin/service diglit3 restart
2 * * * * root /usr/bin/curl -s https://diglit.gcm.schule/diglit3-cron -o /etc/cron.d/diglit3-events
EOF

echo "configuring boot options..."
sudo sed -i 's/console=tty1/console=tty3 quiet vt.global_cursor_default=0/' /boot/firmware/cmdline.txt

echo "install successful"
