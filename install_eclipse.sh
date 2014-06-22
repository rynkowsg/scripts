#!/bin/bash

# Założenia:
# Paczka z eclipse musi być ściągnięta i podana w parametrze skryptu
# Powinno się też podać inne parametry, które uzupełnią plik skrótu.
# Przykłady użycia:
#       sudo ./install_eclipse.sh -p ~/Pobrane/eclipse-standard-kepler-SR2-linux-gtk-x86_64.tar.gz -n "Eclipse Standard" -c "Eclipse IDE for Java Developers"  -l Java
#       sudo ./install_eclipse.sh -r -p ~/Pobrane/eclipse-standard-kepler-SR2-linux-gtk-x86_64.tar.gz

DESTINATION=/opt
TEMP=/tmp

OWNERUSER=grzecho
OWNERGROUP=grzecho

REMOVE=false

while getopts rp:n:c:l: option
do
    case "${option}" in
        r) REMOVE=true;;
        p) PACKAGE=${OPTARG};;
        n) NAME=${OPTARG};;
        c) COMMENT=${OPTARG};;
        l) CATEGORY=${OPTARG};;
    esac
done

PACKAGE_DIR=$(basename ${PACKAGE} .tar.gz)
INSTALLATION_DIR="${DESTINATION}/${PACKAGE_DIR}"
APP_DESKTOP="/usr/share/applications/${PACKAGE_DIR}.desktop"

echo PACKAGE=${PACKAGE}
echo PACKAGE_DIR=${PACKAGE_DIR}
echo INSTALLATION_DIR=${INSTALLATION_DIR}
echo APP_DESKTOP=${APP_DESKTOP}

echo REMOVE=${REMOVE}

if $REMOVE; then
    [[ -d "${INSTALLATION_DIR}" ]] || [[ -f "${APP_DESKTOP}" ]] || exit 2
    rm --force --recursive --verbose ${INSTALLATION_DIR} ${APP_DESKTOP}
    exit 0
fi

echo NAME=${NAME}
echo COMMENT=${COMMENT}
echo CATEGORY=${CATEGORY}

UNPACKED_TMP="${TEMP}/eclipse"
[[ -d "${UNPACKED_TMP}"  ]] && rm -rf "${UNPACKED_TMP}"
tar -zxf "${PACKAGE}" --directory "${TEMP}"

[[ -d "${INSTALLATION_DIR}"  ]] && rm -rf "${INSTALLATION_DIR}"
mv "${UNPACKED_TMP}" "${INSTALLATION_DIR}"

chown -R ${OWNERUSER}:${OWNERGROUP} "${INSTALLATION_DIR}"


echo "[Desktop Entry]
Type=Application
Name=${PACKAGE_DIR}
Comment=
Icon=${INSTALLATION_DIR}/icon.xpm
Exec=${INSTALLATION_DIR}/eclipse
Terminal=false
Categories=Development;IDE;" > ${APP_DESKTOP}

sed --in-place --expression "s:\(Name=\).*:\1${NAME}:g" ${APP_DESKTOP}
sed --in-place --expression "s:\(Comment=\).*:\1${COMMENT}:g" ${APP_DESKTOP}
sed --in-place --expression "s:\(Categories=.*\):\1${CATEGORY};:g" ${APP_DESKTOP}

exit 0
