# Make am models for the site

# Load the environment variables from psurf_values.txt
source ${SITE_DIR}/psurf_values.txt

for YEAR in {2009..2022}; do
for MONTH in Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec; do

export YEAR
export MONTH

varname="PSURF_${MONTH}_${YEAR}"
Ps=$(eval echo \$$varname)

$SCRIPTS_DIR/./am_file_header.sh > \
    ${OUTDIR_AM}/${SITE}_${MONTH}_${YEAR}.amc

awk -f $SCRIPTS_DIR/MERRA_to_am.awk T_col=2 x_H2O_col=3  x_O3_col=4 P_ground=$Ps ${OUTDIR_PROFILES}/${SITE}_${MONTH}_${YEAR}_MERRA_means_ex.txt >> ${OUTDIR_AM}/${SITE}_${MONTH}_${YEAR}.amc

done
done