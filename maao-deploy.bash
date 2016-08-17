#!/bin/bash

# WARN: Must be ran under SUDO

# Supports passing parametrs as environment variables and as arguments to script
# Environment vars and default values:
#   ODOO_USER=odoo
#   ODOO_INSTALL_DIR=/opt/odoo
#   ODOO_DB_HOST=localhost
#   ODOO_DB_USER=odoo
#   ODOO_DB_PASSWORD=odoo
#   ODOO_REPO=https://github.com/managment-and-acounting-on-line/maao
#   ODOO_BRANCH=maao-9.0
#
# Also some configuration could be passed as command line args:
#   sudo bash maao-deploy.bash <db_host> <db_user> <db_pass>
# 

# Parse environment variables
ODOO_REPO=${ODOO_REPO:-https://github.com/managment-and-acounting-on-line/maao};
ODOO_BRANCH=${ODOO_BRANCH:-maao-9.0};
ODOO_USER=${ODOO_USER:-odoo};
PROJECT_ROOT_DIR=${ODOO_INSTALL_DIR:-/opt/odoo};
DB_HOST=${ODOO_DB_HOST:-localhost};
DB_USER=${ODOO_DB_USER:-odoo};
DB_PASSWORD=${ODOO_DB_PASSWORD:-odoo};

# parse commandline args
DB_HOST=${1:-$DB_HOST};
DB_USER=${2:-$DB_USER};
DB_PASSWORD=${3:-$DB_PASSWORD};

set -e;   # fail on errors

#--------------------------------------------------
# Update Server
#--------------------------------------------------
echo -e "\n${BLUEC}Update Server...${NC}\n";
sudo apt-get update
sudo apt-get upgrade -y

# Install extra dependencies
sudo apt-get install -y libtiff5-dev libjpeg8-dev zlib1g-dev \
        libfreetype6-dev liblcms2-dev libwebp-dev 

#--------------------------------------------------
# Install odoo-helper-scripts
#--------------------------------------------------
echo -e "\n${BLUEC}Installing odoo-helper-scripts${NC}\n";
wget -O - https://raw.githubusercontent.com/katyukha/odoo-helper-scripts/dev/install-system.bash | sudo bash -s
sudo odoo-helper system update dev   # checkout to dev version of helpere scripts


#--------------------------------------------------
# Install Odoo
#--------------------------------------------------
echo -e "\n${BLUEC}Installing odoo...${NC}\n";
# import odoo-helper common module, which contains some useful functions
source $(odoo-helper system lib-path common);

# import odoo-helper libs
ohelper_require 'install';

# Do not ask confirmation when installing dependencies
ALWAYS_ANSWER_YES=1;

# Configure default odoo-helper variables
config_default_vars;  # imported from common module
unset VENV_DIR;       # disable vertual environment

# define addons path to be placed in config files
ADDONS_PATH="$ODOO_PATH/openerp/addons,$ODOO_PATH/addons,$ADDONS_DIR";
INIT_SCRIPT="/etc/init.d/odoo";
ODOO_PID_FILE="/var/run/odoo.pid";  # default odoo pid file location

install_create_project_dir_tree;   # imported from 'install' module
install_system_prerequirements;    # imported from 'install' module


# install_and_configure_postgresql;   # imported from 'install' module

if [ ! -d $ODOO_PATH ]; then
    install_clone_odoo;   # imported from 'install' module
fi

install_sys_deps;   # imported from 'install' module
install_python_prerequirements 1;   # imported from 'install' module

# Run setup.py with gevent workaround applied.
odoo_run_setup_py;  # imported from 'install' module

# generate odoo config file
declare -A ODOO_CONF_OPTIONS;
ODOO_CONF_OPTIONS[addons_path]="$ADDONS_PATH";
ODOO_CONF_OPTIONS[admin_passwd]="$(random_string 32)";
ODOO_CONF_OPTIONS[data_dir]="$DATA_DIR";
ODOO_CONF_OPTIONS[logfile]="$LOG_FILE";
ODOO_CONF_OPTIONS[db_host]="$DB_HOST";
ODOO_CONF_OPTIONS[db_port]="False";
ODOO_CONF_OPTIONS[db_user]="$DB_USER";
ODOO_CONF_OPTIONS[db_password]="$DB_PASSWORD";
ODOO_CONF_OPTIONS[pidfile]="None";   # pid file will be managed by init script, not odoo itself
install_generate_odoo_conf $ODOO_CONF_FILE;   # imported from 'install' module

# Write odoo-helper project config
echo "#---ODOO-INSTANCE-CONFIG---" >> /etc/$CONF_FILE_NAME;
echo "`print_helper_config`" >> /etc/$CONF_FILE_NAME;


#--------------------------------------------------
# Create Odoo User
#--------------------------------------------------
if ! getent passwd $ODOO_USER  > /dev/null; then
    echo -e "\n${BLUEC}Createing Odoo user: $ODOO_USER ${NC}\n";
    sudo adduser --system --no-create-home --home $PROJECT_ROOT_DIR --quiet --group $ODOO_USER;
else
    echo -e "\n${YELLOWC}Odoo user already exists, using it.${NC}\n";
fi

#--------------------------------------------------
# Create Init Script
#--------------------------------------------------
echo -e "\n${BLUEC}Creating init script${NC}\n";
cp $ODOO_PATH/debian/init /etc/init.d/odoo
chmod a+x /etc/init.d/odoo
sed -i -r "s@DAEMON=(.*)@DAEMON=/usr/local/bin/odoo.py@" /etc/init.d/odoo;
sed -i -r "s@CONFIG=(.*)@CONFIG=$ODOO_CONF_FILE@" /etc/init.d/odoo;
sed -i -r "s@LOGFILE=(.*)@LOGFILE=$LOG_FILE@" /etc/init.d/odoo;
sed -i -r "s@USER=(.*)@USER=$ODOO_USER@" /etc/init.d/odoo;
sudo update-rc.d odoo defaults

# Configuration file
chown root:$ODOO_USER $ODOO_CONF_FILE
chmod 0640 $ODOO_CONF_FILE;

# Log
chown $ODOO_USER:$ODOO_USER $LOG_DIR
chmod 0750 $LOG_DIR

# Data dir
chown $ODOO_USER:$ODOO_USER $DATA_DIR

#--------------------------------------------------
# Configure logrotate
#--------------------------------------------------
echo -e "\n${BLUEC}Configuring logrotate${NC}\n";
cat > /etc/logrotate.d/odoo << EOF
$LOG_DIR/*.log {
    copytruncate
    missingok
    notifempty
}
EOF

echo -e "\n${GREENC}Odoo installed!${NC}\n";