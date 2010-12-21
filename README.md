Gwydion Experiments
===================

This is a repository for some experiments with the Gwydion Dylan
compiler that are not appropriate for the official svn repository but
that I didn't want to do without support from revision control.  The
initial version of the repository was forked from Gwydion svn revision
12904.  To merge back changes into this repository, it should be
sufficient to generate a patch agianst the initial revision of the git
repository, apply it to a checkout of revision 12904 of the svn
repository, and then synchronize with svn HEAD.

    $ svn info
    Path: .
    URL: svn+ssh://tc@svn.gwydiondylan.org/scm/svn/dylan/trunk/gwydion
    Repository Root: svn+ssh://tc@svn.gwydiondylan.org/scm/svn/dylan
    Repository UUID: 4f5ac42c-83e7-0310-beca-a700b25708b8
    Revision: 12904
    Node Kind: directory
    Schedule: normal
    Last Changed Author: peat
    Last Changed Rev: 12903
    Last Changed Date: 2010-12-20 19:16:44 +0100 (Mon, 20 Dec 2010)
