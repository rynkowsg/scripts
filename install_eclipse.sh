#!/bin/bash

target="eclipse-cpp-kepler-SR1-linux-gtk-x86_64.tar.gz"

#wget -O - http://eclipse.ialto.com/technology/epp/downloads/release/kepler/SR1/${target} | tar -zxvf --directory /opt

tar -zxf ${target} --directory /opt
mv /opt/eclipse /opt/eclipse-cpp
sudo chown -R grzecho:grzecho /opt/eclipse-cpp

sh -c 'cat > /usr/share/applications/'"${target%.tar.gz}.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Eclipse for C/C++
Comment=Eclipse IDE for C/C++ Developers
Icon=/opt/eclipse-cpp/icon.xpm
Exec=/opt/eclipse-cpp/eclipse
Terminal=false
Categories=Development;IDE;Java;
EOF
