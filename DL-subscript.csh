#!/bin/csh -f

# Rangsiman Ketkaew
# Computational Chemistry Research Unit
# Department of Chemistry
# Thammasat University, Thailand
#
# https://github.com/rangsimanketkaew/PBS-submission
#
# Updated: 20180709  Rangsiman Ketkaew  arngsiman1993@gmail.com

echo " -----------------------------------------------------------------"
echo ""
echo " This program is to download the tcsh program script for PBS Pro "
echo " submission on Taiwania cluster, NCHC, Taiwan."
echo ""
echo " [1] Download all submission scripts"
echo " [2] Download subg09      Gaussian 09"
echo " [3] Download subg16      Gaussian 16"
echo " [4] Download subnwchem   NWChem"
echo " [5] Download subnwmult   NWChem (multiple jobs)"
echo " [6] Download subqchem    Q-Chem"
echo " [7] Download suborca     ORCA"
echo " [8] Download subgms      GAMESS (OpenMP)"
echo " [9] Download subgmsmpi   GAMESS (MPI)"
echo ""

if (-f subg09 || -f subg16 || -f subnwchem || -f subnwmult || -f subqchem || -f suborca || -f subgms || -f subgmsmpi) then
echo " Warning: some submission scripts have been found in this directory. Existing files will be replaced."
echo ""
endif

set TOPDIR = "https://raw.githubusercontent.com/rangsimanketkaew/PBS-submission/master"
choice:
echo -n " Enter your choice [1]: "
set INPUT = "$<"
if ( $INPUT == "" || $INPUT == "1" ) then
 rm subg09* subg16* subnwchem* subnwmult* subqchem* suborca subgms subgmsmpi
 wget $TOPDIR/subg09
 wget $TOPDIR/subg16
 wget $TOPDIR/subnwchem
 wget $TOPDIR/subnwmult
 wget $TOPDIR/subqchem
 wget $TOPDIR/suborca
 wget $TOPDIR/subgms
 wget $TOPDIR/subgmsmpi
 wget $TOPDIR/rungms.MPI
else if ($INPUT == "2") then
 rm subg09*
 wget $TOPDIR/subg09
else if ($INPUT == "3") then
 rm subg16*
 wget $TOPDIR/subg16
else if ($INPUT == "4") then
 rm subnwchem*
 wget $TOPDIR/subnwchem
else if ($INPUT == "5") then
 rm subnwmult*
 wget $TOPDIR/subnwmult
else if ($INPUT == "6") then
 rm subqchem*
 wget $TOPDIR/subqchem
else if ($INPUT == "7") then
 rm suborca*
 wget $TOPDIR/suborca
else if ($INPUT == "8") then
 rm subgms
 wget $TOPDIR/subgms
else if ($INPUT == "9") then
 rm subgmsmpi
 wget $TOPDIR/subgmsmpi
 wget $TOPDIR/rungms.MPI
else
 echo "Error: wrong choice, please enter choice number 1-9."
 goto choice
endif

set HERE = "$PWD"
chmod +x $HERE/sub*

echo " -----------------------------------------------------------------"
echo ""
echo "                         ~ ~ ~ Done ~ ~ ~"
echo ""
echo " You can add the alias command lines for submission script in your "
echo " $HOME/.bashrc file."
echo " For example,"
echo ""
echo '     alias subg16="$HOME/subg16"'
echo ""
echo " Then activate .bashrc using following command"
echo ""
echo "     source $HOME/.bashrc"
echo ""
echo " -----------------------------------------------------------------"
 

