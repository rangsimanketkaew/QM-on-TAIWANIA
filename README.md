# PBS-submission
Interactive PBS Professional job submission for quantum chemistry calculation on TAIWANIA (PETA) cluster, National Center for High-Performance Computing, Taiwan. All scripts were written in tcsh and tested during in stage open beta testing. Source code customization is required for use by other job scheduler and other cluster.
<p align="center">
   <img alt="Capture_Menu" src="https://github.com/rangsimanketkaew/PBS-submission/blob/master/taiwania-cluster.jpeg" align=middle width="300pt" hight="100pt" /> 
<p/>

Taiwania official website: [https://www.nchc.org.tw/tw/inner.php?CONTENT_ID=778](https://www.nchc.org.tw/tw/inner.php?CONTENT_ID=778)

### Gaussian 16
* [subg16](subg16) 

* Usage: `subg16 input [output]` <br />
where input is your g16 input file with or without .com extension. For instance,  <br />
`subg16 water_hf` <br />
`subg16 water_hf water_hf_4cores.out`

* If no output specified, basename of input will be used to name output file automatically.

* Capability
  - [x] OpenMP
  - [ ] OpenMPI
  - [ ] MPICH or MVAPICH
  - [x] GP-GPU (CUDA)

* This G16 runtime supports only OpenMP (shared-memory) parallel method.  <br />
  This program recognizes the OMP threads from the value of %nproc line in input.  <br />
  Max %nprocs is 40 and sensible value of %nproc are: 1, 2, 4, 8, 12, 16, 24, 32, and 36.

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
...
```

</details>
<br />

<details>
<summary> Click here to see example of Gaussian input for 4 thread adn 4 GPU request on GPU queue.</summary>
  
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
...
```

</details>
<br />

* Warning: If %nproc is set to 1, G16 job will be submitted in serial queue.  <br />
  If %nproc is 2 through 40, G16 job will be submitted in cf40 queue instead.
  
* For requesting of other queue, we suggest you to modify the PBS script of cf40 as your need.

* Gaussian official website: [http://gaussian.com/](http://gaussian.com/)

---

### Gaussian 09

* [subg09](subg09) 

* Usage: `subg09 input [output]` <br />
where *input* is your g09 input file with or without .com extension. For instance,  <br />
`subg09 water_hf` <br />
`subg09 water_hf water_hf_4cores.`

* If no output specified, basename of input will be used to name output file automatically.

* Capability
  - [x] OpenMP
  - [ ] OpenMPI
  - [ ] MPICH or MVAPICH
  - [ ] GP-GPU (CUDA)

* This G09 runtime supports only OpenMP (shared-memory) parallel method.  <br />
  This program recognizes the OMP threads from the value of %nproc line in input.  <br />
  Max %nprocs is 40 and sensible value of %nproc are: 1, 2, 4, 8, 12, 16, 24, 32, and 36.

* Like G16, G09 will be submitted with serial queue if value of %nproc is set to 1.

---

### Q-Chem
* [subqchem](subqchem)

* Usage: `subqchem thread input [output]` <br />
where **thread** is number of OpenMP threads and **input** is Q-Chem input file with or without .in extension.

* Capability
  - [x] OpenMP
  - [ ] OpenMPI
  - [ ] MPICH or MVAPICH
  - [ ] GP-GPU (CUDA)
  
* Details: Parallelizability of Q-Chem that run in parallel with shared-memory (MPI) is better than that of non-shared memory (OpenMP).

* This script supports the Q-Chem PBS job submission only with OpenMP method. If you want to use MPI instead, talk to TAIWANIA staff.

* Q-Chem official website: [http://www.q-chem.com/](http://www.q-chem.com/)

---

### NWChem (single job submission)
* [subnwchem](subnwchem)

* Usage: `subnwchem [gpu||casper||mpipr] [help]` <br />

* Eample: subnwchem gpu                submit NWChem using CUDA  <br />
           subnwchem gpu casper      submit NWChem using CUDA and Casper

* Capability
  - [ ] OpenMP
  - [x] OpenMPI
  - [x] MPICH or MVAPICH
  - [x] GP-GPU (CUDA)

* It can be used to submit NWChem job with and without using ARMCI methods, Casper and MPI-PR, and with and without GPU/CUDA. Note that GPU/MPI-PR is not available.

* COMMANDS

<center>
  
| Command | Task |
| :---: | --- |
| gpu      | Requests GPU accelerator | 
| casper   | Requests Casper method (against MPI-PR) |
| mpipr    | Requests MPI-PR method (against Casper) | 
| help     | Open this help |
  
</center>

* LIMITATION

<center>

| Quantity | Maximum value |
| --- | --- |
| Compute node | 600 |
| CPU cores | 40 (per node) |
| MPI process | 40 (per node) |
| Threads | 40 (per node & per MPI rank) |

</center>

* NWChem official website:  [http://www.nwchem-sw.org](http://www.nwchem-sw.org)  <br />
* NWChem official manual: [https://github.com/nwchemgit/nwchem/wiki](https://github.com/nwchemgit/nwchem/wiki)

---

### NWChem (multiple jobs submission)
* [subnwmult](subnwmult)

* Usage: `subnwmult input.1.nw [ input.2.nw | input.3.nw | ... ]` <br />

* Capability
  - [ ] OpenMP
  - [x] OpenMPI
  - [x] MPICH or MVAPICH
  - [ ] GP-GPU (CUDA)

* READ BEFORE USE: 
  1. Basename of input file will be used for naming output file. E.g. nwchem.nw => nwchem.out
  2. Existing files whose basename is similar to name of submitting input will be replaced.
  3. Neither ARMCI Casper, nor MPIPR, and nor GPU/CUDA are supported now.

---

### ORCA 

**Sorry: I am still writing the code script for ORCA.**

---

### How to download and activate

1. Open Github of code script.
2. Click at "Raw" button
3. Copy URL address
4. Open your Linux terminal then use the following command for downloading the script.
```
wget https://raw.githubusercontent.com/rangsimanketkaew/PBS-submission/master/name.of.script
```
5. Activate script using the following command
```
chmod +x name.of.script
```
Optional: you can make the alias of script by appending the following command to your `.bashrc` file. <br />
Suppose that script is at `$HOME` directory.
```
alias subnwchem="$HOME/subnwchem"
```

---

### CONTACT
Rangsiman Ketkaew  E-MAIL: rangsiman1993@gmail.com

