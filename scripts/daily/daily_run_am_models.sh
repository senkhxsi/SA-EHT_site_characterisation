# set up a local cache directory for am (speeds up re-runs):
if [ ! -d ${OUTDIR_AM}/am_cache ]; then
    mkdir ${OUTDIR_AM}/am_cache
fi
export AM_CACHE_PATH=${OUTDIR_AM}/am_cache
export AM_CACHE_HASH_MODULUS=7001

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

am ${OUTDIR_AM}/${SITE}_${DAY}_${MONTH}_${YEAR}.amc  $F_MIN GHz $F_MAX GHz $DF MHz 0 deg 1.0 > ${OUTDIR_AM}/${SITE}_${DAY}_${MONTH}_${YEAR}.out  2>${OUTDIR_AM}/${SITE}_${DAY}_${MONTH}_${YEAR}.err

done