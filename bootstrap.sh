#!/bin/sh

#
# Utils
#

p_header() {
    printf "⇒ %s\n" "$*"
}

p_info() {
    printf "💡 %s\n" "$*"
}

p_error() {
    printf "⚠️  %s\n" "$*"
}

p_done() {
    printf "✔ %s\n" "$*"
}

is_exists() {
    command -v "$1" > /dev/null 2>&1
}

#
# functions
#

is_install_unix_tooles() {
    if [ `uname -s` = 'Darwin' ]; then
        if [ "$(xcode-select -p)" = "" ]; then
            p_error "Not installed command line tools!"
            p_info "Run 'xcode-select --install' to install Command Line Tools."
            exit 1
        fi
    fi
    if ! is_exists "make"; then
        p_error "make required!"
        exit 1
    fi
}

download_dotfiles() {
    if [ -d "$DOTFILES_DIR" ]; then
        p_error "$DOTFILES_DIR: already exists"
        exit 1
    fi
    
    p_header "Downloading dotfiles..."

    if is_exists "git"; then
        # --recursive equals to ...
        # git submodule init
        # git submodule update
        git clone --recursive "$DOTFILES_GITHUB" "$DOTFILES_DIR"

    elif is_exists "curl" || is_exists "wget"; then
        # curl or wget
        tarball=$DOTFILES_GITHUB_ARCH
        if is_exists "curl"; then
            curl -L "$tarball"

        elif is_exists "wget"; then
            wget -O - "$tarball"

        fi | tar xvz
        if [ ! -d $DOTFILES_GITHUB_DIR ]; then
            p_error "$DOTFILES_GITHUB_DIR: not found"
            exit 1
        fi
        command mv -f $DOTFILES_GITHUB_DIR "$DOTFILES_DIR"

    else
        p_error "curl or wget required"
        exit 1
    fi

    case $? in
        0 )
            p_done "Downloaded dotfiles."
            ;;
        * )
            p_error "Could not doenload dotfile."
            ;;
    esac
}


deploy_dotfiles() {
    p_header "Deploying dotfiles to $DOTFILES_DIR..."

    mkdir -vp $DOTFILES_DIR &&
        cd $DOTFILES_DIR &&
        make deploy

    case $? in
        0 )
            p_info 'Run `make init` if you need to initialize the software for setup.'
            p_done 'Deployed dotfiles'
            ;;
        * )
            p_error "Could not create directory $DOTFILES_DIR."
            ;;
    esac
}

#
# main
#

DOTFILES_GITHUB=https://github.com/hikch/dotfiles
DOTFILES_GITHUB_REPO=${DOTFILES_GITHUB}.git
DOTFILES_GITHUB_ARCH=${DOTFILES_GITHUB}/archive/main.tar.gz
DOTFILES_GITHUB_DIR=dotfiles-main

# Set DOTFILES_DIR as default variable
if [ -z "${DOTFILES_DIR:-}" ]; then
    DOTFILES_DIR=~/dotfiles; export DOTFILES_DIR
fi

is_install_unix_tooles &&
    download_dotfiles &&
    deploy_dotfiles
