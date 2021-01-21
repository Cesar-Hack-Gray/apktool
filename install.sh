#!/data/data/com.termux/files/usr/bin/sh

#colors 
red='\033[1;31m'  
yellow='\033[1;33m'
reset='\033[0m'

ALPINEDIR="${PREFIX}/share/CHG"
BINDIR="${PREFIX}/bin"
LIBDIR="${ALPINEDIR}/usr/lib"

detect_os() {
	if [ -e $BINDIR/termux-info ]; then
		OS=TERMUX
		AAPT="-a /usr/bin/aapt2"
	else
		grep kali /etc/os-release > /dev/null 2>&1
		if [ $? -eq 0 ]; then
			OS=KALI
			AAPT="--use-aapt2"
		else
			printf "${red}[!] ${yellow}Unsupported system\n"
			exit 1
		fi
	fi
}

install_deps_kali() {
	printf "[*] Installing dependencies...\n"
	apt-get install metasploit-framework bc apktool default-jdk -y > /dev/null
#wget https://github.com/hax4us/Apkmod/raw/master/apkmod.sh -O $PREFIX/bin/apkmod && chmod +x $PREFIX/bin/apkmod
	printf "[*] Done\n"
}

setup_alpine() {
	if [ ! "$1" = "--without-alpine" ]; then
		wget https://raw.githubusercontent.com/Cesar-Hack-Gray/release-download/master/TermuxAlpine.sh -O TermuxAlpine.sh
		bash TermuxAlpine.sh
	fi
	mkdir -p ${ALPINEDIR}/root/.bind
	cat <<EOF | startalpine
	apk add openjdk8-jre libbsd zlib expat libpng protobuf
EOF
}

install_deps() {
	for pkg in aapt apksigner wget bc; do
		if [ ! -f ${BINDIR}/${pkg} ]; then
			apt install ${pkg} -y
		fi
	done
	case "$(getprop ro.product.cpu.abi)" in
		arm64-v8a)
			ARCH=aarch64
			;;
		armeabi|armeabi-v7a)
			ARCH=arm
			;;
		x86|i686)
			ARCH=x86
			;;
		x86_64)
			ARCH=x86_64
			;;
		*)
			printf "your device "$(uname -m)" is not supported yet"
			exit 1
			;;
	esac



	aapturl=https://raw.githubusercontent.com/Cesar-Hack-Gray/apktool/master/aapt/${ARCH}/aapt.tar.gz





	wget ${aapturl} -O aapt.tar.gz && tar -xf aapt.tar.gz -C ${LIBDIR} && rm aapt.tar.gz
	
    for i in aapt aapt2; do
		mv ${LIBDIR}/android/${i} ${ALPINEDIR}/usr/bin
	done

	apktoolurl=https://bitbucket.org/iBotPeaches/apktool/downloads/apktool_2.4.1.jar
	wget ${apktoolurl} -O ${ALPINEDIR}/opt/apktool.jar
	wget https://github.com/hax4us/Apkmod/raw/master/apkmod.sh -O ${BINDIR}/apkmod
	chmod +x ${BINDIR}/apkmod
	chmod +x ${ALPINEDIR}/usr/bin/aapt
	chmod +x ${ALPINEDIR}/usr/bin/aapt2
	rm -rf ~/.apkmod && mkdir -p ~/.apkmod/framework
#ttps://github.com/hax4us/Apkmod/raw/master/apkmod.p12 -O ~/.apkmod/apkmod.p12
}

install_scripts() {
	for Cesar in apkmux.sh apktne.sh apk.rb CHGmux.sh jane.sh; do
		wget https://github.com/Cesar-Hack-Gray/raw/master/.Gray/${Cesar} -O ${Cesar}


	done

	mv apkmux.sh ${BINDIR}/apktool && chmod +x ${BINDIR}/apktool
	mv apktne.sh ${ALPINEDIR}/bin/apktool && chmod +x ${ALPINEDIR}/bin/apktool
    mv CHGmux.sh $BINDIR/jadx && chmod +x $BINDIR/jadx
    mv jane.sh $ALPINEDIR/bin/jadx && chmod +x $ALPINEDIR/bin/jadx

	if [ -d ${HOME}/metasploit-framework -a -d ${PREFIX}/opt/metasploit-framework ]; then
		printf "${red}[!] More than one metasploit detected ,\nremove anyone from them and reinstall Apkmod\notherwise apkmod will not work as expected${reset}"
	elif [ -d ${HOME}/metasploit-framework ]; then
		msf_dir=${HOME}/metasploit-framework
		mv apk.rb ${msf_dir}/lib/msf/core/payload/
	elif [ -d ${PREFIX}/opt/metasploit-framework ]; then
		msf_dir=${PREFIX}/opt/metasploit-framework
		mv apk.rb ${msf_dir}/lib/msf/core/payload/
	else
		printf "${red}[!] Metasploit is not installed hence -b ( bind ) option will not work${reset}"
	fi
}

do_patches() {
    sed -i "s#AAPT=.*#AAPT=\"$AAPT\"#" $BINDIR/apkmod
    if [ $OS = "KALI" ]; then
        sed -i s/"apktool b"/"apktool b --use-aapt2"/g /usr/share/metasploit-framework/lib/msf/core/payload/apk.rb
    fi
}

jadx() {
    JADXVER=1.1.0
    JADXURL=https://github.com/skylot/jadx/releases/download/v${JADXVER}/jadx-$JADXVER.zip
    wget $JADXURL
    mkdir -p $ALPINEDIR/usr/lib/jadx
    unzip jadx-$JADXVER.zip -d $ALPINEDIR/usr/lib/jadx
}

##################
#  MAIN DRIVER   #
##################

detect_os

if [ $OS = "TERMUX" ]; then
	termux-wake-lock
	# Temporary check for alpine version 
	# so that if user has already installed
	# TermuxAlpine then check if this alpine 
	# was installed by apkmod or not.
	if [ -d $PREFIX/share/TermuxAlpine ]; then
		if [ "$(cat $PREFIX/share/TermuxAlpine/etc/alpine-release)" = "3.10.2" ]; then
			mv $PREFIX/share/TermuxAlpine $ALPINEDIR
		fi
	fi
	setup_alpine "$1"
	install_deps
	install_scripts
	jadx
	termux-wake-unlock
else
	install_deps_kali
fi

do_patches
