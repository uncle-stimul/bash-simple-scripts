#!/bin/bash

LOG_PATH="/var/log/postclone.log"

NAME="$(echo $0 | awk -F '[/]' '{printf $NF;}')"
VERSION="1.1"

OLD_MID=$(cat /etc/machine-id 2>> $LOG_PATH)
OLD_DBUS=$(cat /var/lib/dbus/machine-id 2>> $LOG_PATH)
EXS_DBUS=$(ls /var/lib/dbus/machine-id 2> /dev/null| wc -l)
OLD_NAME=$HOSTNAME

function run_default () {
  [ $EUID -ne 0 ] && echo -e "Try use '\033[31msudo bash postclone.sh\033[0m' for run this script" && exit 1

  [ ! -f $LOG_PATH ] && touch $LOG_PATH || echo -n "" > $LOG_PATH

  echo -e "================= $0 =================" \
    && echo -n "Insert new hostname: " && read NEW_NAME \
    && echo -e "================================================"

  echo -ne "Removing Machine-ID from /etc\t" \
    && rm -f /etc/machine-id 1> /dev/null 2>> $LOG_PATH \
    && echo -e "\t  [DONE]" || echo -e "\t [ERROR]"

  [ $EXS_DBUS -ne 0 ] && echo -ne "Removing Machine-ID from /var\t" \
    && (rm /var/lib/dbus/machine-id 1> /dev/null 2>> $LOG_PATH \
    && echo -e "\t  [DONE]" || echo -e "\t [ERROR]")

  echo -ne "Initializing Machine-ID\t\t" \
    && systemd-machine-id-setup 1> /dev/null 2>> $LOG_PATH \
    && echo -e "\t  [DONE]" || echo -e "\t [ERROR]"

  [ $EXS_DBUS -ne 0 ] && echo -ne "Initializing UUID for dbus\t" \
    && (dbus-uuidgen --ensure 1> /dev/null 2>> $LOG_PATH \
    && echo -e "\t  [DONE]" || echo -e "\t [ERROR]")

  echo -ne "Changing hostname\t\t" \
    && hostnamectl set-hostname $NEW_NAME 1> /dev/null 2>> $LOG_PATH \
    && echo -e "\t  [DONE]" || echo -e "\t [ERROR]"

  echo -ne "Changing /etc/hosts\t\t" \
    && sed -i "s/$OLD_NAME/$NEW_NAME/" /etc/hosts 1> /dev/null 2>> $LOG_PATH \
    && echo -e "\t  [DONE]" || echo -e "\t [ERROR]"

  echo -e "================================================\nold_hostname: $OLD_NAME\nnew_hostname: $NEW_NAME"
  echo -e "------------------------------------------------\nold_mashine_id: $OLD_MID\nnew_mashine_id: $(cat /etc/machine-id 2>> $LOG_PATH)"
  [ $EXS_DBUS -ne 0 ] && echo -e "------------------------------------------------\nold_dbus_id:\t$OLD_DBUS\nnew_dbus_id:\t$(cat /var/lib/dbus/machine-id 2>> $LOG_PATH)"
  echo -en "================================================\nReboot now? [Y/n] " && read REBOOT_MODE \
    && [ "$REBOOT_MODE" == "y"  -o "$REBOOT_MODE" == "Y" ] && reboot || echo -e "================================================"
}

function run_silent () {
  [ $EUID -ne 0 ] && echo -e "Try use 'sudo bash postclone.sh silent <new_hostname>' for run this script" && exit 1
  [ ! -f $LOG_PATH ] && touch $LOG_PATH || echo -n "" > $LOG_PATH
  [ "$1" == "" ] && echo -e "Missing parameter with new hostname!" >> $LOG_PATH && exit 1

  hostnamectl set-hostname $1 1> /dev/null 2>> $LOG_PATH \
    && sed -i "s/$OLD_NAME/$1/" /etc/hosts 1> /dev/null 2>> $LOG_PATH \

  rm -f /etc/machine-id 1> /dev/null 2>> $LOG_PATH \
    && systemd-machine-id-setup 1> /dev/null 2>> $LOG_PATH \

  [ $EXS_DBUS -ne 0 ] \
    && /var/lib/dbus/machine-id 1> /dev/null 2>> $LOG_PATH \
    && dbus-uuidgen --ensure 1> /dev/null 2>> $LOG_PATH

  reboot
}

function run_help () {
        echo -e "postclone.sh ver. $VERSION\nParametrs:\nRun script without parametrs\t\t\t-   run postclone.sh in interactive mode"
        echo -e "-s <new_hostname> or --silent <new_hostname>\t-   run postclone.sh in silent mode"
        echo -e "Logs:\nErrors write in $LOG_PATH\nExamples:"
        echo -e "sudo bash $NAME\nsudo bash $NAME -s NEW-VM-01\nsudo bash $NAME --silent NEW-VM-01"
}


case "$1" in
  -h|--help) run_help && exit 1 ;;
  -s|--silent)  run_silent $2 ;;
  "") run_default ;;
  *) run_help && exit 1;;
esac