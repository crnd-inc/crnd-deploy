#!/bin/bash

# TODO:
#      - optionaly install nginx
#      - optionaly configure nginx

# WARN: Must be ran under SUDO

# NOTE: Automaticaly installs odoo-helper-scripts if not installed yet

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

#--------------------------------------------------
# Script params
#--------------------------------------------------
SCRIPT=$0;
SCRIPT_NAME=$(basename $SCRIPT);
SCRIPT_DIR=$(dirname $SCRIPT);
SCRIPT_PATH=$(readlink -f $SCRIPT);
NGIX_CONF_GEN="$SCRIPT_DIR/gen_nginx.py";

WORKDIR=`pwd`;


#--------------------------------------------------
# Parse environment variables
#--------------------------------------------------
ODOO_REPO=${ODOO_REPO:-https://github.com/managment-and-acounting-on-line/maao};
ODOO_BRANCH=${ODOO_BRANCH:-maao-9.0-translate};
ODOO_VERSION=${ODOO_VERSION:-9.0};
ODOO_USER=${ODOO_USER:-odoo};
PROJECT_ROOT_DIR=${ODOO_INSTALL_DIR:-/opt/odoo};
DB_HOST=${ODOO_DB_HOST:-localhost};
DB_USER=${ODOO_DB_USER:-odoo};
DB_PASSWORD=${ODOO_DB_PASSWORD:-odoo};
INSTALL_MODE=${INSTALL_MODE:-git};


#--------------------------------------------------
# Define color variables
#--------------------------------------------------
NC='\e[0m';
REDC='\e[31m';
GREENC='\e[32m';
YELLOWC='\e[33m';
BLUEC='\e[34m';
LBLUEC='\e[94m';


#--------------------------------------------------
# FN: Print usage
#--------------------------------------------------
function print_usage {

    echo "
Usage:

    maao-deploy [options]    - install odoo

Options:

    --odoo-repo <repo>       - git repository to clone odoo from.
                               default: $ODOO_REPO
    --odoo-branch <branch>   - odoo branch to clone. default: $ODOO_BRANCH
    --odoo-version <version> - odoo version to clone. default: $ODOO_VERSION
    --odoo-user <user>       - name of system user to run odoo with.
                               default: $ODOO_USER
    --db-host <host>         - database host to be used by odoo.
                               default: $DB_HOST
    --db-user <user>         - database user to connect to db with
                               default: $DB_USER
    --db-password <password> - database password to connect to db with
                               default: $DB_PASSWORD
    --install-dir <path>     - directory to install odoo in
                               default: $PROJECT_ROOT_DIR
    --install-mode <mode>    - installation mode. could be: 'git', 'archive'
                               default: $INSTALL_MODE
    --local-postgres         - install local instance of postgresql server
    --proxy-mode             - Set this option if you plan to run odoo
                               behind proxy (nginx, etc)
    --local-nginx            - install local nginx and configure it for this
                               odoo instance
    -h|--help|help           - show this help message
";
}

#--------------------------------------------------
# Parse command line
#--------------------------------------------------
while [[ $# -gt 0 ]]
do
    key="$1";
    case $key in
        --odoo-repo)
            ODOO_REPO=$2;
            shift;
        ;;
        --odoo-branch)
            ODOO_BRANCH=$2;
            shift;
        ;;
        --odoo-version)
            ODOO_VERSION=$2;
            shift;
        ;;
        --odoo-user)
            ODOO_USER=$2;
            shift;
        ;;
        --db-host)
            DB_HOST=$2;
            shift;
        ;;
        --db-user)
            DB_USER=$2;
            shift;
        ;;
        --db-password)
            DB_PASSWORD=$2;
            shift;
        ;;
        --install-dir)
            PROJECT_ROOT_DIR=$2;
            shift;
        ;;
        --install-mode)
            if [ "$2" != "git" ] && [ "$2" != "archive" ]; then
                echo "ERROR: Wrong install mode specified: $2"
                exit 1;
            fi
            INSTALL_MODE=$2;
        ;;
        --proxy-mode)
            PROXY_MODE=1;
        ;;
        --local-postgres)
            # Generate random password for database
            DB_HOST="localhost";
            DB_PASSWORD="$(< /dev/urandom tr -dc A-Za-z0-9 | head -c 12)";
            INSTALL_LOCAL_POSTGRES=1;
        ;;
        --local-nginx)
            INSTALL_LOCAL_NGINX=1;
            PROXY_MODE=1;
        ;;
        -h|--help|help)
            print_usage;
            exit 0;
        ;;
        *)
            echo "Unknown option global option /command $key";
            echo "Use --help option to get info about available options.";
            exit 1;
        ;;
    esac;
    shift;
done;
#--------------------------------------------------


set -e;   # fail on errors

#--------------------------------------------------
# Update Server and Install Dependencies
#--------------------------------------------------
echo -e "\n${BLUEC}Update Server...${NC}\n";
sudo apt-get update -qq
sudo apt-get upgrade -qq -y
sudo apt-get install -qq -y libtiff5-dev libjpeg8-dev zlib1g-dev \
        libfreetype6-dev liblcms2-dev libwebp-dev wget git

#--------------------------------------------------
# Generate locales
#--------------------------------------------------
echo -e "\n${BLUEC}Update locales...${NC}\n";
sudo locale-gen en_US.UTF-8
sudo locale-gen ru_UA.UTF-8
sudo locale-gen uk_UA.UTF-8

#--------------------------------------------------
# Ensure odoo-helper installed
#--------------------------------------------------
if ! command -v odoo-helper >/dev/null 2>&1; then
    echo -e "Odoo-helper not installed! installing...";
    wget -O /tmp/odoo-helper-install.bash \
        https://raw.githubusercontent.com/katyukha/odoo-helper-scripts/master/install-system.bash;

    # install latest version of odoo-helper scripts
    sudo bash /tmp/odoo-helper-install.bash dev
fi

# Install odoo pre-requirements
sudo odoo-helper install pre-requirements -y;
sudo odoo-helper install sys-deps -y $ODOO_VERSION;

if [ ! -z $INSTALL_LOCAL_POSTGRES ]; then
    sudo odoo-helper install postgres $DB_USER $DB_PASSWORD;
fi

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
ADDONS_PATH="$ODOO_PATH/openerp/addons,$ODOO_PATH/odoo/addons,$ODOO_PATH/addons,$ADDONS_DIR";
INIT_SCRIPT="/etc/init.d/odoo";
ODOO_PID_FILE="$PROJECT_ROOT_DIR/odoo.pid";  # default odoo pid file location

install_create_project_dir_tree;   # imported from 'install' module

if [ ! -d $ODOO_PATH ]; then
    if [ "$INSTALL_MODE" == "git" ]; then
        install_clone_odoo;   # imported from 'install' module
    elif [ "$INSTALL_MODE" == "archive" ]; then
        install_download_odoo;
    else
        echo -e "${REDC}ERROR:${NC} wrong install mode specified: '$INSTALL_MODE'!";
    fi
fi

install_python_prerequirements;   # imported from 'install' module

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

# pid file will be managed by init script, not odoo itself
ODOO_CONF_OPTIONS[pidfile]="None";

if [ ! -z $PROXY_MODE ]; then
    ODOO_CONF_OPTIONS[proxy_mode]="True";
fi

install_generate_odoo_conf $ODOO_CONF_FILE;   # imported from 'install' module

# Write odoo-helper project config
echo "#---ODOO-INSTANCE-CONFIG---" >> /etc/$CONF_FILE_NAME;
echo "`print_helper_config`" >> /etc/$CONF_FILE_NAME;

# this will make odoo helper scripts to run odoo with specified user
# (via sudo call)
echo "SERVER_RUN_USER=$ODOO_USER;" >> /etc/$CONF_FILE_NAME;

#--------------------------------------------------
# Fix odoo 9/10 addons path compatability
#--------------------------------------------------
if [ ! -d $ODOO_PATH/openerp/addons ]; then
    mkdir -p $ODOO_PATH/openerp/addons;
fi
if [ ! -d $ODOO_PATH/odoo/addons ]; then
    mkdir -p $ODOO_PATH/odoo/addons;
fi

#--------------------------------------------------
# Create Odoo User
#--------------------------------------------------
if ! getent passwd $ODOO_USER  > /dev/null; then
    echo -e "\n${BLUEC}Createing Odoo user: $ODOO_USER ${NC}\n";
    sudo adduser --system --no-create-home --home $PROJECT_ROOT_DIR \
        --quiet --group $ODOO_USER;
else
    echo -e "\n${YELLOWC}Odoo user already exists, using it.${NC}\n";
fi

#--------------------------------------------------
# Create Init Script
#--------------------------------------------------
echo -e "\n${BLUEC}Creating init script${NC}\n";
cp $ODOO_PATH/debian/init /etc/init.d/odoo
chmod a+x /etc/init.d/odoo
sed -i -r "s@DAEMON=(.*)@DAEMON=$(check_command odoo.py odoo)@" /etc/init.d/odoo;
sed -i -r "s@CONFIG=(.*)@CONFIG=$ODOO_CONF_FILE@" /etc/init.d/odoo;
sed -i -r "s@LOGFILE=(.*)@LOGFILE=$LOG_FILE@" /etc/init.d/odoo;
sed -i -r "s@USER=(.*)@USER=$ODOO_USER@" /etc/init.d/odoo;
sudo update-rc.d odoo defaults

# Configuration file
chown root:$ODOO_USER $ODOO_CONF_FILE;
chmod 0640 $ODOO_CONF_FILE;

# Log
chown $ODOO_USER:$ODOO_USER $LOG_DIR;
chmod 0750 $LOG_DIR

# Data dir
chown $ODOO_USER:$ODOO_USER $DATA_DIR;

# Odoo root dir
chown $ODOO_USER:$ODOO_USER $PROJECT_ROOT_DIR;

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

if [ ! -z $INSTALL_LOCAL_NGINX ]; then
    echo -e "${BLUEC}Installing and configuring local nginx..,${NC}";
    NGINX_CONF_PATH="/etc/nginx/sites-available/$(hostname).conf";
    sudo apt-get install nginx;
    sudo python $NGIX_CONF_GEN \
        --instance-name="$(hostname -s)" \
        --frontend-server-name="$(hostname)" > $NGINX_CONF_PATH;
    echo -e "${GREENC}Nginx seems to be installed and default config is generated. ";
    echo -e "Look at $NGINX_CONF_PATH for nginx config.${NC}";
fi

