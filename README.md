# videolooper-in-raspberry-para-totens

# RaspberryPi VLC_Videolooper

Videolooper baseado em VLC para Raspberry Pi - Debian11

INTRODUÇÃO
Este Videolooper foi projetado para usar a interface de linha de comando do VLC Player, que está incluído na instalação padrão do Raspberry Pi OS, Debian.

Este Videolooper foi testado no Raspberry Pi . Para configurar este Videolooper, siga estas instruções passo a passo. Sinta-se livre para fazer seus próprios ajustes de acordo com suas próprias necessidades.

## 01 - Pré-requisito

Recomendamos que você trabalhe com uma instalação limpa do Raspberry Pi OS com desktop (sem software recomendado, a menos que pretenda usá-lo).

Antes de começar a fazer qualquer outra coisa, você deve fazer login e atualizar sua instalação:

### comando:

sudo apt update && sudo apt upgrade



## 02 - Configurar usuário de estação de trabalho sem privilégios

Frequentemente, usamos este Videolooper em um Raspberry Pi que precisava ser acessado via SSH pela Internet, e é por isso que configuramos uma conta de usuário sem privilégios. Para este guia, usamos uma conta de usuário chamada estação de trabalho para executar nosso script de reprodução automática. Mas primeiro concedemos ao nosso novo usuário também direitos de administrador. Isso facilita a alteração de todas as configurações necessárias, portanto, no futuro, nosso Raspberry Pi fará login automaticamente como estação de trabalho. Revogaremos os direitos de administrador mais tarde.


### comando1:

sudo adduser workstation

### comando2:

sudo usermod -a -G adm,tty,dialout,cdrom,audio,video,plugdev,games,users,input,netdev,gpio,i2c,spi,sudo *workstation*

## obs1: repare que workstation está em negrito, desta forma caso tenha dado outro nome apos o comando sudo adduser lembre-se de repetir esse usuário no lugar do nome em negrito.


Em seguida, faça login em sua nova conta de usuário:


### comando3:
su - workstation

obs: siga a mesma regra da OBS1 ACIMA.

Depois de fazer login, altere as configurações de login automático in  

/etc/lightdm/lightdm.conf:

### Comando4:

sudo nano /etc/lightdm/lightdm.conf

Encontre a linha que diz autologin-user=pi e mude para autologin-user=workstation

crie o seguinte documento no diretorio   /etc/systemd/system/autologin@.service:

### comando5:

sudo nano /etc/systemd/system/autologin@.service

Por fim, para ter certeza absoluta de que seu novo usuário estará logado na inicialização, execute:

sudo raspi-config

Navegue até 1 System Options e selecione Boot / Auto login. Certifique-se de selecionar a estação de trabalho do usuário para fazer login automaticamente na área de trabalho(escolha a opção em que realiza o autologin com a interface grafica, geralmente fica na ultima opção). Observe que o raspi-config está em constante desenvolvimento. A localização do item de menu necessário pode mudar! Em seguida, reinicie seu Raspberry Pi. Agora você deve estar logado em seu ambiente de área de trabalho como estação de trabalho.

conect-se com o usuário administrador com o comando abaixo:

sudo - usuario

***atenção**** substitua o nome usuário acima pelo nome usuário administrador da sua máquina!

feito isso, Para revogar os direitos de administrador da estação de trabalho, execute o seguinte comando:

sudo usermod -a -G adm,tty,dialout,cdrom,audio,video,plugdev,games,users,input,netdev,gpio,i2c,spi ***workstation**

## obs3: repare que workstation está em negrito, desta forma caso tenha dado outro nome apos o comando sudo adduser lembre-se de repetir esse usuário no lugar do nome em negrito.

Reinicie o seu raspberry.

## 03 - Prepare Desktop Environment


O VLC mostra brevemente a área de trabalho quando recarrega o loop da lista de reprodução, e é por isso que queremos ocultar todos os elementos presentes na área de trabalho. Existem várias configurações que você pode alterar:

Clique com o botão direito do mouse na barra de menus superior e altere as configurações para ocultar automaticamente a barra de menus. Altere também seu tamanho para 0px (2px é definido como padrão, que ficará visível como uma linha fina na parte superior da tela)

Clique com o botão direito do mouse na área de trabalho para alterar as configurações da área de trabalho. Selecione nenhum plano de fundo como plano de fundo da área de trabalho e altere a cor do plano de fundo para preto. Oculte também todos os itens visíveis em sua área de trabalho (ou seja, desmarque a opção que mostra a lixeira, drives USB, etc.)
Abra o gerenciador de arquivos e, em suas configurações avançadas, desative todas as notificações pop-up para quando uma unidade USB for inserida

Para ocultar automaticamente o cursor do mouse, faça login na sua conta de administrador e instale o unclutter:
su - (usuario)
sudo apt install unclutter

***atenção**** substitua o nome usuário acima pelo nome usuário administrador da sua máquina!

## 04 - Prepare Pastas e Locais

A maioria das etapas durante a configuração a seguir requer direitos de administrador, e é por isso que você deve permanecer conectado como um usuário administrador. Alguns locais de pastas usados ​​pelo nosso VLC Videolooper não existem após uma nova instalação do Raspberry Pi OS. Precisamos criá-los:

sudo mkdir /home/workstation/Videos/
sudo mkdir /home/workstation/Script
sudo mkdir /media/workstation

***atenção!**  caso não consiga criar diretamente com o comando acima, tente criar pasta por pasta utilizando o mesmo comando mkdir, ou use a função de recursividade -r*

A última pasta será gerada automaticamente assim que você inserir uma unidade USB enquanto estiver conectado como estação de trabalho. Nós apenas criamos esta pasta manualmente para evitar um erro caso você não insira um drive USB antes que o Videolooper seja iniciado pela primeira vez.


## 05 - Configurar Manipulador e Serviço de Dispositivo USB

Precisamos habilitar nosso Videolooper para saber quando um drive USB é inserido. Para fazer isso, primeiro definimos uma nova regra do udev:

### comando:
sudo nano /etc/udev/rules.d/usb_hook.rules

ao abrir o editor de texto insira as informações abaixo:

***ACTION=="add", KERNEL=="sd[a-z][0-9]", TAG+="systemd", ENV{SYSTEMD_WANTS}="usbstick-handler@%k"**

salve e saia do editor.

Agora criamos um serviço systemd, que monitora quando um dispositivo USB é conectado e define o que acontece quando uma unidade USB é inserida.

### comando:

sudo nano /lib/systemd/system/usbstick-handler@.service

insira as seguintes informações:

[Unit]
Description=Mount USB sticks
BindsTo=dev-%i.device
After=dev-%i.device

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/automount /dev/%I

**salve e saia do editor**

O script executado deve ser muito curto, porque nessa configuração o udev mata scripts em execução mais longos que foram iniciados pelo systemd usando essa regra do udev. Se executássemos nosso script de reprodução automática diretamente por meio desse serviço systemd, ele não funcionaria. Assim, criamos esta solução alternativa: usamos o script automount iniciado pelo systemd (quando uma unidade USB é inserida) para modificar um arquivo em nosso disco rígido. Além disso, assistimos a esse arquivo com o inotify (uma ferramenta de monitoramento), que notificará nosso VLC-Videolooper sempre que esse arquivo for modificado.


Primeiro instalamos o inotify:

### comando:

sudo apt install inotify-tools

Em seguida, criamos nosso pequeno script:

### comando:
sudo nano /usr/local/bin/automount

insira as seguintes informações:

#!/bin/bash

export mnt=/home/**workstation**/Script/.mnt
find /dev/sd* | sed -n '1~2!p' | sed ':a;N;$!ba;s/\n/ /g' > "$mnt"



## obs1: repare que workstation está em negrito, desta forma caso tenha dado outro nome apos o comando sudo adduser lembre-se de repetir esse usuário no lugar do nome em negrito.Depois salve o arquivo e saia do editor


O script de montagem automática simplesmente grava o identificador de disco SCSI dos dispositivos USB inseridos em um arquivo de registro temporário (.mnt). Cada vez que um dispositivo USB é inserido, este arquivo é substituído. Não importa o que exatamente o script automount faz com este arquivo, desde que o modifique para que o inotify perceba a modificação.

Finalmente, precisamos tornar este script executável:

### comando:
sudo chmod +x /usr/local/bin/automount

## 06 - Script de reprodução automática do VLC

Agora criamos o script real que usa inotify como gatilho, cria uma lista de reprodução e inicia o VLC para reproduzir o loop. Neste script você pode definir todos os parâmetros e todas as opções que a linha de comando do VLC tem a oferecer. Por exemplo: queremos apenas reproduzir arquivos MP4, MOV e MKV. E se você quiser reproduzir um AVI? Basta editar este script e adicioná-lo à lista de tipos de arquivo que você deseja reproduzir. Talvez você queira girar o vídeo na tela, silenciar o vídeo ou reproduzir uma apresentação de slides de imagens? Aqui você pode adicionar os parâmetros necessários. Existem muitas possibilidades:

### comando

sudo nano /home/***workstation**/Script/autoplay.sh

## obs1: repare que workstation está em negrito, desta forma caso tenha dado outro nome apos o comando sudo adduser lembre-se de repetir esse usuário no lugar do nome em negrito.Depois salve o arquivo e saia do editor.

insira as seguintes informações que estão entre as linhas pontilhadas   ***atenção ## obs1: repare que workstation está em negrito, desta forma caso tenha dado outro nome apos o comando sudo adduser lembre-se de repetir esse usuário no lugar do nome em negrito.Depois salve o arquivo e saia do editor.**:

------------------------------------------------------------------------------------------------

#!/bin/sh

# VLC OPTIONS:
# View all possible options: vlc -H

# Specify file paths and playlist location to be used for playback
export USB=/media/***workstation**
export AUTOPLAY=/home/***workstation**/Videos
export PLAYLIST=/home/***workstation**/Videos/playlist.m3u
export mnt=/home/***workstation**/Script/.mnt

FILETYPES="-name *.mp4 -o -name *.mov -o -name *.mkv"

# Playlist Options

Playlist_Options="-L --started-from-file --one-instance --playlist-enqueue"

#Additional Playlist Options

#      --one-instance, --no-one-instance
#                                 Allow only one running instance
#                                 (default disabled)
#          Allowing only one running instance of VLC can sometimes be useful,
#          for example if you associated VLC with some media types and you don't
#          want a new instance of VLC to be opened each time you open a file in
#          your file manager. This option will allow you to play the file with
#          the already running instance or enqueue it.
#      --playlist-enqueue, --no-playlist-enqueue
#                                 Enqueue items into playlist in one instance
#                                 mode
#                                 (default disabled)
#          When using the one instance only option, enqueue items to playlist
#          and keep playing current item.
#      --random
#                                 Play files randomly

# Output Modules

Video_Output="--gles2 egl_x11 --glconv mmal_converter"
Audio_Output="--stereo-mode 1"

# Interface Options
# Fullscreen, hide title display, decorations, window borders, etc.

Interface_Options="-f --no-video-title-show"

# Some useful Video Filters for Special Occacions:

# Mirror video filter (mirror)
# Splits video in two same parts, like in a mirror
#      --mirror-split {0 (Vertical), 1 (Horizontal)}
#                                 Mirror orientation
#          Defines orientation of the mirror splitting. Can be vertical or horizontal.
#      --mirror-direction {0 (Left to right/Top to bottom), 1 (Right to left/Bottom to top)}

#VLC AUTOMATIC FULLSCREEN LOOP:

# When a USB is plugged in at startup or before the Raspberry Pi is booted, Inotify is not yet ready to notice
# filechanges in the watchfile, which is why we run an see if there are playable files once  at boot and start
# the watch script afterwards:

sleep 10;
echo "#EXTM3U" > "$PLAYLIST";
find "$USB" -type f \( $FILETYPES \)  >> "$PLAYLIST";
find "$AUTOPLAY" -type f \( $FILETYPES \)  >> "$PLAYLIST";
sed -i '/\/\./d' "$PLAYLIST";
sed -i '2,$s/^/file:\/\//' "$PLAYLIST";
sleep 0.1;
if [ "$(wc -l < /home/***workstation**/Videos/playlist.m3u )" != "1" ]; then
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
    if [ "$(wc -l < /home/***workstation**/Videos/playlist.m3u )" != "1" ]; then
        /usr/bin/cvlc -q $Video_Output $Audio_Output $Interface_Options $Playlist_Options "$PLAYLIST"
    fi
done

------------------------------------------------------------------------------------------------------------


### Além disso, este script precisa ser executável,***atenção ## obs1: repare que workstation está em negrito, desta forma caso tenha dado outro nome apos o comando sudo adduser lembre-se de repetir esse usuário no lugar do nome em negrito.Depois salve o arquivo e saia do editor.**:

## comando:

sudo chmod +x /home/***workstation**/Script/autoplay.sh


## 07 - Serviço VLC Autoplay

Por fim, precisamos criar outro serviço systemd que execute nosso VLC Autoplay Script na inicialização:

### comando:

sudo nano /lib/systemd/system/autoplay.service



insira as seguintes informações que estão entre as linhas pontilhadas   ***atenção ## obs1: repare que workstation está em negrito, desta forma caso tenha dado outro nome apos o comando sudo adduser lembre-se de repetir esse usuário no lugar do nome em negrito.Depois salve o arquivo e saia do editor.**:

------------------------------------------------------------------------------------------

[Unit]
Description=Autoplay
After=multi-user.target

[Service]
WorkingDirectory=/home/workstation
User=workstation
Group=workstation
Environment="DISPLAY=:0"
Environment="XAUTHORITY=/home/workstation/.Xauthority"
Environment="XDG_RUNTIME_DIR=/run/user/1001"
ExecStart=/bin/sh /home/workstation/Script/autoplay.sh

[Install]
WantedBy=graphical.target

-----------------------------------------------------------------------------------------------

Verifique novamente se o XDG_RUNTIME_DIR está correto (se não estiver correto, o script será encerrado com um erro). Deve ser 1001.No entanto, se, por exemplo, for 1002, 1003, 104, etc. enquanto você estiver conectado como estação de trabalho, altere  esse numero no escript acima em seu serviço systemd de acordo. Faça login como estação de trabalho:

### comando:

su workstation

### comando:
id -u

o número não é o 1001? então  munde para usuário administrador com o comando:

## su (usuarioadministrador)

execute o seguinte comando novamente:

### comando:

sudo nano /lib/systemd/system/autoplay.service

Procure pela linha :Environment="XDG_RUNTIME_DIR=/run/user/1001"

e faça a alteração do numero de acordo com o valor encontrado pós utilização do comando  id -u, salve e saia do editor.

logue novamente na estação de trabalho

su ***workstation**

e execute o seguintes comandos 1 por 1, pode ser que o 1 comando exija que vc digite a senha, pode digitar caso seja solicitado:

sudo systemctl daemon-reload

sudo systemctl enable autoplay.service

sudo systemctl start autoplay.service


**Se você receber um erro, você pode tentar:**

sudo systemctl reset-failed

se não siga os próximos passos:

## 08 - configuração do app vlc player

abra o VLC PLAYER, clique em tools ou ferramentas, clique em preferencias e em seguida clique no ícone do cone com nome video, na opção saída de vídeo selecione a opção que contenha o nome 11(xcb)  e abaixo escolha a tela que irá apresentar. salve.

acesse o diretório de script com o comando:

### comando:

cd /home/***workstation**/Script

na pasta Script digite:

### comando:

. autoplay.sh 

E dê enter, ***atenção** se atente ao ponto e espaço antes da palavra autoplay.sh, não está errado é exatamente assim que deve executar. isso fara com que vc execute o escript direto da pasta para testar sua funcionalidade

***ATENÇÃO LEMBRE -SE SE COLOCAR O VÍDEO NA PASTA Video do usuário ***workstation**

## 09 - Links e Recursos

Download and install Raspberry Pi OS:
https://www.raspberrypi.org/software/operating-systems/
https://www.raspberrypi.org/software/

Raspberry Pi Security:
https://www.raspberrypi.org/documentation/configuration/security.md
https://raspberrytips.com/security-tips-raspberry-pi/

VLC Command Line:
https://wiki.videolan.org/VLC_command-line_help/
https://wiki.videolan.org/Documentation:Command_line/



## 10 - Licença

Copyright (c) 2023 emesonfreire
Copyright (c) 2022 emesonfreire
Copyright (c) 2021 term7, 


A permissão é concedida, gratuitamente, a qualquer pessoa que obtenha uma cópia deste software e arquivos de documentação associados (o "Software"), para lidar com o Software sem restrições, incluindo, sem limitação, os direitos de usar, copiar, modificar, mesclar , publicar, distribuir, sublicenciar e/ou vender cópias do Software e permitir que as pessoas a quem o Software é fornecido o façam, sujeito às seguintes condições:

O aviso de direitos autorais acima e este aviso de permissão devem ser incluídos em todas as cópias ou partes substanciais do Software.

O SOFTWARE É FORNECIDO "COMO ESTÁ", SEM GARANTIA DE QUALQUER TIPO, EXPRESSA OU IMPLÍCITA, INCLUINDO MAS NÃO SE LIMITANDO ÀS GARANTIAS DE COMERCIABILIDADE, ADEQUAÇÃO A UM DETERMINADO FIM E NÃO VIOLAÇÃO. EM NENHUM CASO OS AUTORES OU DETENTORES DOS DIREITOS AUTORAIS SERÃO RESPONSÁVEIS POR QUALQUER REIVINDICAÇÃO, DANOS OU OUTRA RESPONSABILIDADE, SEJA EM UMA AÇÃO DE CONTRATO, ILÍCITO OU DE OUTRA FORMA, DECORRENTE DE OU EM CONEXÃO COM O SOFTWARE OU O USO OU OUTROS NEGÓCIOS NO PROGRAMAS.
