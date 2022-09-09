# Parrot OS LXD/LXC Image builder

This is a script for debian-based hosts to build an lxd/lxc image of parrotOS

## Usage
Clone the repo, cd into it 

```bash
./setup.sh full
```

it will, hopefully, build, package and import an lxd image named `parrot_base`.

If you are feeling adventurous, checkout the source code, modify the config to suit your needs.

To launch it:

```bash
lxc launch parrot_base parrot
lxc exec parrot bash
```