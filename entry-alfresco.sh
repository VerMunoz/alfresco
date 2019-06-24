#!/usr/bin/env bash

# Script gathered from: https://raw.githubusercontent.com/gui81/docker-alfresco/ and modified by Vero is FIRST. 
#Verificación de archivos

trap "container_stop" SIGTERM SIGINT 
export STOP=0;

ALFRESCO_CONFIG="/opt/alfresco-community/tomcat/shared/classes/"
if [ ! -f $ALFRESCO_CONFIG/alfresco-global.properties ]; then
   tar -xzf /tmp/docker_config.tar.gz -C /
fi

# Step 0: Set the Alfresco HOME

ALF_HOME=${ALF_HOME:="/opt/alfresco-community"}
ALF_BIN=$ALF_HOME/bin
ALF_SETUP=$ALF_HOME/setup
CATALINA_HOME=$ALF_HOME/tomcat
CONTENT_STORE=${CONTENT_STORE:="$ALF_HOME/alf_data/contentstore"}
ALFRESCO_GLOBAL_PROPERTIES=$CATALINA_HOME/shared/classes/alfresco-global.properties

# Step 1: set functions 

function container_stop {
    export STOP=1;
}

function cfg_replace_option {
  grep "$1" "$3" > /dev/null
  if [ $? -eq 0 ]; then
    # replace option
    echo "replacing option  $1=$2  in  $3"
    sed -i "s#^\($1\s*=\s*\).*\$#\1$2#" $3
    if (( $? )); then
      echo "cfg_replace_option failed"
      exit 1
    fi
  else
    # add option if it does not exist
    echo "adding option  $1=$2  in  $3"
    echo "$1=$2" >> $3
  fi
}


function tweak_alfresco {

 cfg_replace_option alfresco.host $DIR_ROOT $ALFRESCO_GLOBAL_PROPERTIES
  #alfresco host+proto+port
  cfg_replace_option alfresco.host $ALFRESCO_HOSTNAME $ALFRESCO_GLOBAL_PROPERTIES
  cfg_replace_option alfresco.protocol $ALFRESCO_PROTOCOL $ALFRESCO_GLOBAL_PROPERTIES
  cfg_replace_option alfresco.port $ALFRESCO_PORT $ALFRESCO_GLOBAL_PROPERTIES

  #share host+proto+port
  cfg_replace_option share.host $SHARE_HOSTNAME $ALFRESCO_GLOBAL_PROPERTIES
  cfg_replace_option share.protocol $SHARE_PROTOCOL $ALFRESCO_GLOBAL_PROPERTIES
  cfg_replace_option share.port $SHARE_PORT $ALFRESCO_GLOBAL_PROPERTIES

  #set server mode
  cfg_replace_option system.serverMode $SYSTEM_SERVERMODE $ALFRESCO_GLOBAL_PROPERTIES

  #db.schema.update=true
  cfg_replace_option db.driver $DB_DRIVER $ALFRESCO_GLOBAL_PROPERTIES
  cfg_replace_option db.username $DB_USERNAME $ALFRESCO_GLOBAL_PROPERTIES
  cfg_replace_option db.password $DB_PASSWORD $ALFRESCO_GLOBAL_PROPERTIES
  cfg_replace_option db.name $DB_NAME $ALFRESCO_GLOBAL_PROPERTIES
  cfg_replace_option db.host $DB_HOST $ALFRESCO_GLOBAL_PROPERTIES
  cfg_replace_option db.port $DB_PORT $ALFRESCO_GLOBAL_PROPERTIES
  cfg_replace_option db.url jdbc:${DB_KIND,,}://${DB_HOST}:${DB_PORT}/${DB_NAME}${DB_CONN_PARAMS} $ALFRESCO_GLOBAL_PROPERTIES

  cfg_replace_option mail.host $MAIL_HOST $ALFRESCO_GLOBAL_PROPERTIES
  cfg_replace_option mail.port $MAIL_PORT $ALFRESCO_GLOBAL_PROPERTIES
  cfg_replace_option mail.username $MAIL_USERNAME $ALFRESCO_GLOBAL_PROPERTIES
  cfg_replace_option mail.password $MAIL_PASSWORD $ALFRESCO_GLOBAL_PROPERTIES
  cfg_replace_option mail.from.default $MAIL_FROM_DEFAULT $ALFRESCO_GLOBAL_PROPERTIES
  cfg_replace_option mail.protocol $MAIL_PROTOCOL $ALFRESCO_GLOBAL_PROPERTIES
  cfg_replace_option mail.smtp.auth $MAIL_SMTP_AUTH $ALFRESCO_GLOBAL_PROPERTIES
  cfg_replace_option mail.smtp.starttls.enable $MAIL_SMTP_STARTTLS_ENABLE $ALFRESCO_GLOBAL_PROPERTIES
  cfg_replace_option mail.smtps.auth $MAIL_SMTPS_AUTH $ALFRESCO_GLOBAL_PROPERTIES
  cfg_replace_option mail.smtps.starttls.enable $MAIL_SMTPS_STARTTLS_ENABLE $ALFRESCO_GLOBAL_PROPERTIES

  cfg_replace_option ftp.port $FTP_PORT $ALFRESCO_GLOBAL_PROPERTIES

  # @see https://forums.alfresco.com/en/viewtopic.php?f=8&t=20893
  # CIFS works, but you have to login as a native Alfresco account, like admin
  # because CIFS does not work with LDAP authentication
  cfg_replace_option cifs.enabled $CIFS_ENABLED $ALFRESCO_GLOBAL_PROPERTIES
  cfg_replace_option cifs.Server.Name $CIFS_SERVER_NAME $ALFRESCO_GLOBAL_PROPERTIES
  cfg_replace_option cifs.domain $CIFS_DOMAIN $ALFRESCO_GLOBAL_PROPERTIES
  cfg_replace_option cifs.hostannounce "true" $ALFRESCO_GLOBAL_PROPERTIES
  cfg_replace_option cifs.broadcast "0.0.0.255" $ALFRESCO_GLOBAL_PROPERTIES
  cfg_replace_option cifs.ipv6.enabled "false" $ALFRESCO_GLOBAL_PROPERTIES

  cfg_replace_option nfs.enabled $NFS_ENABLED $ALFRESCO_GLOBAL_PROPERTIES

  # authentication
  if [ "$LDAP_ENABLED" == "true" ]; then
    cfg_replace_option authentication.chain "alfrescoNtlm1:alfrescoNtlm,ldap1:${LDAP_KIND}" $ALFRESCO_GLOBAL_PROPERTIES

    # now make substitutions in the LDAP config file
    LDAP_CONFIG_FILE=$CATALINA_HOME/shared/classes/alfresco/extension/subsystems/Authentication/${LDAP_KIND}/ldap1/${LDAP_KIND}-authentication.properties

    cfg_replace_option "ldap.authentication.userNameFormat" "$LDAP_AUTH_USERNAMEFORMAT" "$LDAP_CONFIG_FILE"
    cfg_replace_option ldap.authentication.java.naming.provider.url $LDAP_URL $LDAP_CONFIG_FILE
    cfg_replace_option ldap.authentication.defaultAdministratorUserNames $LDAP_DEFAULT_ADMINS $LDAP_CONFIG_FILE
    cfg_replace_option ldap.synchronization.java.naming.security.principal $LDAP_SECURITY_PRINCIPAL $LDAP_CONFIG_FILE
    cfg_replace_option ldap.synchronization.java.naming.security.credentials $LDAP_SECURITY_CREDENTIALS $LDAP_CONFIG_FILE
    cfg_replace_option ldap.synchronization.groupSearchBase $LDAP_GROUP_SEARCHBASE $LDAP_CONFIG_FILE
    cfg_replace_option ldap.synchronization.userSearchBase $LDAP_USER_SEARCHBASE $LDAP_CONFIG_FILE
    cfg_replace_option ldap.synchronization.userIdAttributeName $LDAP_USER_ATTRIBUTENAME $LDAP_CONFIG_FILE
    cfg_replace_option ldap.synchronization.groupMemberAttributeName $LDAP_GROUP_MEMBER_ATTRIBUTENAME $LDAP_CONFIG_FILE
  else
    cfg_replace_option authentication.chain "alfrescoNtlm1:alfrescoNtlm" $ALFRESCO_GLOBAL_PROPERTIES
  fi

  # content store
  cfg_replace_option dir.contentstore "${CONTENT_STORE}/contentstore" $ALFRESCO_GLOBAL_PROPERTIES
  cfg_replace_option dir.contentstore.deleted "${CONTENT_STORE}/contentstore.deleted" $ALFRESCO_GLOBAL_PROPERTIES
}


log() {
  if [[ "$@" ]]; then echo "[ AMX `date +'%Y-%m-%d %T'`] $@";
  else echo; fi
}

# Step 2: verify if this is a new installation or not. If NOT, unpack Alfresco files. 

if [ ! -d $ALF_HOME/alf_data/keystore ]; then
  
  log "$ALF_HOME/alf_data/keystore directory is empty! Unpacking default config"
  tar -xzf /root/alfresco_alfdata.tar.gz 

  log "Default config unpacked"

fi

# Step 3: Set communication variables 

ALFRESCO_HOSTNAME=${ALFRESCO_HOSTNAME:-127.0.0.1}
ALFRESCO_PROTOCOL=${ALFRESCO_PROTOCOL:-http}
if [ "${ALFRESCO_PROTOCOL,,}" = "https" ]; then
  ALFRESCO_PORT=${ALFRESCO_PORT:-8443}
else
  ALFRESCO_PORT=${ALFRESCO_PORT:-8080}
fi

# Step 4: Set share variables 

SHARE_HOSTNAME=${SHARE_HOSTNAME:-127.0.0.1}
SHARE_PROTOCOL=${SHARE_PROTOCOL:-http}
if [ "${SHARE_PROTOCOL,,}" = "https" ]; then
  SHARE_PORT=${SHARE_PORT:-8443}
else
  SHARE_PORT=${SHARE_PORT:-8080}
fi

# Step 5: Set DB variables

DB_KIND=${DB_KIND:="mysql"}
DB_USERNAME=${DB_USERNAME:="alfesco"}
DB_PASSWORD=${DB_PASSWORD:="admin"}
DB_NAME=${DB_NAME:="alfresco"}
DB_HOST=${DB_HOST:="localhost"}


case "${DB_KIND,,}" in
  postgresql)
    DB_DRIVER=org.postgresql.Driver
    DB_PORT=${DB_PORT:-5432}
    ;;
  mysql)
    DB_DRIVER=org.gjt.mm.mysql.Driver
    DB_PORT=${DB_PORT:-3306}
    DB_CONN_PARAMS=${DB_CONN_PARAMS:-?useSSL=false}
    ;;
  *)
    log "Database kind '$DB_KIND' not supported!"
    exit 1
esac

# Step 6: Set server mode, production by default.

SYSTEM_SERVERMODE=${SYSTEM_SERVERMODE:-PRODUCTION}


# Step 7: Setting mail notification configuration 

MAIL_HOST=${MAIL_HOST:-localhost}
MAIL_PORT=${MAIL_PORT:-25}
MAIL_USERNAME=${MAIL_USERNAME:-}
MAIL_PASSWORD=${MAIL_PASSWORD:-}
MAIL_FROM_DEFAULT=${MAIL_FROM_DEFAULT:-alfresco@alfresco.org}
MAIL_PROTOCOL=${MAIL_PROTOCOL:-smtp}
MAIL_SMTP_AUTH=${MAIL_SMTP_AUTH:-false}
MAIL_SMTP_STARTTLS_ENABLE=${MAIL_SMTP_STARTTLS_ENABLE:-false}
MAIL_SMTPS_AUTH=${MAIL_SMTPS_AUTH:-false}
MAIL_SMTPS_STARTTLS_ENABLE=${MAIL_SMTPS_STARTTLS_ENABLE:-false}


# Step 8: set FTP Port

FTP_PORT=${FTP_PORT:-21}


# Step 9: CIFS setting 

CIFS_ENABLED=${CIFS_ENABLED:-true}
CIFS_SERVER_NAME=${CIFS_SERVER_NAME:-localhost}
CIFS_DOMAIN=${CIFS_DOMAIN:-WORKGROUP}


# Step 10: Enable NFS

NFS_ENABLED=${NFS_ENABLED:-true}


# Step 11: LDAP config. Disabled by default.

LDAP_ENABLED=${LDAP_ENABLED:-false}
LDAP_KIND=${LDAP_KIND:-ldap}
LDAP_AUTH_USERNAMEFORMAT=${LDAP_AUTH_USERNAMEFORMAT-uid=%s,cn=users,cn=accounts,dc=example,dc=com}
LDAP_URL=${LDAP_URL:-ldap://ldap.example.com:389}
LDAP_DEFAULT_ADMINS=${LDAP_DEFAULT_ADMINS:-admin}
LDAP_SECURITY_PRINCIPAL=${LDAP_SECURITY_PRINCIPAL:-uid=admin,cn=users,cn=accounts,dc=example,dc=com}
LDAP_SECURITY_CREDENTIALS=${LDAP_SECURITY_CREDENTIALS:-password}
LDAP_GROUP_SEARCHBASE=${LDAP_GROUP_SEARCHBASE:-cn=groups,cn=accounts,dc=example,dc=com}
LDAP_USER_SEARCHBASE=${LDAP_USER_SEARCHBASE:-cn=users,cn=accounts,dc=example,dc=com}
LDAP_USER_ATTRIBUTENAME=${LDAP_USER_ATTRIBUTENAME:-uid}
LDAP_GROUP_MEMBER_ATTRIBUTENAME=${LDAP_GROUP_MEMBER_ATTRIBUTENAME:-memberUid}

# Step 12: RUN "tweak_alfresco" function
tweak_alfresco

# Step 13: if directory $AMP_DIR_ALFRESCO exists then  install additional modules 

if [ -d "$AMP_DIR_ALFRESCO" ]; then
  log "Installing Alfresco AMPs from $AMP_DIR_ALFRESCO..."
  $ALF_HOME/java/bin/java -jar $ALF_HOME/bin/alfresco-mmt.jar install $AMP_DIR_ALFRESCO $CATALINA_HOME/webapps/alfresco.war -directory -force -verbose
  $ALF_HOME/java/bin/java -jar $ALF_HOME/bin/alfresco-mmt.jar list $CATALINA_HOME/webapps/alfresco.war
fi


# Step 14: if directory $AMP_DIR_SHARE exists then  install additional modules 

if [ -d "$AMP_DIR_SHARE" ]; then
  log "Installing Share AMPs from $AMP_DIR_SHARE..."
  $ALF_HOME/java/bin/java -jar $ALF_HOME/bin/alfresco-mmt.jar install $AMP_DIR_SHARE $CATALINA_HOME/webapps/share.war -directory -force -verbose
  $ALF_HOME/java/bin/java -jar $ALF_HOME/bin/alfresco-mmt.jar list $CATALINA_HOME/webapps/share.war
fi

# Step 15: runs script setenv.sh

source $ALF_HOME/scripts/setenv.sh
export FONTCONFIG_PATH=/etc/fonts

# Step 16: starts ALFRESCO :D 

$ALF_HOME/tomcat/scripts/ctl.sh start


EXIT_DAEMON=0
while [ $EXIT_DAEMON -eq 0 ]; do
    if [ $STOP != 0 ]
    then
        log "Stopping Alfresco";
        $ALF_HOME/tomcat/scripts/ctl.sh stop 
        break;
    else
        ps aux |grep alfresco |grep -q -v grep
        PROCESS_1_STATUS=$?
        if [ $PROCESS_1_STATUS -ne 0 ]; then
            log "The process Alfresco is not found. Launching it again."
            $ALF_HOME/tomcat/scripts/ctl.sh start
        fi
    fi
    sleep 5
done
