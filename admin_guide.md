% Administrators Guide
% [Dario Berzano](mailto:dario.berzano@cern.ch)

This howto will provide you with basic information to create a
sandboxed environment for a user willing to access the Private
Cloud.

There is a single [Ruby](http://www.ruby-lang.org/) command line
interface guiding you throughout the steps or doing them for you
automatically. The script uses the
[OpenNebula Cloud API](opennebula.org/doc/3.8/oca/ruby/).

From the user's perspective, the Cloud exposes an API compatible with
Amazon EC2. It can be accessed using
[Euca2ools](http://www.eucalyptus.com/download/euca2ools), an open
source implementation of the
[Amazon clients](https://aws.amazon.com/ec2/faqs/).


Rationale: user's sandbox
-------------------------

When we give access to one user to the private Cloud, we would like it
to be "sandboxed", in the sense that as much as possible of the things
that happen there will not negatively impact the whole
infrastructure's behavior.

A "private sandbox" is composed of a **OpenNebula user** and an
isolated **Virtual Network**.

### OpenNebula User

An OpenNebula User with no administrative privileges has to be
created. The user:

*   belongs to one special **group** (called *ec2*)
*   has a restrictive **quota** on the number of VMs and the amount of
    resources she can use
*   can only use those **images** whose specific permissions make them
    *public*

### Virtual Network

In our private Cloud infrastructure a Virtual Network is isolated from
the others by filtering out mac addresses using
[ebtables](http://ebtables.sourceforge.net/) on the hypervisors.

Network isolation is performed automatically by OpenNebula, which also
deals gracefully by updating the rules when migrating VMs.

An isolated Virtual Network is constituted by:

*   a private set of class-C IP addresses, in the form *172.16.X.Y*:
    each Virtual Network has its own *X*
*   a Virtual Router, based on [OpenWrt](https://openwrt.org/),
    providing Authoritative DHCP, DNS, NAT and port forwarding for the
    private network

The Virtual Router always has:

*   a private address: *172.16.X.254*
*   a public address, took from the pool named *VRouter-Pub*

The public address is the entry point to the entire Virtual Network.

Virtual Router has two access points (user is *root*, password is
undisclosed):

*   HTTPS access on port *60443*
*   SSH access on port *60022*

The Virtual Router comes with an Elastic IP functionality, that allows
to use EC2-compatible APIs to bind the public IP address to one of the
private VM instances dynamically.


Using onevrouter-create
-----------------------

The `onevrouter-create.rb` script is capable of performing all the
actions required to create a new user's environment. It should be used
from the `oneadmin` user as it might need OpenNebula administrative
privileges if you want to commit changes.

Syntax:

```bash
onevrouter-generator.rb \
  --username clouduser --public-ip 193.205.66.216 \
  --priv-ip 172.16.XXX.0/24 [--[no-]commit]
```

The above example will take all the necessary steps to create:

*   an OpenNebula user named *clouduser*
*   proper quota and group assignments for the aforementioned user
*   a private Virtual Network *172.16.XXX.0* named *clouduser-Prv*,
    visible to the user
*   a public Virtual Network containing only one IP address, namely
    *193.205.66.216*, called *clouduser-Pub*, invisible to the user
    (it will be used transparently by the Elastic IP functionality)
*   a Virtual Router having a private ip *172.16.XXX.254* and a public
    ip *193.205.66.216*

**Please note:** if you add the parameter `--commit`, the script will
actually perform those steps and requires administrative privileges.
If you intend to review settings before committing them, then you can
run the script as-is, or with the `--no-commit` parameter: proper
templates will be created, and instructions on what to do will be
printed on screen.

### Example of creating a user sandbox

See how to use it below:

```bash
$> onevrouter-generator.rb --username clouduser --public-ip 193.205.66.216 --priv-ip 172.16.216.0/24
```

Creation is always safe and interactive. A summary output is presented
to the user, who has to confirm the action by typing exactly the
indicated words:

```
We are going to create a User with her own VRouter, Pub and Prv network with the following parameters:

* User name        : clouduser
* Public IP        : 193.205.66.216
* Public Hostname  : cloud-gw-216.to.infn.it
* Private IP range : 172.16.216.0..172.16.216.255

NOTE: template files will be created for the network and VRouter, but no change will be committed to OpenNebula.

Is this OK? Type "yes, it is":
```

After giving proper confirmation, since we are not committing any
change, templates will be created **in the current directory**. An
output similar to the following is presented:

```
Generating template clouduser.onequota...ok
Generating template clouduser-VRouter.onevm...ok
Generating template clouduser-Prv.onevnet...ok
Generating template clouduser-Pub.onevnet...ok

You should create the user with quota like this:

  oneuser create clouduser password
  oneuser quota clouduser clouduser.onequota

Then you should annotate User ID and Private VNet ID and add an ACL
like this:

  oneacl create "#<UserID> NET/#<PrivateVNetID> USE+MANAGE"

where you will substitute <UserID> and <PrivateVNetID>
```

If you have chosen to commit changes directly to OpenNebula, after
giving proper confirmation you'll find an output like the following:

```
Creating user clouduser...ok (user ID: 40)
Adding user clouduser to group 106...ok
Adding a default user quota for clouduser...Creating private network clouduser-Pub...ok (vnet ID: 105)
Creating public network clouduser-Prv...ok (vnet ID: 106)
Creating ACLs...ok (acl ID: 127)
Instantiating VM clouduser-VRouter...ok (VM ID: 3383)
```

The output above represents a situation where everything went right.
Please note that **no templates are created** when committing.

**Also note** that the created user has password set to *password*,
and should be immediately changed using the `oneuser` command.


The OpenNebula EC2 interface daemon: econe
------------------------------------------

OpenNebula itself has an optional daemon that listens for EC2 requests
and translates them to OpenNebula RPC requests. The daemon is called
`econe-server`, and the OpenNebula website has
[some documentation](http://opennebula.org/documentation:archives:rel3.8:ec2qcg)
on it.

The daemon also associates defined *flavors* to specific OpenNebula
templates.

A specially modified version of the EC2 daemon has been created, and
it is available
[on a special branch](https://github.com/dberzano/opennebula-torino/tree/one-3.8-ec2)
of a GitHub repository which forks the
[original one](http://dev.opennebula.org/).

### List of relevant files

All the files needed by the econe-server are under version control on
the OpenNebula master host.

*   `etc/econe.conf`: econe-server configuration file
*   `etc/ec2query_templates/generic.erb.in`: generic Virtual Machine
    template in the OpenNebula format. It is used to create a VM
    definition out of an EC2 flavor. From this file, several VM
    templates will be created by substituting the variables `@NAME@`,
    `@MEMORY@` (in MB), `@DISK@` (in MB as well) and `@CPU@` (*i.e.*,
    the number of CPUs.)
*   `etc/ec2_query_templates/makeflavors.sh`: creates the real *erb*
    templates out of some definitions defined in the same file
*   `econe-associate`, `econe-disassociate`: scripts to associate and
    disassociate an Elastic IP to a VM. How those scripts are called
    is explained in the `econe.conf` file
*   `econe-server-ctl`: script to start, stop and control the
    `econe-server` daemon and set the environment to get it from a
    custom folder, instead of using the system-wide installation

### Starting and stopping the daemon

To start the daemon:

    econe-server-ctl start

To stop it:

    econe-server-ctl stop

To check whether it's running, and the listening port:

    econe-server-ctl status

To retrieve the logfiles:

    econe-server-ctl log
    econe-server-ctl errlog

The daemon ordinarily runs under the user `oneadmin`.


Using the EC2 and OpenNebula interfaces
---------------------------------------

The OpenNebula administrative Unix account is preconfigured to operate
on the cloud infrastructure using the `one*` commands.

In case it's needed to use the cloud "as another user", or to test the
EC2 interface, there is a command to invoke that prepares the
environment for you:

    cloud-enter

You'll be prompted for your username and your password, and you'll be
capable of using both the `one*` and the `euca-*` commands. See the
User's Guide for more information on the euca2ools.
