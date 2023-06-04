FROM nginx:latest

# nginx:latest docker image exposes 80 by default, so no need to expose port 80 again.
# Some Paas providers (Back4app) only allow one exposed port, and it has to be port 80.
# Some Paas providers (Codesandbox) prohibit listening on port 80, in such case, use port 8080 instead and
#  delete these lines from nginx.conf: "listen 80;" and "listen [::]:80;"

WORKDIR /app
USER root

COPY supervisor.conf /etc/supervisor/conf.d/supervisord.conf

COPY webpage.html ./template_webpage.html
COPY nginx.conf ./template_nginx.conf
COPY config.json ./template_config.json
COPY client_config.json ./template_client_config.json
COPY entrypoint.sh ./
COPY substitution.sh ./
COPY cfd_refresh.sh ./
COPY monitor.sh ./
COPY mikutap.zip ./

RUN apt-get update && apt-get install -y wget unzip qrencode iproute2 systemctl openssh-server && \
    wget -O cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb && \
    dpkg -i cloudflared.deb && \
    rm -f cloudflared.deb && \
    wget -O temp.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip && \
    unzip temp.zip xray && \
    rm -f temp.zip && \
    chmod -v 755 xray entrypoint.sh

# Configure supervisor
RUN apt-get install -y supervisor && \
    chmod -v 755 xray monitor.sh cfd_refresh.sh

# Configure OpenSSH on port 22 and 2222
RUN apt-get install -y openssh-server && \
    sed -i '1i\Port 2222' /etc/ssh/sshd_config && \
    mkdir -p /run/sshd && \
    mkdir -p /root/.ssh && \
    touch /root/.ssh/authorized_keys && \
    chmod 644 /root/.ssh/authorized_keys

# Configure Dropbear, run along with with OpenSSH on port 2223
RUN apt-get install --no-install-recommends -y dropbear && \
    sed -i 's/^NO_START=.*/NO_START=0/' /etc/default/dropbear && \
    sed -i 's/^DROPBEAR_PORT=.*/DROPBEAR_PORT=2223/' /etc/default/dropbear && \
    sed -i 's/^DROPBEAR_EXTRA_ARGS=.*/DROPBEAR_EXTRA_ARGS="-s -g"/' /etc/default/dropbear

# Uncomment to install official warp client
# RUN wget -O warp.deb https://pkg.cloudflareclient.com/uploads/cloudflare_warp_2023_3_398_1_amd64_002e48d521.deb && \
#    dpkg -i warp.deb || true && \
#    rm -f warp.deb && \
#    apt -y --fix-broken install && \
#    mkdir -p /root/.local/share/warp && \
#    echo "yes" > /root/.local/share/warp/accepted-tos.txt

ENTRYPOINT [ "./entrypoint.sh" ]
