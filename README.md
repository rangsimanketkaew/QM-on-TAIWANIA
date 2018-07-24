# PBS-submission

A Suite of PBS Pro Script Generator for Interactive Job Submission on TAIWANIA Cluster 

Automatic generator of PBS Professional script for interactive job submission of quantum chemistry application on TAIWANIA (PETA) cluster, National Center for High-Performance Computing, Taiwan. All scripts were written in tcsh and tested during in stage open beta testing. Source code customization is required for use by other job scheduler and other cluster.
<p align="center">
   <img alt="Capture_Menu" src="https://github.com/rangsimanketkaew/PBS-submission/blob/master/taiwania-cluster.jpeg" align=middle width="300pt" hight="100pt" /> 
<p/>

Taiwania official website: https://iservice.nchc.org.tw

**DISCLAIMER:**
1. I am not a staff of National Center for High-Performance Computing (NCHC), Taiwan.
2. I am not related to National Center for High-Performance Computing (NCHC), Taiwan.
3. I do not take any responsibility if any damage or failure cuased through use of all script or program taken through this Github repository.

---

### Table of Contents
<!--ts-->
   * [Getting Program](#getting-program)
   * [Gaussian 09](#gaussian-09)
   * [Gaussian 16](#gaussian-16)
   * [NWChem](#nwchem)
      * [Single job submission](#single-job-submission)
      * [Multiple jobs submission](#multiple-jobs-submission)
   * [Q-Chem](#q-chem)
   * [ORCA](#orca)
   * [GAMESS](#gamess)
      * [Shared memory parallel system](#shared-memory-parallel-system)
      * [Distributed memory parallel system](#distributed-memory-parallel-system)
   * [LAMMPS](#lammps)
   * [CONTACT](#contact)
<!--te-->

---

### Getting Program

Program source codes are available at [releases page](https://github.com/rangsimanketkaew/PBS-submission/releases).

---

### Gaussian 09

* [subg09](subg09) 

* Usage: `subg09 input [output]` <br />
where **input** is your g09 input file with or without .com extension. For example,  <br />
`subg09 water_hf` <br />
`subg09 water_hf water_hf_4cores.`

* If no output specified, basename of input will be used to name output file automatically.

* Capability
  - [x] OpenMP
  - [ ] Intel MPI
  - [ ] OpenMPI
  - [ ] MPICH or MVAPICH
  - [ ] GP-GPU (CUDA)

* This G09 runtime supports only OpenMP (shared-memory) parallel method.  <br />
  This program recognizes the OMP threads from the value of %nprocs line in input.  <br />
  Max %nprocs is 40 and sensible value of %nproc are: 1, 2, 4, 8, 12, 16, 24, 32, and 36.

* Like G16, G09 will be submitted with serial queue if value of %nproc is set to 1.

<details>
<summary> Click here to see example of Gaussian input for 4 thread request on CPU queue.</summary>

```
%chk=vomilenine-freq-g16-4.chk
%mem=8GB
%nprocshared=4          !! <<----  This value is assigned as OMP_NUM_THREADS value.
#p freq B3LYP/6-31G(d)

Title Card Required

0 1
 C                  2.77247700   -1.55726100   -0.24944000
 C                  2.57516800   -0.21391100    0.22236700
 C                  3.66258100    0.58993400    0.49571100
 C                  4.95487500    0.05924200    0.30006200
 C                  5.13835000   -1.24438700   -0.15742400
 C                  4.04078000   -2.07971400   -0.44110700
 H                  3.54022600    1.61215000    0.84659000
 H                  5.82063000    0.68647200    0.50832700
 H                  6.14732700   -1.63065000   -0.30202500
 H                  4.18101400   -3.09833800   -0.79798600
 N                  1.50857200   -2.23308200   -0.46688800
 C                  1.09205700    0.01376600    0.31548100
 C                  0.56508400   -1.38330300   -0.16916400
 C                  0.45169100    0.19038400    1.70181800
 H                  0.83716900    1.07864500    2.23417400
 H                  0.61400000   -0.67650100    2.36782500
 C                 -1.02531100    0.35002700    1.28672300
 H                 -1.62528500    0.84001900    2.08048000
 C                 -0.92615500   -1.59776300   -0.23639300
 H                 -1.16616400   -2.69064700   -0.25662300
 N                 -1.59116700   -1.02041200    0.99900700
 C                  0.45662500    1.13244700   -0.55154600
 H                  0.50638000    0.83609200   -1.63113300
 C                 -1.01485700    1.18415400   -0.05441000
 H                 -1.34499800    2.22278200    0.13282400
 C                  1.18183100    2.47371100   -0.45244600
 O                  1.77040700    2.90633300   -1.41767100
 C                  1.12488300    3.24417800    0.83431200
 H                  1.96513800    3.95149200    0.90568700
 H                  0.20810900    3.84695700    0.89196200
 H                  1.14807000    2.59412400    1.72379300
 C                 -1.43760100   -0.86406700   -1.51074000
 H                 -2.21770900   -1.45377000   -2.02155200
 H                 -0.63475100   -0.74431500   -2.26051300
 C                 -1.99672600    0.50937600   -1.06002400
 H                 -2.15238600    1.17083500   -1.93738400
 C                 -3.07440500   -0.82309500    0.77399500
 H                 -3.54334800   -0.53697600    1.74827200
 O                 -3.70333500   -2.06174800    0.48837800
 H                 -3.47163400   -2.39796600   -0.40177600
 C                 -3.29369900    0.20245900   -0.33620000
 C                 -4.47635800    0.74125600   -0.64594500
 C                 -4.60024253    1.78394479   -1.77246740
 H                 -4.05885576    2.66655486   -1.50265297
 H                 -4.19662792    1.38069830   -2.67766766
 H                 -5.63131953    2.02904648   -1.91979486
 H                 -5.39456085    0.49863744   -0.15305581
 
 
```

</details>
<br />

---

### Gaussian 16
* [subg16](subg16) 

* Usage: `subg16 input [output]` <br />
where **input** is your g16 input file with or without .com extension. For example,  <br />
`subg16 water_hf` <br />
`subg16 water_hf water_hf_4cores.out`

* If no output specified, basename of input will be used to name output file automatically.

* Capability
  - [x] OpenMP
  - [ ] Intel MPI
  - [ ] OpenMPI
  - [ ] MPICH or MVAPICH
  - [x] GP-GPU (CUDA) - only in modified version.

* This G16 runtime supports only OpenMP (shared-memory) parallel method.  <br />
  This program recognizes the OMP threads from the value of %nprocs line in input.  <br />
  Max %nprocs is 40 and sensible value of %nproc are: 1, 2, 4, 8, 12, 16, 24, 32, and 36.
  
* GP-GPU is not now supported in current version of subg16, talk to me if you want a demo of modified `subg16gpu`.

<details>
<summary> Click here to see example of Gaussian input for 4 thread and 4 GPU request on GPU queue.</summary>

```
%chk=vomilenine-freq-g16-4cpu-4gpu.chk
%mem=8GB
%cpu=0-7
%gpucpu=0-3=0-3             !! <<---- 4 of 8 CPUs, 0th 1st 2nd 3rd, are used to control 4 GPU.
#p freq B3LYP/6-31G(d)

Title Card Required

0 1
 C                  2.77247700   -1.55726100   -0.24944000
 C                  2.57516800   -0.21391100    0.22236700
 C                  3.66258100    0.58993400    0.49571100
 C                  4.95487500    0.05924200    0.30006200
 C                  5.13835000   -1.24438700   -0.15742400
 C                  4.04078000   -2.07971400   -0.44110700
 H                  3.54022600    1.61215000    0.84659000
 H                  5.82063000    0.68647200    0.50832700
 H                  6.14732700   -1.63065000   -0.30202500
 H                  4.18101400   -3.09833800   -0.79798600
 N                  1.50857200   -2.23308200   -0.46688800
 C                  1.09205700    0.01376600    0.31548100
 C                  0.56508400   -1.38330300   -0.16916400
 C                  0.45169100    0.19038400    1.70181800
 H                  0.83716900    1.07864500    2.23417400
 H                  0.61400000   -0.67650100    2.36782500
 C                 -1.02531100    0.35002700    1.28672300
 H                 -1.62528500    0.84001900    2.08048000
 C                 -0.92615500   -1.59776300   -0.23639300
 H                 -1.16616400   -2.69064700   -0.25662300
 N                 -1.59116700   -1.02041200    0.99900700
 C                  0.45662500    1.13244700   -0.55154600
 H                  0.50638000    0.83609200   -1.63113300
 C                 -1.01485700    1.18415400   -0.05441000
 H                 -1.34499800    2.22278200    0.13282400
 C                  1.18183100    2.47371100   -0.45244600
 O                  1.77040700    2.90633300   -1.41767100
 C                  1.12488300    3.24417800    0.83431200
 H                  1.96513800    3.95149200    0.90568700
 H                  0.20810900    3.84695700    0.89196200
 H                  1.14807000    2.59412400    1.72379300
 C                 -1.43760100   -0.86406700   -1.51074000
 H                 -2.21770900   -1.45377000   -2.02155200
 H                 -0.63475100   -0.74431500   -2.26051300
 C                 -1.99672600    0.50937600   -1.06002400
 H                 -2.15238600    1.17083500   -1.93738400
 C                 -3.07440500   -0.82309500    0.77399500
 H                 -3.54334800   -0.53697600    1.74827200
 O                 -3.70333500   -2.06174800    0.48837800
 H                 -3.47163400   -2.39796600   -0.40177600
 C                 -3.29369900    0.20245900   -0.33620000
 C                 -4.47635800    0.74125600   -0.64594500
 C                 -4.60024253    1.78394479   -1.77246740
 H                 -4.05885576    2.66655486   -1.50265297
 H                 -4.19662792    1.38069830   -2.67766766
 H                 -5.63131953    2.02904648   -1.91979486
 H                 -5.39456085    0.49863744   -0.15305581
 

```

</details>
<br />

* Warning: If %nproc is set to 1, G16 job will be submitted in serial queue.  <br />
  If %nproc is 2 through 40, G16 job will be submitted in cf40 queue instead.
  
* For requesting of other queue, we suggest you to modify the PBS script of cf40 as your need.

* Gaussian official website: http://gaussian.com/

---

### NWChem 

#### Single job submission

* [subnwchem](subnwchem)

* Usage: `subnwchem input[.nw] [output[.out]] [gpu | casper | mpipr | help]` <br />
where **input** is NWChem input file with or without .nwchem extension. <br/>
Explaination of each optional keyword are below. <br /> 
Example of using subnwchem are following
  - `subnwchem input`           
  Submit job on CPU node.
  - `subnwchem input mpipr`         
  Submit job on CPU node using MPI-PR. Recommended for medium & large jobs.
  - `subnwchem input casper`        
  Submit job on CPU node using Casper. Use Casper when MPI-PR fails.
  - `subnwchem input gpu`           
  Submit job on GPU node using CUDA.
  - `subnwchem input gpu casper`    
  Submit job on GPU node using CUDA and Casper.

* Capability
  - [ ] OpenMP
  - [x] Intel MPI
  - [ ] OpenMPI
  - [x] MPICH or MVAPICH
  - [x] GP-GPU (CUDA)

* subnwchem supports NWChem to run the requested ARMCI method: Casper and MPI-PR, and GPU/CUDA accelerator on GPU compute node. 

* GPU/CUDA technology supports only the tensor contraction engine (TCE) module for coupled-cluster (CC) calculation. Note that CUDA/MPI-PR is not now supported. Please do avoid requesting CUDA and MPI-PR simultaneously. Command line optional argument is case sensitive. Lowercase is only supported.

* Commands

<center>

| Command | Function |
| :---:   | --- |
| input   | MWChem input file with or without .nw extension |
| output  | MWChem output file with or without .out extension |
| gpu     | Requests GPU accelerator |
| casper  | Requests Casper method (against MPI-PR) |
| mpipr   | Requests MPI-PR method (against Casper) |
| help   <br/> -h <br/> -help | Open this help |

</center>

* Limitations

<center>

| Quantity     | Maximum value |
| ---          | --- |
| Compute node | 600 |
| CPU cores    | 40 (per node) |
| MPI process  | 40 (per node) |
| Threads      | 40 (per node & per MPI rank) |

</center>

#### Multiple jobs submission

* [subnwmult](subnwmult)

* Usage: `subnwmult 1st_inp.nw [ 2nd_inp.nw | 3rd_inp.nw | ... | 10th_inp.nw ]` <br />
Note that the first NWChem input is at least required.

* Capability
  - [ ] OpenMP
  - [x] Intel MPI
  - [ ] OpenMPI
  - [x] MPICH or MVAPICH
  - [ ] GP-GPU (CUDA)

* READ BEFORE USE:
  1. User is not allowed to specify output file. Basename of input file will be used for naming output file. For example, nwchem.nw => nwchem.out
  2. Existing output file whose basename is similar to name of submitting input will be overwritten.
  3. Neither ARMCI Casper, nor MPIPR, and nor GPU/CUDA are supported at this time.

* To implement ARMCI and GPU modules in subnwmult, consult [subnwchem](subnwchem) script.

* NWChem official website: http://www.nwchem-sw.org  <br />
* NWChem official manual: https://github.com/nwchemgit/nwchem/wiki

---

### Q-Chem
* [subqchem](subqchem)

* Usage: `subqchem [thread] input [output]` <br />
where **thread** is number of OpenMP threads and **input** is Q-Chem input file with or without .in extension.<br/>
Default value of thread is 1.

* Capability
  - [x] OpenMP
  - [x] Intel MPI (TBA)
  - [ ] OpenMPI
  - [ ] MPICH or MVAPICH
  - [ ] GP-GPU (CUDA)
  
* Details: Parallelizability of Q-Chem that run in parallel with shared-memory (OpenMP) is better than that of non-shared memory (MPI).

<details>
<summary> Click here to see example of Q-Chem input.</summary>

```
$molecule
0 1
O
H1 O OH
H2 O OH H1 HOH

OH  = 0.947
HOH = 105.5
$end


$rem
jobtype = freq
exchange = pbe
correlation = pbe
basis = 6-31+g*
ideriv = 2
$end
```

</details>
<br />

* This script supports the Q-Chem PBS job submission with only OpenMP. If you want to use MPI instead, talk to TAIWANIA staff.

* Q-Chem official website: http://www.q-chem.com/

---

### ORCA 
* [suborca](suborca)

* Usage: `suborca input [output]` <br />
where **input** is ORCA input file with or without .inp extension.

* Capability
  - [ ] OpenMP
  - [ ] Intel MPI
  - [x] OpenMPI
  - [ ] MPICH or MVAPICH
  - [ ] GP-GPU (CUDA)

* ORCA generates a lot of tempolrary and scratch files in working directory, where input file is. suborca will make the symbolic link of input file to scratch folder of server in order to avoid writing scratch files in working directory. Hence, ORCA will read linking standard input file and write output file in working directory.

* suborca supports the PBS job submission with only OpenMPI parallel method. Please unload/disable other MPI module before running ORCA.

* suborca detects the user-defined number of MPI processes from value of **PALn** keyword, where n is sensible positive integer, in keyword line of input file. Following is an example of single-point energy calculation run in parallel with 8 MPI ranks.

<details>
<summary> Click here to see example of ORCA input for 8 MPI ranks.</summary>

```
! RHF TightSCF PModel
! opt PAL8

* xyz 0 1
 C 0.000000 0.000000 0.000000
 C 0.000000 0.000000 1.400000
 C 1.212436 0.000000 2.100000
 C 2.424871 0.000000 1.400000
 C 2.424871 0.000000 0.000000
 C 1.212436 0.000000 -0.700000
 H -0.943102 0.000000 1.944500
 H 1.212436 0.000000 3.189000
 H 3.367973 0.000000 1.944500
 H 3.367973 0.000000 -0.544500
 H 1.212436 0.000000 -1.789000
 H -0.943102 0.000000 -0.544500
*
```

</details>
<br/>

* ORCA official website: https://orcaforum.cec.mpg.de/

---

### GAMESS
* [subgms](subgms) and [subgmsmpi](subgmsmpi)

* Usage: `subgms input [output]`  
* Usage: `subgmsmpi input [output]` <br/>
where **input** is GAMESS input file with or without .inp extension.

* These two scripts are used to submit GAMESS calculation using PBS Pro job scheduler for OpenMP (subgms) and MPI (subgmsmpi) parallelization methods. Default GAMESS executable is **gamess.00.x**.

#### Shared memory parallel system

* [subgms](subgms)

* Dependency: [rungms.mod](rungms.mod)

* Capability
  - [x] OpenMP
  - [ ] Intel MPI
  - [ ] OpenMPI
  - [ ] MPICH or MVAPICH
  - [ ] GP-GPU (CUDA)

* Support only shared memory parallel (SMP) system using OpenMP protocol for GAMESS version that built with OpenMP algorithm. Visit [this website](https://sites.google.com/site/rangsiman1993/comp-chem/install-gamess-parallel) for installation of GAMESS with OpenMP utilization. Parallelization over multiple compute node and/or multiple processors is forbidden.

* `rungms.mod` is required for subgms script. You must save rungms.mod in either your $HOME directory or in GAMESS top directory before running subgms.

* This subgms script was tested with `$GAMESS/tests/openmp/parallel/omp-exam12.inp`.

#### Distributed memory parallel system

* [subgmsmpi](subgmsmpi)

* Dependency: [rungms.MPI](rungms.MPI)

* Capability
  - [ ] OpenMP
  - [x] Intel MPI
  - [x] OpenMPI
  - [x] MPICH or MVAPICH
  - [ ] GP-GPU (CUDA)

* Support only distributed memory parallel system using MPI protocol for GAMESS version that built with MPI method. Visit [this website](https://sites.google.com/site/rangsiman1993/comp-chem/install-gamess-parallel) for installation of GAMESS with MPI utilization. Parallelization over multiple compute node and/or multiple processors is allowed.

* `rungms.MPI` is required for subgmsmpi script. You must save rungms.MPI in either your $HOME directory or in GAMESS top directory before running subgmsmpi.

* This subgmsmpi script was tested with GAMESS version 14 FEB 2018 R1, which compiled with MPI & MKL of Intel Parallel Studio XE 2018 update1, on Taiwania Intel Xeon cluster equiped with Intel Omni-Path high-speed interconnect technology. GNU-OpenMPI, MPICH, and MVAPICH are also supported.

<details>
<summary> Click here to see example of GAMESS input for OpenMP testing: omp-exam12.inp, file is available at $GAMESS/tests/openmp/parallel/omp-exam12.inp </summary>

```
!
! Two pyrazine molecules at 20 A distance.
!
! INTOMP parameter in $INTGRL controls the algorithm of
! MPI/OpenMP workload separation. INTOMP=2 assumes
! MPI parallelization over top (I) and 2nd (J) loops collapsed,
! and OpenMP parallelization over 3nd (K) and 4th (L) loops
! collapsed.
!
! Method: RHF/6-31G*
! Final energy:
!   FINAL RHF ENERGY IS     -525.1379673445
!
 $CONTRL
  SCFTYP=rhf
!  dfttyp=b3lyp
!  RUNTYP=Optimize
  RUNTYP=Energy
  maxit=50 nprint=4 $END
 $SYSTEM TIMLIM=50 MEMORY=10000000 $END
 $SCF    DIRSCF=.TRUE. CONV=1.0d-7 FDIFF=.false. $END
 $BASIS  GBASIS=n31 NGAUSS=6 npfunc=1 $END
 $INTGRL INTOMP=2 $END
!$BASIS  GBASIS=n31 NGAUSS=6 npfunc=1 ndfunc=1 $END
 $GUESS  GUESS=huckel $END
 $DATA
 Two pyrazine molecules on the 20 A distance from each other
C1
NITROGEN    7.0      1.386350000        -0.291970000         0.013520000
NITROGEN    7.0     -1.386330000         0.292270000         0.006810000
CARBON      6.0      0.918820000         0.970770000        -0.018780000
CARBON      6.0     -0.448890000         1.258970000        -0.022080000
CARBON      6.0     -0.918810000        -0.970950000         0.007300000
CARBON      6.0      0.448860000        -1.259140000         0.010580000
HYDROGEN    1.0      1.661070000         1.765960000        -0.025760000
HYDROGEN    1.0     -0.807120000         2.286040000        -0.031760000
HYDROGEN    1.0      0.807140000        -2.286110000         0.027350000
HYDROGEN    1.0     -1.661090000        -1.766020000         0.021390000
NITROGEN    7.0      1.386350000        -0.291970000        20.013520000
NITROGEN    7.0     -1.386330000         0.292270000        20.006810000
CARBON      6.0      0.918820000         0.970770000        19.981220000
CARBON      6.0     -0.448890000         1.258970000        19.977920000
CARBON      6.0     -0.918810000        -0.970950000        20.007300000
CARBON      6.0      0.448860000        -1.259140000        20.010580000
HYDROGEN    1.0      1.661070000         1.765960000        19.974240000
HYDROGEN    1.0     -0.807120000         2.286040000        19.968240000
HYDROGEN    1.0      0.807140000        -2.286110000        20.027350000
HYDROGEN    1.0     -1.661090000        -1.766020000        20.021390000
 $END
```

</details>
<br/>

* GAMESS official website: http://www.msg.ameslab.gov/gamess/

---

### LAMMPS
* [sublmp](sublmp)

* Usage: `sublmp INPUT NODES NMPI OMP [ OUTPUT ] [ help ]` <br/>
INPUT  = LAMMPS input file. <br/>
NODES  = Number of compute nodes. <br/>
NMPI   = Number of MPI processes (per node). <br/>
OMP    = Number of OMP threads (per process). <br/>
OUTPUT = LAMMPS output file. [optional]

* Capability
  - [ ] OpenMP
  - [x] Intel MPI
  - [ ] OpenMPI
  - [ ] MPICH or MVAPICH
  - [ ] GP-GPU (CUDA)

* Maximum MPI processes/node and OMP threads/process are 40.

* GPU is not now supported.

* This program was tested with LAMMPS that built with Intel compiler, MKL, MPI from Intel Parallel Studio XE 2018 update 1, and GCC 6.3.0 compiler. `make intel_cpu_intelmpi`

---

### CONTACT
Rangsiman Ketkaew  <br />
E-mail: rangsiman1993@gmail.com

