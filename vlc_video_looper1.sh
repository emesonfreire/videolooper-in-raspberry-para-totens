#!/bin/bash


# atualiza o sistema
sudo apt update && sudo apt upgrade



# Obter nome do novo usuário
read -p "workstation" USERNAME

# Cria o usuário
sudo useradd -m $USERNAME

# Obter senha do novo usuário
read -p "1234" PASSWORD

# Define a senha do usuário recém-criado
echo "$USERNAME:$PASSWORD" | sudo chpasswd


# concedendo direitos d administrador

sudo usermod -a -G adm,tty,dialout,cdrom,audio,video,plugdev,games,users,input,netdev,gpio,i2c,spi,sudo workstation

#Em seguida, faça login em sua nova conta de usuário:

# Troca para o novo usuário e define a senha

su $USERNAME -c "echo '$PASSWORD' | passwd --stdin $USERNAME"

#Depois de fazer login, altere as configurações de login automático in  

#/etc/lightdm/lightdm.conf:

sudo sed -i 's/^autologin-user=.*/autologin-user=workstation/' /etc/lightdm/lightdm.conf

# Cria o arquivo e escreve o conteúdo neleno diretorio  /etc/systemd/system/autologin@.service

sudo bash -c "echo '[Service]' > /etc/systemd/system/autologin@.service"
sudo bash -c "echo 'ExecStart=-/sbin/agetty --autologin workstation --noclear %I $TERM' >> /etc/systemd/system/autologin@.service"

#Por fim, para ter certeza absoluta de que seu novo usuário estará logado na inicialização, execute:

# Executa o raspi-config
spawn sudo raspi-config

# Espera até que o menu principal seja exibido
expect "Raspberry Pi Software Configuration Tool (raspi-config)"

# Seleciona a opção "1 System Options"
send -- "1\r"
expect "System Options"

# Seleciona a opção "S5 Boot / Auto Login"
send -- "S5\r"
expect "Boot / Auto Login"

# Seleciona a opção "B2 Console Autologin"
send -- "B2\r"
expect "Console Autologin"

# Seleciona a opção "B4 Desktop Autologin"
send -- "B4\r"
expect "Desktop Autologin"

# Seleciona a estação de trabalho do usuário para fazer login automático na área de trabalho
send -- "workstation\r"
expect "Desktop Autologin"

# Sai do raspi-config
send -- "\r"
expect eof

# Executa o reboot
spawn sudo reboot
expect "Broadcast message from root@"


