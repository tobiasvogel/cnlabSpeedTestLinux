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

/usr/bin/java -Xms256m -Xmx1024m -XX:PermSize=256m -XX:MaxPermSize=256m -Djava.net.preferIPv4Stack=true -Djavax.net.ssl.keyStore=${APPDIR}/security/cacerts -Xbootclasspath/p:libs/fontawesomefx-8.9.jar:libs/jackson-all-1.9.11.jar:libs/log4j-api-2.2.jar:libs/log4j-core-2.2.jar:libs/okhttp-3.2.0.jar:libs/okio-1.6.0.jar:libs/simple-xml-2.7.jar:libs/speedTestLib.jar:libs/sqlite-jdbc-3.8.7.jar -cp ${APPDIR}:${APPDIR}/libs:${APPDIR}/security:${APPDIR}/HSIPerformanceAppletFX-1.5.0.jar ch.cnlab.performanceapplet.fx.Main

exit 0