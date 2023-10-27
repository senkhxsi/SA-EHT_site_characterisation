# Make am models for the site

# Load the environment variables from psurf_values.txt
#source psurf_values.txt

#for YEAR in {2009..2019}; do
#for SEASON in Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec; do

#export YEAR
#export SEASON

#varname="PSURF_${SEASON}_${YEAR}"
#Ps=$(eval echo \$$varname)

# Load the environment variables from "profile_stats.sh"
source profile_stats_inst.sh
echo "Estimated surface pressure (mbar):" $PS


./am_file_header.sh > \
    ${OUTDIR_AM}/15_APRIL_2022.amc

awk -f MERRA_to_am.awk T_col=2 x_H2O_col=3  x_O3_col=4 P_ground=$PS ${OUTDIR_PROFILES}/15_APRIL_2022_MERRA_inst_ex.txt >> ${OUTDIR_AM}/15_APRIL_2022.amc

#done
#done