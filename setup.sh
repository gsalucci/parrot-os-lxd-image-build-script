#!/bin/bash

declare -A config

# Loads the default config
defaultConfig () {
    config+=([build_dir]=$(pwd)"/build")
    config+=([parrot_main_url]="https://raw.githubusercontent.com/ParrotSec/debootstrap/master/scripts/parrot")
    config+=([parrot_rolling_url]="https://raw.githubusercontent.com/ParrotSec/debootstrap/master/scripts/rolling")
    config+=([parrot_mirror_url]="https://mirror.parrot.sh/mirrors/parrot/")
    config+=([debootstrap_script_path]="/usr/share/debootstrap/scripts")
    config+=([target_arch]="amd64")
    config+=([os_name]="parrot")
    config+=([os_release]="rolling")
    config+=([os_description]="ParrotOS lxc/lxd base image.")
    config+=([image_name]="parrot_base")
}

# Cleans the build directory
clean () {
    echo "Deleting ${config[build_dir]}"
    sudo rm -Irf ${config[build_dir]}
    echo "Deleting debootstrap parrot scripts at ${config[debootstrap_script_path]}"
    sudo rm ${config[debootstrap_script_path]}/parrot ${config[debootstrap_script_path]}/rolling
    echo "Deleting rootfs archive"
    sudo rm -I $(pwd)/rootfs.tar.gz
    echo "Deleting metadata"
    rm $(pwd)/metadata.yaml
    rm $(pwd)/metadata.tar.gz
    mkdir ${config[build_dir]}
}

# Installs parrot image building prerequisites
_installPrerequisites () {
    local dbpath=$(which debootstrap)
    local wgetpath=$(which wget)
    if [ ! -z "$dbpath" -a ! -z "$wgetpath" ]; then
        echo "Satisfies prerequisites"
        return 0
    fi
    sudo apt install -y debootstrap wget
}

# builds the rootfs
build () {
    _installPrerequisites

    # We download parrots scripts
    wget ${config[parrot_main_url]}
    wget ${config[parrot_rolling_url]}
    
    #move them to debootstrap scripts path
    sudo mv parrot rolling ${config[debootstrap_script_path]}

    # create build dir
    mkdir ${config[build_dir]}
    # set build dir permissions
    sudo chown -R root:root ${config[build_dir]}

    # launch debootstrap targetting build dir
    sudo debootstrap --arch ${config[target_arch]} parrot ${config[build_dir]} ${config[parrot_mirror_url]}
}



package () {
    echo "Compressing rootfs"
    # compress build folder 
    sudo tar -cvzf rootfs.tar.gz -C ${config[build_dir]} .
    echo "Creating metadata.yaml"

    cat <<- EOF > metadata.yaml
architecture: "${config[target_arch]}"
creation_date: $(date +%s)
properties:
architecture: "${config[target_arch]}"
description: "${config[os_description]}"
os: "${config[os_name]}"
release: "${config[os_release]}"  
EOF
    echo "Compressing metadata"
    tar -cvzf metadata.tar.gz metadata.yaml
}

import () {
    echo "Importing image as ${config[image_name]}"
    lxc image import metadata.tar.gz rootfs.tar.gz --alias ${config[image_name]}
}

full () {
	build
	# Exit if debootstrap failed
	local exit_code=$?
	if [ $exit_code -ne 0 ]; then
        exit $exit_code
    fi
    package
    exit_code=$?
    if [ $exit_code -ne 0 ]; then
        exit $exit_code
    fi
    import
}

defaultConfig
$1 "${@:2}"
