#!/bin/sh
set -e

usage() { echo "Usage: $0 [-t <theme>] [-p <plugin>] [-l <locale>] [-f <font>] [-c <file>]" 1>&2; exit 1; }

# Initialisation des variables
THEME=powerlevel10k/powerlevel10k
PLUGINS=""
LOCALE="fr_FR.UTF-8"
P10K_CONFIG_FILE=""
FONTS=""
FONTS_PATH=/usr/share/fonts

while getopts ":t:p:f:l:c:" opt; do
    case ${opt} in
        t)
            readonly THEME=$OPTARG
            ;;
        p)
            readonly PLUGINS="${PLUGINS}$OPTARG "
            ;;
	    l)
            readonly LOCALE=$OPTARG
	        ;;
	    f)
            readonly FONTS="${FONTS}$OPTARG "
	        ;;
        c)
            readonly P10K_CONFIG_FILE=$OPTARG
            ;;
        \?)
            usage
            ;;
        :)
            echo "Invalid option: $OPTARG requires an argument" 1>&2
            ;;
    esac
done
shift $((OPTIND -1))

show_arguments() {
cat <<-EOM
    Installing Oh-My-Zsh with:
        THEME            = $THEME
        PLUGINS          = $PLUGINS
        FONTS            = $FONTS
        LOCALE           = $LOCALE
        P10K_CONFIG_FILE = $P10K_CONFIG_FILE
EOM
}

show_arguments

check_dist() {
    (
        . /etc/os-release
        echo $ID
    )
}

install_dependencies() {
    DIST=`check_dist`
    echo "###### Installing dependencies for $DIST"

    if [ "`id -u`" = "0" ]; then
        Sudo=''
    elif which sudo; then
        Sudo='sudo'
    else
        echo "WARNING: 'sudo' command not found. Skipping the installation of dependencies. "
        echo "If this fails, you need to do one of these options:"
        echo "   1) Install 'sudo' before calling this script"
        echo "OR"
        echo "   2) Install the required dependencies: git curl wget zsh"
        return
    fi

    case $DIST in
        alpine)
            $Sudo apk add --update --no-cache git curl zsh
        ;;
        centos | amzn)
            $Sudo yum update -y
            $Sudo yum install -y git curl
            $Sudo yum install -y ncurses-compat-libs # this is required for AMZN Linux (ref: https://github.com/emqx/emqx/issues/2503) 
            $Sudo wget http://mirror.ghettoforge.org/distributions/gf/el/7/plus/x86_64/zsh-5.1-1.gf.el7.x86_64.rpm -O zsh-5.1-1.gf.el7.x86_64.rpm
            $Sudo rpm -i zsh-5.1-1.gf.el7.x86_64.rpm
            $Sudo rm zsh-5.1-1.gf.el7.x86_64.rpm
        ;;
        *)
            $Sudo apt-get update
            $Sudo apt-get -y install git curl zsh locales locales-all wget
            $Sudo locale-gen $LOCALE
    esac
}

zshrc_template() {
_HOME=$1; 
_THEME=$2; shift; shift
_PLUGINS=$*;

cat <<- EOM
    export LANG='fr_FR.UTF-8'
    export LANGUAGE='fr_FR:fr'
    export LC_ALL='fr_FR.UTF-8'
    #export TERM=xterm-256color
    ##### Zsh/Oh-my-Zsh Configuration
    export ZSH="$_HOME/.oh-my-zsh"
    ZSH_THEME="${_THEME}"
    plugins=($_PLUGINS)
    source \$ZSH/oh-my-zsh.sh
    bindkey "\$terminfo[kcuu1]" history-substring-search-up
    bindkey "\$terminfo[kcud1]" history-substring-search-down
EOM
}

powerline10k_config() {
cat <<- EOM
    POWERLEVEL9K_SHORTEN_STRATEGY="truncate_to_last"
    POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(user dir vcs status newline prompt_char)
    POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status command_execution_time background_jobs newline ip)
    POWERLEVEL9K_STATUS_OK=false
    POWERLEVEL9K_STATUS_CROSS=true
EOM
}

install_dependencies

cd /tmp

# Copie des polices
if [ ! -d $FONTS_PATH ]; then
    mkdir -p $FONTS_PATH
fi
for font in $FONTS; do
    if [ "`echo $font | grep -E '^http.*'`" != "" ]; then
       wget -nv -A.ttf $font -P $FONTS_PATH
    fi
done
fc-cache -f -v

# Installation de la locale
# regex :^[A-Za-z]{2,4}([_-][A-Za-z]{4})?([_-]([A-Za-z]{2}|[0-9]{3}))?$

# Installation de "Oh-My-Zsh"
if [ ! -d $HOME/.oh-my-zsh ]; then
    sh -c "$(curl https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" --unattended
fi

plugin_list=""
for plugin in $PLUGINS; do
    if [ "`echo $plugin | grep -E '^http.*'`" != "" ]; then
        plugin_name=`basename $plugin`
        git clone $plugin $HOME/.oh-my-zsh/custom/plugins/$plugin_name
    else
        plugin_name=$plugin
    fi
    plugin_list="${plugin_list}$plugin_name "
done

zshrc_template "$HOME" "$THEME" "$plugin_list" > $HOME/.zshrc

if [ "$THEME" = "powerlevel10k/powerlevel10k" ]; then
    git clone https://github.com/romkatv/powerlevel10k $HOME/.oh-my-zsh/custom/themes/powerlevel10k
    if [ "$P10K_CONFIG_FILE" != "" ]; then
        wget -nv $P10K_CONFIG_FILE
        echo 'source ~/.p10k.zsh' >> $HOME/.zshrc
    else
        powerline10k_config >> $HOME/.zshrc
    fi
fi
