#!/bin/bash

# Version bêta testée sur ubuntu et debian server vps Ovh
# à tester sur kimsufi et autres hébergeurs

##################################################
#     variables install paquets Ubuntu/Debian
##################################################  

#  Debian

paquetsWebD="mc aptitude apache2 apache2-utils autoconf build-essential ca-certificates comerr-dev curl cfv dtach htop irssi libapache2-mod-php5 libcloog-ppl-dev libcppunit-dev libcurl3 libcurl4-openssl-dev libncurses5-dev libterm-readline-gnu-perl libsigc++-2.0-dev libperl-dev libssl-dev libtool libxml2-dev ncurses-base ncurses-term ntp openssl patch pkg-config php5 php5-cli php5-dev php5-fpm php5-curl php5-geoip php5-mcrypt php5-xmlrpc pkg-config python-scgi screen ssl-cert subversion texinfo unrar-free unzip zlib1g-dev"

paquetsRtoD="xmlrpc-api-utils libtorrent14 rtorrent"

sourceMediaD="deb http://www.deb-multimedia.org jessie main non-free"
paquetsMediaD="mediainfo ffmpeg"

upDebWebMinD="http://prdownloads.sourceforge.net/webadmin/webmin_1.830_all.deb"
paquetWebMinD="perl libnet-ssleay-perl openssl libauthen-pam-perl libpam-runtime libio-pty-perl apt-show-versions python"
debWebMinD="webmin_1.830_all.deb"

# Ubuntu

paquetsWebU="mc aptitude apache2 apache2-utils autoconf build-essential ca-certificates comerr-dev curl cfv dtach htop irssi libapache2-mod-php7.0 libcloog-ppl-dev libcppunit-dev libcurl3 libcurl4-openssl-dev libncurses5-dev libterm-readline-gnu-perl libsigc++-2.0-dev libperl-dev libssl-dev libtool libxml2-dev ncurses-base ncurses-term ntp openssl patch pkg-config php7.0 php7.0-cli php7.0-dev php7.0-fpm php7.0-curl php-geoip php7.0-mcrypt php7.0-xmlrpc pkg-config python-scgi screen ssl-cert subversion texinfo unrar-free unzip zlib1g-dev"

paquetsRtoU="xmlrpc-api-utils libtorrent19 rtorrent"

paquetsMediaU="mediainfo ffmpeg"

upDebWebMinU="http://www.webmin.com/download/deb/webmin-current.deb"
debWebMinU="webmin-current.deb"


#############################
#       Fonctions
#############################


__verifSaisie() {
if [[ $1 =~ ^[a-zA-Z0-9]{2,15}$ ]]; then
	yno="o"
else 	echo "Uniquement des caractères alphanumériques"
	echo "Entre 2 et 15 caractères"
	yno="n"
fi
}



__ouinon() {
tmp=""
until [[ $tmp == "ok" ]]; do
echo
echo -n "Voulez-vous continuer ? (o/n) "; read yno
case $yno in
	[nN] | [nN][oO][nN])
		echo "Désolé, à bientôt !"
		sed -i "s/$userLinux ALL=(ALL) NOPASSWD:ALL/$userLinux ALL=(ALL:ALL) ALL/" /etc/sudoers
		if [ -e /var/www/html/info.php ]; then rm /var/www/html/info.php; fi
		exit 1
	;;
	[Oo] | [Oo][Uu][Ii])
		echo "On continu !"
		tmp="ok"
		sleep 1
	;;
	*)
		echo "Entrée invalide"
		sleep 1
	;;
esac
done
}    #  fin __ouinon(

__serviceapache2restart() {
service apache2 restart
if [ $? != 0 ]
then
	echo "Il y a un problème de configuration avec apache2"
	service apache2 status
	echo "Régler le problème et relancer le script"
	echo "Google est votre ami  !"
	__ouinon
fi
}   #  fin __serviceapache2restart()

__creauser() {
echo
tmp=""; tmp2=""
until [[ $tmp == "ok" ]]; do
	echo -n "Choisir un nom d'utilisateur linux (ni espace ni \) : "
	read userLinux
	__verifSaisie $userLinux
	if [[ $yno == "o" ]]; then
		egrep "^$userLinux" /etc/passwd >/dev/null
		if [[ $? -eq 0 ]]; then
			echo "$userLinux existe déjà, choisir un autre nom"
			yno="N"
		else
			echo -n "Vous confirmez '$userLinux' comme nom d'utilisateur ? (o/n) "
			read yno
		fi
	fi
	case $yno in
		[Oo] | [Oo][Uu][Ii])   # création d'un utilisateur
			until [[ $tmp2 == "ok" ]]; do
				echo -n "Choisissez un mot de passe (ni espace ni \) : "
				read pwLinux
				echo -n "Resaisissez ce mot de passe : "
				read pwLinux2
				case $pwLinux2 in
					$pwLinux)
						#  créer l'utilisateur $userlinux
						pass=$(perl -e 'print crypt($ARGV[0], "pwLinux")' $pwLinux)
						useradd -m -G adm,dip,plugdev,www-data,sudo,cdrom -p $pass $userLinux
						echo "bash" >> /home/$userLinux/.profile
						echo $userLinux > $repLance/pass1
						if [[ $? -ne 0 ]]; then
							echo "Impossible de créer un utilisateur linux"
							__ouinon
						fi
						tmp2="ok"; tmp="ok"
					;;
					*)
						echo "Les deux saisies du mot de passe ne sont pas identiques. Recommencez"
						echo
						sleep 1
					;;
				esac
			done  # fin création d'un utilisateur
		;;
		[nN] | [nN][oO][nN])
			echo "Nom d'utilisateur invalidé. Reprendre la saisie"
			sleep 1
		;;
		*)
			echo "Entrée invalide"
			sleep 1
			;;
	esac
done
}  # __creauser

__erreurApt() {
	echo; echo "Une erreur c'est produite durant l'installation des paquets."
	__messageErreur
}   #  fin __erreurApt()

__messageErreur() {
	echo; echo "Consulter le wiki"
	echo "https://github.com/Patlol/Handy-Install-Web-Server-ruTorrent-/wiki/Si-quelque-chose-se-passe-mal"
	echo; echo "puis continuer/arrêter l'installation"
	__ouinon
}  # fin __messageErreur

#############################
#     Début du script
#############################


# root ?

if [[ $(id -u) -ne 0 ]]; then
	echo
	echo "Ce script nécessite d'être exécuté avec sudo."
	echo
	echo "id : "`id`
	echo
	exit 1
fi

# info système

lsb_release &> /dev/null
if [ $? -ne 0 ]; then
	apt-get install -y lsb-release
	__erreurApt
fi

repLance=$(echo `pwd`)
arch=$(uname -m)
interface=ifconfig | grep "Ethernet" | awk -F" " '{ print $1 }'  # pas tjs eth0 ...
IP=$(ifconfig $interface 2>/dev/null | grep 'inet ad' | awk -F: '{ printf $2 }' | awk '{ printf $1 }')  
distrib=$(cat /etc/issue | awk -F"\\" '{ print $1 }')
nameDistrib=$(lsb_release -si)  # Debian ou Ubuntu
os_version=$(lsb_release -sr)   # 18 , 8.041 ...
os_version_M=$(echo $os_version | awk -F"." '{ print $1 }' | awk -F"," '{ print $1 }')  # version majeur
description=$(lsb_release -sd)     #  nom de code
user=$(id -un)       #  root avec user sudo 
loguser=$(logname)   #  user avec user sudo

# ubuntu / debian et bonne version ?

if [ $nameDistrib == "Debian" -a $os_version_M -gt 8 -o $nameDistrib == "Ubuntu" -a $os_version_M -gt 16 ]; then
	echo
	echo "Vous utilisez $description"
	echo
	echo "Ce script est prévu pour fonctionner sur un serveur Debian 8.xx ou Ubuntu 16.xx"
	echo "Vous risquez d'avoir des problèmes de version à l'installation"
	__ouinon
fi

if [ $nameDistrib == "Debian" -a $os_version_M -lt 8 -o $nameDistrib == "Ubuntu" -a $os_version_M -lt 16 ]; then
	echo
	echo "Vous utilisez $description"
	echo
	echo "Ce script fonctionne sur un serveur Debian 8.xx ou Ubuntu 16.xx"
	echo
	exit 1
fi

if [ $nameDistrib != "Debian" -a $nameDistrib != "Ubuntu" ]; then
	echo
	echo "Vous utilisez $description"
	echo
	echo "Ce script fonctionne sur un serveur Debian 8.xx ou Ubuntu 16.xx !!!"
	echo
	exit 1
fi


# espace dispo

homeDispo=$(df -h | grep /home | awk -F" " '{ print $4 }')
rootDispo=$(df -h | grep  /$ | awk -F" " '{ print $4 }')

# portSSH aléatoire

RANDOM=$$  # N° processus du script
portSSH=0   #   initialise 20000 65535
PLANCHER=20000
ECHELLE=65534
while [ "$portSSH" -le $PLANCHER ]
do
  portSSH=$RANDOM
  let "portSSH %= $ECHELLE"  # Ramène $portSSH dans $ECHELLE.
done

#--------------------------------------------------------------



#############################
#    Partie interactive
#    ID, PW, questions
#############################

echo
clear
echo "***********************************************"
echo "|  Récupération des informations nécessaires  |"
echo "|             aux installations               |"
echo "***********************************************"
echo
echo "Distribution : "$description
echo "Architecture : "$arch
if [[ $arch != "x86_64" ]]
then
	echo "Vous n'êtes pas en 64 bits ???"
	echo "------------------------------"
	echo "Est-ce normal, avez-vous installé la bonne version de l'OS ?"
fi
echo "Votre IP : "$IP
echo "Vous êtes logué en : "$loguser
echo
echo "Durée du script : environ 10mn"
#----------------------------------------------------------
# vérif place sur disque

echo
echo
echo "Place disponible sur les partitions du disques"
echo

if [ -z "$homeDispo" ]  # /
then
	echo "Vous n'avez pas de partition /home."
	echo "Votre partition root (/) a "$rootDispo" de libre."
	len=${#rootDispo}
	entier=${rootDispo:0:len-1}
	entier=$(echo $entier | awk -F"." '{ print $1 }' | awk -F"," '{ print $1 }')
	miniDispo=319
 	if [ "$entier" -lt "$miniDispo" ]
 	then
		echo
		echo
		echo "*************************************************************************************"
		echo "|                                                                                   |"
		echo "|    ATTENTION seulement "$rootDispo", pour stocker les fichiers téléchargés !      |"
		echo "|                                                                                   |"
		echo "*************************************************************************************"
	fi
else  # /home
	echo "Votre partition /home a $homeDispo de libre."
	len=${#homeDispo}
	entier=${homeDispo:0:len-1}
	entier=$(echo $entier | awk -F"." '{ print $1 }' | awk -F"," '{ print $1 }')	
	miniDispo=299
 	if [ "$entier" -lt "$miniDispo" ]
 	then
		echo "************************************************************************************"
		echo "|                                                                                  |"
		echo "|    ATTENTION seulement "$homeDispo", pour stocker les fichiers téléchargés !     |"
		echo "|                                                                                  |"
		echo "************************************************************************************"		
	fi
fi

echo
echo
echo "*******************************************************************************"
echo "|                                                                             |"
echo "|                                ATTENTION !!!                                |"
echo "|                                                                             |"
echo "|        L'utilisation de ce script doit se faire sur un serveur nu,          |"
echo "|                    tel que livré par votre hébergeur.                       |"
echo "|    Une installation quelconque risque d'être endommagée par ce script !!!   |"
echo "|         Ne jamais exécuter ce script sur un serveur en production           |"
echo "|                                                                             |"
echo "*******************************************************************************"

if [ ! -e $repLance"/pass1" ]; then   # évite ce passage si 2éme passe
	tmp=""
	until [[ $tmp == "ok" ]]; do
		echo
		echo -n "Voulez-vous continuer l'installation ? (o/n) "
		read yno

		case $yno in
			[nN] | [nN][oO][nN])
				echo "Au revoir, a bientôt."
				exit 0
			;;
			[Oo] | [Oo][Uu][Ii])
				echo "Allons-y !"
				tmp="ok"
			;;
			*)
				echo "Entrée invalide"
				sleep 1
			;;
		esac
	done

#------------------------------------------------

# linux user

	echo
	if [[ $loguser != "root" ]]; then
		echo "Vous avez lancé le script depuis $loguser avec 'sudo'"
	else
		echo "Vous avez lancé le script depuis root"
	fi
	echo "Vous allez devoir créer un utilisateur spécifique"
	echo
	__creauser
	echo "A bientôt ! avec"
	echo "'login $userLinux'"
	echo "'cd $repLance'"
	echo "'sudo ./`basename $0`'"
	chmod u+rwx,g+rx,o+rx $0			
	exit 0
else
	userLinux=$(cat pass1)
	if [[ $userLinux != $loguser ]]; then
		echo
		echo "Vous êtes logué avec $loguser"		
		echo "Vous deviez lancer le script en étant logué avec $userLinux !"
		echo "'sudo login $userLinux'"
		echo "'cd $repLance'"
		echo "'sudo ./`basename $0`'"
		exit 1
	fi
fi   # fin de évite ce passage si 2éme passe

# Rutorrent user

echo
echo
echo "Utilisateur ruTorrent"
tmp=""; tmp2=""
until [[ $tmp == "ok" ]]; do
	echo
	echo "Il est préférable de choisir un nom différent de celui de l'utilisateur Linux"
	echo -n "Choisir un nom d'utilisateur ruTorrent (ni espace ni \) : "
	read userRuto
	__verifSaisie $userRuto
	if [[ $yno == "o" ]]; then
		echo -n "Vous confirmez '$userRuto' comme nom d'utilisateur ? (o/n) "
		read yno
	fi
	case $yno in
		[Oo] | [Oo][Uu][Ii])
			until [[ $tmp2 == "ok" ]]; do
				echo -n "Choisissez un mot de passe (ni espace ni \) : "
				read pwRuto
				echo -n "Resaisissez ce mot de passe : "
				read pwRuto2
				case $pwRuto2 in
					$pwRuto)
						tmp="ok"; tmp2="ok"
					;;
					*)
						echo "Les deux saisies du mot de passe ne sont pas identiques. Recommencez"
						echo
						sleep 1
					;;
				esac
			done
		;;
		[nN] | [nN][oO][nN])
			echo "Nom d'utilisateur invalidé. Reprendre la saisie"
			sleep 1
		;;
		*)
			echo "Entrée invalide"
			sleep 1
		;;
	esac
done

#  cakebox

echo
echo
echo "Cakebox"
echo "Cakebox vous permettra, sur une interface graphique"
echo "web, de streamer, naviguer et partager vos films"
echo "depuis la seedbox, sans les télécharger sur votre PC."
echo "Pour plus d'infos https://github.com/cakebox/cakebox"
tmp=""; tmp2=""; tmp3=""
until [[ $tmp3 == "ok" ]]; do
	echo
	echo -n "Souhaitez-vous insaller Cakebox ? (o/n) "
	read yno
	case $yno in
		[nN] | [nN][oO][nN])
			echo "Ok on continu"
			tmp3="ok"
			installCake="non"
		;;
		[Oo] | [Oo][Uu][Ii])
			until [[ $tmp == "ok" ]]; do
				echo
				echo "Choisir un nom d'utilisateur Cakebox"
				echo -n "(peut-être le même que pour rutorrent) (ni espace ni \) : "
				read userCake
				__verifSaisie $userCake
				yno1=$yno
				if [[ $yno1 == "o" ]]; then
					echo -n "Vous confirmez '$userCake' comme nom d'utilisateur ? (o/n) "
					read yno1
				fi
				case $yno1 in
					[Oo] | [Oo][Uu][Ii])
						until [[ $tmp2 == "ok" ]]; do
							echo -n "Choisissez un mot de passe (ni espace ni \) : "
							read pwCake
							echo -n "Resaisissez ce mot de passe : "
							read pwCake2
							case $pwCake2 in
								$pwCake)
									installCake="oui"
									tmp="ok"; tmp2="ok"; tmp3="ok"
								;;
								*)
									echo "Les deux saisies du mot de passe ne sont pas identiques. Recommencez"
									echo
									sleep 1
								;;
							esac # pwCake
						done # tmp2
					;;
					[nN] | [nN][oO][nN])
						echo "Nom d'utilisateur invalidé. Reprendre la saisie"
						sleep 1
					;;
					*)
						echo "Entrée invalide"
						sleep 1
					;;
				esac # yno1
			done # tmp
		;;
		*)
			echo "Entrée invalide"
			sleep 1
		;;
	esac # yno
done  # tmp3


#  webmin

echo
echo
echo "WebMin"
echo
echo "WebMin vous permettra d'effectuer la plus-part"
echo "des taches d'administration de votre serveur sur une"
echo "interface graphique web. Pour plus d'infos http://www.webmin.com/"
tmp=""
until [[ $tmp == "ok" ]]; do
	echo
	echo -n "Souhaitez-vous insaller WebMin ? (o/n) "
	read yno
	case $yno in
		[nN] | [nN][oO][nN])
			echo "Ok on continu"
			tmp="ok"
			installWebMin="non"
			sleep 1
		;;
		[Oo] | [Oo][Uu][Ii])
			installWebMin="oui"
			tmp="ok"
			sleep 1
		;;
		*)
			echo "Entrée invalide"
			sleep 1
		;;
	esac # yno
done  # tmp


# port ssh

echo
echo
echo "Dans le but de sécuriser SSH et SFTP il est proposé"
echo "de changer le port standard (22) et d'interdire root"
echo "c'est une mesure de sécurité fortement recommandée."
echo "L'utilisateur sera $userLinux et un port aléatoire"
echo "ou désigné par vous."
echo
tmp=""; port=0
until [[ $tmp == "ok" ]]; do
echo
echo -n "Souhaitez-vous appliquer cette modification ? (o/n) "; read yno
case $yno in
	[nN] | [nN][oO][nN])
		echo
		echo "Le port reste 22 et l'utilisateur root"
		changePort="non"
		portSSH="22"
		tmp="ok"
		sleep 2
	;;
	[Oo] | [Oo][Uu][Ii])
		echo
		echo "L'utilisateur sera $userLinux"
		echo "Le port aléatoire proposé est $portSSH"
		echo "Souhaitez-vous un autre port (entre 20000 65535)"
		echo -n "Si oui saisissez le ici "; read port
		if [[ $port -eq 0 ]]; then
			tmp="ok"
			changePort="oui"
			sleep 1	
		elif [ $port -gt 65535 -o $port -lt 20000 ]; then
				echo "entrée invalide (entre 20000 et 65535)"
				sleep 2
			else
				changePort="oui"
				portSSH=$port
				tmp="ok"
				sleep 1	
		fi
	;;
	*)
		echo
		echo "Entrée invalide"
		sleep 1
	;;
esac
done  #  fin port ssh


#  Récapitulation

clear
echo "*************************************************"
echo "|  Récapitulation des informations nécessaires  |"
echo "|              aux installations                |"
echo "*************************************************"
echo
echo "Distribution : "$description
echo "Architecture : "$arch
echo "Votre IP : "$IP

# echo "Votre nom de user actuel : "$loguser

if [ -z "$homeDispo" ]
then
	echo "Vous n'avez pas de partition /home."
else
	echo "Votre partition /home a $homeDispo de libre."
fi
echo "Votre partition root (/) a "$rootDispo" de libre."
echo
echo "Nom de votre utilisateur Linux (accès SSH et SFTP) : "$userLinux
echo "Port pour SSh : "$portSSH
echo "Nom de votre utilisateur ruTorrent : "$userRuto
echo "Mot de passe de votre utilisateur ruTorrent : "$pwRuto
if [[ $installCake != "oui" ]]
then
	echo "Vous ne souhaitez pas installer Cakebox"
else
	echo "Vous souhaitez installer Cakebox"
	echo "Nom de votre utilisateur Cakebox : "$userCake
	echo "Mot de passe de votre utilisateur Cakebox : "$pwCake
fi
if [[ $installWebMin != "oui" ]]
then
	echo "Vous ne souhaitez pas installer WebMin"
else
	echo "Vous souhaitez installer WebMin"
	echo "L'utilisateur sera "root" avec son mot de passe"
fi
echo
echo
echo "                                                                     "
echo "                       ATTENTION !!!                                 "
echo "                                                                     "
echo "  Vous devez impérativement conserver ces informations en lieu sûr.  "
echo "  Les noms d'utilisateur, mots de passe et port sont indispensables  "
echo "  à l'utilisation du serveur.                                        "
echo "                                                                     "
echo "  Toutes ces informations seront utilisables seulement après         "
echo "  la bonne exécution du script.                                      "
echo "                                                                     "
tmp=""
until [[ $tmp == "ok" ]]; do
echo
echo -n "Voulez-vous continuer l'installation ? (o/n) "
read yno
case $yno in
	[nN] | [nN][oO][nN])
		echo "Au revoir, a bientôt."
		exit 0
	;;
	[Oo] | [Oo][Uu][Ii])
		echo "Allons-y !"
		tmp="ok"
		sleep 1
	;;
	*)
		echo "Entrée invalide"
		sleep 1
	;;
esac
done




############################################
#            Début de la fin
############################################


clear
echo
echo
echo
echo "*************************************************"
echo "|                 Installation                  |"
echo "*************************************************"
echo
echo
echo
echo "***********************************************"
echo "|              Update système                 |"
echo "|       Création de l'utilisateur linux       |"
echo "|          Installation des paquets           |"
echo "***********************************************"
sleep 2
echo
# upgrade
apt-get update -yq
sortie=$?
apt-get upgrade -yq
if [[ $? -eq 0 && $sortie -eq 0 ]]
then 
	echo "****************************"	
	echo "|  Mise à jour effectuée   |"
	echo "****************************"
	sleep 2
else
	__erreurApt  # __erreurApt()
fi

echo
echo "$userLinux ALL=(ALL) NOPASSWD:ALL" >>/etc/sudoers;
usermod -aG www-data $userLinux

# config mc

# config mc user
mkdir -p /home/$userLinux/.config/mc/
cp $repLance/fichiers-conf/mc_panels.ini /home/$userLinux/.config/mc/panels.ini
cd /home/$userLinux
chown -R $userLinux:$userLinux .config/

# config mc root
mkdir -p /root/.config/mc/
cp $repLance/fichiers-conf/mc_panels.ini /root/.config/mc/panels.ini

echo
echo "******************************"
echo "|    Utilisateur linux ok    |"
echo "******************************"
sleep 3
echo

# Installation paquets

echo
echo "***********************************************"
echo "|          Installation des paquets           |"
echo "|         necessaires au serveur web          |"
echo "***********************************************"
sleep 2

if [[ $nameDistrib == "Debian" ]]; then
	paquets=$paquetsWebD
else
	paquets=$paquetsWebU
fi
apt-get install -y $paquets
if [[ $? -eq 0 ]]
then 
	echo "****************************"	
	echo "|     Paquets installés    |"
	echo "****************************"
	sleep 2
else
	__erreurApt  # __erreurApt()
fi

echo
echo "***********************************************"
echo "|           Configuration apache2             |"
echo "***********************************************"
sleep 2

# config apache
echo
echo
a2enmod ssl
a2enmod auth_digest
a2enmod reqtimeout
a2enmod authn_file
a2enmod rewrite

cp /etc/apache2/apache2.conf /etc/apache2/apache2.conf.old
sed -i 's/^Timeout[ 0-9]*/Timeout 30/' /etc/apache2/apache2.conf
echo "ServerTokens Prod" >> /etc/apache2/apache2.conf
echo "ServerSignature Off" >> /etc/apache2/apache2.conf
__serviceapache2restart
	
echo "***********************************************"
echo "|      Fin de configuration d'Apache          |"
echo "***********************************************"
sleep 2
echo

# vérif bon fonctionnement apache et php

echo "<?php phpinfo(); ?>" >/var/www/html/info.php
headTest1=`curl -Is http://$IP/info.php/| head -n 1`
headTest2=`curl -Is http://$IP/| head -n 1`
headTest1=$(echo $headTest1 | awk -F" " '{ print $3 }')
headTest2=$(echo $headTest2 | awk -F" " '{ print $3 }')
if [[ $headTest1 == OK* ]] && [[ $headTest2 == OK* ]]
then 
	echo "***********************************************"
	echo "|        Apache et php fonctionne             |"
	echo "***********************************************"
	sleep 2
else
	echo; echo "Une erreur apache/php c'est produite"
	__messageErreur    #  __messageErreur()
fi
rm /var/www/html/info.php
echo -e 'Options All -Indexes\n<Files .htaccess>\norder allow,deny\ndeny from all\n</Files>' > /var/www/html/.htaccess


# téléchargement rtorrent libtorrent xmlrpc

echo
echo "*******************************************************"
echo "|  Début de l'installation de rtorrent et libtorrent  |"
echo "|                    et xmlrpc                        |"
echo "*******************************************************"
echo
sleep 3

if [[ $nameDistrib == "Debian" ]]; then
	paquets=$paquetsRtoD
else
	paquets=$paquetsRtoU
fi
apt-get install -y $paquets
if [[ $? -eq 0 ]]
then 
	echo "****************************"	
	echo "|     Paquets installés    |"
	echo "****************************"
	sleep 2
else
	__erreurApt
fi

# configuration rtorrent
echo
echo "*****************************************"
echo "|    Configuration de .rtorrent.rc      |"
echo "*****************************************"
sleep 2
#-----------------------------------------------------------------
cp $repLance/fichiers-conf/rto_rtorrent.rc /home/$userLinux/.rtorrent.rc

sed -i 's/<username>/'$userLinux'/g' /home/$userLinux/.rtorrent.rc

#-----------------------------------------------------------------

echo $userLinux | sudo -S -u $userLinux mkdir /home/$userLinux/downloads
echo $userLinux | sudo -S -u $userLinux mkdir /home/$userLinux/downloads/watch
echo $userLinux | sudo -S -u $userLinux mkdir /home/$userLinux/downloads/.session

# mettre rtorrent en deamon / screen
echo
echo "******************************************************"
echo "|  Configuration de rtorrent sous screen en daemon   |"
echo "******************************************************"
sleep 2
echo

#-----------------------------------------------------------------
cp $repLance/fichiers-conf/rto_rtorrent.conf /etc/init/$userLinux-rtorrent.conf

chmod u+rwx,g+rwx,o+rx  /etc/init/$userLinux-rtorrent.conf
sed -i 's/<username>/'$userLinux'/g' /etc/init/$userLinux-rtorrent.conf

#-----------------------------------------------------------------

cp $repLance/fichiers-conf/rto_rtorrentd.sh /etc/init.d/rtorrentd.sh

chmod u+rwx,g+rwx,o+rx  /etc/init.d/rtorrentd.sh
sed -i 's/<username>/'$userLinux'/g' /etc/init.d/rtorrentd.sh

ln -s /etc/init.d/rtorrentd.sh  /etc/rc4.d/S99rtorrentd.sh
ln -s /etc/init.d/rtorrentd.sh  /etc/rc5.d/S99rtorrentd.sh
ln -s /etc/init.d/rtorrentd.sh  /etc/rc6.d/K01rtorrentd.sh
systemctl daemon-reload
service rtorrentd start

#-----------------------------------------------------------------

sleep 2
sortie=`pgrep rtorrent`

if [ -n "$sortie" ]
then 
	echo "*************************************************"
	echo "|  rtorrent en daemon fonctionne correctement  |"
	echo "*************************************************"
	sleep 2
else
	echo; echo "Il y a un problème avec rtorrent !!!"
	__messageErreur
fi


# installation de rutorrent

echo
echo "**************************************************************"
echo "|  Création certificat auto signé et utilisateur ruTorrennt  |"
echo "|            Modifications apache pour ruTorrent             |"
echo "**************************************************************"
sleep 2
echo


# certif ssl

openssl req -new -x509 -days 365 -nodes -newkey rsa:2048 -out /etc/apache2/apache.pem -keyout /etc/apache2/apache.pem -subj "/C=FR/ST=Paris/L=Paris/O=Global Security/OU=RUTO Department/CN=$IP"

chmod 600 /etc/apache2/apache.pem

cp /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-available/default-ssl.conf.old

sed -i "/<\/VirtualHost>/i \<Location /rutorrent>\nAuthType Digest\nAuthName \"rutorrent\"\nAuthDigestDomain \/var\/www\/html\/rutorrent\/ http:\/\/$IP\/rutorrent\n\nAuthDigestProvider file\nAuthUserFile \/etc\/apache2\/.htpasswd\nRequire valid-user\nSetEnv R_ENV \"\/var\/www\/html\/rutorrent\"\n<\/Location>\n" /etc/apache2/sites-available/default-ssl.conf

a2ensite default-ssl
__serviceapache2restart


# création de userRuto

(echo -n "$userRuto:rutorrent:" && echo -n "$userRuto:rutorrent:$pwRuto" | md5sum) > /etc/apache2/.htpasswd
sed -i 's/[ ]*-$//' /etc/apache2/.htpasswd


# Modifier la configuration du site par défaut (pour rutorrent)

cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf.old
#-----------------------------------------------------------------
cp $repLance/fichiers-conf/apa_000-default.conf /etc/apache2/sites-available/000-default.conf
#-------------------------------------------------------------------

sed -i 's/<server IP>/'$IP'/g' /etc/apache2/sites-available/000-default.conf
__serviceapache2restart

echo
echo "************************************************************"
echo "|  Configuration sur Apache du site par défaut terminée   |"
echo "************************************************************"
sleep 1
echo
echo
echo "*************************************************"
echo "|   Installation et configuration de ruTorrent  |"
echo "*************************************************"
sleep 2

# téléchargement

cd /var/www/html
mkdir source
cd source
wget https://github.com/Novik/ruTorrent/archive/master.zip
unzip master.zip
mv ruTorrent-master /var/www/html/rutorrent
cd /var/www/html
chown -R www-data:www-data /var/www/html/rutorrent

# fichier de config,  échapper les $variable

mv /var/www/html/rutorrent/conf/config.php /var/www/html/rutorrent/conf/config.php.old
cd /var/www/html/rutorrent/conf

cp $repLance/fichiers-conf/ruto_config.php /var/www/html/rutorrent/conf/config.php

cd /var/www/html
chown -R www-data:www-data rutorrent
chmod -R 755 rutorrent

# modif du thème de rutorrent

cd /var/www/html/rutorrent/share/users/
mkdir -p $userRuto/torrents; mkdir -p $userRuto/settings
chown -R www-data:www-data $userRuto
chmod -R 777 $userRuto; 

echo 'O:6:"rTheme":2:{s:4:"hash";s:9:"theme.dat";s:7:"current";s:8:"Oblivion";}' > /var/www/html/rutorrent/share/users/$userRuto/settings/theme.dat
chmod u+rwx,g+rx,o+rx $userRuto 
chmod 666 /var/www/html/rutorrent/share/users/$userRuto/settings/theme.dat
chown www-data:www-data /var/www/html/rutorrent/share/users/$userRuto/settings/theme.dat


# installation de mediainfo et ffmpeg
echo
echo "**********************************************"
echo "|    Installation de mediainfo et ffmpeg     |"
echo "**********************************************"
sleep 2
echo

if [[ $nameDistrib == "Debian" ]]; then
	chmod 777 /etc/apt/sources.list
	echo $sourceMediaD >> /etc/apt/sources.list
	chmod 644 /etc/apt/sources.list
	apt-get update -yq
	apt-get install -y deb-multimedia-keyring
	apt-get update -yq
	apt-get install -y --force-yes $paquetsMediaD
	sortie=$?
else
	apt-get install -y $paquetsMediaU
	sortie=$?
fi
if [[ $sortie -eq 0 ]]
then 
	echo "****************************"	
	echo "|     Paquets installés    |"
	echo "****************************"
	sleep 2
else
	__erreurApt
fi

# installation des plugins rutorrent

echo
echo "*************************************************"
echo "|      Installation des plugins ruTorrent       |"
echo "*************************************************"
sleep 2

cd /var/www/html/rutorrent/plugins
mkdir conf
cd conf

cp $repLance/fichiers-conf/ruto_plugins.ini /var/www/html/rutorrent/plugins/conf/plugins.ini

# création de conf/users/userRuto en prévision du multiusers
mkdir -p /var/www/html/rutorrent/conf/users/$userRuto
cp /var/www/html/rutorrent/conf/access.ini /var/www/html/rutorrent/conf/plugins.ini /var/www/html/rutorrent/conf/users/$userRuto
cp $repLance/fichiers-conf/ruto_multi_config.php /var/www/html/rutorrent/conf/users/$userRuto/config.php
port=5000
sed -i -e 's/<port>/'$port'/' -e 's/<username>/'$userRuto'/' /var/www/html/rutorrent/conf/users/$userRuto/config.php

cd ..
chown -R www-data:www-data conf/

# Ajouter le plugin log-off

cd /var/www/html/rutorrent/plugins
wget https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/rutorrent-logoff/logoff-1.3.tar.gz

tar -zxf logoff-1.3.tar.gz
cd logoff

sed -i "s|\(\$logoffURL.*\)|\$logoffURL = \"https://www.qwant.com/\";|" /var/www/html/rutorrent/plugins/logoff/conf.php
sed -i "s|\(\$allowSwitch.*\)|\$allowSwitch = \"$userRuto\";|" /var/www/html/rutorrent/plugins/logoff/conf.php

cd ..
chown -R www-data:www-data logoff
headTest=`curl -Is http://$IP/rutorrent/| head -n 1`
headTest=$(echo $headTest | awk -F" " '{ print $3 }')
if [[ $headTest == Unauthorized* ]]
then 
	echo "****************************"	
	echo "|  ruTorrent fonctionne    |"
	echo "****************************"
else
	echo; echo "Une erreur c'est produite sur ruTorrent"
	__messageErreur
fi
sleep 2


# install cakebox and Co

if [[ $installCake == "oui" ]]
then
. $repLance/insert/cakeboxinstall
fi  # cakebox


# install webmin

if [[ $installWebMin == "oui" ]]
then
. $repLance/insert/webmininstall
fi   # Webmin


# sécuriser ssh

if [[ $changePort == "oui" ]]; then
. $repLance/insert/sshsecuinstall
fi  # changePort
sleep 3


# remettre sudoers en ordre
sed -i "s/$userLinux ALL=(ALL) NOPASSWD:ALL/$userLinux ALL=(ALL:ALL) ALL/" /etc/sudoers

# copie les script dans home

cp -r  $repLance /home/$userLinux/HiwsT

# générique de fin

hostName=$(hostname -f)
clear
echo
echo "Vous pouvez télécharger et streamer à loisir vos films (de vacances) !"
echo
echo "Pour accéder à ruTorrent :"
echo -en "\thttp(s)://$IP/rutorrent"
echo "   ID : $userRuto  PW : $pwRuto"
echo -e "\tou http(s)://$hostName/rutorrent"
echo -e "\tEn https accépter la connexion non sécurisée et"
echo -e "\tl'exception pour ce certificat !"

if [[ $installCake == "oui" ]]; then
	echo "Pour accéder à Cakebox :"
	echo -en "\thttp://$IP/cakebox"
	echo "   ID : $userCake  PW : $pwCake"
	echo -e "\tou http://$hostName/cakebox"
	echo -e "\t /!\\ NE PAS utiliser https si vous voulez streamer !"
	echo -e "\tSur votre poste en local pour le streaming utiliser firefox"
	echo -e "\tPenser à vérifier la présence du plugin vlc sur firefox"
	echo -e "\tSur linux : sudo apt-get install browser-plugin-vlc"
fi

if [[ $installWebMin == "oui" ]]; then
	echo "Pour accéder à WebMin :"
	echo -e "\thttps://$IP:10000"
	echo -e "\tou https://$hostName:10000"
	echo -e "\tID : root  PW : votre mot de passe root"
	echo -e "\tAccépter la connexion non sécurisée et"
	echo -e "\tl'exception pour ce certificat !"
fi

echo
sleep 1
echo "En cas de problème concernant strictement"
echo "ce script, vous pouvez aller"
echo "Consulter le wiki : https://github.com/Patlol/Handy-Install-Web-Server-ruTorrent-/wiki"
echo "et poster sur https://github.com/Patlol/Handy-Install-Web-Server-ruTorrent-/issues"
echo
sleep 1
if [[ $changePort == "oui" ]]; then   # ssh sécurisé
	echo "************************************************"
	echo "|     ATTENTION le port standard et root       |"
	echo "|     n'ont plus d'accès en SSH et SFTP        |"
	echo "************************************************"
	echo
	echo "Pour accéder à votre serveur en ssh :"
	echo "Depuis linux, sur une console :"
	echo -e "\tssh -p$portSSH  $userLinux@$IP"
	echo -e "\tsur la console du serveur 'su $userLinux'"
	echo "Depuis windows utiliser PuTTY"
	echo
	sleep 1
	echo "Pour accéder aux fichiers via SFTP :"
	echo -en "\tHôte : $IP"
	echo -e "\tPort : $portSSH"
	echo -e "\tProtocole : SFTP-SSH File Transfer Peotocol"
	echo -e "\tAuthentification : normale"
	echo -en "\tIdentifiant : $userLinux"
	if [[ $pwLinux != "" ]]; then
		echo -e "\tMot de passe : $pwLinux"
	else 
		echo -e "\tVotre mot de passe"
	fi
	echo
	sleep 1
else   # ssh n'est pas sécurisé
	echo "Pour accéder à votre serveur en ssh :"
	echo "Depuis linux, sur une console :"
	echo -e "\tssh root@$IP"
	echo "Depuis windows utiliser PuTTY"
	echo
	sleep 1
	echo "Pour accéder aux fichiers via SFTP :"
	echo -en "\tHôte : $IP"
	echo -e "\tPort : 22"
	echo -e "\tProtocole : SFTP-SSH File Transfer Peotocol"
	echo -e "\tAuthentification : normale"
	echo -e "\tIdentifiant : root"
fi   # ssh pas sécurisé/ sécurisé
echo
echo "REBOOTEZ VOTRE SERVEUR"
echo
tmp=""
until [[ $tmp == "ok" ]]; do
	echo
	echo -n "Voulez-vous rebooter maintenant ? (o/n) "; read yno
	case $yno in
		[nN] | [nN][oO][nN])
			echo
			echo "Il faudra rebooter pour que tout fonctionne à 100%"
			exit 0
		;;
		[Oo] | [Oo][Uu][Ii])
			sleep 2
			reboot
		;;
		*)
			echo "Entrée invalide"
			sleep 1
		;;
	esac
done



