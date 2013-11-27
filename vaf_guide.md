% Virtual Analysis Facility for ALICE Guide
% [Dario Berzano](mailto:dario.berzano@cern.ch)

This guide provides basic information for using the PROOF-based
Analysis Facility for ALICE at INFN Torino.


General information
-------------------

The Virtual Analysis Facility is a PROOF cluster running on virtual
machines capable of expanding and reducing automatically upon user
requests by starting and stopping virtual machines.

Elasticity happens behind the scenes: from the user's point of view it
is an ordinary PROOF cluster.

It is essentially based on the following tools:

*   [PROOF on Demand](http://pod.gsi.de/) to use PROOF on top of a
    batch system;
*   [HTCondor](http://research.cs.wisc.edu/htcondor/) as a dynamic
    workload management system;
*   [Elastiq](bit.ly/elastiq), the tool that brings elasticity to the
    whole system by starting and stopping virtual machines
    automatically when appropriate.


Preparation
-----------

> The operations described in this section need to be executed only
> the first time you connect (or each time your certificate expires).

As a Grid user, you must have your certificate and private key
installed **both in your browser and in `~/.globus`**. The files are
named `userkey.pem` and `usercert.pem`.


### Authenticate to the VAF

You must copy them to your home directory on the Virtual Analysis
Facility head node.

To do so, connect to the following web site with
your browser:

> <https://cloud-gw-218.to.infn.it/auth>

Ignore the warning. If you are able to connect, you are presented with
a web page saying for how long your credentials will be valid.


### Prepare your SSH connection

SSH is the tool you'll need to connect to the VAF, and it's the only
tool you'll ever need. Your Grid private key will be used as
credentials and you won't need any password.

To avoid typing long commands to connect, edit your `~/.ssh/config`
file (create an empty one in case you don't have it) and add the
following lines (copy & paste them, and substitute
`<YOUR_ALIEN_USERNAME>` with your actual AliEn username):

    Host cloud-gw-218.to.infn.it
      CheckHostIP no
      User <YOUR_ALIEN_USERNAME>
      UserKnownHostsFile /dev/null
      StrictHostKeyChecking no
      ForwardX11 yes
      ForwardX11Timeout 596h
      IdentityFile ~/.globus/userkey.pem

You can try if the connection works right afterwards by executing:

    ssh cloud-gw-218.to.infn.it


### Transfer your credentials to the VAF

In order to connect to AliEn, you must have your user certificate
private key transferred to the VAF head node. Do so by issuing:

    rsync -av ~/.globus/ cloud-gw-218.to.infn.it:.globus/

This last point must be repeated each time your certificate expires.


Running on the VAF
------------------

Running on the VAF is slightly different than running on the ALICE
CAF: the main difference is that you must request the number of
PROOF workers you desire before starting the analysis.

Choosing the appropriate AliRoot version with its dependencies is
much simpler and it is done automatically to reduce user errors.


### Connect to the VAF

There are two steps to connect to the VAF. First, go to the website:

> <https://cloud-gw-218.to.infn.it/auth>

Your "token" will be valid for a while: after that period you will
need to go again to that page.

While the "token" is valid you can SSH to the VAF:

    ssh cloud-gw-218.to.infn.it

and you'll be in.

**In case SSH fails** it probably means that you need to refresh your
"token" using the web browser and the provided link.


### Choose your AliRoot version

Once you are in, you are in an environment where all AliRoot versions
available on the Grid can be used out of the box.

To select which AliRoot version to use, edit the file
`~/.vaf/common.before` and set the following variable appropriately:

    export VafAliRootVersion='v5-05-38-AN'

You don't have to worry about the ROOT version since it will be chosen
automatically according to the compatibility list available on
[MonALISA](alimonitor.cern.ch/packages/).


### Load the shell environment

Simply enter the environment by typing:

    vaf-enter

This opens a new shell. To "clean" the environment, simply exit by
typing:

    exit

**Note:** each time you change your AliRoot version, you need to exit
and re-enter.

A token is automatically requested when entering the environment. All
the ALICE tools are available and can be used, like `aliensh` and
`aliroot`.

You can check if the AliRoot version is the correct one by typing:

    which aliroot


### Start your PROOF session

Inside the environment you can start your PROOF session by doing:

    vafctl --start

If you want, you can check if your PoD/PROOF server is up by typing:

    pod-info -lcns


### Request PROOF workers

When your PROOF session is up, you must request some workers. To do so
simply run:

    vafreq <NUM_OF_WORKERS>

where you'll substitute the number of desired workers to
`<NUM_OF_WORKERS>`.

You can do it many times to add workers to a currently running PROOF
session. For instance, if you notice that the workers you have are not
enough, you'll use `vafreq` to add some workers to it.

Not all the workers you request will be available immediately. You can
monitor the number of available workers by typing:

    vafcount

The command can be terminated via `Ctrl-C`. When you have an
appropriate number of workers running, you can start your PROOF
analysis.


#### Workers are on Virtual Machines

It might take some time for your workers to become available. The VAF
is currently configured to have **4 VMs with 6 PROOF workers each**,
meaning that, in case nobody else is using it, **24 workers** are
immediately available.

Additional worker requests will trigger the startup of new virtual
machines: usually such virtual machines will be ready in no more than
**6 minutes**, meaning that this is the maximum time you'll have to
wait after requesting more than 24 workers.

Once the workers are up, they stay there for a working day, so the
next time you'll need PROOF workers in the same working day, the
request will be satisfied immediately and with no delay.

**To sum up:** a small delay can be perceived the first time you ask
for workers, but you will not perceive it until the next working day.

As soon as you have a bunch of workers available, you can start your
analysis. If more workers become available while the analysis is
running, they will be automatically available for the next analysis.

For instance, you can request **100 workers**: as soon as something
like **20 workers** are up, you start your first analysis; the next
time you will automatically have more workers.


### Running a PROOF analysis

The macro you use to start an analysis on TAF is different than the
CAF (for instance you don't need to enable AliRoot there).

The new workflow consists of **opening the PROOF connection** and
**enabling some AliRoot libraries**. In most cases it is sufficient to
open ROOT by running `root`, and not `aliroot`.

This boils down to the following snippet:

```cpp
// List of AliRoot parameters
TList *list = new TList();
list->Add(new TNamed("ALIROOT_MODE", "AliRoot"));
list->Add(new TNamed("ALIROOT_EXTRA_LIBS", "OADB:ESD"));

// Open PROOF connection
TProof::Open("pod://");

// Upload and enable package
gProof->UploadPackage("AliRoot.par");
gProof->EnablePackage("AliRoot.par", list);
```

Datasets have also different names with respect to the CAF. Names used
here are *semantic*, as extensively explained
[in the documentation](http://proof.web.cern.ch/proof/TDataSetManagerAliEn.html).


#### The AliRoot.par package

Use the `AliRoot.par` package to enalbe and control AliRoot options on
the client, master and all the workers. Such options include things as
connecting to AliEn or enabling extra libraries.

> Download the `AliRoot.par` package from [here](extras/AliRoot.par)
> and place it in your working directory.

Options are passed via `TNamed` objects constituted by two parameters:
the option name and the option value (both are strings). A `TList` of
`TNamed` objects is passed as the second argument of the
`EnablePackage()` function, as seen from the code snippet above.

The following options are available:

*   `ALIROOT_MODE`: set it to `AliRoot`, `sim` or `rec` to
    respectively load on all workers the macro
    `$ALICE_ROOT/macros/loadlibs.C`, `loadlibssim.C` or
    `loadlibsrec.C`.
*   `ALIROOT_EXTRA_LIBS`: list of colon-separated extra AliRoot
    libraries to load, such as `OADB:ESD:STEERbase`. Names with or
    without the leading `lib` are both accepted.
*   `ALIROOT_EXTRA_INCLUDES`: list of colon-separated extra AliRoot
    include paths with respect to `$ALICE_ROOT`, such as
    `STEER:TOF:PWG/FLOW/Base`.
*   `ALIROOT_ENABLE_ALIEN`: set it to `1` to enable AliEn on all
    workers - this is needed if you want your workers to access
    `alien://` files.

**Note**: none of the options is mandatory! Usually, the only option
you will need to use is `ALIROOT_EXTRA_LIBS`.


### Turn off your PROOF cluster

When your working day is finished, remember to turn off your PROOF
cluster to free resources:

    vafctl --stop


### Troubleshooting

Unlike the CAF, in case of problems (PROOF hangups, unexpected
crashes, etc.) you can restart PROOF on your own by doing:

    vafctl --stop
    vafctl --start

This is the general recover procedure in case something goes wrong.
When you restart PoD/PROOF like this, you must ask for new workers
again using `vafreq`.
