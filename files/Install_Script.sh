#!/bin/bash
# Copyright (c) 2018 fithwum
# All rights reserved

# Teamspeak server version check.
TS_VERSION="3.5.1"
CHANGELOG=/ts3server/CHANGELOG_${TS_VERSION}

function wget () {
    : ${DEBUG:=0}
    local URL=$1
    local tag="Connection: close"
    local mark=0

    if [ -z "${URL}" ]; then
        printf "Usage: %s \"URL\" [e.g.: %s http://www.google.com/]" \
               "${FUNCNAME[0]}" "${FUNCNAME[0]}"
        return 1;
    fi
    read proto server path <<<$(echo ${URL//// })
    DOC=/${path// //}
    HOST=${server//:*}
    PORT=${server//*:}
    [[ x"${HOST}" == x"${PORT}" ]] && PORT=80
    [[ $DEBUG -eq 1 ]] && echo "HOST=$HOST"
    [[ $DEBUG -eq 1 ]] && echo "PORT=$PORT"
    [[ $DEBUG -eq 1 ]] && echo "DOC =$DOC"

    exec 3<>/dev/tcp/${HOST}/$PORT
    echo -en "GET ${DOC} HTTP/1.1\r\nHost: ${HOST}\r\n${tag}\r\n\r\n" >&3
    while read line; do
        [[ $mark -eq 1 ]] && echo $line
        if [[ "${line}" =~ "${tag}" ]]; then
            mark=1
        fi
    done <&3
    exec 3>&-
}

# Main Install.
if [ "/ts3server/CHANGELOG_*" == "/ts3server/CHANGELOG_${TS_VERSION}" ]
	then
		echo "INFO ! ts3server ${TS_VERSION} files found ... running current docker."
		# cd /ts3server
		exec /ts3server/ts3server_minimal_runscript.sh inifile=ts3server.ini start
		exit 0
	else
		echo "WARNING ! ts3server ${TS_VERSION} files not found, checking and installing new files as needed."

# Download & unpack teamspeak3 files & move into /ts3server.
	if [ -e "${CHANGELOG}" ]
		then
			echo "INFO ! ts3server is ${TS_VERSION} ... checking ini/sh files before running current docker."
		else
			echo "WARNING ! ts3server is out of date ... will download new copy from teamspeak."
				wget https://files.teamspeak-services.com/releases/server/${TS_VERSION}/teamspeak3-server_linux_amd64-${TS_VERSION}.tar.bz2 -O /ts3temp/ts3server_${TS_VERSION}.tar.bz2
				sleep 2
				tar -xf /ts3temp/ts3server_${TS_VERSION}.tar.bz2 -C /ts3temp/serverfiles --strip-components=1
				sleep 2
				rm -frv /ts3temp/serverfiles/ts3server_startscript.sh
				rm -frv /ts3temp/ts3server_${TS_VERSION}.tar.bz2
				cp -uR /ts3temp/serverfiles/. /ts3server/
				sleep 2
				mv /ts3server/redist/libmariadb.so.2 /ts3server/libmariadb.so.2
				mv /ts3server/CHANGELOG ${CHANGELOG}
				rm -fr /ts3temp/serverfiles/*
	fi

# Check if the ini/sh files exist in /ts3server and copy if needed.
	if [ -e /ts3server/ts3server_minimal_runscript.sh ]
		then
			echo "INFO ! ts3server_minimal_runscript.sh found ... will not download."
		else
			echo "WARNING ! ts3server_minimal_runscript.sh not found ... will download new copy."
				wget https://raw.githubusercontent.com/fithwum/files-for-dockers/master/scripts/ts3server_minimal_runscript.sh -O /ts3temp/inifiles/ts3server_minimal_runscript.sh
				cp /ts3temp/inifiles/ts3server_minimal_runscript.sh /ts3server/
				rm -frv /ts3temp/ts3server_minimal_runscript.sh
	fi
	if [ -e /ts3server/ts3db_mariadb.ini ]
		then
			echo "INFO ! ts3db_mariadb.ini found ... will not download."
		else
			echo "WARNING ! ts3db_mariadb.ini not found ... will download new copy."
				wget https://raw.githubusercontent.com/fithwum/files-for-dockers/master/files/ts3db_mariadb.ini -O /ts3temp/inifiles/ts3db_mariadb.ini
				cp /ts3temp/inifiles/ts3db_mariadb.ini /ts3server/
				rm -frv /ts3temp/inifiles/ts3db_mariadb.ini
	fi
	if [ -e /ts3server/ts3server.ini ]
		then
			echo "INFO ! ts3server.ini found ... will not download."
		else
			echo "WARNING ! ts3server.ini not found ... will download new copy."
				wget https://raw.githubusercontent.com/fithwum/files-for-dockers/master/files/ts3server.ini -O /ts3temp/inifiles/ts3server.ini
				cp /ts3temp/inifiles/ts3server.ini /ts3server/
				rm -frv /ts3temp/inifiles/ts3server.ini
	fi

	sleep 1

# set permissions.
	chown 99:100 -R /ts3server
	chmod 777 -R /ts3server
	chmod +x -v /ts3server/ts3server_startscript.sh
	chmod +x -v /ts3server/ts3server
	sleep 1

# run the server.
	echo "INFO ! Starting ts3server ${TS_VERSION} ..."
	sleep 10m
	# cd /ts3server
	exec /ts3server/ts3server_minimal_runscript.sh inifile=ts3server.ini start
fi
exit 0
