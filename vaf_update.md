% Updating VAF virtual machines (for administrators)
% [Dario Berzano](mailto:dario.berzano@cern.ch)

This guide explains how to preserve user's data while updating the
virtual machines of the Virtual Analysis Facility.


Rationale
---------

The Virtual Analysis Facility is based on CernVM virtual machines
divided into:

*   a **head node**;
*   several *disposable* **worker nodes**.

Since CernVM is based on the µCernVM bootloader and it picks all the
needed software from CernVM-FS, it is sufficient to create a new
CernVM virtual machine to have immediately available the freshest
software version.

While the **worker nodes** can be destroyed without any concern on
data loss, we may want to preserve user's home directories.

A procedure explaining how to do so follows. The examples are relative
to the Virtual Analysis Facility in Torino.


Step 1: back up the original data
---------------------------------

Connect to a non-VAF node where you have administrator (root)
privileges. In Torino you would do:

    ssh root@one-master.to.infn.it

**Note:** since we are preserving user's permissions, we want to do
this operation as the root user.

Assuming that your head node is `cloud-gw-218.to.infn.it` and the
private key for the root user is called `ProdTaf`, run the following
command:

    rsync -avz --delete --delete-excluded \
      -e "ssh -i /var/lib/one/users/prooftaf/ProdTaf.pem \
        -oUserKnownHostsFile=/dev/null \
        -oStrictHostKeyChecking=no \
        -oCheckHostIP=no" \
      root@cloud-gw-218.to.infn.it:/home/ \
      /tmp/vaf-home/ \
      --exclude '*/.proof' \
      --exclude '*/.PoD' \
      --exclude '**/cloud-user'

If the operation is successful you will end up with a copy of the sole
relevant files in `/tmp/vaf-home`.

**Note:** this command will work as-is (copy-paste it) in Torino.


Step 2: renovate the virtual cluster
------------------------------------

At this point you can safely destroy the old virtual machines and
create the new ones.

**Note:** don't forget to assign the elastic IP to the head node where
applicable.


Step 3: restore data on the new VAF
-----------------------------------

When the fresh head node is up, home directories can be restored to it
with the following command:

    rsync -avz \
      -e "ssh -i /var/lib/one/users/prooftaf/ProdTaf.pem \
        -oUserKnownHostsFile=/dev/null \
        -oStrictHostKeyChecking=no \
        -oCheckHostIP=no" \
      /tmp/vaf-home/ \
      root@cloud-gw-218.to.infn.it:/home

**Note:** this command will work as-is (copy-paste it) in Torino.
