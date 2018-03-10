#!/bin/bash


APPDIR="$( pwd $0 )"
NOWHICH=""

export APPDIR NOWHICH

function exit_app {
	unset APPDIR NOWHICH
}

trap exit_app SIGINT SIGTERM SIGKILL SIGABRT SIGSEGV SIGQUIT

echo ""
echo "Running in ${APPDIR}."
echo ""

function check_which {
	if [ `which bash >/dev/null 2>&1; echo $?` != 0 ]; then
		NOWHICH=1
	else
		NOWHICH=0
	fi
}

function check_depends {
	if [ ${NOWHICH} == 0 ]; then
		if [ `which ${1} >/dev/null 2>&1; echo $?` != 0 ]; then

			if [ -x "/sbin/${1}" ] || [ -x "/usr/sbin/${1}" ] || [ -x "/usr/local/sbin/${1}" ]; then
				echo ""
				echo "WARNING: Although \"${1}\" is installed on your System"
				echo "         you seem not to be allowed to execute the"
				echo "         \"${1}\" binary or it is not located within your"
				echo "         \$PATH-variable."
				echo "         Try re-running this Program with root privileges."
				echo ""
				exit 127
			fi

			echo ""
			echo "ERROR: Tool \"${1}\" not found on your System."
			echo ""
			echo "On most Debian-derived Linux-Distributions, the required"
			echo "tools can be installed using the following command:"
			echo ""
			echo "  sudo apt-get install mtr ethtool util-linux \\"
			echo "               net-tools pciutils wireless-tools \\"
			echo "               iputils-ping dnsutils"
			echo ""
			echo "similarly, on most RedHat-derived Linux-Distributions"
			echo "the following command might be used:"
			echo ""
			echo "  sudo yum install mtr ethtool util-linux \\"
			echo "           net-tools pciutils wireless-tools \\"
			echo "           iputils bind-utils"
			echo ""
			exit 1
		else
			echo "OK: Tool \"${1}\" found at $(which ${1})."
		fi
	else
		echo "NOWHICH1"
	fi
}

function check_java {
	if [ $(readlink -e $(which java) > /dev/null 2>&1; echo $?) != 0 ] || [ $(java -version > /dev/null 2>&1; echo $?) != 0 ]; then
		echo ""
		echo "ERROR: No Java runtime found on your System."
		echo "       Please make sure, you have a up to date Java"
		echo "       runtime installed on your system and check"
		echo "       that it can be found within your \$PATH-variable."
		echo ""
	else
		
		if [ -z "`java -XshowSettings:properties -version 2>&1 | grep 'java\.vm\.vendor' | grep -i oracle`" ]; then
			echo ""
			echo "INFO: Java was found on your System but"
			echo "      the version installed could not be"
			echo "      identified. This Program might or"
			echo "      might not run using the currently"
			echo "      installed Java runtime."
			echo ""
		else
			echo "OK: Oracle Java `java -XshowSettings:properties -version 2>&1 | grep 'java\.version' | awk '{ print $3};'` found at $(which java)."
		fi
	fi



}

check_which

echo "------"
check_depends mtr
check_depends ethtool
check_depends arp
check_depends whereis
check_depends ifconfig
check_depends iwconfig
check_depends lspci
check_depends ping
check_depends ping6
check_depends nslookup
check_java
echo "------"




## Check Libraries (version)


cd ${APPDIR}


FONTAWESOME=`find libs/ -iname fontawesome*jar`
JACKSONALL=`find libs/ -iname jackson-all*jar`
LOG4JAPI=`find libs/ -iname log4j-api*jar`
LOG4JCORE=`find libs/ -iname log4j-core*jar`
OKHTTP=`find libs/ -iname okhttp*jar`
OKIO=`find libs/ -iname okio*jar`
SIMPLEXML=`find libs/ -iname simple-xml*jar`
SPEEDTESTLIB=`find libs/ -iname speedTestLib*jar`
SQLITEJDBC=`find libs/ -iname sqlite-jdbc*jar`
HSIPERFORMANCEAPPLET=`basename $(find . -iname HSIPerformanceAppletFX*jar)`


/usr/bin/java -Xms256m -Xmx1024m -Djava.net.preferIPv4Stack=true -Djavax.net.ssl.keyStore=${APPDIR}/security/cacerts -Xbootclasspath/p:${FONTAWESOME}:${JACKSONALL}:${LOG4JAPI}:${LOG4JCORE}:${OKHTTP}:${OKIO}:${SIMPLEXML}:${SPEEDTESTLIB}:${SQLITEJDBC} -cp ${APPDIR}:${APPDIR}/libs:${APPDIR}/security:${APPDIR}/${HSIPERFORMANCEAPPLET} ch.cnlab.performanceapplet.fx.Main

exit 0
