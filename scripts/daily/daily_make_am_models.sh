# Make am models for the site

export LC_NUMERIC=C

# Load the environment variables from psurf_values.txt
source ${SITE_DIR}/daily_psurf_values.txt

# Find all files ending in "SUB.nc" in DATADIR, sort them, and store in array
files=($(find "$DATADIR" -name "*SUB.nc" -type f | sort))

# Loop over each file
for file in "${files[@]}"; do
    
    # Extract just the filename from the full path
    filename=$(basename "$file")
    
    # Extract the date from the filename
    # Remove the ".SUB.nc" suffix
    temp=${filename%.SUB.nc}
    # Extract just the date part (last 8 characters)
    date_str=${temp: -8}      # Gets e.g. "20250514"
    
    # Extract year, month, day from YYYYMMDD format
    YEAR=${date_str:0:4}    # First 4 characters: 2025
    MONTH=${date_str:4:2}   # Next 2 characters: 05
    DAY=${date_str:6:2}     # Last 2 characters: 14

varname="PSURF_${DAY}_${MONTH}_${YEAR}"
Ps=$(eval echo \$$varname)

$SCRIPTS_DIR/./daily_am_file_header.sh > \
    ${OUTDIR_AM}/${SITE}_${DAY}_${MONTH}_${YEAR}.amc

awk -f $SCRIPTS_DIR/../MERRA_to_am.awk T_col=2 x_H2O_col=3  x_O3_col=4 P_ground=$Ps ${OUTDIR_PROFILES}/${SITE}_${DAY}_${MONTH}_${YEAR}_MERRA_means_ex.txt >> ${OUTDIR_AM}/${SITE}_${DAY}_${MONTH}_${YEAR}.amc

done
