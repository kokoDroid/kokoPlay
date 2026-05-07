#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="kokoplay-certilia"
CONTAINER_NAME="kokoplay-certilia"

echo "🔍 Checking Docker..."
command -v docker >/dev/null || { echo "❌ Docker not installed"; exit 1; }

# Allow X11 access
echo "🖥️ Enabling X11 access..."
xhost +local:docker >/dev/null 2>&1 || true

# Create docker group if missing
if ! getent group docker >/dev/null; then
    echo "➕ Creating docker group..."
    sudo groupadd docker
else
    echo "✔ docker group already exists"
fi

# Restart socket (safe even if already running)
sudo systemctl restart docker.socket || true

# Add user to group only if not already in it
if ! id -nG "$USER" | grep -qw docker; then
    echo "➕ Adding $USER to docker group..."
    sudo usermod -aG docker "$USER"
    echo "Applaying new group with log out,please restart this script"
    newgrp docker
else
    echo "✔ $USER already in docker group"
fi

echo "📦 Installing firefox-certilia launcher..."

sudo tee /usr/local/bin/firefox-certilia > /dev/null << 'EOF'
#!/usr/bin/env bash

#CONTAINER_NAME="${CONTAINER_NAME}"
CONTAINER_NAME="kokoplay-certilia"
PROFILE="/tmp/firefox-certilia"
xhost +SI:localuser:\$USER >/dev/null 2>&1


# Ensure container is running
docker start "$CONTAINER_NAME" >/dev/null 2>&1 || true

docker exec "$CONTAINER_NAME" bash -c '
#rm -rf /tmp/firefox-certilia
#mkdir -p /tmp/firefox-certilia
chown -R 1000:1000 /tmp/firefox-certilia
'
docker exec -u 1000:1000 "$CONTAINER_NAME" bash -c '
exec firefox --no-remote --new-instance --profile /tmp/firefox-certilia
'

EOF
sudo chmod +x /usr/local/bin/firefox-certilia

echo "📦 Installing certiliaclient host wrapper..."

sudo tee /usr/local/bin/certiliaclient > /dev/null << EOF
#!/usr/bin/env bash

CONTAINER_NAME="${CONTAINER_NAME}"

# Ensure container is running
docker start "\$CONTAINER_NAME" >/dev/null 2>&1 || true

# Execute real binary inside container

exec docker exec -it "\$CONTAINER_NAME" /usr/bin/certiliaclient "\$@"

EOF

sudo chmod +x /usr/local/bin/certiliaclient
# Apply group without logout
#newgrp docker

# Build image if not exists
if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
    echo "🏗️ Building Docker image..."

    cat > /tmp/Dockerfile.certilia << 'EOF'
FROM debian:latest

ENV DEBIAN_FRONTEND=noninteractive

ARG UID
ARG GID

#RUN apt update && apt upgrade -y

RUN apt-get update && apt-get install -y \
    wget gnupg ca-certificates \
    pcscd libpcsclite1 libpcsclite-dev \
    opensc libnss3-tools libccid \
    p11-kit p11-kit-modules \
    usbutils sudo dbus \
    libgl1 \
    libglu1-mesa \
    libegl1 \
    libopengl0 \
    mesa-utils \
    libasound2 \
    libxcb1 \
    libx11-6 \
    libx11-xcb1 \
    libxcb-cursor0 \
    libxcb-render0 \
    libxcb-shape0 \
    libxcb-xfixes0 \
    libxcb-randr0 \
    libxcb-image0 \
    libxcb-keysyms1 \
    libxcb-icccm4 \
    libxcb-sync1 \
    libxcb-xinerama0 \
    libxkbcommon0 \
    libxkbcommon-x11-0 \
    x11-apps \
    pcsc-tools \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*


RUN wget -O /tmp/firefox.tar.xz \
  "https://download.mozilla.org/?product=firefox-latest&os=linux64&lang=en-US"

RUN tar -xJf /tmp/firefox.tar.xz -C /opt
RUN ln -sf /opt/firefox/firefox /usr/local/bin/firefox

# Brave
#RUN wget -qO- https://brave-browser-apt-release.s3.brave.com/brave-core.asc | gpg --dearmor > /usr/share/keyrings/brave.gpg && \
#    echo "deb [signed-by=/usr/share/keyrings/brave.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" > /etc/apt/sources.list.d/brave.list && \
#    apt-get update && apt-get install -y brave-browser


# Certilia middleware
#RUN wget -O /tmp/certilia.deb https://www.certilia.com/uploads/certiliamiddleware_3_9_8_2_amd64_4ee1c45ac2.deb && \
#    apt-get install -y /tmp/certilia.deb || apt-get -f install -y
RUN wget -O /tmp/certilia.deb https://www.certilia.com/uploads/certiliamiddleware_3_9_8_2_amd64_4ee1c45ac2.deb && \
    apt-get update && \
    apt-get install -y /tmp/certilia.deb || (apt-get -f install -y && apt-get install -y /tmp/certilia.deb)

RUN which certiliaclient || (echo "❌ certiliaclient missing!" && exit 1)

#RUN useradd -m user && echo "user:user" | chpasswd && adduser user sudo


RUN useradd -m user \
 && mkdir -p /home/user \
 && chown -R user:user /home/user

#RUN mkdir -p /run/pcscd \
# && chmod 777 /run/pcscd

COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh
COPY setup.sh /usr/local/bin/setup.sh
RUN chmod +x /usr/local/bin/setup.sh

USER user
WORKDIR /home/user

#COPY setup.sh /home/user/setup.sh
#RUN chmod +x /home/user/setup.sh

#COPY --chmod=0755 setup.sh /home/user/setup.sh
#COPY --chmod=0755 start.sh /home/user/start.sh


#ENTRYPOINT ["/usr/local/bin/start.sh"]

#COPY --chown=user:user --chmod=0755 setup.sh /home/user/setup.sh
#COPY --chown=user:user --chmod=0755 start.sh /home/user/start.sh
#CMD ["/bin/bash", "-c", "/home/user/setup.sh && exec dbus-run-session -- brave-browser"]

#CMD ["/home/user/start.sh"]
CMD ["/usr/local/bin/setup.sh"]
EOF


cat > /tmp/start.sh << 'EOF'
#!/usr/bin/env bash
set -e


echo "🚀 Starting pcscd..."
pcscd --disable-polkit &

sleep 2

echo "📁 Running setup..."
/usr/local/bin/setup.sh
#/home/user/setup.sh



EOF

    cat > /tmp/setup.sh << 'EOF'
#!/usr/bin/env bash
set -e

echo "🚀 Starting pcscd..."
# Stop pcscd cleanly if running
if pgrep -x pcscd >/dev/null; then
    pkill -x pcscd
    echo "⏳ Waiting for pcscd to stop..."
    while pgrep -x pcscd >/dev/null; do
        sleep 0.2
    done
fi

# Clean stale socket ONLY if it exists and no process is using it
if [ -S /run/pcscd/pcscd.comm ]; then
    echo "🧹 Removing stale pcscd socket..."
    rm -f /run/pcscd/pcscd.comm
fi


mkdir -p /run/pcscd
#pcscd --disable-polkit &
pcscd --foreground --disable-polkit &

PCSC_PID=$!

echo "⏳ Waiting for reader..."

for i in {1..30}; do
    if pcsc_scan -n 2>/dev/null | grep -q "Reader"; then
        echo "✔ Reader detected"
        break
    fi
    sleep 1
done


PROFILE="/tmp/firefox-certilia"
PKCS11="/usr/lib/akd/certiliamiddleware/pkcs11/libEidPkcs11.so"
rm -rf "$PROFILE"
mkdir -p "$PROFILE"

# Create NSS DB if missing
if [[ ! -f "$PROFILE/cert9.db" ]]; then
    certutil -N -d sql:"$PROFILE" --empty-password
fi

# Add module only if not already present
if ! modutil -dbdir sql:"$PROFILE" -list | grep -q "Certilia"; then
    echo "📌 Adding Certilia PKCS#11 module..."
    sleep 5
    pkill -x firefox 2>/dev/null || true
    printf '\n' | modutil \
        -dbdir sql:"$PROFILE" \
        -add "Certilia" \
        -libfile "$PKCS11"

    chown -R 1000:1000 /tmp/firefox-certilia
   
else
    echo "✔ Certilia module already registered"
fi

#echo "Starting certilia client"
#/usr/bin/certiliaclient >/dev/null 2>&1 &

echo "✅ Environment ready!"
echo "👉 Insert eID and use Brave."
echo "To run firefox container from host CLI use:firefox-certilia, for certilia client (card reader) use: certiliaclient"
echo "Put card reader with id into usb. Start certilia client, then start firefox"
exec sleep infinity

EOF

    docker build -t "$IMAGE_NAME" -f /tmp/Dockerfile.certilia /tmp  \
                --build-arg UID=`id -u` \
                --build-arg GID=`id -g` \
   #docker build --no-cache -t "$IMAGE_NAME" -f /tmp/Dockerfile.certilia /tmp

fi

# Remove old container if exists
if docker ps -a | grep -q "$CONTAINER_NAME"; then
    echo "♻️ Removing old container..."
    docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
fi

echo "🚀 Starting Certilia environment..."
#  -v $HOME/.pki:/home/user/.pki \
#    -v /run/pcscd:/run/pcscd \
#    -v /run/pcscd/pcscd.comm:/run/pcscd/pcscd.comm \
#    -e PCSCLITE_CSOCK_NAME=/run/pcscd/pcscd.comm \-v /run/user/1000:/run/user/1000
 #   --user root \

#--user $(id -u):$(id -g) \

docker run -it \
    --name "$CONTAINER_NAME" \
    --device=/dev/bus/usb \
    --user root \
    --group-add plugdev \
    --network=host \
    -v /run/user/1000:/run/user/1000 \
    -e DISPLAY=$DISPLAY \
    -e XDG_RUNTIME_DIR=/run/user/1000 \
    -e DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus \
    -v /run/user/1000/bus:/run/user/1000/bus \
    -e QT_QPA_PLATFORM=xcb \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -v $XDG_RUNTIME_DIR:$XDG_RUNTIME_DIR \
    -v /dev/bus/usb:/dev/bus/usb \
    --device-cgroup-rule='c 189:* rmw' \
    --privileged \
    "$IMAGE_NAME"

