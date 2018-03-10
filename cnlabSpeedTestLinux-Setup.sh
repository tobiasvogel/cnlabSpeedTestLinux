#!/bin/bash

DOWNLOADURL="https://download.cnlab.ch/performance/macos/cnlabSpeedTest.dmg"

DOWNLOADGITSCRIPT="https://github.com/tobiasvogel/cnlabSpeedTestLinux/raw/master/cnlabSpeedTestLinux.sh"

DLAGENT=""

TMPAGENT=""

TMPDLFILE=""

TMPHFSFILE=""

NOWHICH=""

P7ZUTIL=""

SUDOCMD=""

HFSSUPPORT=""

TMPMNTDIR=""

INSTALLDIR=""

TMPRUNSCRIPT=""

PATHARRAY=()

export PATHARRAY NOWHICH DOWNLOADURL DOWNLOADGITSCRIPT DLAGENT TMPAGENT TMPDLFILE TMPHFSFILE P7ZUTIL SUDOCMD HFSSUPPORT TMPMNTDIR INSTALLDIR TMPRUNSCRIPT


function exit_app {
	if [ -n "${TMPMNTDIR}" ]; then
		if [ -n "`grep ${TMPMNTDIR} /proc/mounts`" ]; then
			run_sudo "`which umount`" "${TMPMNTDIR}"
		fi
		rmdir -v "${TMPMNTDIR}"
	fi
	(>&2 echo "Cleaning up...")
	if [ -n "${TMPDLFILE}" -a -e "${TMPDLFILE}" ]; then
		rm -vf "${TMPDLFILE}"
	fi
	if [ -n "${TMPHFSFILE}" -a -e "${TMPHFSFILE}" ]; then
		rm -vf "${TMPHFSFILE}"
	fi
	if [ -n "${TMPRUNSCRIPT}" -a -e "${TMPRUNSCRIPT}" ]; then
		rm -vf "${TMPRUNSCRIPT}"
	fi
	
	unset PATHARRAY NOWHICH DOWNLOADURL DOWNLOADGITSCRIPT DLAGENT TMPAGENT TMPDLFILE TMPHFSFILE P7ZUTIL SUDOCMD HFSSUPPORT TMPMNTDIR INSTALLDIR TMPRUNSCRIPT
}

trap exit_app SIGINT SIGTERM SIGKILL SIGABRT SIGSEGV SIGQUIT

exec 3>&1

function fecho {
	printf '%s\n' "$@" >&3
}


#### Functions


check_root() {
	if [ "`id -u`" == "0" ]; then
		(>&2 echo "Please do not run this script as root user.")
		exit_app
		exit 1
	fi
}

check_root


check_which() {
        if [ `which bash >/dev/null 2>&1; echo $?` != 0 ]; then
                NOWHICH=1
        else
                NOWHICH=0
        fi
}


create_path_array() {

	OLDIFS=${IFS}
	IFS=$'\n'

	for NEWITEM in `echo $PATH | tr -t [=:=] '\n'`; do

		PATHARRAY=( "${PATHARRAY[@]}" "${NEWITEM}" )
	
	done

	DEFAULTITEMS=( "/sbin" "/bin" "/usr/sbin" "/usr/bin" "/usr/local/sbin" "/usr/local/bin" )

	COUNT="${#PATHARRAY[@]}"

	for ((i=0 ; i < COUNT ; i++)); do

		EXITINNERLOOP=0

		COUNTDEFAULTS="${#DEFAULTITEMS[@]}"	
		NEWDEFAULTITEMS=()

		for ((j=0 ; j < COUNTDEFAULTS ; j++)); do
			if [ $EXITINNERLOOP -lt 1 ]; then
				if [ "${DEFAULTITEMS[$j]}" == "${PATHARRAY[$i]}" ]; then
					for ITEM in "${DEFAULTITEMS[@]}"; do
						if [ ! "${ITEM}" == "${DEFAULTITEMS[$j]}" ]; then
						NEWDEFAULTITEMS=( "${NEWDEFAULTITEMS[@]}" "${ITEM}" )
						fi
					done

					EXITINNERLOOP=1
				fi	
			fi
		done
		if [ ${#NEWDEFAULTITEMS[@]} -gt 0 ]; then
			DEFAULTITEMS=( "${NEWDEFAULTITEMS[@]}" )
		fi
	done

	for NEWITEM in "${DEFAULTITEMS[@]}"; do 
	
		COUNT=
		PATHARRAY=( "${PATHARRAY[@]}" "${NEWITEM}" )
	
	done

	IFS=${OLDIFS}

}


find_in_path() {
	FOUND=0

	for POSSIBLEDIR in "${PATHARRAY[@]}"; do
		if [ -x "${POSSIBLEDIR}/${1}" -a $FOUND -lt 1 ]; then
                        fecho "OK: Tool \"${1}\" found at ${POSSIBLEDIR}."
			FOUND=1
		fi
	done

	if [ $FOUND -gt 0 ]; then
		return "0" #zero is a success in Bash manner!
	else
		return "1"
	fi
}

check_depends() {
        if [ ${NOWHICH} == 0 ]; then
                if [ `which ${1} >/dev/null 2>&1; echo $?` != 0 ]; then
			(>&2 echo "")
			(>&2 echo "WARNING: Tool \"${1}\" NOT found.")
			(>&2 echo "")
			return "1"
                else
                        fecho "OK: Tool \"${1}\" found at $(which ${1})."
			return 0 #zero is a success in Bash manner!
                fi
        else
		find_in_path ${1}
        fi
}

# borrowed from https://stackoverflow.com/a/5032641/4281842
strindex() {
	x="${1%%$2*}"
	[[ "$x" = "$1" ]] && echo -1 || echo "${#x}"
}


check_hfsmount() {
	if [ -r /proc/filesystems ]; then
	if [ -n "`grep -o hfsplus /proc/filesystems`" ]; then
		fecho "OK: HFS+ filesystems are supported."
	else
		(>&2 echo "WARNING: Couldn't confirm HFS+ support.")
	fi
	fi
}


get_sudo() {
	SUDOCMD=""
	if [ `which pkexec >/dev/null 2>&1 ; echo $?` == "0" ]; then
		SUDOCMD="pkexec"
	elif [ `which sudo >/dev/null 2>&1 ; echo $?` == "0" ]; then
		SUDOCMD="sudo"
	elif [ `which su >/dev/null 2>&1 ; echo $?` == "0" ]; then
		SUDOCMD="su"
	else
		(>&2 echo "")
		(>&2 echo "ERROR: Didn't find a convenient way to run commands")
		(>&2 echo "as privileged user. Please see the FAQ section at")
		(>&2 echo "https://github.com/tobiasvogel/cnlabSpeedTestLinux/wiki/FAQ")
		(>&2 echo "for more information.")
		(>&2 echo "")
		exit_app
		exit 1
	fi
}

run_sudo() {
	if [ "${SUDOCMD}" == "pkexec" ]; then
		pkexec --user root ${@}
	elif [ "${SUDOCMD}" == "sudo" ]; then
		sudo -A --user root ${@}
	else
		su -c "${@}" root
	fi
}

get_install_dir() {
	fecho ""
	fecho "By default, this Script will install the cnlab"
	fecho "SpeedTest Application into a subfolder of \"/opt\"."
	fecho ""
	DIRVALID=0
	DIRECTORY="/opt"
	while [ $DIRVALID -eq 0 ]; do
		fecho ""
		fecho "Install in \"${DIRECTORY}\""
		read -p "[(A)ccept/(c)hange] : ? " ANSWER
		if [ "$ANSWER" == "" ]; then # User confirmed using RETURN
			ANSWER="A"
		fi
		ANSWER=${ANSWER:0:1}
		if [ "$ANSWER" == "A" -o "$ANSWER" == "a" ]; then
			DIRVALID=1
			INSTALLDIR="/opt"
		elif [ "$ANSWER" == "C" -o "$ANSWER" == "c" ]; then
			DIRVALID=0
			fecho "Please specify the parent install directory below"			
			read -e -p "? " -i "${DIRECTORY}" DIRECTORY
			if [ -d "$DIRECTORY" ]; then
				DIRVALID=1
				INSTALLDIR="${DIRECTORY}"
			fi
		fi
	done
	echo "${INSTALLDIR}"
	return 0
}

mount_hfs_img() {
	MOUNT=`which mount`
	run_sudo "${MOUNT}" "-t hfsplus -o loop ${1} ${2}"
	sleep 2
	GREP=`cat /proc/mounts | grep ${2} | grep hfs`
	if [ -z "${GREP}" ]; then
		(>&2 echo "")
		(>&2 echo "WARNING: Couldn't confirm the Disk Image has been mounted successfully.")
		(>&2 echo "")
	fi
}

create_tmpdir() {

if [ "${TMPAGENT}" == "mktemp" ]; then
	TMPMNTDIR=`mktemp --suffix=".mount" --directory`
else
	TMPMNTDIR=`tempfile --suffix=".mount"`
	rm -f ${TMPMNTDIR} && mkdir ${TMPMNTDIR}
fi

	if [ -d "${TMPMNTDIR}" ]; then
		echo "${TMPMNTDIR}"
		return  0 
	else
		(>&2 echo "")
		(>&2 echo "ERROR: Couldn't create temporary directory.")
		(>&2 echo "Please see the FAQ section at" )
		(>&2 echo "https://github.com/tobiasvogel/cnlabSpeedTestLinux/wiki/FAQ")
		(>&2 echo "")
		exit_app
		exit 1
	fi
}

#### Main Program


check_which

if [ $NOWHICH == 1 ]; then
	create_path_array
fi

if [ "$(check_depends wget)" == "1" ]; then
	if [ "$(check_depends curl)" == "0" ]; then
		DLAGENT="curl"
	else
		echo "ERROR: Either one of the \"wget\" or \"curl\" utilities is required. None found."
		exit_app
		exit 1
	fi
else
	DLAGENT="wget"
fi

if [ "$(check_depends 7z)" == "1" ]; then
	if [ "$(check_depends 7za)" == "0" ]; then
		P7ZUTIL="7za"
	else
		echo "ERROR: The \"7-Zip\" Tool is required. Not found."
		exit_app
		exit 1
	fi
else
	P7ZUTIL="7z"
fi


if [ "$(check_depends mktemp)" == "1" ]; then
	if [ "$(check_depends tempfile)" == "0" ]; then
		TMPAGENT="tempfile"
	else
		echo "ERROR: Either one of the \"mktemp\" or \"tempfile\" utilities is required. None found."
		exit_app
		exit 1
	fi
else
	TMPAGENT="mktemp"
fi

if [ "$(check_depends icns2png)" == "1" ]; then
	echo "ERROR: \"icns2png\" from the package \"icnsutils\" (Ubuntu, Debian, ..) or"
	echo "       \"libicns-utils\" (Red Hat, Fedora, Cent OS, .. ) respectively is required"
	echo "       but was not found."
	exit_app
	exit 1
fi


TMPDLFILE=`${TMPAGENT} --suffix=".dmg"`

echo ""
echo "Downloading file from \"${DOWNLOADURL}\" to temporary location \"${TMPDLFILE}\":"
echo ""

if [ "${DLAGENT}" == "wget" ]; then
	wget --no-verbose --show-progress --output-document=${TMPDLFILE} "${DOWNLOADURL}"
else
	curl --progress-bar --output ${TMPDLFILE} --url "${DOWNLOADURL}"
fi

OLDIFS=${IFS}
IFS=$'\n'

TABLEHEADER=$(LC_ALL=C ${P7ZUTIL} l ${TMPDLFILE} | grep -A 99 -e '^\s\+Date\s\+Time\s\+\(Attr\s\+\)\?Size\s\+\Compressed\s\+\Name' | head -n1)

NAMECLMNPOS=`strindex "${TABLEHEADER}" "Name"`

HFSFILENAME=$(LC_ALL=C ${P7ZUTIL} l ${TMPDLFILE} | grep -A 99 -e '^\s\+Date\s\+Time\s\+\(Attr\s\+\)\?Size\s\+\Compressed\s\+\Name' | sed 's/^.\{'"${NAMECLMNPOS}"'\}//' | grep -e '\(hfs\|hfsplus\|hfs+\)')

TMPHFSFILE=`${TMPAGENT} --suffix=".hfsimg"`

echo "Extracting file \"${HFSFILENAME}\" to temporary location \"${TMPHFSFILE}\":"

RESULT=`$(${P7ZUTIL} e -so "${TMPDLFILE}" "${HFSFILENAME}" | cat - > ${TMPHFSFILE}); echo $?`

IFS=${OLDIFS}

if [ ! "${RESULT}" == "0" ]; then
	echo ""
	echo "I'm Sorry!"
	echo "An error occured during the file-extraction process."
	echo "Please check the FAQ section for this script on Github"
	echo "at https://github.com/tobiasvogel/cnlabSpeedTestLinux/wiki/FAQ"
	echo ""
	exit_app
	exit 1
fi

TMPMNTDIR=`create_tmpdir`

get_sudo

mount_hfs_img "${TMPHFSFILE}" "${TMPMNTDIR}"

INSTALLDIR=`get_install_dir`

TMPRUNSCRIPT=`${TMPAGENT} --suffix=".runscript"`

echo ""
echo "Downloading Launch-Script from \"${DOWNLOADGITSCRIPT}\" to temporary location \"${TMPRUNSCRIPT}\":"
echo ""

if [ "${DLAGENT}" == "wget" ]; then
	wget --no-verbose --show-progress --output-document=${TMPDLFILE} "${DOWNLOADGITSCRIPT}"
else
	curl --progress-bar --output ${TMPDLFILE} --url "${DOWNLOADGITSCRIPT}"
fi

run_sudo "`which mkdir` -v -m 755 ${INSTALLDIR}/cnlabSpeedTest ${INSTALLDIR}/cnlabSpeedTest/icons ${INSTALLDIR}/cnlabSpeedTest/logs"
run_sudo "`which cp` -R --no-preserve=mode ${TMPMNTDIR}/cnlabSpeedTest.app ${INSTALLDIR}/cnlabSpeedTest/"

run_sudo "`which icns2png` -x -d 32 -o ${INSTALLDIR}/cnlabSpeedTest/icons/ ${INSTALLDIR}/cnlabSpeedTest/cnlabSpeedTest.app/Contents/Resources/cnlabSpeedTest.icns"

run_sudo "`which mv` ${INSTALLDIR}/cnlabSpeedTest/cnlabSpeedTest.app/Contents/Java/* ${INSTALLDIR}/cnlabSpeedTest/"

run_sudo "`which mv` ${INSTALLDIR}/cnlabSpeedTest/cnlabSpeedTest.app/Contents/PlugIns/Java.runtime/Contents/Home/jre/lib/security ${INSTALLDIR}/cnlabSpeedTest/"

run_sudo "`which rm` -rf ${INSTALLDIR}/cnlabSpeedTest/cnlabSpeedTest.app"

run_sudo "`which cp` ${TMPRUNSCRIPT} ${INSTALLDIR}/cnlabSpeedTest/run.sh"

run_sudp "`which chmod` +x ${INSTALLDIR}/cnlabSpeedTest/run.sh"

run_sudo "`which ln` -sv ${INSTALLDIR}/cnlabSpeedTest/run.sh /usr/bin/cnlabSpeedTest"

if [ -d "/usr/share/pixmaps" ]; then
STDICON="`find ${INSTALLDIR}/cnlabSpeedTest/icons | grep 256`"
if [ -n "${STDICON}" ]; then
  run_sudo "`which ln` -sv ${STDICON} /usr/share/pixmaps/cnlabSpeedTest.png"
fi
fi