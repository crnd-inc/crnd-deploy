#--------------------------------------------------
# Apply environment configuration
#--------------------------------------------------
ODOO_REPO=${ODOO_REPO:-https://github.com/managment-and-acounting-on-line/maao};
ODOO_BRANCH=${ODOO_BRANCH:-maao-9.0};
ODOO_USER=${ODOO_USER:-odoo};
PROJECT_ROOT_DIR=${ODOO_INSTALL_DIR:-/opt/odoo};
DB_HOST=${ODOO_DB_HOST:-localhost};
DB_PORT=${ODOO_DB_PORT:-5432}
DB_USER=${ODOO_DB_USER:-odoo};
DB_PASSWORD=${ODOO_DB_PASSWORD:-odoo};

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
ODOO_PID_FILE="/var/run/odoo.pid";  # default odoo pid file location

echo "---Create project tree---"
install_create_project_dir_tree;   # imported from 'install' module
# install_system_prerequirements;    # imported from 'install' module


# install_and_configure_postgresql;   # imported from 'install' module

if [ ! -d $ODOO_PATH ]; then
    echo "--- Clonning odoo ---";
    install_clone_odoo;   # imported from 'install' module
else
    echo "--- Odoo seems to be installed ---";
fi

echo "--- installing system dependencies ---"
install_sys_deps;   # imported from 'install' module
#install_python_prerequirements 1;   # imported from 'install' module

echo "--- installing odoo ---"
# Run setup.py with gevent workaround applied.
odoo_run_setup_py;  # imported from 'install' module

# generate odoo config file
declare -A ODOO_CONF_OPTIONS;
ODOO_CONF_OPTIONS[addons_path]="$ADDONS_PATH";
ODOO_CONF_OPTIONS[admin_passwd]="${ODOO_ADMIN_PASS:-$(random_string 32)}";
ODOO_CONF_OPTIONS[data_dir]="$DATA_DIR";
ODOO_CONF_OPTIONS[logfile]="";  # No log file for docker odoo instance
ODOO_CONF_OPTIONS[db_host]="$DB_HOST";
ODOO_CONF_OPTIONS[db_port]="$DB_PORT";
ODOO_CONF_OPTIONS[db_user]="$DB_USER";
ODOO_CONF_OPTIONS[db_password]="$DB_PASSWORD";
ODOO_CONF_OPTIONS[pidfile]="";
install_generate_odoo_conf $ODOO_CONF_FILE;   # imported from 'install' module

# Write odoo-helper project config
echo "#---ODOO-INSTANCE-CONFIG---" >> /etc/$CONF_FILE_NAME;
echo "`print_helper_config`" >> /etc/$CONF_FILE_NAME;

echo -e "\n${GREENC}Odoo installed!${NC}\n";

