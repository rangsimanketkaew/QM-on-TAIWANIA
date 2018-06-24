#!/bin/csh -f

# Multiple NWChem Interactive PBS Jobs Submission 
# on Taiwania cluster, NCHC, Taiwan
# 
# Updated 20180623  Rangsiman Ketkaew  rangsiman1993@gmail.com

if ($#argv == 0) then

echo ""
echo "  Multiple NWChem Interactive PBS Jobs Submission"
echo "  ==============================================="
echo ""
echo "  READ BEFORE USE: "
echo "   1. Basename of input file will be used for naming output file. E.g. nwchem.nw => nwchem.out"
echo "   2. Existing files whose basename is similar to name of submitting input will be replaced."
echo "   3. Neither ARMCI Casper, nor MPIPR, and nor GPU/CUDA are supported now."
echo ""
echo "  Normal usage: subnwchem.mult input.1.nw [ input.2.nw | input.3.nw | ... ] "
echo ""

exit 0

endif

set NWCHEM_TOP = "/pkg/nwchem/Casper/i18gcc6/nwchem-6.8.1-fixmrcc"
set NWCHEM_TARGET = LINUX64
set NWCHEM_EXE = "$NWCHEM_TOP/bin/$NWCHEM_TARGET/nwchem"

set INPUTSUB = ( $argv[*] )
set NUM = "$#INPUTSUB"
if ($NUM >= 10) then
  echo "Error: The upper limit of input file is 10."
  exit 1
endif
echo "|"
echo "| Check list if submitted $NUM files exist"

set ERRORLIST = ""
@ i = 1
while ($i <= $NUM)
  set INPUTFILE  = "$INPUTSUB[$i]"
  if ( -f $INPUTFILE) then
    echo "| [/]  $i.  $INPUTSUB[$i]"
  else
    echo "| [x]  $i.  $INPUTSUB[$i]"
    set ERRORLIST = "$ERRORLIST $i"
  endif
@ i ++
end

if ( "$ERRORLIST" != "" ) then
  echo "|"
  echo "| Error: Files no.$ERRORLIST do not exist."
  exit 1
endif

  echo "|"
  echo "| ======== Job Queue and Server Policy ======="
#  echo '|\
  echo '| Queue    max.Node    max.CPU    max.Walltime\
| -----    --------    -------    ------------\
| serial   1           1          96:00:00 \
| ctest    2           80         00:30:00 \
| cf40     1           40         96:00:00 \
| cf160    4           80         96:00:00 \
| ct400    10          400        96:00:00 \
| ct800    20          800        72:00:00 \
| cf1200   30          1200       48:00:00 \
| ct2k     50          2000       48:00:00 \
| ct6k     150         6000       24:00:00 \
| ct8k     200         8000       24:00:00'
  echo "|"

  echo -n "| Enter Compute node: "
  set JOBNODE = "$<"
  echo -n "| Enter CPU cores: "
  set JOBCPU = "$<"
  set JOBMPI = "$JOBCPU"
  set JOBTHREAD = 1
  echo -n "| Enter job queue: "
  set JOBQUEUE = "$<"
  echo -n "| Enter job time (E.g. 00:30:00 for 30 minutes): "
  set JOBTIME = "$<"

echo "| "
echo "| Job Information"
echo "| Compute node     = $JOBNODE"
echo "| CPU cores        = $JOBCPU (per node)"
echo "| MPI process      = $JOBMPI (per node)"
echo "| OMP THREADS      = $JOBTHREAD (per MPI process)"
echo "| Job Queue        = $JOBQUEUE"
echo "| Wall-time        = $JOBTIME"
echo "| "

@ TOTALMPI = ($JOBNODE * $JOBMPI)
echo -n "| If job info is correct, enter to continue: "
set CONFIRM = "$<"
if ("null$CONFIRM" != "null") exit 1

#---Start loop
echo "|"
@ i = 1
while ($i <= $NUM)
input:
  set INPUTFILE  = "$INPUTSUB[$i]"
  set FILENAME = `basename $INPUTFILE .nw`
  set OUTPUTFILE = "$FILENAME".out
  set JOBINPUT = "$INPUTFILE"
  set JOBOUTPUT = "$OUTPUTFILE"
  set JOBNAME = "$FILENAME"
  set PBS_SCRIPT = "submit.nwchem.$FILENAME.sh"

cat <<EOF > $PBS_SCRIPT
#!/bin/bash
#PBS -l select=$JOBNODE\:ncpus=$JOBCPU\:mpiprocs=$JOBMPI\:ompthreads=$JOBTHREAD
#PBS -l walltime=$JOBTIME
#PBS -q $JOBQUEUE
#PBS -N $JOBNAME
#PBS -P \$PROJ_ID

module load intel/2018_u1 cuda/8.0.61 gcc/6.3.0

cd \$PBS_O_WORKDIR

ulimit -c 0
ulimit -s unlimited

export SCRATCH_DIR=/work1/$USER/SCRATCH/nwchem/nwchem.pbs\${PBS_JOBID/\.srvc1/}
if [ ! -d \$SCRATCH_DIR ]; then mkdir -p \$SCRATCH_DIR; fi

export I_MPI_PIN_DOMAIN=omp
export MPI_ROOT=\$I_MPI_ROOT/intel64
export MPICC=\$MPI_ROOT/bin/mpiicc
export MPICXX=\$MPI_ROOT/bin/mpiicpc
export MPIFC=\$MPI_ROOT/bin/mpiifort
if [ ! -f ~/.nwchemrc ]; then ln -s /pkg/nwchem/etc/default.nwchemrc ~/.nwchemrc; fi

export MACHLIST=\$PBS_O_WORKDIR/nodelist.\${PBS_JOBID/\.srvc1/}

mpirun -PSM2 -n $TOTALMPI $NWCHEM_EXE \
$JOBINPUT > $JOBOUTPUT

EOF

  qsub $PBS_SCRIPT
@ i ++
end

echo "| "
echo "| Your jobs has been submitted."
echo "| Use 'qstat -u $USER' to tract your jobs."
echo "| "

