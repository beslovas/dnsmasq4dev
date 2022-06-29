#!/bin/bash

# Covenience script for setting up wildcard DNS resolver on OSX
# https://github.com/beslovas/dnsmasq4dev
#
# Copyright (c) 2022 beslovas. Released under the MIT License.

[[ ! $OSTYPE == "darwin"* ]] && \
    echo "Not supported OS: $OSTYPE" && \
    exit 1

DNSMASQ_CONF=/etc/dnsmasq.conf
PROCEED=

usage()
{
    cat << USAGE >&2

    dnsmasq4dev.sh --domain <domain>

    --domain -d <domain>    Domain to setup wildcard support
    -h --help               Show this help dialog

USAGE
    exit 1
}

ask_user_confirmation()
{
    [[ -z $1 ]] && 1="Do you want to proceed?"
    while true;
    do
        echo "$1 [y/n]"
        read
        case $REPLY in
            y )
                export PROCEED=true
                break
            ;;
                n )
                break
            ;;
            * )
                echo -e "\nUnknown answer."
            ;;
        esac
    done
}

while [ "${1:-}" != "" ]; do
    case "$1" in
        --domain | -d )
            shift
            DOMAIN=$1
        ;;
        -h | --help | * )
            usage
            exit 1
        ;;
    esac
    shift
done

[[ -z $DOMAIN ]] && usage


if [[ ! `which brew` ]]; then
    echo "✗ Homebrew is not installed."
    ask_user_confirmation "Do you want to install it?"

    [[ -n $PROCEED ]] \
        && /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
        && PROCEED=""
        || echo "Quitting."
        || exit 0
fi

DNSMASQ_CONF="$(brew --prefix)$DNSMASQ_CONF"

if [[ ! `brew list | grep dnsmasq` ]]; then
    HOMEBREW_NO_ENV_HINTS=1 brew install dnsmasq
    [[ -f $DNSMASQ_CONF ]] && mv $DNSMASQ_CONF $DNSMASQ_CONF.example

    [[ ! -f `brew list dnsmasq | grep /homebrew.mxcl.dnsmasq.plist` ]]

    sudo cp $(brew list dnsmasq | grep /homebrew.mxcl.dnsmasq.plist$) /Library/LaunchDaemons/ && \
    sudo launchctl load -w /Library/LaunchDaemons/homebrew.mxcl.dnsmasq.plist
else
    echo "✓ dnsmasq is already installed with brew."
fi

[[ ! `brew list dnsmasq` ]] \
    && echo "✗ Installation of dnsmasq is corrupt. Quitting." \
    && exit 1


[[ -f $DNSMASQ_CONF ]] \
    && echo "✓ File /usr/local/etc/dnsmasq.conf already exist." \
    || touch $DNSMASQ_CONF

if [[ -z $(cat $DNSMASQ_CONF) ]]; then
    PROCEED=true
else
    [[ ! $(grep '^listen-address=127.0.0.1' $DNSMASQ_CONF) ]] \
        && echo "Its configuration will be updated and it can change dnsmasq behaviour." \
        && ask_user_confirmation \
        || echo "✓ $DNSMASQ_CONF is already configured."
fi

[[ -n $PROCEED ]] \
    && echo "listen-address=127.0.0.1" >> $DNSMASQ_CONF

[[ ! $(grep "^address=/$DOMAIN/127.0.0.1" $DNSMASQ_CONF) ]] \
    && echo "address=/$DOMAIN/127.0.0.1" >> $DNSMASQ_CONF \
    || echo "✓ $DNSMASQ_CONF configuration for address '$DOMAIN' already exists"

sudo brew services restart dnsmasq


[ -d /etc/resolver ] || sudo mkdir -p /etc/resolver
sudo tee /etc/resolver/$DOMAIN > /dev/null <<EOF
nameserver 127.0.0.1
domain $DOMAIN
search_order 1
EOF


sudo killall -HUP mDNSResponder
sudo killall mDNSResponderHelper
sudo dscacheutil -flushcache


echo -e "\n✓ dnsmasq setup with configuration for address '*.$DOMAIN' is finished.\n"
echo -e "Try to 'ping dnsmasq4dev.$DOMAIN' :)\n"

exit 0
