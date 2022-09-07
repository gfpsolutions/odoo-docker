#!/bin/bash
set -e

# set the postgres database host, port, user and password according to the environment
# and pass them as arguments to the odoo process if not present in the config file
#: ${HOST:=${DB_PORT_5432_TCP_ADDR:='db'}}
#: ${PORT:=${DB_PORT_5432_TCP_PORT:=5432}}
#: ${USER:=${DB_ENV_POSTGRES_USER:=${POSTGRES_USER:='odoo'}}}
#: ${PASSWORD:=${DB_ENV_POSTGRES_PASSWORD:=${POSTGRES_PASSWORD:='odoo'}}}

# Custom Addons 
cd $S3_MOUNT_DIRECTORY_ADDONS
#git clone -b $ODOO_VERSION --single-branch --depth 1 https://$GITHUB_ACCESS_TOKEN@github.com/odoo/enterprise
git clone https://$GITHUB_ACCESS_TOKEN@github.com/gfpsolutions/enterprise
cd $S3_MOUNT_DIRECTORY_ADDONS/custom
git clone -b $GITHUB_CUSTOM_MODULE_BRANCH --single-branch --depth 1 https://$GITHUB_ACCESS_TOKEN@github.com/gfpsolutions/$GITHUB_CUSTOM_MODULE
git clone -b master --single-branch --depth 1 https://$GITHUB_ACCESS_TOKEN@github.com/gfpsolutions/delivery_ss
git clone -b main --single-branch --depth 1 https://$GITHUB_ACCESS_TOKEN@github.com/gfpsolutions/web_gantt_native
git clone -b main --single-branch --depth 1 https://$GITHUB_ACCESS_TOKEN@github.com/gfpsolutions/web_widget_time_delta
git clone -b main --single-branch --depth 1 https://$GITHUB_ACCESS_TOKEN@github.com/gfpsolutions/web_widget_colorpicker
git clone -b main --single-branch --depth 1 https://$GITHUB_ACCESS_TOKEN@github.com/gfpsolutions/project_native
chown -R odoo $S3_MOUNT_DIRECTORY_ADDONS 
pip3 install holidays==0.10.3
pip3 install easypost
pip3 install dropbox

DB_ARGS=()
function check_config() {
    param="$1"
    value="$2"
    if grep -q -E "^\s*\b${param}\b\s*=" "$ODOO_RC" ; then       
        value=$(grep -E "^\s*\b${param}\b\s*=" "$ODOO_RC" |cut -d " " -f3|sed 's/["\n\r]//g')
    fi;
    DB_ARGS+=("--${param}")
    DB_ARGS+=("${value}")
}
#check_config "db_host" "$HOST"
#check_config "db_port" "$PORT"
#check_config "db_user" "$USER"
#check_config "db_password" "$PASSWORD"
check_config "db_host" "$ODOO_DB_SERVICE_HOST"
check_config "db_port" "$ODOO_DB_SERVICE_PORT"
check_config "db_user" "$USER"
check_config "db_password" "$PASSWORD"

case "$1" in
    -- | odoo)
        shift
        if [[ "$1" == "scaffold" ]] ; then
            exec odoo "$@"
        else
            wait-for-psql.py ${DB_ARGS[@]} --timeout=30
            exec odoo "$@" "${DB_ARGS[@]}"
        fi
        ;;
    -*)
        wait-for-psql.py ${DB_ARGS[@]} --timeout=30
        exec odoo "$@" "${DB_ARGS[@]}"
        ;;
    *)
        exec "$@"
esac

exit 1
