#!/bin/sh

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
    type -P $1 > /dev/null 2>&1
}


install_make_cmd() {
    if ! is_exists "make"; then
        if [ `uname -s` = 'Darwin' ]; then
            xcode-select --install || True
        fi
    fi
    if ! is_exists "make"; then
        p_error "Not found make command!"
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
        local tarball=$DOTFILES_GITHUB_ARCH
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

    p_done "Downloaded dotfiles."
}


deploy_dotfiles() {
    p_header "Deploying dotfiles to $DOTFILES_DIR..."

    cd $DOTFILES_DIR &&
        make deploy &&

    p_info 'Run `make init` if you need to initialize the software for setup.'
    p_done 'Deployed dotfiles'
}

#
# main
#
DOTFILES_GITHUB=https://github.com/hikch/dotfiles
DOTFILES_GITHUB_REPO=${DOTFILES_GITHUB}.git
DOTFILES_GITHUB_ARCH=${DOTFILES_GITHUB}/archive/main.tar.gz
DOTFILES_GITHUB_DIR=dotfiles-main

# Set DOTPATH as default variable
if [ -z "${DOTFILES_DIR:-}" ]; then
    DOTFILES_DIR=~/dotfiles; export DOTFILES_DIR
fi

download_dotfiles &&
    install_make_cmd &&
    deploy_dotfiles
    
