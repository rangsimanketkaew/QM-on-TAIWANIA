#!/bin/csh
#
#  last update = 17 Aug 2016
#
#  This is a C-shell script to execute GAMESS, by typing
#       rungms JOB VERNO NCPUS >& JOB.log &
#  JOB    is the name of the 'JOB.inp' file to be executed,
#  VERNO  is the number of the executable you chose at 'lked' time,
#  NCPUS  is the number of processors to be used, or the name of
#         a host list file.
#
#  Unfortunately execution is harder to standardize than compiling,
#  so you have to do a bit more than name your machine type here:
#
#    a) choose the target for execution from the following list:
#           sockets, mpi, ga, altix, cray-xt, ibm64-sp, sgi64
#       IBM Blue Gene uses separate execution files: ~/gamess/machines/ibm-bg
#
#       choose "sockets" if your compile time target was any of these:
#             axp64, hpux32, hpux64, ibm32, ibm64, linux32,
#             mac32, mac64, sgi32, sun32, sun64
#       as all of these systems use TCP/IP sockets.  Do not name your
#       specific compile time target, instead choose "sockets".
#
#       If your target was 'linux64', you may chose "sockets" or "mpi",
#       according to how you chose to compile.  The MPI example below
#       should be carefully matched against info found in 'readme.ddi'!
#
#       Choose 'ga' if and only if you did a 'linux64' build linked
#       to the LIBCCHEM software for CPU/GPU computations.
#
#           Search on the words typed in capital letters just below
#           in order to find the right place to choose each one:
#    b) choose a directory SCR where large temporary files can reside.
#       This should be the fastest possible disk access, very spacious,
#       and almost certainly a local disk.
#       Translation: do not put these files on a slow network file system!
#    c) choose a directory USERSCR on the file server where small ASCII
#       supplementary output files should be directed.
#       Translation: it is OK to put this on a network file system!
#    d) name the location GMSPATH of your GAMESS binary.
#    e) change the the VERNO default to the version number you chose when
#       running "lked" as the VERNO default, and maybe NCPUS' default.
#    f) make sure that the ERICFMT file name and MCPPATH pathname point to
#       your file server's GAMESS tree, so that all runs can find them.
#       Again, a network file system is quite OK for these two.
#    g) customize the execution section for your target below,
#       each has its own list of further requirements.
#    h) it is unwise to have every user take a copy of this script, as you
#       can *NEVER* update all the copies later on.  Instead, it is better
#       to ask other users to create an alias to point to a common script,
#       such as this in their C-shell .login file,
#             alias gms '/u1/mike/gamess/rungms'
#    i) it is entirely possible to make 'rungms' run in a batch queue,
#       be it PBS, DQS, et cetera.  This is so installation dependent
#       that we leave it to up to you, although we give examples.
#       See ~/gamess/tools, where there are two examples of "front-end"
#       scripts which can use this file as the "back-end" actual job.
#       We use the front-end "gms" on local Infiniband clusters using
#       both Sun Grid Engine (SGE), and Portable Batch System (PBS).
#       See also a very old LoadLeveler "ll-gms" for some IBM systems.
#
set TARGET=sockets
set SCR=TEMPLATE_1
set USERSCR=TEMPLATE_2
set GMSPATH=TEMPLATE_3
#
set JOB=$1      # name of the input file xxx.inp, give only the xxx part
set VERNO=$2    # revision number of the executable created by 'lked' step
set NCPUS=$3    # number of compute processes to be run
#
# provide defaults if last two arguments are not given to this script
if (null$VERNO == null) set VERNO=00
if (null$NCPUS == null) set NCPUS=1
#
#  ---- the top third of the script is input and other file assignments ----
#
echo "----- GAMESS execution script 'rungms' -----"
set master=`hostname`
echo This job is running on host $master
echo under operating system `uname` at `date`
#
#      Batch scheduler, if any, should provide its own working directory,
#      on every assigned node (if not, modify scheduler's prolog script).
#      The SCHED variable, and scheduler assigned work space, is used
#      below only in the MPI section.  See that part for more info.
                      set SCHED=none
if ($?PBS_O_LOGNAME)  set SCHED=PBS
if ($?SGE_O_LOGNAME)  set SCHED=SGE
if ($SCHED == SGE) then
   set SCR=$TMPDIR
   echo "SGE has assigned the following compute nodes to this run:"
   uniq $TMPDIR/machines
endif
if ($SCHED == PBS) then
   #    our ISU clusters have different names for local working disk space.
   if ($?TMPDIR) then
      set SCR=$TMPDIR
   else
      set SCR=/scratch/$PBS_JOBID
   endif
   echo "PBS has assigned the following compute nodes to this run:"
   uniq $PBS_NODEFILE
endif
#
echo "Available scratch disk space (Kbyte units) at beginning of the job is"
df -k $SCR
echo "GAMESS temporary binary files will be written to $SCR"
echo "GAMESS supplementary output files will be written to $USERSCR"

#        this added as experiment, February 2007, as 8 MBytes
#        increased to 32 MB in October 2013 for the VB2000 code.
#        its intent is to detect large arrays allocated off the stack
limit stacksize 32768

#  Grab a copy of the input file.
#  In the case of examNN jobs, file is in tests/standard subdirectory.
#  In the case of exam-vbNN jobs, file is in vb2000's tests subdirectory.
if ($JOB:r.inp == $JOB) set JOB=$JOB:r      # strip off possible .inp
echo "Copying input file $JOB.inp to your run's scratch directory..."
if (-e $JOB.inp) then
   set echo
   cp  $JOB.inp  $SCR/$JOB.F05
   unset echo
else
   if (-e tests/standard/$JOB.inp) then
      set echo
      cp  tests/standard/$JOB.inp  $SCR/$JOB.F05
      unset echo
   else
      if (-e tests/$JOB.inp) then
         set echo
         cp  tests/$JOB.inp  $SCR/$JOB.F05
         unset echo
      else
         echo "Input file $JOB.inp does not exist."
         echo "This job expected the input file to be in directory `pwd`"
         echo "Please fix your file name problem, and resubmit."
         exit 4
      endif
   endif
endif

#    define many environment variables setting up file names.
#    anything can be overridden by a user's own choice, read 2nd.
#
source $GMSPATH/gms-files.csh
if (-e $HOME/.gmsrc) then
   echo "reading your own $HOME/.gmsrc"
   source $HOME/.gmsrc
endif
#
#    In case GAMESS has been interfaced to the Natural Bond Orbital
#    analysis program (http://www.chem.wisc.edu/~nbo6), you must
#    specify the full path name to the NBO binary.
#    This value is ignored if NBO has not been linked to GAMESS.
#
setenv NBOEXE /u1/mike/nbo6/bin/nbo6.i8.exe
#
#        choose remote shell execution program.
#    Parallel run do initial launch of GAMESS on remote nodes by the
#    following program.  Note that the authentication keys for ssh
#    must have been set up correctly.
#    If you wish, choose 'rsh/rcp' using .rhosts authentication instead.
setenv DDI_RSH ssh
setenv DDI_RCP scp
#
#    If a $GDDI input group is present, the calculation will be using
#    subgroups within DDI (the input NGROUP=0 means this isn't GDDI).
#
#    The master within each group must have a copy of INPUT, which is
#    dealt with below (prior to execution), once we know something about
#    the host names where INPUT is required.  The INPUT does not have
#    the global rank appended to its name, unlike all other files.
#
#    OUTPUT and PUNCH (and perhaps many other files) are opened on all
#    processes (not just the master in each subgroup), but unique names
#    will be generated by appending the global ranks.  Note that OUTPUT
#    is not opened by the master in the first group, but is used by all
#    other groups.  Typically, the OUTPUT from the first group's master
#    is the only one worth saving, unless perhaps if runs crash out.
#
#    The other files that GDDI runs might use are already defined above.
#
set ngddi=`grep -i '^ \$GDDI' $SCR/$JOB.F05 | grep -iv 'NGROUP=0 ' | wc -l`
if ($ngddi > 0) then
   set GDDIjob=true
   echo "This is a GDDI run, keeping various output files on local disks"
   set echo
   setenv  OUTPUT $SCR/$JOB.F06
   setenv   PUNCH $SCR/$JOB.F07
   unset echo
else
   set GDDIjob=false
endif

#             replica-exchange molecular dynamics (REMD)
#     option is active iff runtyp=md as well as mremd=1 or 2.
#     It utilizes multiple replicas, one per subgroup.
#     Although REMD is indeed a GDDI kind of run, it handles its own
#     input file manipulations, but should do the GDDI file defs above.
set runmd=`grep -i runtyp=md $SCR/$JOB.F05 | wc -l`
set mremd=`grep -i mremd= $SCR/$JOB.F05 | grep -iv 'mremd=0 ' | wc -l`
if (($mremd > 0) && ($runmd > 0) && ($ngddi > 0)) then
   set GDDIjob=false
   set REMDjob=true
   echo "This is a REMD run, keeping various output files on local disks"
   set echo
   setenv TRAJECT     $SCR/$JOB.F04
   setenv RESTART $USERSCR/$JOB.rst
   setenv    REMD $USERSCR/$JOB.remd
   unset echo
   set GDDIinp=(`grep -i '^ \$GDDI' $JOB.inp`)
   set numkwd=$#GDDIinp
   @ g = 2
   @ gmax = $numkwd - 1
   while ($g <= $gmax)
      set keypair=$GDDIinp[$g]
      set keyword=`echo $keypair | awk '{split($1,a,"="); print a[1]}'`
      if (($keyword == ngroup) || ($keyword == NGROUP)) then
         set nREMDreplica=`echo $keypair | awk '{split($1,a,"="); print a[2]}'`
         @ g = $gmax
      endif
      @ g++
   end
   unset g
   unset gmax
   unset keypair
   unset keyword
else
   set REMDjob=false
endif

#    data left over from a previous run might be precious, stop if found.
if ((-e $PUNCH) || (-e $MAKEFP) || (-e $TRAJECT) || (-e $RESTART) ) then
   echo "Please save, rename, or erase these files from a previous run:"
   echo "     $PUNCH,"
   echo "     $TRAJECT,"
   echo "     $RESTART, and/or"
   echo "     $MAKEFP,"
   echo "and then resubmit this computation."
   exit 4
endif

#  ---- the middle third of the script is to execute GAMESS ----
#
#  we show execution sections that should work for
#        sockets, mpi, altix, cray-xt, ibm64-sp, sgi64
#  and then two others
#        cray-x1, necsx
#  which are not mentioned at the top of this file, as they are quite stale.
#
#   Most workstations run DDI over TCP/IP sockets, and therefore execute
#   according to the following clause.  The installer must
#      a) Set the path to point to the DDIKICK and GAMESS executables.
#      b) Build the HOSTLIST variable as a word separated string, i.e. ()'s.
#         There should be one host name for every compute process that is
#         to be run.  DDIKICK will automatically generate a set of data
#         server processes (if required) on the same hosts.
#   An extended explanation of the arguments to ddikick.x can be found
#   in the file gamess/ddi/readme.ddi, if you have any trouble executing.
#
if ($TARGET == sockets) then
#
#        adjust the path pointing to GAMESS and DDIKICK binaries
#           The default path to GAMESS was already set above!
#     At Iowa State, we have many operating systems, and store files
#     in different partitions according to which system is being used.
#     The other nodes have a separate directory for each machine,
#     based on their host names.
#
#       special compilation for IBM AIX pSeries p4+   (uname AIX)
   if (`hostname` == ti.msg.chem.iastate.edu) set GMSPATH=/ti/mike/gamess
#       special compilation for Digital AXP500        (uname OSF1)
   if (`hostname` == in.msg.chem.iastate.edu) set GMSPATH=/in/mike/gamess
   if (`hostname` == sn.msg.chem.iastate.edu) set GMSPATH=/in/mike/gamess
#       special compilation for Sun SunFire 280R      (uname SunOS)
   if (`hostname` == hf.msg.chem.iastate.edu) set GMSPATH=/hf/mike/gamess
   if (`hostname` == ta.msg.chem.iastate.edu) set GMSPATH=/hf/mike/gamess
#       special compilation for Sun V40Z Opteron uS3  (uname also= SunOS)
   if (`hostname` == as.msg.chem.iastate.edu) set GMSPATH=/as/mike/gamess
#       special compilation for HP rx2600 Itan2       (uname HP-UX)
   if (`hostname` == zr.msg.chem.iastate.edu) set GMSPATH=/zr/mike/gamess
   if (`hostname` == nb.msg.chem.iastate.edu) set GMSPATH=/zr/mike/gamess
#       special compilation for SGI Altix 450         (uname also= Linux)
   if (`hostname` == br.msg.chem.iastate.edu) set GMSPATH=/br/mike/gamess
#       special compilation for SGI XE210             (uname also= Linux)
   if (`hostname` == se.msg.chem.iastate.edu) set GMSPATH=/se/mike/gamess
   if (`hostname` == sb.msg.chem.iastate.edu) set GMSPATH=/se/mike/gamess
#       place holder for an Apple node                (uname Darwin)
   if (`hostname` == XX.msg.chem.iastate.edu) set GMSPATH=/users/mike/desktop/gamess

#      -- some special settings for certain operating systems --

   set os=`uname`
#         IBM's AIX needs special setting if node is more than a 4-way SMP
   if ($os == AIX) setenv EXTSHM ON
#         next allows the huge modules in efpmodule.src to load for execution
   if ($os == AIX) limit datasize 2097151
#         Fedora Core 1 can't run DDI processes w/o placing a finite
#         but large limit on the stack size (2**27 bytes seems OK)
   if ($os == Linux) limit stacksize 131072
#         In case this Linux system is using Intel's Math Kernel Library
#         to obtain its BLAS, we insist each process runs single-threaded.
#         one variable is for MKL up to 9, the other from 10 on up.
   if ($os == Linux) setenv MKL_SERIAL YES
   if ($os == Linux) setenv MKL_NUM_THREADS 1

#         it is unlikely that you would need to change DDI_VER from 'new'!
#         some antique system lacking pthreads, for example, might have
#         to use the old DDI code, so we keep an execution example below.
   set DDI_VER='new'
   if (`hostname` == antique.msg.chem.iastate.edu) set DDI_VER='old'

#
#       Six examples of how to build the HOSTLIST are shown....
#           terminology: CPU= processor core,
#                       NODE= physical enclosure (box/blade)
#
#       1. User provided a host list as a file. The host list should have this
#          structure (one node per line, two entrees per line: node name
#          and the number of cores):
#          node1 8
#          node2 12
#          ...
   if (-e $NCPUS) then
      set NNODES=`wc -l <$NCPUS`
      set HOSTLIST=()
      @ CPU=1
      set ncores=0
      while ($CPU <= $NNODES)
         set node=`sed -n -e "$CPU p" <$NCPUS`
         set n=`echo $node | awk '{ print $1 }'`
         set c=`echo $node | awk '{ print $2 }'`
         set HOSTLIST=($HOSTLIST ${n}:cpus=$c)
         @ CPU++
         @ ncores += $c
      end
      echo Using $NNODES nodes and $ncores cores from $NCPUS.
      set NCPUS=$ncores
      goto skipsetup
   endif
#
#       2. Sequential execution is sure to be on this very same host
   if ($NCPUS == 1) then
      set NNODES=1
      set HOSTLIST=(`hostname`)
   endif
#
#       3. This is an example of how to run on a multi-core SMP enclosure,
#          where all CPUs (aka COREs) are inside a -single- NODE.
#     At other locations, you may wish to consider some of the examples
#     that follow below, after commenting out this ISU specific part.
   if ($NCPUS > 1) then
      switch (`hostname`)
         case se.msg.chem.iastate.edu:
         case sb.msg.chem.iastate.edu:
            if ($NCPUS > 2) set NCPUS=2
            set NNODES=1
            set HOSTLIST=(`hostname`:cpus=$NCPUS)
            breaksw
         case cd.msg.chem.iastate.edu:
         case zn.msg.chem.iastate.edu:
         case ni.msg.chem.iastate.edu:
         case te.msg.chem.iastate.edu:
         case pb.msg.chem.iastate.edu:
         case bi.msg.chem.iastate.edu:
         case po.msg.chem.iastate.edu:
         case at.msg.chem.iastate.edu:
         case as.msg.chem.iastate.edu:
            if ($NCPUS > 4) set NCPUS=4
            set NNODES=1
            set HOSTLIST=(`hostname`:cpus=$NCPUS)
            breaksw
         case gd.msg.chem.iastate.edu:
         case bolt.iprt.iastate.edu:
            if ($NCPUS > 6) set NCPUS=6
            set NNODES=1
            set HOSTLIST=(`hostname`:cpus=$NCPUS)
            breaksw
         case br.msg.chem.iastate.edu:
            if ($NCPUS > 8) set NCPUS=8
            set NNODES=1
            set HOSTLIST=(`hostname`:cpus=$NCPUS)
            breaksw
         case ga.msg.chem.iastate.edu:
         case ge.msg.chem.iastate.edu:
            if ($NCPUS > 12) set NCPUS=12
            set NNODES=1
            set HOSTLIST=(`hostname`:cpus=$NCPUS)
            breaksw
         default:
            echo " "
            echo Assuming a single but multicore node.
            echo " "
            set NNODES=1
            set HOSTLIST=(`hostname`:cpus=$NCPUS)
      endsw
   endif
#
#       4. How to run in a single computer, namely the "localhost", so
#          this computer needn't have a proper Internet name.
#          This example also presumes SysV was deliberately *not* chosen
#          when DDI was compiled, so that host names have to be repeated,
#          instead of using the simpler localhost:cpus=$NCPU form.
#
#          This example is appropriate for use with the pre-compiled
#          Apple binary from our web site, provided it is uncommented,
#          and the passage #2 just above is deleted or commented out.
#
#--   set HOSTLIST=()
#--   @ n=1
#--   while ($n <= $NCPUS)
#--      set HOSTLIST=($HOSTLIST localhost)
#--      @ n++
#--   end
#--   set NNODES=$NCPUS
#
#       5. A phony example, of four dual processors (arbitrary names)
#          Since their names never change, we just can just specify them.
#          Note that we can use a short name like 'bb' if and only if
#          system name resolution can map them onto the true host names.
   if (`hostname` == aa.msg.chem.iastate.edu) then
      set NCPUS=8
      set NNODES=4
      set HOSTLIST=(aa:cpus=2 bb:cpus=2 cc:cpus=2 dd:cpus=2)
   endif
#
#       6. An example of 16 uniprocessor boxes in a Beowulf-type cluster.
#          Because they are uniprocessors, we just set NNODES = NCPUS.
#          Their host names fall into the pattern fly1 to fly16,
#          which we can turn into a HOSTLIST with a small loop.
   if (`hostname` == fly1.fi.ameslab.gov) then
      set NNODES=$NCPUS
      set HOSTLIST=()
      set nmax=$NCPUS
      if ($nmax > 16) set nmax=16
      @ CPU=1
      while ($CPU <= $nmax)
         set HOSTLIST=($HOSTLIST fly$CPU)
         @ CPU++
      end
      unset $CPU
   endif

skipsetup:

#
#        we have now finished setting up a correct HOSTLIST.
#        uncomment the next two if you are doing script debugging.
#--echo "The generated host list is"
#--echo $HOSTLIST
#

#        One way to be sure that the master node of each subgroup
#        has its necessary copy of the input file is to stuff a
#        copy of the input file onto every single node right here.
   if ($GDDIjob == true) then
      @ n=2   # master in master group already did 'cp' above
      while ($n <= $NNODES)
         set host=$HOSTLIST[$n]
         set host=`echo $host | cut -f 1 -d :` # drop anything behind a colon
         echo $DDI_RCP $SCR/$JOB.F05 ${host}:$SCR/$JOB.F05
              $DDI_RCP $SCR/$JOB.F05 ${host}:$SCR/$JOB.F05
         @ n++
      end
   endif

   if ($REMDjob == true) then
      source $GMSPATH/tools/remd.csh $TARGET $nREMDreplica
      if ($status > 0) exit $status
   endif
#
#        Just make sure we have the binaries, before we try to run
#
   if ((-x $GMSPATH/gamess.$VERNO.x) && (-x $GMSPATH/ddikick.x)) then
   else
      echo The GAMESS executable gamess.$VERNO.x
      echo or else the DDIKICK executable ddikick.x
      echo could not be found in directory $GMSPATH,
      echo or else they did not properly link to executable permission.
      exit 8
   endif
#
#        OK, now we are ready to execute!
#    The kickoff program initiates GAMESS process(es) on all CPUs/nodes.
#
   if ($DDI_VER == new) then
      set echo
      $GMSPATH/ddikick.x $GMSPATH/gamess.$VERNO.x $JOB \
          -ddi $NNODES $NCPUS $HOSTLIST \
          -scr $SCR < /dev/null
      unset echo
   else
      set path=($GMSPATH $path)
      set echo
      ddikick.x $JOB $GMSPATH gamess.$VERNO.x $SCR $NCPUS $HOSTLIST < /dev/null
      unset echo
   endif
endif

#      ------ end of the TCP/IP socket execution section -------



#                     - a typical MPI example -
#
#         This section is customized to two possible MPI libraries:
#             Intel MPI or MVAPICH2 (choose below).
#             We do not know tunings to use openMPI correctly!!!
#         This section is customized to two possible batch schedulers:
#             Sun Grid Engine (SGE), or Portable Batch System (PBS)
#
#         See ~/gamess/tools/gms, which is a front-end script to submit
#         this file 'rungms' as a back-end script, to either scheduler.
#
#                   if you are using some other MPI:
#         See ~/gamess/ddi/readme.ddi for information about launching
#         processes using other MPI libraries (each may be different).
#         Again: we do not know how to run openMPI effectively.
#
#                   if you are using some other batch scheduler:
#         Illustrating other batch scheduler's way's of providing the
#         hostname list is considered beyond the scope of this script.
#         Suffice it to say that
#             a) you will be given hostnames at run time
#             b) a typical way is a disk file, named by an environment
#                variable, containing the names in some format.
#             c) another typical way is an blank separated list in some
#                environment variable.
#         Either way, whatever the batch scheduler gives you must be
#         sliced-and-diced into the format required by your MPI kickoff.
#
if ($TARGET == mpi) then
   #
   #      Besides the usual three arguments to 'rungms' (see top),
   #      we'll pass in a "processers per node" value, that is,
   #      all nodes are presumed to have equal numbers of cores.
   #
   set PPN=$4
   #
   #      Allow for compute process and data servers (one pair per core)
   #      note that NCPUS = #cores, and NPROCS = #MPI processes
   #
   @ NPROCS = $NCPUS + $NCPUS
   #
   #      User customization required here:
   #       1. specify your MPI choice: impi/mpich/mpich2/mvapich2/openmpi
   #          Note that openMPI will probably run at only half the speed
   #          of the other MPI choices, so openmpi should not be used!
   #       2. specify your MPI library's top level path just below,
   #          this will have directories like include/lib/bin below it.
   #       3. a bit lower, perhaps specify your ifort path information.
   #
   set DDI_MPI_CHOICE=impi
   #
   #        ISU's various clusters have various iMPI paths, in this order:
   #              dynamo/chemphys2011/exalted/bolt/CyEnce/CJ
   if ($DDI_MPI_CHOICE == impi) then
      #-- DDI_MPI_ROOT=/opt/intel/impi/3.2
      #-- DDI_MPI_ROOT=/share/apps/intel/impi/4.0.1.007/intel64
      #-- DDI_MPI_ROOT=/share/apps/intel/impi/4.0.2.003/intel64
      #-- DDI_MPI_ROOT=/share/apps/mpi/impi/intel64
      set DDI_MPI_ROOT=/shared/intel/impi/4.1.0.024/intel64
      #-- DDI_MPI_ROOT=/share/apps/mpi/impi/intel64
   endif
   #
   #        ISU's various clusters have various MVAPICH2 paths, in this order:
   #              dynamo/exalted/bolt/thebunny/CJ
   if ($DDI_MPI_CHOICE == mvapich2) then
      #-- DDI_MPI_ROOT=/share/apps/mpi/mvapich2-1.9a2-generic
      #-- DDI_MPI_ROOT=/share/apps/mpi/mvapich2-1.9a2-qlc
      #-- DDI_MPI_ROOT=/share/apps/mpi/mvapich2-1.9-generic-gnu
      #-- DDI_MPI_ROOT=/share/apps/mpi/mvapich2-2.0a-generic
      set DDI_MPI_ROOT=/share/apps/mpi/mvapich2-2.1a-mlnx
   endif
   #
   #        ISU's various clusters have various openMPI paths
   #          examples are our bolt/CyEnce clusters
   if ($DDI_MPI_CHOICE == openmpi) then
      #-- DDI_MPI_ROOT=/share/apps/mpi/openmpi-1.6.4-generic
      set DDI_MPI_ROOT=/shared/openmpi-1.6.4/intel-13.0.1
   endif
   #
   #   MPICH/MPICH2
   if ($DDI_MPI_CHOICE == mpich) then
      set DDI_MPI_ROOT=/share/apps/share/mpi/mpich-3.1.3-generic-gnu
   endif
   if ($DDI_MPI_CHOICE == mpich2) then
      set DDI_MPI_ROOT=/share/apps/share/mpi/mpich-3.1.3-generic-gnu
   endif
   #
   #        pre-pend our MPI choice to the library and execution paths.
   switch ($DDI_MPI_CHOICE)
      case impi:
      case mpich:
      case mpich2:
      case mvapich2:
      case openmpi:
         setenv LD_LIBRARY_PATH $DDI_MPI_ROOT/lib:$LD_LIBRARY_PATH
         set path=($DDI_MPI_ROOT/bin $path)
         rehash
         breaksw
      default:
         breaksw
   endsw
   #
   #       you probably don't need to modify the kickoff style (see below).
   #
   if ($DDI_MPI_CHOICE == impi)     set MPI_KICKOFF_STYLE=hydra
   if ($DDI_MPI_CHOICE == mpich)    set MPI_KICKOFF_STYLE=hydra
   if ($DDI_MPI_CHOICE == mpich2)   set MPI_KICKOFF_STYLE=hydra
   if ($DDI_MPI_CHOICE == mvapich2) set MPI_KICKOFF_STYLE=hydra
   if ($DDI_MPI_CHOICE == openmpi)  set MPI_KICKOFF_STYLE=orte
   #
   #  Argonne's MPICH2, offers two possible kick-off procedures,
   #  guided by two disk files (A and B below).
   #  Other MPI implementations are often derived from Argonne's,
   #  and so usually offer these same two styles.
   #  For example, iMPI and MVAPICH2 can choose either "3steps" or "hydra",
   #  but openMPI uses its own Open Run Time Environment, "orte".
   #
   #  Kickoff procedure #1 uses mpd demons, which potentially collide
   #  if the same user runs multiple jobs that end up on the same nodes.
   #  This is called "3steps" here because three commands (mpdboot,
   #  mpiexec, mpdallexit) are needed to run.
   #
   #  Kickoff procedure #2 is little faster, easier to use, and involves
   #  only one command (mpiexec.hydra).  It is called "hydra" here.
   #
   #  Kickoff procedure #3 is probably unique to openMPI, "orte".
   #
   #  A. build HOSTFILE,
   #     This file is explicitly used only by "3steps" initiation,
   #     but it is always used below during file cleaning,
   #     and while creating the PROCFILE at step B,
   #     so we always make it.
   #
   setenv HOSTFILE $SCR/$JOB.nodes.mpd
   if (-e $HOSTFILE) rm $HOSTFILE
   touch $HOSTFILE
   #
   if ($NCPUS == 1) then
             # Serial run must be on this node itself!
      echo `hostname` >> $HOSTFILE
      set NNODES=1
   else
             # Parallel run gets node names from scheduler's assigned list:
      if ($SCHED == SGE) then
         uniq $TMPDIR/machines $HOSTFILE
         set NNODES=`wc -l $HOSTFILE`
         set NNODES=$NNODES[1]
      endif
      if ($SCHED == PBS) then
         uniq $PBS_NODEFILE $HOSTFILE
         set NNODES=`wc -l $HOSTFILE`
         set NNODES=$NNODES[1]
      endif
   endif
   #           uncomment next lines if you need to debug host configuration.
   #--echo '-----debug----'
   #--echo HOSTFILE $HOSTFILE contains
   #--cat $HOSTFILE
   #--echo '--------------'
   #
   #  B. the next file forces explicit "which process on what node" rules.
   #     The contents depend on the kickoff style.  This file is how
   #     we tell MPI to double-book the cores with two processes,
   #     thus accounting for both compute processes and data servers.
   #
   setenv PROCFILE $SCR/$JOB.processes.mpd
   if (-e $PROCFILE) rm $PROCFILE
   touch $PROCFILE

   switch ($MPI_KICKOFF_STYLE)

   case 3steps:

   #
   if ($NCPUS == 1) then
      echo "-n $NPROCS -host `hostname` $GMSPATH/gamess.$VERNO.x" >> $PROCFILE
   else
      if ($NNODES == 1) then
             # when all processes are inside a single node, it is simple!
             # all MPI processes, whether compute processes or data servers,
             # are just in this node.   (note: NPROCS = 2*NCPUS!)
         echo "-n $NPROCS -host `hostname` $GMSPATH/gamess.$VERNO.x" >> $PROCFILE
      else
             # For more than one node, we want PPN compute processes on
             # each node, and of course, PPN data servers on each.
             # Hence, PPN2 is doubled up.
             # Front end script 'gms' is responsible to ensure that NCPUS
             # is a multiple of PPN, and that PPN is less than or equals
             # the actual number of cores in the node.
         @ PPN2 = $PPN + $PPN
         @ n=1
         while ($n <= $NNODES)
            set host=`sed -n -e "$n p" $HOSTFILE`
            set host=$host[1]
            echo "-n $PPN2 -host $host $GMSPATH/gamess.$VERNO.x" >> $PROCFILE
            @ n++
         end
      endif
   endif
   breaksw

   case hydra:

   if ($NNODES == 1) then
             # when all processes are inside a single node, it is simple!
             # all MPI processes, whether compute processes or data servers,
             # are just in this node.   (note: NPROCS = 2*NCPUS!)
      @ PPN2 = $PPN + $PPN
      echo "`hostname`:$NPROCS" > $PROCFILE
   else
             # For more than one node, we want PPN compute processes on
             # each node, and of course, PPN data servers on each.
             # Hence, PPN2 is doubled up.
             # Front end script 'gms' is responsible to ensure that NCPUS
             # is a multiple of PPN, and that PPN is less than or equals
             # the actual number of cores in the node.
      @ PPN2 = $PPN + $PPN
      @ n=1
      while ($n <= $NNODES)
         set host=`sed -n -e "$n p" $HOSTFILE`
         set host=$host[1]
         echo "${host}:$PPN2" >> $PROCFILE
         @ n++
      end
   endif
   breaksw

   case orte:
   #   openMPI can double book cores on its command line, no PROCFILE!
   @ PPN2 = $PPN + $PPN
   echo "no process file is used" >> $PROCFILE
   breaksw

   endsw
   #           uncomment next lines if you need to debug host configuration.
   #--echo '-----debug----'
   #--echo PROCFILE $PROCFILE contains
   #--cat $PROCFILE
   #--echo '--------------'
   #
   #     ==== values that influence the MPI operation ====
   #
   #     tunings below are specific to Intel MPI 3.2 and/or 4.0:
   #        a very important option avoids polling for incoming messages
   #           which allows us to compile DDI in pure "mpi" mode,
   #           and get sleeping data servers if the run is SCF level.
   #        trial and error showed process pinning slows down GAMESS runs,
   #        set debug option to 5 to see messages while kicking off,
   #        set debug option to 200 to see even more messages than that,
   #        set statistics option to 1 or 2 to collect messaging info,
   #        iMPI 4.0 on up defaults fabric to shm,dapl: dapl only is faster.
   #
   if ($DDI_MPI_CHOICE == impi) then
      set echo
      setenv I_MPI_WAIT_MODE enable
      setenv I_MPI_PIN disable
      setenv I_MPI_DEBUG 0
      setenv I_MPI_STATS 0
      #              next two select highest speed mode of an Infiniband
      setenv I_MPI_FABRICS dapl
      setenv I_MPI_DAT_LIBRARY libdat2.so
      # Force use of "shared memory copy" large message transfer mechanism
      # The "direct" mechanism was introduced and made default for IPS 2017,
      # and makes GAMESS hang when DD_GSum() is called. See IPS 2017 release notes
      # for more details.
      setenv I_MPI_SHM_LMT shm
      #              next two select TCP/IP, a slower way to use Infiniband.
      #              The device could be eth0 if IP over IB is not enabled.
      #--setenv I_MPI_FABRICS tcp
      #--setenv I_MPI_TCP_NETMASK ib0
      #      in case someone wants to try the "tag matching interface",
      #      an option which unfortunately ignores the WAIT_MODE in 4.0.2!
      #--setenv I_MPI_FABRICS tmi
      #--setenv I_MPI_TMI_LIBRARY libtmi.so
      #--setenv I_MPI_TMI_PROVIDER psm
      #--setenv TMI_CONFIG $DDI_MPI_ROOT/etc/tmi.conf
      unset echo
   endif
   #
   #      similar tunings for MVAPICH2 are
   if ($DDI_MPI_CHOICE == mvapich2) then
      set echo
      setenv MV2_USE_BLOCKING 1
      setenv MV2_ENABLE_AFFINITY 0
      unset echo
   endif
   #
   #      similar tunings for openMPI are
   #         this parameter appears to be ignored, in our hands,
   #         as the data servers always use as much machine time as
   #         the compute processes.  This effectively halves the
   #         performance of each core, and renders openMPI more or
   #         less useless.  Using '--mca mpi_yield_when_idle 1'
   #         on the orterun command line is also of no avail.
   if ($DDI_MPI_CHOICE == openmpi) then
      set echo
      setenv OMPI_MCA_mpi_yield_when_idle 1
      unset echo
   endif
   #
   #         ... thus ends setting up the process initiation,
   #             tunings, pathnames, library paths, for the MPI.
   #
   #
   #    Compiler library setup (ifort)
   #        just ignore this (or comment out) if you're using gfortran.
   #        ISU's various clusters have various compiler paths, in this order:
   #              dynamo/chemphys2011/exalted/bolt/CyEnce/thebunny/CJ
   #
   #----- LD_LIBRARY_PATH /opt/intel/fce/10.1.018/lib:$LD_LIBRARY_PATH
   #----- LD_LIBRARY_PATH /share/apps/intel/composerxe-2011.1.107/compiler/lib/intel64:$LD_LIBRARY_PATH
   #----- LD_LIBRARY_PATH /share/apps/intel/composerxe-2011.4.191/compiler/lib/intel64:$LD_LIBRARY_PATH
   #----- LD_LIBRARY_PATH /share/apps/intel/composer_xe_2013.3.163/compiler/lib/intel64:$LD_LIBRARY_PATH
   setenv LD_LIBRARY_PATH /shared/intel/composer_xe_2013.1.117/compiler/lib/intel64:$LD_LIBRARY_PATH
   #----- LD_LIBRARY_PATH "/share/apps/intel/composer_xe_2011_sp1.8.273/composer_xe_2011_sp1.11.339/compiler/lib/intel64:$LD_LIBRARY_PATH"
   #----- LD_LIBRARY_PATH /share/apps/intel/composer_xe_2013.5.192/compiler/lib/intel64:$LD_LIBRARY_PATH

   #
   #    Math library setup (MKL or Atlas):
   #
   #          set up Intel MKL (math kernel library):
   #          GAMESS links MKL statically, for single threaded execution,
   #          so if you use MKL, you can probably skip this part.
   #             below are ISU's dynamo/CyEnce clusters
   #--setenv LD_LIBRARY_PATH /opt/intel/mkl/10.0.3.020/lib/em64t
   #--setenv LD_LIBRARY_PATH /share/apps/intel/composer_xe_2013/mkl/lib/intel64
   #--setenv MKL_SERIAL YES
   #--setenv MKL_NUM_THREADS 1
   #
   #          set up Atlas, if you use that.
   #--setenv LD_LIBRARY_PATH /usr/lib64/atlas:$LD_LIBRARY_PATH

   #
   #   =========== runtime path/library setup is now finished! ===========
   #     any issues with paths and libraries can be debugged just below:
   #
   #--echo '-----debug----'
   #--echo the execution path is
   #--echo $path
   #--echo " "
   #--echo the library path is
   #--echo $LD_LIBRARY_PATH
   #--echo " "
   #--echo The dynamically linked libraries for this binary are
   #--ldd $GMSPATH/gamess.$VERNO.x
   #--echo '--------------'
   #
   #           the next two setups are GAMESS-related
   #
   #     Set up Fragment MO runs (or other runs exploiting subgroups).
   #     One way to be sure that the master node of each subgroup
   #     has its necessary copy of the input file is to stuff a
   #     copy of the input file onto every single node right here.
   if ($GDDIjob == true) then
      set nmax=`wc -l $HOSTFILE`
      set nmax=$nmax[1]
      set lasthost=$master
      echo GDDI has to copy your input to every node....
      @ n=2   # input has already been copied into the master node.
      while ($n <= $nmax)
         set host=`sed -n -e "$n p" $HOSTFILE`
         set host=$host[1]
         if ($host != $lasthost) then
            echo $DDI_RCP $SCR/$JOB.F05 ${host}:$SCR/$JOB.F05
                 $DDI_RCP $SCR/$JOB.F05 ${host}:$SCR/$JOB.F05
            set lasthost=$host
         endif
         @ n++
      end
      #      The default for the logical node size is all cores existing
      #      in the physical node (just skip setting the value).
      #      Some FMO runs may benefit by choosing smaller logical node
      #      sizes, if the physical nodes have many cores.
      #      Perhaps, trial and error might show most efficient run times
      #      of your particular problem occur using 4 cores per logical node?
      #---setenv DDI_LOGICAL_NODE_SIZE 4
   endif

   if ($REMDjob == true) then
      source $GMSPATH/tools/remd.csh $TARGET $nREMDreplica
      if ($status > 0) exit $status
   endif

   #
   #  Now, at last, we can actually kick-off the MPI processes...
   #
   echo "MPI kickoff will run GAMESS on $NCPUS cores in $NNODES nodes."
   echo "The binary to be executed is $GMSPATH/gamess.$VERNO.x"
   echo "MPI will run $NCPUS compute processes and $NCPUS data servers,"
   echo "    placing $PPN of each process type onto each node."
   echo "The scratch disk space on each node is $SCR, with free space"
   df -k $SCR
   #
   chdir $SCR
   #
   switch ($MPI_KICKOFF_STYLE)

   case 3steps:
      #
      #  a) bring up a 'ring' of MPI demons
      #
      set echo
      mpdboot --rsh=ssh -n $NNODES -f $HOSTFILE
      #
      #  b) kick off the compute processes and the data servers
      #
      mpiexec -configfile $PROCFILE < /dev/null
      #
      #  c) shut down the 'ring' of MPI demons
      #
      mpdallexit
      unset echo
      breaksw
   #
   case hydra:
      if ($DDI_MPI_CHOICE == impi) then
         set echo
         setenv I_MPI_HYDRA_ENV all
         setenv I_MPI_PERHOST $PPN2
         unset echo
      endif
      if ($DDI_MPI_CHOICE == mvapich2) then
         set echo
         setenv HYDRA_ENV all
         unset echo
      endif
      set echo
      mpiexec.hydra -f $PROCFILE -n $NPROCS \
            $GMSPATH/gamess.$VERNO.x < /dev/null
      unset echo
      breaksw

   case orte:
      set echo
      orterun -np $NPROCS --npernode $PPN2 \
              $GMSPATH/gamess.$VERNO.x < /dev/null
      unset echo
      breaksw
   #
   case default:
      echo rungms: No valid DDI-over-MPI startup procedure was chosen.
      exit
   endsw
   #
   #    keep HOSTFILE, as it is passed to the file erasing step below
   rm -f $PROCFILE
   #
endif
#      ------ end of the MPI execution section -------

if ($TARGET == ga) then
   #
   #      This section is used if and only if you run GAMESS+LIBCCHEM,
   #      over Global Arrays (GA) which is running over MPI.
   #
   #      To save space, the more verbose notes in the MPI section are
   #      not all here.  See the MPI section for extra comments.
   #
   #      LIBCCHEM wants only one process per assigned node, hence the
   #      hardwiring of processes per node to just 1.  In effect, the input
   #      value NCPUS, and thus NPROCS, are node counts, not core counts.
   #      Parallelization inside the nodes is handled by LIBCCHEM threads.
   #      The lack of data servers is due to GA as the message passing agent.
   #
   set PPN=1
   @ NPROCS = $NCPUS
   #
   #      User customization here!
   #         select MPI from just two: impi,mvapich2
   #         select MPI top level directory pathname.
   #
   set GA_MPI_CHOICE=impi
   #
   #        ISU's various clusters have various iMPI paths
   #          the examples are our exalted/bolt clusters
   if ($GA_MPI_CHOICE == impi) then
      set GA_MPI_ROOT=/share/apps/intel/impi/4.0.2.003/intel64
      #-- GA_MPI_ROOT=/share/apps/mpi/impi/intel64
   endif
      #       MPICH
   if ($GA_MPI_CHOICE == mpich) then
      set GA_MPI_ROOT=/share/apps/share/mpi/mpich-3.1.3-generic-gnu
   endif
   #       MPICH2
   if ($GA_MPI_CHOICE == mpich2) then
      set GA_MPI_ROOT=/share/apps/share/mpi/mpich-3.1.3-generic-gnu
   endif
   #        ISU's various clusters have various MVAPICH2 paths
   #          the examples are our exalted/bolt clusters
   if ($GA_MPI_CHOICE == mvapich2) then
      set GA_MPI_ROOT=/share/apps/mpi/mvapich2-1.9a2-sock
      #-- GA_MPI_ROOT=/share/apps/mpi/mvapich2-1.9-generic-gnu
   endif
   #
   #      we were unable to run by iMPI/hydra, but the old 3steps=OK.
   #      in contrast, MVAPICH2 ran well by hydra, but not by mpirun_rsh.
   if ($GA_MPI_CHOICE == impi)     set MPI_KICKOFF_STYLE=3steps
   if ($GA_MPI_CHOICE == mpich)    set MPI_KICKOFF_STYLE=hydra
   if ($GA_MPI_CHOICE == mpich2)   set MPI_KICKOFF_STYLE=hydra
   if ($GA_MPI_CHOICE == mvapich2) set MPI_KICKOFF_STYLE=hydra
   #
   #   ===== set up MPI control files to execute 1 process per node =====
   #
   #  A. build HOSTFILE,
   #
   setenv HOSTFILE $SCR/$JOB.nodes.mpd
   if (-e $HOSTFILE) rm $HOSTFILE
   touch $HOSTFILE
   #
   if ($NCPUS == 1) then
             # Serial run must be on this node itself!
      echo `hostname` >> $HOSTFILE
      set NNODES=1
   else
             # Parallel run gets node names from scheduler's assigned list:
      if ($SCHED == SGE) then
         uniq $TMPDIR/machines $HOSTFILE
         set NNODES=`wc -l $HOSTFILE`
         set NNODES=$NNODES[1]
      endif
      if ($SCHED == PBS) then
         uniq $PBS_NODEFILE $HOSTFILE
         set NNODES=`wc -l $HOSTFILE`
         set NNODES=$NNODES[1]
      endif
   endif
   #           uncomment next lines if you need to debug host configuration.
   #--echo '-----debug----'
   #--echo HOSTFILE $HOSTFILE contains
   #--cat $HOSTFILE
   #--echo '--------------'
   #
   #  B. the next file forces explicit "which process on what node" rules.
   #
   setenv PROCFILE $SCR/$JOB.processes.mpd
   if (-e $PROCFILE) rm $PROCFILE
   touch $PROCFILE

   switch ($MPI_KICKOFF_STYLE)

   case mpirun_rsh:

#           MVAPICH2 hasn't got the 3-step way, but has a similar 'mpirun_rsh'.
#           PROCFILE can remain empty, since it isn't used for this case.
      breaksw

   case 3steps:

   if ($NCPUS == 1) then
      echo "-n $NPROCS -host `hostname` $GMSPATH/gamess.cchem.$VERNO.x" >> $PROCFILE
   else
      if ($NNODES == 1) then
             # when all processes are inside a single node, it is simple!
             # all MPI processes, whether compute processes or data servers,
             # are just in this node.   (note: NPROCS = 2*NCPUS!)
         echo "-n $NPROCS -host `hostname` $GMSPATH/gamess.cchem.$VERNO.x" >> $PROCFILE
      else
         @ n=1
         while ($n <= $NNODES)
            set host=`sed -n -e "$n p" $HOSTFILE`
            set host=$host[1]
            echo "-n $PPN -host $host $GMSPATH/gamess.cchem.$VERNO.x" >> $PROCFILE
            @ n++
         end
      endif
   endif
   breaksw

   case hydra:

   if ($NNODES == 1) then
             # when all processes are inside a single node, it is simple!
      echo "`hostname`:$PPN" > $PROCFILE
   else
      @ n=1
      while ($n <= $NNODES)
         set host=`sed -n -e "$n p" $HOSTFILE`
         set host=$host[1]
         echo "${host}:$PPN" >> $PROCFILE
         @ n++
      end
   endif
   breaksw

   endsw
   #
   #           uncomment next lines if you need to debug host configuration.
   #--echo '-----debug----'
   #--echo PROCFILE $PROCFILE contains
   #--cat $PROCFILE
   #--echo '--------------'
   #
   #     add the MPI to the execution path.
   #
   if ($GA_MPI_CHOICE == impi)     set path=($GA_MPI_ROOT/bin $path)
   if ($GA_MPI_CHOICE == mpich)    set path=($GA_MPI_ROOT/bin $path)
   if ($GA_MPI_CHOICE == mpich2)   set path=($GA_MPI_ROOT/bin $path)
   if ($GA_MPI_CHOICE == mvapich2) set path=($GA_MPI_ROOT/bin $path)
   #
   #         ... thus ends setting up the process initiation files,
   #             tunings, and pathnames for the MPI.
   #
   #        ===== locate any shared object libraries we need here =====
   #       note we are adding onto any pre-existing system's library path,
   #       placing our choices first means they are sure to be obeyed.
   #
   #  a) next line finds the CUDA runtime libraries
   #            the examples are our exalted/bolt clusters
   setenv LD_LIBRARY_PATH /share/apps/cuda4.1/lib64:$LD_LIBRARY_PATH
   #--env LD_LIBRARY_PATH /share/apps/cuda/lib64:$LD_LIBRARY_PATH
   #
   #  b) next finds the right MPI libraries
   #
   if ($GA_MPI_CHOICE == impi) then
      setenv LD_LIBRARY_PATH $GA_MPI_ROOT/lib:$LD_LIBRARY_PATH
   endif
   if ($GA_MPI_CHOICE == mpich) then
      setenv LD_LIBRARY_PATH $GA_MPI_ROOT/lib:$LD_LIBRARY_PATH
   endif
   if ($GA_MPI_CHOICE == mpich2) then
      setenv LD_LIBRARY_PATH $GA_MPI_ROOT/lib:$LD_LIBRARY_PATH
   endif
   if ($GA_MPI_CHOICE == mvapich2) then
      setenv LD_LIBRARY_PATH $GA_MPI_ROOT/lib:$LD_LIBRARY_PATH
   endif
   #
   #  c) next line finds ifort-related compiler libraries
   #     ignore this, or comment out if you're using gfortran.
   #            the examples are our exalted/bolt clusters
   setenv LD_LIBRARY_PATH /share/apps/intel/composerxe-2011.4.191/compiler/lib/intel64:$LD_LIBRARY_PATH
   #--env LD_LIBRARY_PATH /share/apps/intel/composer_xe_2013.3.163/compiler/lib/intel64:$LD_LIBRARY_PATH
   #
   #  d) next line finds Intel MKL (math kernel library) libraries
   #  While pure-GAMESS steps run, we want serial execution here, note that
   #  at times LIBCCHEM manipulates some of its steps to use threaded MKL.
   #  Atlas is an acceptable substitute for MKL, if you linked to Atlas.
   #            the examples are our exalted/bolt clusters
   setenv LD_LIBRARY_PATH /share/apps/intel/composerxe-2011.4.191/mkl/lib/intel64:$LD_LIBRARY_PATH
   #--env LD_LIBRARY_PATH /share/apps/intel/composer_xe_2013.3.163/mkl/lib/intel64:$LD_LIBRARY_PATH
   #--setenv MKL_SERIAL YES
   #--setenv MKL_NUM_THREADS 1
   #
   #--setenv LD_LIBRARY_PATH /usr/lib64/atlas:$LD_LIBRARY_PATH
   #
   #      any issues with run-time libraries can be debugged just below
   #--echo '-----debug----'
   #--echo the execution path is
   #--echo $path
   #--echo the library path is
   #--echo $LD_LIBRARY_PATH
   #--echo The dynamically linked libraries for this binary are
   #--ldd $GMSPATH/gamess.cchem.$VERNO.x
   #--echo '--------------'
   #
   #     ==== values that influence the MPI operation ====
   #
   #     There is a known problem with GA on QLogics brand infiniband,
   #     for which the high speed IB mode "dapl" does not work correctly.
   #     In our experience, Mellanox brand infiniband works OK.
   #
   #         our exalted/bolt clusters have QLogics/Mellanox boards.
   #
   if ($GA_MPI_CHOICE == impi) then
      set echo
      setenv I_MPI_WAIT_MODE enable
      setenv I_MPI_PIN disable
      setenv I_MPI_DEBUG 0
      setenv I_MPI_STATS 0
      #      Qlogics Infiniband must run in IPoIB mode due to using GA.
      #         recently, device ib0 stopped working, but eth1 is OK.
      setenv I_MPI_FABRICS tcp
      setenv I_MPI_TCP_NETMASK eth1
      #      Mellanox Infiniband can launch GA in a native IB mode
      #--env I_MPI_FABRICS dapl
      #--env I_MPI_DAT_LIBRARY libdat2.so
      unset echo
   endif
   #
   #      similar tunings for MVAPICH2 are
   #      DPM=dynamic process management (GA does MPI spawning)
   #      see MPI explanation for QLogics/Mellanox choice about IPoIB/DAPL
   if ($GA_MPI_CHOICE == mvapich2) then
      set echo
      setenv MV2_USE_BLOCKING 1
      setenv MV2_USE_THREAD_WARNING 0
      setenv MV2_ENABLE_AFFINITY 0
      setenv MV2_SUPPORT_DPM 1
      #   comment out the next line if you are using DAPL instead of IPoIB
      setenv HYDRA_IFACE ib0
      unset echo
   endif
   #
   #          ===== Runtime control over LIBCCHEM =====
   #      set GMS_CCHEM to 1 to enable calls to LIBCCHEM.
   #      set CCHEM to control use of GPUs, or memory used.
   #                for example, setenv CCHEM 'devices=;memory=100m'
   #                disables the usage of GPUs,
   #                and limits memory/node to 100m (units m,g both OK)
   #      set OMP_NUM_THREADS to limit core usage to fewer than all cores.
   #
   setenv GMS_CCHEM '1'
   #
   #      Our 'gms' front end for PBS batch submission changes the value
   #      of NUMGPU to 2 or 4 depending on user's request, or else
   #      leaves NUMGPU at 0 if the user decides to ignore any GPUs.
   #
   #      Please set to your number of GPU's if you are not using
   #      the front end 'gms' to correctly change this value.
   #      The 0 otherwise leads to ignoring GPUs (OK if you have none).
   #
   #      Approximately 1 GByte of memory should be given per CPU thread.
   #      Our system is hex-core nodes, your memory setting might vary.
   @ NUMGPU=0
   if ($NUMGPU > 0) then
      setenv CCHEM 'memory=6g'
   else
      setenv CCHEM 'devices=;memory=6g'
   endif
   #
   #  Now, at last, we can actually kick-off the MPI/GA processes...
   #
   echo "MPI kickoff will start GAMESS on $NCPUS cores in $NNODES nodes."
   echo "LIBCCHEM will generate threads on all other cores in each node."
   echo "LIBCCHEM will run threads on $NUMGPU GPUs per node."
   echo "LIBCCHEM's control setting for CCHEM is $CCHEM"
   echo "The binary to be executed is $GMSPATH/gamess.cchem.$VERNO.x"
   echo "The scratch disk space on each node is $SCR, with free space"
   df -k $SCR
   chdir $SCR
   #
   switch ($MPI_KICKOFF_STYLE)
     case 3steps:
       #
       #  a) bring up a 'ring' of MPI demons
       #
       set echo
       mpdboot --rsh=ssh -n $NNODES -f $HOSTFILE
       #
       #  b) kick off the compute processes and the data servers
       #
       mpiexec -configfile $PROCFILE < /dev/null
       #
       #  c) shut down the 'ring' of MPI demons
       #
       mpdallexit
       unset echo
       breaksw

#          never succeeded in getting next kickoff stuff to actually work!
     case mpirun_rsh:
       set echo
       mpirun_rsh -ssh -np $NNODES -hostfile $HOSTFILE \
            $GMSPATH/gamess.cchem.$VERNO.x
       unset echo
       breaksw

     case hydra:
       if ($GA_MPI_CHOICE == impi) then
         set echo
         setenv I_MPI_HYDRA_ENV all
         setenv I_MPI_PERHOST $PPN
         unset echo
       endif
       if ($GA_MPI_CHOICE == mvapich2) then
         set echo
         setenv HYDRA_ENV all
         setenv HYDRA_DEBUG 0
         unset echo
       endif
       set echo
       mpiexec.hydra -f $PROCFILE -n $NPROCS \
             $GMSPATH/gamess.cchem.$VERNO.x < /dev/null
       unset echo
       breaksw

     case default:
       echo No valid GA/MPI startup procedure chosen.
       exit
       breaksw
   endsw
   #
   #    keep HOSTFILE, as it is passed to the file erasing step below
   rm -f $PROCFILE
   #
endif
#      ------ end of the GA execution section -------


#     SGI Altix or ICE, using ProPack's mpt MPI library, and PBS batch queues
#
if ($TARGET == altix) then
#
#  James Ianni bumped up two values in the script from Dave Anderson,
#  but not the first one shown.  Alan Sheinine discovered the final two.
#
   set SMP_SIZE=36
   echo Assuming this Altix has $SMP_SIZE cores/node...
   set echo
   setenv MPI_BUFS_THRESHOLD 32
#    default:  96 pages (1 page = 16KB), Max:  1 million pages
   setenv MPI_BUFS_PER_PROC 512
#    default:  32 pages (1 page = 16KB), Max:  1 million pages
   setenv MPI_BUFS_PER_HOST 32
#    set number of milliseconds between polls, helps data servers sleep
   setenv MPI_NAP 1
#    way to force MPI processes out to every node (each with SMP_SIZE cores)
   setenv MPI_CONNECTIONS_THRESHOLD $SMP_SIZE
   unset echo

   setenv GMSPATH /usr/local/u/boatzj/gamess
   cat ${PBS_NODEFILE} | sort  > $SCR/$JOB.nodes.$$
   cat $SCR/$JOB.nodes.$$ $SCR/$JOB.nodes.$$ | sort > $SCR/$JOB.2xnodes.$$
   setenv PBS_NODEFILE $SCR/$JOB.2xnodes.$$

#-debug
#--   echo "Contents of PBS_NODEFILE are ..."
#--   cat $PBS_NODEFILE
#--   echo "PBS_NODEFILE has the following number of hostnames:"
#--   cat $PBS_NODEFILE | wc -l
#-debug

   @ NPROCS = $NCPUS + $NCPUS
   chdir $SCR
   set echo
   mpiexec_mpt -v -n $NPROCS $GMSPATH/gamess.$VERNO.x $JOB
   unset echo
   rm $SCR/$JOB.nodes.$$
   rm $SCR/$JOB.2xnodes.$$
endif


#   CRAY-XT (various models) running GAMESS/DDI over MPI wants you to
#      a) set the path to point to the GAMESS executable
#      b) set SMP_SIZE to the number of cores in each XT node
#      c) read the notes below about SCR and USERSCR
#
#   This machine runs only one MPI process/core, with most of these
#   able to be compute processes.  DDI_DS_PER_NODE lets you pick
#   how many of processes are to function as data servers.
#   So a node runs SMP_SIZE minus DDI_DE_PER_NODE compute processes.
#
#   The TPN variable below lets you use more memory, by wasting
#   some of the processors, if that is needed to do your run.
#   The 4th run parameter has to be passed at time of job submission,
#   if not, all cores are used.
#
#   This machine may not allow FORTRAN to access the file server
#   directly.  As a work-around, input data like the error function
#   table can to be copied to the working disk SCR.  Any extra
#   output files can be rescued from USERSCR after the run ends.
#
#   For speed reasons, you probably want to set SCR at the top of this
#   file to /tmp, which is a RAM disk.  Not all data centers will let
#   you do this, and it is acceptable to use the less eficient
#   alternative of setting SCR to a /lustre subdirectory.
#
#   You should set USERSCR to your directory in /lustre, which is
#   visible to all compute nodes, but not as fast as its /tmp.
#   Supplemental output files (like .dat) are then not in a RAM
#   disk which is wiped automatically at job end.
#
#   If you use subgroups, e.g. $GDDI input for FMO runs, you should
#   modify the input copying near the top of this file to copy to
#   USERSCR rather than SCR.  A file in /lustre is visible to all
#   nodes!  You must also change gms-files.csh to define INPUT as
#   being in USERSCR rather than SCR.
#
#   aprun flags:
#   -n is number of processing elements PEs required for the application
#   -N is number of MPI tasks per physical node
#   -d is number of threads per MPI task (interacts w/ OMP_NUM_THREADS)
#   -r is number of CPU cores to be used for core specialization
#   -j is number of CPUs to use per compute unit (single stream mode)
#   If your data center does not let you use -r 1 below, to run on
#   a jitter-free microkernel, just remove that flag from 'aprun'.
#
if ($TARGET == cray-xt) then
       #   path to binary, and number of cores per node.
   set GMSPATH=/u/sciteam/spruitt/gamess
   set SMP_SIZE=16

       # number of processes per node (TPN=tasks/node)
   set TPN=$4
   if (null$TPN == null) set TPN=$SMP_SIZE
   if ($TPN > $SMP_SIZE) set TPN=$SMP_SIZE

   if (!(-e $SCR/$JOB)) mkdir $SCR/$JOB

       # copy auxiliary data files to working disk, redefine their location.
   cp    $ERICFMT $SCR/$JOB/ericfmt.dat
   cp -r $MCPPATH $SCR/$JOB/MCP
   setenv ERICFMT $SCR/$JOB/ericfmt.dat
   setenv MCPPATH $SCR/$JOB/MCP

       # execute, with a few run-time tunings set first.
   set echo
   setenv DDI_DS_PER_NODE 1
   setenv OMP_NUM_THREADS 1
#---   setenv MPICH_UNEX_BUFFER_SIZE 90000000
   setenv MPICH_MAX_SHORT_MSG_SIZE 4000
   chdir $SCR/$JOB
   aprun -j 1 -n $NCPUS -N $TPN $GMSPATH/gamess.$VERNO.x $JOB
   unset echo

#             Rescue the supplementary ASCII output files,
#             from /lustre to one's permanent disk storage.
#             This user is doing FMO trajectories, mainly,
#             and ends up saving all those files...
   set PERMSCR=/u/sciteam/spruitt/scr
   if (-e $USERSCR/$JOB.efp)   cp $USERSCR/$JOB.efp   $PERMSCR
   if (-e $USERSCR/$JOB.gamma) cp $USERSCR/$JOB.gamma $PERMSCR
   if (-e $USERSCR/$JOB.trj)   cp $USERSCR/$JOB.trj   $PERMSCR
   if (-e $USERSCR/$JOB.rst)   cp $USERSCR/$JOB.rst   $PERMSCR
   if (-e $USERSCR/$JOB.dat)   cp $USERSCR/$JOB.dat   $PERMSCR
                               cp $USERSCR/$JOB.trj.000* $PERMSCR
   rm -f  $USERSCR/$JOB.*
#              clean SCR, e.g. the RAM disk /tmp
   rm -f  $SCR/$JOB/$JOB.F*
   rm -f  $SCR/$JOB/ericfmt.dat
   rm -rf $SCR/$JOB/MCP
   rmdir  $SCR/$JOB
#             perhaps these next things are batch queue related files?
#             this is dangerous if jobs are launched from home directory,
#             as it will wipe out input and output!
   #---rm -f  /u/sciteam/spruitt/$JOB.*
endif


#   The IBM SP running DDI using mixed LAPI/MPI messaging wants you to
#      a) set the path to point to the GAMESS executable
#      b) define hosts in a host file, which are probably defined by
#         a batch queue system.  An example for LoadLeveler is given.
#   Please note that most IBM systems schedule their batch jobs with
#   the LoadLeveler software product.  Please see gamess/tools/llgms for
#   a "front-end" script that submits this script as a "back-end" job,
#   with all necessary LL accouterments inserted at the top of the job.
#
if ($TARGET == ibm64-sp) then
#
#     point this to where your GAMESS executable is located
   set path=($path /u1/mike/gamess)
#
#     error messages defaulted to American English, try C if lacking en_US
   setenv LOCPATH /usr/lib/nls/loc:/usr/vacpp/bin
   setenv LANG en_US
#
#     this value is picked up inside DDI, then used in a "chdir $SCR"
   setenv DDI_SCRATCH $SCR
#
#     define the name of a host name file.
#
   setenv HOSTFILE $SCR/$JOB.poehosts
   if (-e $HOSTFILE) rm -f $HOSTFILE
#
#        If the job was scheduled by LoadLeveler, let LL control everything.
#
   if ($?LOADLBATCH) then
#        just get POE to tell us what nodes we were dynamically assigned to.
      /usr/bin/poe hostname -stdoutmode ordered > $HOSTFILE
      set SMP_SIZE = $TPN
#
#        Otherwise, if this was not an LoadLeveler job, here's a hack!
#        It is unlikely this will match your SP's characteristics, as
#        we just guess its a 4-way node, 4 processors, run interactively.
#        It is here mainly to illustrate the sort of MP_XXX's you need.
   else
      set SMP_SIZE=4
      set NCPUS=4
      set NNODES=1
      echo `hostname`  > $HOSTFILE
      echo `hostname` >> $HOSTFILE
      echo `hostname` >> $HOSTFILE
      echo `hostname` >> $HOSTFILE

      echo "Variables controlling Parallel Environment process kickoff are"
      set echo
      setenv MP_NODES          $NNODES
      setenv MP_PROCS          $NCPUS
      setenv MP_HOSTFILE       $HOSTFILE
      setenv MP_CPU_USE        unique
      setenv MP_ADAPTER_USE    dedicated
#       GAMESS is implemented using both MPI and LAPI active messages.
      setenv MP_MSG_API        MPI,LAPI
      setenv MP_EUILIB         us
#       SP systems with one switch adapter might use css0, not striping csss
      setenv MP_EUIDEVICE      csss
      setenv MP_RESD           no
      unset echo
   endif

#       and now we are ready to execute, using poe to kick off the tasks.
   @ NNODES = ($NCPUS - 1) / $SMP_SIZE + 1
   echo "Running $NCPUS processes on $NNODES nodes ($SMP_SIZE-way SMP)."
   set echo
   /usr/bin/poe gamess.$VERNO.x $JOB -stdinmode none
   unset echo
endif


#   SGI Origin (a very old machine) running SHMEM wants you to
#      a) set the path to point to the GAMESS executable
#   NOTE!  This does not mean SGI Altix or ICE!!!
#   We've heard that setting the environment variable
#       SMA_SYMMETRIC_SIZE to 2147483648 (2 GB)
#   may be helpful if you see DDI_SHPALLOC error messages.
#
if ($TARGET == sgi64) then
   set GMSPATH=/home/hbar4/people/schmidt/gamess
   chdir $SCR
   set echo
   mpirun -np $NCPUS $GMSPATH/gamess.$VERNO.x $JOB < /dev/null
   unset echo
endif


#   Cray X1 running SHMEM wants you to
#      a) set the path to point to the GAMESS executable
#   this is not mentioned above, as it hasn't been verified for ages and ages.
if ($TARGET == cray-x1) then
   set GMSPATH=/u1/mike/gamess
   set OPTS="-m exclusive"
   if ($NCPUS > 16) then
      set PERNODE=16
   else
      set PERNODE=$NCPUS
   endif
   chdir $SCR
   set echo
   aprun -c core=0 -n $NCPUS -N $PERNODE $OPTS $GMSPATH/gamess.$VERNO.x $JOB
   unset echo
endif


#   NEC SX Series wants you to
#      a) set the path variable to point to the GAMESS executable
#   this is not mentioned above, as it hasn't been verified for ages and ages.
if ($TARGET == necsx) then
   set GMSPATH=/u1/mike/gamess

   chdir $SCR
   setenv F_RECLUNIT BYTE
   setenv F_ABORT YES
   setenv F_ERROPT1 252,252,2,2,1,1,2,1
   setenv F_PROGINF detail
   setenv F_SETBUF 4096
   echo Running $NCPUS compute processes and $NCPUS data server processes...
   @ NPROCS = $NCPUS + $NCPUS
   set echo
   mpirun -np $NPROCS $GMSPATH/gamess.$VERNO.x $JOB < /dev/null
   unset echo
endif
#
#  ---- the bottom third of the script is to clean up all disk files ----
#  It is quite useful to display to users how big the disk files got to be.
#
echo ----- accounting info -----
#
#   in the case of GDDI runs, we save the first PUNCH file only.
#   If something goes wrong, the .F06.00x, .F07.00x, ... from the
#   other groups are potentially interesting to look at.
if ($GDDIjob == true) cp $SCR/$JOB.F07 $USERSCR/$JOB.dat
#
#   Clean up the master's scratch directory.
#
echo Files used on the master node $master were:
ls -lF $SCR/$JOB.*
rm -f  $SCR/$JOB.F*
#
#   Clean/Rescue any files created by the VB2000 plug-in
if (-e $SCR/$JOB.V84)        mv $SCR/$JOB.V84     $USERSCR
if (-e $SCR/$JOB.V80)        rm -f $SCR/$JOB.V*
if (-e $SCR/$JOB.TEMP02)     rm -f $SCR/$JOB.TEMP*
if (-e $SCR/$JOB.orb)        mv $SCR/$JOB.orb     $USERSCR
if (-e $SCR/$JOB.vec)        mv $SCR/$JOB.vec     $USERSCR
if (-e $SCR/$JOB.mol)        mv $SCR/$JOB.mol     $USERSCR
if (-e $SCR/$JOB.molf)       mv $SCR/$JOB.molf    $USERSCR
if (-e $SCR/$JOB.mkl)        mv $SCR/$JOB.mkl     $USERSCR
if (-e $SCR/$JOB.xyz)        mv $SCR/$JOB.xyz     $USERSCR
ls $SCR/${JOB}-*.cube > $SCR/${JOB}.lis
if (! -z $SCR/${JOB}.lis) mv $SCR/${JOB}*.cube $USERSCR
rm -f $SCR/${JOB}.lis
ls $SCR/${JOB}-*.grd > $SCR/${JOB}.lis
if (! -z $SCR/${JOB}.lis) mv $SCR/${JOB}*.grd $USERSCR
rm -f $SCR/${JOB}.lis
ls $SCR/${JOB}-*.csv > $SCR/${JOB}.lis
if (! -z $SCR/${JOB}.lis) mv $SCR/${JOB}*.csv $USERSCR
rm -f $SCR/${JOB}.lis
#
#   Clean up scratch directory of remote nodes.
#
#   This may not be necessary, e.g. on a T3E where all files are in the
#   same directory, and just got cleaned out by the previous 'rm'.  Many
#   batch queue managers provide cleaning out of scratch directories.
#   It still may be interesting to the user to see the sizes of files.
#
#   The 'lasthost' business prevents multiple cleanup tries on SMP nodes.
#
if ($TARGET == sockets) then
   set nmax=${#HOSTLIST}
   set lasthost=$HOSTLIST[1]
   @ n=2   # master already cleaned above
   while ($n <= $nmax)
      set host=$HOSTLIST[$n]
      set host=`echo $host | cut -f 1 -d :`   # drop anything behind a colon
      if ($host != $lasthost) then
         echo Files from $host are:
         $DDI_RSH $host -l $USER -n "ls -l $SCR/$JOB.*"
         $DDI_RSH $host -l $USER -n "rm -f $SCR/$JOB.F*"
         set lasthost=$host
      endif
      @ n++
   end
endif
#
#    This particular example is for the combination iMPI, w/SGE or PBS.
#    We have inherited a file of unique node names from above.
#    There is an option to rescue the output files from group DDI runs,
#    such as FMO, in case you need to see the other group's outputs.
if ($TARGET == mpi) then
   set nnodes=`wc -l $HOSTFILE`
   set nnodes=$nnodes[1]
   @ n=1
   set master=`hostname`
           # burn off the .local suffix in our cluster's hostname
   set master=$master:r
   while ($n <= $nnodes)
      set host=`sed -n -e "$n p" $HOSTFILE`
           # in case of openMPI, unwanted stuff may follow the hostname
      set host=$host[1]
      if ($host != $master) then
         echo Files used on node $host were:
         #---------FMO rescue------
         #--if ($GDDIjob == true) then
         #--   echo "========= OUTPUT from node $host is =============="
         #--   ssh $host -l $USER "cat $SCR/$JOB.F06*"
         #--endif
         #---------FMO rescue------
         ssh $host -l $USER "ls -l $SCR/$JOB.*"
         ssh $host -l $USER "rm -f $SCR/$JOB.*"
      endif
      @ n++
   end
#          clean off the last file on the master's scratch disk.
   rm -f $HOSTFILE
   #
   if ($?I_MPI_STATS) then
      if ($I_MPI_STATS > 0) mv $SCR/stats.txt ~/$JOB.$NCPUS.stats
   endif
endif
#
#   IBM SP cleanup code...might need to be something other than 'rsh'.
#
if ($TARGET == ibm64-sp) then
   set lasthost=$master
   @ n=2   # we already cleaned up the master node just above.
   @ nmax=$NCPUS
   while ($n <= $nmax)
      set host=`sed -n -e "$n p" $HOSTFILE`
      if ($host != $lasthost) then
         echo Files used on node $host were:
         rsh $host "ls -l $SCR/$JOB.*"
         rsh $host "rm -f $SCR/$JOB.F*"
         set lasthost=$host
      endif
      @ n++
   end
   rm -f $HOSTFILE
endif
#
#  and this is the end
#
date
time
exit
