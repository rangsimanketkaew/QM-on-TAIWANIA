# PBS-submission
Automated script for interactive PBS job submission.

These scripts can be only used for PBS Professional on TAIWANIA cluster.

Source code customization is required for other Job Scheduler and other cluster.

### Gaussian 16
* [subg16](subg16)
* Usage: subg16 inputfile
where inputfile is Gaussian input file with or withour .com extension.

### Q-Chem
* subqchem
* Usage:

### NWChem 
* [subnwchem](subnwchem)
* Usage: subqchem inputfile <br />
          where input file is Q-Chem input with or without .in extension.
* Details: Parallelizability of Q-Chem that run in parallel with shared-memory (MPI) is better than that of non-shared memory (OpenMP).
* This script supports the Q-Chem PBS job submission only with OpenMP method. If you want to use MPI instead, talk to TAIWANIA staff.

### Multiple NWChem jobs
* subnwmult
* Usage: 
  
---

### How to download
1. Open Githup source code of script.
2. Click on "Raw"
3. Copy URL address
4. Open your Linux terminal then use the following command for downloading the script.
```
wget url
```

Rangsiman Ketkaew
rangsiman1993@gmail.com
