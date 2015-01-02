Welcome to yajam
================

yajam (*yet another jail manager*) is a tool designed to efficiently and
securely manage a larger number of FreeBSD jails. Other than existing tools do,
yajam does not use
[nullfs](http://www.freebsd.org/cgi/man.cgi?query=mount_nullfs) to share parts
of the base system among several jails. As of today, there are a few good points
for not doing so anymore:

* disk space is cheap, and the FreeBSD base system is not that big (in
  comparison to the sizes of modern hard disks)
* a dedicated userland per jail allows flexibility with the userland version
  (as long as the jail's FreeBSD userland version is smaller than or equal to
  the host's FreeBSD version)
* and finally, not using nullfs means not being exposed to any potential
  jail-breaking bug (this doesn't mean there currently is one, but file pointer
  issues have already be seen to be a source of hassle in the past, so I
  wouldn't bet my life on the safety of nullfs for now and all times)

yajam puts a strong focus on security and reliability. Therefore, it implements
some additional restrictions:

* to foster reliability, jails are created, updated or upgraded from the
  FreeBSD source tree
  ([freebsd-update](http://www.freebsd.org/cgi/man.cgi?query=freebsd-update) is
  not necessarily the most reliable tool when it comes to **not** breaking an
  existing FreeBSD installation)
* the source tree(s) used to build the jails are kept separate from the host
  system's source tree, allowing to apply dedicated restrictions for jails via
  `src.conf` limitations
* although each jail has got it's own base system, it is kept read-only
  wherever possible (i. e. anything but `/home`, `/etc`, `/var`, `/tmp` and
  `/usr/local`), and setuid is only allowed within the read-only part of a jail
  to hedge about malicious manipulations
