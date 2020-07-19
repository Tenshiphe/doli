# DOLI : DevOps Laboratoire d'Intrusion 
# Image Docker avec Kali, les outils et la configuration
FROM kalilinux/kali-rolling

# Variables
ENV TERM xterm-256color

# Mise à jour du système
RUN apt-get -y update && apt-get -y dist-upgrade && apt-get -y autoremove && apt-get clean

# Installation des outils additionnels
RUN apt-get -y --no-install-recommends install aircrack-ng amap apt-utils beef bsdmainutils burpsuite ca-certificates cewl crackmapexec crunch curl dirb dirbuster dnsenum dnsrecon dnsutils dos2unix enum4linux exploitdb ftp fontconfig gcc git gobuster golang hashcat hping3 hydra iputils-ping john joomscan kpcli libffi-dev make man-db masscan metasploit-framework mimikatz nasm nbtscan ncat netcat-traditional nikto nmap onesixtyone oscanner passing-the-hash patator php powershell powersploit proxychains4 python2 python3 python3-pip python3-setuptools python-dev python-setuptools recon-ng responder ruby-dev samba samdump2 seclists sipvicious smbclient smbmap smtp-user-enum snmp socat sqlmap ssh-audit sslscan tcpdump testssl.sh theharvester tnscmd10g vim wafw00f weevely wfuzz wget whatweb whatweb whois wordlists wpscan yersinia zaproxy zsh

RUN sh -c "$(curl -fsSL https://raw.github.com/tenshiphe/zsh-in-docker/master/zsh-in-docker.sh)" -- \
    -p "git" \
    -p https://github.com/zsh-users/zsh-autosuggestions \
    -p https://github.com/zsh-users/zsh-completions \
    -p https://github.com/zsh-users/zsh-history-substring-search \
    -p https://github.com/zsh-users/zsh-syntax-highlighting \
    -f https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf \
    -f https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf \
    -f https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf \
    -f https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf \
    -c https://raw.githubusercontent.com/Tenshiphe/duc/master/.p10k.zsh

# Configuration des alias
RUN echo "alias ll='ls -la'" >> /root/.zshrc && \
    echo "alias ld='ls -d */'" >> /root/.zshrc && \
    echo "alias pip='python -m pip'" >> /root/.zshrc && \
    echo "alias scan-range='nmap -T5 -n -sn'" >> /root/.zshrc && \
    echo "alias http-server='python3 -m http.server 8080'" >> /root/.zshrc && \
    echo "alias php-server='php -S 127.0.0.1:8080 -t .'" >> /root/.zshrc

# Initialisation de la base Metasploit et démarrage automatique
 RUN service postgresql start && msfdb init && cp /usr/share/metasploit-framework/config/database.yml /root/.msf4

# Exposition des volumes
VOLUME /root /tmp /var/lib/postgresql

# Exposition du LPORT pour shell inversé
EXPOSE 4444

WORKDIR /root
CMD ["/bin/zsh"]
