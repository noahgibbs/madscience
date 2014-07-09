## Various useful things to do here:

vagrant up / vagrant destroy / vagrant ssh

vagrant provision

librarian-chef install

vagrant plugin install vagrant-omnibus --plugin-version 1.4.1

TODO: remove StrictHostKeyChecking toggle after we install an SSH key automatically
ssh www@localhost -p2222 -o "StrictHostKeyChecking no"

## Not so good:

knife cookbook create my_cookbook_name - puts it under the "cookbooks" subdir,
doesn't seem to have a way not to.
