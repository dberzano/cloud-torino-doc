% Users Guide: how to use the Cloud
% [Dario Berzano](mailto:dario.berzano@cern.ch)

This document will briefly describe all the necessary steps and tools
to manage your personal virtual infrastructure on your own.

In particular, you'll learn how to:

*   create and shutdown a virtual machine
*   access a virtual machine by associating a public IP address

All the management and access operations can be performed from any
computer connected to the INFN Torino network infrastructure.

You do not need to install yourself the tools to manage your virtual
machines: [Euca2ools](http://www.eucalyptus.com/download/euca2ools)
are already available from the **public login machines**.


Request Cloud access
--------------------

Before you can access the cloud, you or your group should obtain cloud
access from the Computing Centre.

Your account will have:

*   **credentials:** a username and a password
*   **quota:** a limit to the maximum number of resources you can use
    at the same time
*   **firewall and network isolation:** a special private network will
    be created for your account
*   **one public Elastic IP address:** since the network is isolated,
    you'll be given a public IP address that you can map to one of
    your virtual machines


Accessing the Cloud
-------------------

To access the cloud it is sufficient to log in to one of the Linux
**public login machines**, such as:

*   zoroastro.to.infn.it
*   melchiorre.to.infn.it
*   gaspare.to.infn.it
*   baldassarre.to.infn.it

Once logged in you may enter the Cloud environment by typing:

    ~berzano/euca2ools/bin/cloud-enter [cloud_user_name]

If you do not provide any `cloud-user-name` you'll be prompted for
one. A **password** will be asked as well. Keep in mind that these are
not your INFN credentials, but different credentials that you can use
solely for accessing the Cloud:

    Cloud user: <your_username>
    Password for cloud user "<your_username>": <your_password>
    Commands start with euca-*, use [Tab] to complete.
    Type exit to return to your normal shell.

    cloud@infnto user: m5l
    user@to01xl.to.infn.it [~] >

This is an ordinary shell from which you can run normal shell
commands, plus the `euca-*` commands needed for managing the cloud.

> **Note:** it might be convenient to create an **alias** for the
> `cloud-enter` command.
>
> If you are using the C Shell:
>
> `echo alias cloud-enter ~berzano/euca2ools/bin/cloud-enter >> ~/.cshrc`
>
> If you are using Bash:
>
> `echo alias cloud-enter=~berzano/euca2ools/bin/cloud-enter >> ~/.bash_profile`


### Euca2ools: managing VMs, keys and IP addresses

> **Note:** in order to use the
> [Euca2ools](http://www.eucalyptus.com/download/euca2ools) we are
> assuming that you have entered the **cloud environment** by using
> `cloud-enter` as previously described.


Key management
--------------

A **keypair** is needed to access your virtual machine. It is a pair
of a public and a private SSH keys for the *root* user of the virtual
machine.

The following list of commands will explain how to create, list and
delete stored keys.


### euca-create-keypair

Keypairs are created by means of the `euca-create-keypair` command.

The **public key** will be stored in a database and automatically
added to the list of *authorized keys* for the virtual machine.

The **private key** will instead be returned to a file. You should
keep your private key in a safe place, since it is the one you'll need
to be granted administrative privileges in your virtual machines.

To create a keypair:

    euca-create-keypair -f privkey.pem TypeTheNameYouWant

A keypair called `TypeTheNameYouWant` will be created. The private
part of the newly created key is saved inside the `privkey.pem` file
with proper permissions.

Output of command shows the fingerprint associated with the newly
created keypair:

    KEYPAIR TypeTheNameYouWant  18:c9:ed:71:30:0a:2c:fe:63:6f:64:35:ef:a7:e2:6f

You can create any number of keypairs you like, with different names.
You can then choose which keypair to associate to a virtual machine
when instantiating it.


### euca-describe-keypairs

Lists all the created keypairs.

    euca-describe-keypair

Will produce an output similar to:

    KEYPAIR TypeTheNameYouWant  18:c9:ed:71:30:0a:2c:fe:63:6f:64:35:ef:a7:e2:6f
    KEYPAIR FooBar  18:92:c1:40:8e:d7:ee:e5:f8:75:d1:60:ab:bc:8b:d9
    KEYPAIR AnotherFancyName    83:a5:ec:a3:1b:20:ad:36:09:b4:1b:00:51:a5:03:73


### euca-delete-keypair

Deletes a created keypair.

    euca-delete-keypair FooBar

will delete the keypair `FooBar`.


Creating and deleting VMs
-------------------------

Virtual machines are created as *instances* from *base images*. Such
base images are made available for everybody as public images on the
private cloud.

The commands to list such base images, create instances and delete
them are described below.


### euca-describe-images

This command returns a list of possible base images you can use for
your virtual machines.

    euca-describe-images

can be run without parameters and returns something like:

    IMAGE   ami-00000156    M5L-Base-build4 m5l available   private     i386    machine
    IMAGE   ami-00000297    Ubuntu Server 12.10 oneadmin    available   public      i386    machine
    IMAGE   ami-00000304    cvm-2.7.1   oneadmin    available   public      i386    machine
    IMAGE   ami-00000322    cvm-2.7.1-ami   oneadmin    available   public      i386    machine

The relevant parts are the ID (such as *ami-00000156*) and the
meaningful description (such as *M5L-Base-build4*). You will refer to
the ID when instantiating a VM.


### euca-run-instances

This is the command used to create new virtual machines from the
available images.

When you create a new virtual machine, you will need to specify:

*   the **base image ID**, that is: one of the `ami-*` strings
    displayed by the `euca-describe-images` command
*   the so-called **flavour**, *i.e.* a set defining the number of
    CPUs, RAM and extra *ephemeral* disk space; a complete list of
    flavours is available below
*   the **key** to associate to the root user for SSH, which must be
    in the list of keys returned by `euca-describe-keypairs`
*   an optional **contextualization script** (the *user data*), a text
    file whose format depends on the contextualization mechanism
    implemented inside the base image

Putting things altogether:

    euca-run-instances ami-<id> -k <keyname> -f /path/to/user-data.txt -t m1.<flavour>

Other parameters are available, try with `--help` to get the full
list.


#### List of possible flavors

| Flavour   | CPUs | RAM     | Disk   |
| --------- | ---- | ------- | ------ |
| m1.tiny   | 1    | 512 MB  | 3 GB   |
| m1.small  | 1    | 2.6 GB  | 20 GB  |
| m1.medium | 3    | 7.7 GB  | 60 GB  |
| m1.large  | 6    | 15.4 GB | 120 GB |

*   **CPUs:** is the number of virtual CPUs
*   **Disk:** the so-called "ephemeral" disk, *i.e.* an empty disk
    seen by the VM as an additional block device. Usually, if the root
    disk is `/dev/vda`, the *ephemeral* disk would be `/dev/vdb`


### euca-describe-instances

Lists currently running instances, along with their associated private
IP.

    euca-describe-instances

will return an output similar to:

    RESERVATION default m5l default
    INSTANCE    i-00003397      172.16.211.1    172.16.211.1    running none    3397            2013-08-26T15:00:59+02:0    default eki-EA801065    eri-1FEE1144        monitoring-disabled     172.16.211.1
    INSTANCE    i-00003398      172.16.211.2    172.16.211.2    running none    3398            2013-08-26T15:27:56+02:0    default eki-EA801065    eri-1FEE1144        monitoring-disabled     172.16.211.2

Two items from each line are important:

*   the **instance ID**, for instance: `i-00003397`
*   the **private IP address** (like `172.16.211.1`)

> Note that the IP is private and the VM cannot be accessed through it
> directly. For accessing the VM from the outside, Elastic IPs are
> used, as described below.

The instance ID is necessary for every instance operation, like
shutting the VM down.


### euca-terminate-instances

Used to shut down one or more instances via their IDs.

    euca-terminate instances i-<id1> [i-<id2> [i-<id3>...]]


Public Elastic IPs
------------------

Each user account has one public elastic IP associated.

Such IP address is:

*   **public** because it is accessible from the whole INFN network
    (or even from the outside, if requested)
*   **elastic** because it is not associated to a particular virtual
    machine: you can associate it to any instance you are running by
    yourself without any external intervention

The usual workflow for associating Elastic IPs is the following:

1.  **allocate** the Elastic IP
2.  **associate** the IP to a running instance
3.  **associate** to another instance *(and so on)*
4.  **disassociate** so that it is no longer associated to any VM
    instance
5.  **release** the Elastic IP

Further explanation of the commands follows.


### euca-allocate-address

This command requires no parameters. It tells the Cloud to return an
Elastic IP address and **takes no parameters**.

    euca-allocate-address

will display on the screen the assigned IP address:

    ADDRESS 193.205.66.212

A hostname is associated to the address as well. One way to return the
corresponding hostname is:

    getent hosts 193.205.66.212

Output will be something like:

    193.205.66.212  cloud-gw-212.to.infn.it

> Please note that **you cannot choose the IP address**: only **one**
> IP address is available per user. If you run the
> `euca-allocate-address` command after having already allocated the
> address, it will fail after a timeout.


### euca-associate-address

Associates an allocated IP address to a running instance.

Usage:

    euca-associate-address -i i-<instance_id> <elastic_ip>

For example:

    euca-associate-address -i i-00003397 193.205.66.212

> The elastic IP **must** be the one returned by the
> `euca-allocate-address` command, elsewhere the command will fail.


### euca-describe-addresses

Returns the allocated Elastic IP along with the associated instance,
if applicable.

    euca-describe-address

Output in case the address is **associated** to an instance:

    ADDRESS 193.205.66.212  i-00003397  standard

Output in case the address is **allocated** but not associated to any
instance:

    ADDRESS 193.205.66.211      standard

No output is produced in case the address has not been allocated.

> **Note:** if you want to reassign an associated IP address to a
> different instance, there is no need to disassociate it before: just
> associate to the new one and it will get disassociated from the
> former instance automatically.


### euca-disassociate-address

Disassociates an IP address from an instance.

    euca-disassociate-address <elastic_ip>

it will disassociate the Elastic IP from its current instance.


### euca-release-address

Releases a previously allocated Elastic IP. Syntax:

    euca-release-address <elastic_ip>
