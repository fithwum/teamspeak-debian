#!/bin/bash
# Copyright (c) 2018 fithwum
# All rights reserved

# Variables.
echo " "
echo "Checking server version from teamspeak."
wget --no-cache https://www.teamspeak.com/versions/server.json -O /ts3temp/server.json
TS_VERSION_CHECK=$(cat /ts3temp/server.json | grep version | head -1 | awk -F: '{print $4}' | sed 's/[",]//g' | sed "s/checksum//g")
TS_VERSION=${TS_VERSION_CHECK}
CHANGELOG=/ts3server/CHANGELOG_${TS_VERSION}
echo " "
echo "Latest server version from teamspeak:$TS_VERSION"

# Main install (debian).
# Check for files in /ts3server and download/create if needed.
if [ -e "${CHANGELOG}" ]
	then
		echo " "
		echo "INFO ! ts3server is ${TS_VERSION} ... checking that ini/sh files exist before running current docker."
		rm -fr /ts3temp/server.json
	else
		echo " "
		echo "WARNING ! ts3server is out of date ... will download new copy from teamspeak."
			echo " "
			echo "INFO ! Preserving settings/logs/userfiles in /ts3temp/serverfiles."
			echo "INFO ! (this might take some time)"
			cp -R /ts3server/files/. /ts3temp/serverfiles/files/
			cp -R /ts3server/logs/. /ts3temp/serverfiles/logs/
			cp /ts3server/*.ini /ts3temp/serverfiles
			cp /ts3server/*.sh /ts3temp/serverfiles
			echo " "
			echo "INFO ! Clearing old teamspeak files."
			rm -fr /ts3server/*
			echo " "
			echo "INFO ! Copying files back from /ts3temp/serverfiles."
			echo "INFO ! (this might take some time)"
			cp -R /ts3temp/serverfiles/. /ts3server/
			rm -fr /ts3temp/serverfiles/*
			sleep 1
			wget --no-cache https://files.teamspeak-services.com/releases/server/${TS_VERSION}/teamspeak3-server_linux_amd64-${TS_VERSION}.tar.bz2 -O /ts3temp/ts3server_${TS_VERSION}.tar.bz2
			tar -xf /ts3temp/ts3server_${TS_VERSION}.tar.bz2 -C /ts3temp/serverfiles --strip-components=1
			sleep 1
			rm -fr /ts3temp/serverfiles/ts3server_startscript.sh
			rm -fr /ts3temp/ts3server_${TS_VERSION}.tar.bz2
			cp -uR /ts3temp/serverfiles/. /ts3server/
			sleep 1
			mv /ts3server/redist/libmariadb.so.2 /ts3server/libmariadb.so.2
			mv /ts3server/CHANGELOG ${CHANGELOG}
			rm -fr /ts3temp/serverfiles/*
			rm -fr /ts3temp/server.json
fi

# Check if the ini/sh files exist in /ts3server and download/create if needed.
if [ -e /ts3server/ts3server_minimal_runscript.sh ]
	then
		echo " "
		echo "INFO ! ts3server_minimal_runscript.sh found ... will not download."
	else
		echo " "
		echo "WARNING ! ts3server_minimal_runscript.sh not found ... will download new copy."
			wget --no-cache https://raw.githubusercontent.com/fithwum/files-for-dockers/master/scripts/ts3server_minimal_runscript.sh -O /ts3temp/inifiles/ts3server_minimal_runscript.sh
			cp /ts3temp/inifiles/ts3server_minimal_runscript.sh /ts3server/
			rm -fr /ts3temp/ts3server_minimal_runscript.sh
fi
if [ -e /ts3server/ts3db_mariadb.ini ]
	then
		echo " "
		echo "INFO ! ts3db_mariadb.ini found ... will not download."
	else
		echo " "
		echo "WARNING ! ts3db_mariadb.ini not found ... will download new copy."
			wget --no-cache https://raw.githubusercontent.com/fithwum/files-for-dockers/master/files/ts3db_mariadb.ini -O /ts3temp/inifiles/ts3db_mariadb.ini
			cp /ts3temp/inifiles/ts3db_mariadb.ini /ts3server/
			rm -fr /ts3temp/inifiles/ts3db_mariadb.ini
fi
if [ -e /ts3server/ts3server.ini ]
	then
		echo " "
		echo "INFO ! ts3server.ini found ... will not download."
	else
		echo " "
		echo "WARNING ! ts3server.ini not found ... will download new copy."
			wget --no-cache https://raw.githubusercontent.com/fithwum/files-for-dockers/master/files/ts3server.ini -O /ts3temp/inifiles/ts3server.ini
			cp /ts3temp/inifiles/ts3server.ini /ts3server/
			rm -fr /ts3temp/inifiles/ts3server.ini
fi

sleep 1

# Set permissions.
chown 99:100 -R /ts3server
chmod 777 -R /ts3server
chmod +x /ts3server/ts3server_minimal_runscript.sh
chmod +x /ts3server/ts3server

# Run teamspeak server.
echo " "
echo "INFO ! Starting ts3server ${TS_VERSION}"
exec /ts3server/ts3server_minimal_runscript.sh inifile=ts3server.ini start

exit
