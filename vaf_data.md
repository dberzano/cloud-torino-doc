% Staging data on the VAF (for administrators)
% [Dario Berzano](mailto:dario.berzano@cern.ch)

This guide explains how to manage data on the Virtual Analysis
Facility for ALICE at INFN Torino.


Overview
--------

Currently the Torino VAF has a dedicated storage and a pre-configured
dataset stager.

The dedicated storage is on **alice-srv-11.to.infn.it**. Data is
exported in two ways:

*   via direct GlusterFS, mounted on **pmaster.to.infn.it** under
    `/storage` and available as if it was a local filesystem
*   via XRootD, where files are accessible via the prefix
    `root://alice-srv-11.to.infn.it//...`

If we wanted to access the AliEn file:

    alien:///alice/data/2012/LHC12a/000177233/ESDs/pass1/12000177233040.97/root_archive.zip#AliESDs.root

we would access, with the `/storage` mountpoint:

    /storage/alice/data/2012/LHC12a/000177233/ESDs/pass1/12000177233040.97/root_archive.zip#AliESDs.root

and, via XRootD:

    root://alice-srv-11.to.infn.it//storage/alice/data/2012/LHC12a/000177233/ESDs/pass1/12000177233040.97/root_archive.zip#AliESDs.root

For the latter, please mind the double slashes `//` after the server
name, and the `/storage` prefix appended to the AliEn path name.


Using the dataset stager
------------------------

In the current setup there is an instance of the [afdsmgrd dataset
stager](http://proof.web.cern.ch/proof/DatasetStager.html) already
running on `pmaster.to.infn.it`. Instructions on how to install and
set up a separate instance are pending.


Staging data
------------

This is a step-by-step howto to stage data on the Torino Virtual
Analysis Facility: please follow it closely.

The dataset name format is illustrated
[here](http://proof.web.cern.ch/proof/TDataSetManagerAliEn.html).


### Connect to pmaster.to.infn.it

Dataset staging operations are done on `pmaster.to.infn.it`. Connect
to it as the *sysman* user, or connect to root then `su` to that user,
*e.g.*:

    ssh root@pmaster.to.infn.it

then, from the root prompt of `pmaster.to.infn.it`:

    su sysman


### Enter the staging environment

To enter the staging environment, save the following script somewhere,
then *execute* (do *not* source it!) it:

```bash
#!/bin/bash

source /cvmfs/alice.cern.ch/etc/login.sh
eval $( alienv printenv VO_ALICE@ROOT::v5-34-13 )

rm -f $HOME/.PoD
mkdir -p $HOME/.PoD
cat > $HOME/.PoD/user_xpd.cf0 <<_EOF_
xpd.datasetsrc alien cache:/opt/aaf/var/proof/datasets-cache urltemplate:/storage<path> cacheexpiresecs:604800
xpd.stagereqrepo dir:/opt/aaf/var/proof/datasets
_EOF_

export LD_LIBRARY_PATH="/cvmfs/sft.cern.ch/lcg/external/Boost/1.53.0_python2.4/x86_64-slc5-gcc41-opt/lib:$LD_LIBRARY_PATH"
source /cvmfs/sft.cern.ch/lcg/external/PoD/3.12/x86_64-slc5-gcc41-python24-boost1.53/PoD_env.sh

alien-token-init proof
pod-server stop
pod-server start

T="/tmp/stage-pod-$UID.C"
cat > $T <<_EOF_
{
  TProof::Open("pod://", "masteronly");
}
_EOF_

root -l -b /tmp/stage-pod-$UID.C

rm -f $T
pod-server stop
```

**Note:** you can customize the ROOT version: usually point it to the
latest one.

After executing the script, you will be dropped to a ROOT prompt.


### Check available free space

It is **extremely important** to check if there is enough free space
on the VAF storage before issuing requests. To do so, from the
`pmaster.to.infn.it` prompt:

    df -h /storage


### Stage data

Staging data is a two-step operation. First, check if the dataset you
want to stage is correct, *e.g.*:

```cpp
gProof->ShowDataSet( "Data;Period=LHC12a;Run=177233;Variant=ESD;Pass=1" )
```

The summary will contain an estimate of the data size. In case you are
satisfied, and you have double-checked the free disk space, you may
proceed with request its staging:

```cpp
gProof->RequestStagingDataSet( "Data;Period=LHC12a;Run=177233;Variant=ESD;Pass=1" )
```


### Check staging progress

To check the staging progress, on `pmaster.to.infn.it` do, as root:

    service afdsmgrd log
