#!/bin/csh -f

# Download/Update PBS Pro submission scripts generator program
# of quantum chemistry program package on TAIWANIA cluster, 
# NCHC, Taiwan.
#
# Rangsiman Ketkaew (MSc student)
# Computational Chemistry Research Unit
# Department of Chemistry
# Faculty of Science and Technology
# Thammasat University, Thailand
# E-mail: rangsiman1993@gmail.com
#
# https://github.com/rangsimanketkaew/PBS-submission
#
# Updated: 20180709  Rangsiman Ketkaew  arngsiman1993@gmail.com
# #############################################################

echo " -----------------------------------------------------------------"
echo ""
echo " This is to download/update the C-shell program for the PBS Pro "
echo " submission script generator on Taiwania cluster, NCHC, Taiwan."
echo " Host server: https://github.com/rangsimanketkaew/PBS-submission"
echo ""
echo " [1]  All programs"
echo " [2]  subg09                  Gaussian 09"
echo " [3]  subg16                  Gaussian 16"
echo " [4]  subnwchem               NWChem"
echo " [5]  subnwmult               NWChem (multiple jobs)"
echo " [6]  subqchem                Q-Chem"
echo " [7]  suborca                 ORCA"
echo " [8]  subgms + rungms.mod     GAMESS (OpenMP)"
echo " [9]  subgmsmpi + rungms.MPI  GAMESS (MPI)"
echo " [10] sublmp                  LAMMPS (CPU)"
echo ""

if (-f subg09 || -f subg16 || -f subnwchem || -f subnwmult || -f subqchem || -f suborca || -f subgms || -f subgmsmpi || -f sublmp) then
  echo " Warning: Scripts have been found in present directory. Existing files will be replaced."
  echo -n " Do you want to continue ? [y/n]: "
  set CONT = "$<"
  if ( $CONT == "y" || $CONT == "yes" ) then
    echo " -----------------------------------------------------------------"
  else if ( $CONT == "n" || $CONT == "no" ) then
    echo " EXIT..."
    exit 1
  endif
  echo ""
endif

set TOPDIR = "https://raw.githubusercontent.com/rangsimanketkaew/PBS-submission/master"

choice:

echo -n " Enter your choice [1]: "
set INPUT = "$<"

if ( $INPUT == "" || $INPUT == "1" ) then
 rm subg09 subg16 subnwchem subnwmult subqchem suborca subgms subgmsmpi rungms.mod rungms.MPI sublmp
 wget $TOPDIR/subg09
 wget $TOPDIR/subg16
 wget $TOPDIR/subnwchem
 wget $TOPDIR/subnwmult
 wget $TOPDIR/subqchem
 wget $TOPDIR/suborca
 wget $TOPDIR/subgms
 wget $TOPDIR/rungms.mod
 wget $TOPDIR/subgmsmpi
 wget $TOPDIR/rungms.MPI
 wget $TOPDIR/sublmp
else if ($INPUT == "2") then
 rm subg09
 wget $TOPDIR/subg09
else if ($INPUT == "3") then
 rm subg16
 wget $TOPDIR/subg16
else if ($INPUT == "4") then
 rm subnwchem
 wget $TOPDIR/subnwchem
else if ($INPUT == "5") then
 rm subnwmult
 wget $TOPDIR/subnwmult
else if ($INPUT == "6") then
 rm subqchem
 wget $TOPDIR/subqchem
else if ($INPUT == "7") then
 rm suborca
 wget $TOPDIR/suborca
else if ($INPUT == "8") then
 rm subgms
 wget $TOPDIR/subgms
 wget $TOPDIR/rungms.mod
else if ($INPUT == "9") then
 rm subgmsmpi
 wget $TOPDIR/subgmsmpi
 wget $TOPDIR/rungms.MPI
else if ($INPUT == "10") then
 rm sublmp
 wget $TOPDIR/sublmp
else
 echo "Error: Your choice is incorrect. Please enter choice number 1-10."
 goto choice
endif

set HERE = "$PWD"

chmod +x $HERE/sub*
chmod +x $HERE/rungms*

echo " ---------------------------- DONES ------------------------------"
echo ""
echo "                  :)  THANK YOU VERY MUCH  :) "
echo ""
echo " -----------------------------------------------------------------"
 
