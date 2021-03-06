#!/bin/bash

# This script is used by the main developer to quickly compile and install the current version
# of Guake sources. Nothing say it will work directly on your environment. Use with caution!

NO_INSTALL=true
RUN_TESTS=false
CREATE_ENV=true
EXEC_AUTOGEN=false
EXEC_UPDATE_PO=false

echo "execute guake for developer."
echo "use --test to run tests"
echo "use --install to install guake on your system"
echo "use --no-create-env to disable virtualenv creation"
echo "(beware, gconf schema will be altered)"
echo "use --reinstall to force complete reinstall"
echo "use --uninstall to force complete uninstall"
echo "use --update-po to force update translations"

ARGS=$*
if [[ `echo $ARGS | grep --regexp="--no-create-env"` ]]; then
    CREATE_ENV=false
fi

if [[ `echo $ARGS | grep --regexp="--test"` ]]; then
    RUN_TESTS=true
fi


if [[ $1 == "--install" ]]; then
    NO_INSTALL=false
fi

if [[ $1 == "--uninstall" ]]; then
    UNINSTALL=true
fi

if [[ $1 == "--reinstall" ]]; then
    EXEC_AUTOGEN=true
fi

if [[ $1 == "--update-po" ]]; then
    EXEC_UPDATE_PO=true
fi

if [[ ! -f configure ]]; then
    EXEC_AUTOGEN=true
fi

if [[ $EXEC_AUTOGEN == true ]]; then
    sudo apt-get install -y build-essential python autoconf
    sudo apt-get install -y gnome-common gtk-doc-tools libglib2.0-dev libgtk2.0-dev libgconf2-dev
    sudo apt-get install -y python-gtk2 python-gtk2-dev python-vte glade python-glade2
    sudo apt-get install -y python-vte python-gconf python-appindicator
    sudo apt-get install -y notify-osd libutempter0 glade-gtk2
    sudo apt-get install -y python-notify python-xdg python-keybinder
    sudo pip install colorlog
    if [[ -f Makefile ]]; then
        make clean
    fi
    ./autogen.sh
fi

if [[ $UNINSTALL == true ]]; then
    sudo make uninstall
    if [[ -d env ]]; then
        rm -rfv env
    fi
    exit 1
fi

make || exit 1
if [[ $EXEC_UPDATE_PO == true ]]; then
    cd po
    make update-po || exit 1
    make || exit 1
    cd ..
fi

function make_virtualenv {
    echo "Trying to prepare a virtualenv"
    if [[ ! -d env ]]; then
        virtualenv --system-site-packages env
    fi
    echo "sourcing env" && source env/bin/activate
    echo "Installing dev requirements" && pip install --upgrade -r python-requirements.txt
    gconftool-2 --install-schema-file=data/guake.schemas
}

# RUN TESTS or RUN GUAKE without installing it
if [[ $NO_INSTALL == true ]]; then

    if [[ $CREATE_ENV == true ]]; then
        make_virtualenv
    fi
    echo "sourcing env" && source env/bin/activate

    if [[ $RUN_TESTS == true ]]; then
        echo "running tests.."
        PYTHONPATH=src env/bin/py.test src/guake/tests
    else
        echo "Launching guake inside virtualenv"
        PYTHONPATH=src python2.7 src/guake/main.py --no-startup-script
    fi

else
  sudo make install && gconftool-2 --install-schema-file=/usr/local/etc/gconf/schemas/guake.schemas || exit 1

  guake --quit 2> /dev/null
  guake --no-startup-script
fi
