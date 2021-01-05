# How_to_install_mariadb_in_ubuntu

# example script
this project has Vagrantfile.
```shell
vagrant up
```
mariadb-fedora environment is being launch.

# if you want to create vagrant box from vagrant file.

```
# stop vagrant environment
vagrant halt

# search virtualbox environment.
ls -1 ~/VirtualBox\ VMs/

# packaging your vagrant virtualbox environment. 
vagrant package --base <yourvirtualbox_environment_name> --output fedora33-postgresql.box

# add box
vagrant box add localhost/fedora33-postgresql fedora33-postgresql.box
```

# reference
[How to install ghost in ubuntu](https://ghost.org/docs/install/ubuntu/)