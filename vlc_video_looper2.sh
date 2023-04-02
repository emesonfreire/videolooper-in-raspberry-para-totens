#!/bin/bash

# Obter nome do novo usuário
read -p "user" USERNAME
# Obter senha do novo usuário
read -p "1234" PASSWORD

# Define a senha do usuário recém-criado
echo "$USERNAME:$PASSWORD" | sudo chpasswd

# Troca para o novo usuário e define a senha

su $USERNAME -c "echo '$PASSWORD' | passwd --stdin $USERNAME"

sudo usermod -a -G adm,tty,dialout,cdrom,audio,video,plugdev,games,users,input,netdev,gpio,i2c,spi workstation

#Para ocultar automaticamente o cursor do mouse, faça login na sua conta de administrador e instale o unclutter:

sudo apt install unclutter -y

# Cria o diretório Videos em /home/workstation/
sudo mkdir /home/workstation/Videos/

# Cria o diretório Script em /home/workstation/
sudo mkdir /home/workstation/Script/

# Cria o diretório workstation em /media/
sudo mkdir /media/workstation

## 05 - Configurar Manipulador e Serviço de Dispositivo USB

#Precisamos habilitar nosso Videolooper para saber quando um drive USB é inserido. Para fazer isso, primeiro definimos uma nova regra do udev:

#!/bin/bash

# Define o conteúdo do arquivo em uma variável
conteudo='ACTION=="add", KERNEL=="sd[a-z][0-9]", TAG+="systemd", ENV{SYSTEMD_WANTS}="usbstick-handler@%k"'

# Cria o arquivo usb_hook.rules em /etc/udev/rules.d/ e escreve o conteúdo especificado
echo $conteudo | sudo tee /etc/udev/rules.d/usb_hook.rules > /dev/null


#Agora criamos um serviço systemd, que monitora quando um dispositivo USB é conectado e define o que acontece quando uma unidade USB é inserida.

# Define o conteúdo do arquivo em uma variável
conteudo='[Unit]
Description=Mount USB sticks
BindsTo=dev-%i.device
After=dev-%i.device

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/automount /dev/%I'

# Cria o arquivo usbstick-handler@.service em /lib/systemd/system/ e escreve o conteúdo especificado
echo $conteudo | sudo tee /lib/systemd/system/usbstick-handler@.service > /dev/null

# Verifica se o inotify-tools já está instalado
if dpkg -s inotify-tools >/dev/null 2>&1; then
  echo "inotify-tools já está instalado!"
  exit 0
fi

# Instala o inotify-tools
sudo apt-get update
sudo apt-get install -y inotify-tools

echo "inotify-tools instalado com sucesso!"
exit 0

# Criar script para automontagem
sudo echo -e '#!/bin/bash\n\nexport mnt=/home/workstation/Script/.mnt\nfind /dev/sd* | sed -n "1~2!p" | sed ":a;N;\$!ba;s/\\n/ /g" > "$mnt"' | sudo tee /usr/local/bin/automount

# Dar permissão de execução ao script
sudo chmod +x /usr/local/bin/automount

## 06 - Script de reprodução automática do VLC

echo $conteudo | sudo tee /home/workstation/Script/autoplay.sh > /dev/null

conteudo='#!/bin/bash



# Specify file paths and playlist location to be used for playback
export USB=/media/workstation
export AUTOPLAY=/home/workstation/Videos
export PLAYLIST=/home/workstation/Videos/playlist.m3u
export mnt=/home/workstation/Script/.mnt

FILETYPES="-name *.mp4 -o -name *.mov -o -name *.mkv"

# Playlist Options
Playlist_Options="-L --loop --started-from-file --one-instance --playlist-enqueue --no-random"

# Output Modules
Video_Output="--gles2 egl_x11 --glconv mmal_converter"
Audio_Output="--stereo-mode 1"

# Interface Options
Interface_Options="-f --no-video-title-show"

# VLC AUTOMATIC FULLSCREEN LOOP:

# When a USB is plugged in at startup or before the Raspberry Pi is booted, Inotify is not yet ready to notice
# file changes in the watchfile, which is why we run an see if there are playable files once at boot and start
# the watch script afterwards:

sleep 10;
echo "#EXTM3U" > "$PLAYLIST";
find "$USB" -type f \( $FILETYPES \)  >> "$PLAYLIST";
find "$AUTOPLAY" -type f \( $FILETYPES \)  >> "$PLAYLIST";
sed -i '/\/\./d' "$PLAYLIST";
sed -i '2,$s/^/file:\/\//' "$PLAYLIST";
sleep 0.1;
if [ "$(wc -l < /home/workstation/Videos/playlist.m3u )" != "1" ]; then
    /usr/bin/cvlc -q $Video_Output $Audio_Output $Interface_Options $Playlist_Options "$PLAYLIST"
fi


# Start WatchScript:

while /usr/bin/inotifywait -e modify "$mnt"; do
    sleep 10;
    echo "#EXTM3U" > "$PLAYLIST";
    find "$USB" -type f \( $FILETYPES \)  >> "$PLAYLIST";
    find "$AUTOPLAY" -type f \( $FILETYPES \)  >> "$PLAYLIST";
    sed -i '/\/\./d' "$PLAYLIST";
    sed -i '2,$s/^/file:\/\//' "$PLAYLIST";
    sleep 0.1;
    if [ "$(wc -l < /home/workstation/Videos/playlist.m3u )" != "1" ]; then
        /usr/bin/cvlc -q $Video_Output $Audio_Output $Interface_Options $Playlist_Options "$PLAYLIST"
    fi
done'


# Salvar e sair do nano
echo -e '\x1B:wq\n'

sudo chmod +x /home/workstation/Script/autoplay.sh

# Troca para o novo usuário e define a senha

su $USERNAME -c "echo '$PASSWORD' | passwd --stdin $USERNAME"


#Por fim, precisamos criar outro serviço systemd que execute nosso VLC Autoplay Script na inicialização:

# Define o conteúdo do arquivo de serviço
SERVICE_FILE_CONTENT="[Unit]
Description=Autoplay
After=multi-user.target

[Service]
WorkingDirectory=/home/workstation
User=workstation
Group=workstation
Environment=\"DISPLAY=:0\"
Environment=\"XAUTHORITY=/home/workstation/.Xauthority\"
Environment=\"XDG_RUNTIME_DIR=/run/user/1001\"
ExecStart=/bin/sh /home/workstation/Script/autoplay.sh

[Install]
WantedBy=graphical.target"

# Cria o arquivo de serviço
echo "$SERVICE_FILE_CONTENT" > /lib/systemd/system/autoplay.service

sudo systemctl daemon-reload

sudo systemctl enable autoplay.service

sudo systemctl start autoplay.service

reboot