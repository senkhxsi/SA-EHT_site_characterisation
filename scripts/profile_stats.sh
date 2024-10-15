# This script computes avgian profile statistics for a given site by
# first horizontally interpolating a set of MERRA-2 NetCDF files to the
# site longitude and latitude, then using a set of nco scripts to compute
# the average profiles for temperature, water vapour, liquid water, ice water and ozone.
#!/bin/bash


if [ -f "${SITE_DIR}/psurf_values.txt" ]; then
    echo ""psurf_values.txt" exists. Deleting..."
    rm ${SITE_DIR}/psurf_values.txt
    echo "File deleted."
else
    echo "File does not exist."
fi

PSURF_FILE=${SITE_DIR}/psurf_values.txt


for YEAR in {2009..2022}; do
for MONTH in Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec; do

echo $SITE $MONTH $YEAR

# Find data files by season, and concatenate
case $MONTH in
Jan)
    find $DATADIR  \( -name *Np.${YEAR}01* \) -print  | sort -t '.' -k 3 | ncrcat -3 -h -O -o 0.nc
    ;;
Feb)
    find $DATADIR  \( -name *Np.${YEAR}02* \) -print  | sort -t '.' -k 3 | ncrcat -3 -h -O -o 0.nc
    ;;
Mar)
    find $DATADIR  \( -name *Np.${YEAR}03* \) -print  | sort -t '.' -k 3 | ncrcat -3 -h -O -o 0.nc
    ;;
Apr)
    find $DATADIR  \( -name *Np.${YEAR}04* \) -print  | sort -t '.' -k 3 | ncrcat -3 -h -O -o 0.nc
    ;;
May)
    find $DATADIR  \( -name *Np.${YEAR}05* \) -print  | sort -t '.' -k 3 | ncrcat -3 -h -O -o 0.nc
    ;;
Jun)
    find $DATADIR  \( -name *Np.${YEAR}06* \) -print  | sort -t '.' -k 3 | ncrcat -3 -h -O -o 0.nc
    ;;
Jul)
    find $DATADIR  \( -name *Np.${YEAR}07* \) -print  | sort -t '.' -k 3 | ncrcat -3 -h -O -o 0.nc
    ;;
Aug)
    find $DATADIR  \( -name *Np.${YEAR}08* \) -print  | sort -t '.' -k 3 | ncrcat -3 -h -O -o 0.nc
    ;;
Sep)
    find $DATADIR  \( -name *Np.${YEAR}09* \) -print  | sort -t '.' -k 3 | ncrcat -3 -h -O -o 0.nc
    ;;
Oct)
    find $DATADIR  \( -name *Np.${YEAR}10* \) -print  | sort -t '.' -k 3 | ncrcat -3 -h -O -o 0.nc
    ;;
Nov)
    find $DATADIR  \( -name *Np.${YEAR}11* \) -print  | sort -t '.' -k 3 | ncrcat -3 -h -O -o 0.nc
    ;;
Dec)
    find $DATADIR  \( -name *Np.${YEAR}12* \) -print  | sort -t '.' -k 3 | ncrcat -3 -h -O -o 0.nc
    ;;
esac


# split into one file for each neighboring MERRA grid point
ncks -O -d lon,0 -d lat,0 0.nc 1.nc
ncks -O -d lon,1 -d lat,0 0.nc 2.nc
ncks -O -d lon,0 -d lat,1 0.nc 3.nc
ncks -O -d lon,1 -d lat,1 0.nc 4.nc

# Interpolate to the site position (ncflint segfaults with -i option, so
# give explicit weights with -w.) Start by computing the weighting factors.
W1=$(awk -v x=$SITE_LONG -v x0=$MERRA_LONG0 -v x1=$MERRA_LONG1 'BEGIN {print (x1 - x) / (x1 - x0)}')
W2=$(awk -v w1=$W1 'BEGIN {print 1.0 - w1}')
W3=$(awk -v y=$SITE_LAT -v y0=$MERRA_LAT0 -v y1=$MERRA_LAT1 'BEGIN {print (y1 - y) / (y1 - y0)}')
W4=$(awk -v w3=$W3 'BEGIN {print 1.0 - w3}')

# Do the interpolation, then use ncap2 to set the lon and lat
# fields in the NetCDF file to the interpolated coordinates.
ncflint -O -w ${W1},${W2} 1.nc 2.nc 7.nc
ncap2 -O -s "lon={${SITE_LONG}}" 7.nc 5.nc
ncflint -O -w ${W1},${W2} 3.nc 4.nc 7.nc
ncap2 -O -s "lon={${SITE_LONG}}" 7.nc 6.nc
ncflint -O -w ${W3},${W4} 5.nc 6.nc 7.nc
ncap2 -O -s "lat={${SITE_LAT}}" 7.nc ${SITE}_${MONTH}_${YEAR}.nc

# Get edge height means for surface pressure estimation
ncap2 -O -S $SCRIPTS_DIR/H_avgs.nco 1.nc 8.nc
ncap2 -O -S $SCRIPTS_DIR/H_avgs.nco 2.nc 9.nc
ncap2 -O -S $SCRIPTS_DIR/H_avgs.nco 3.nc 10.nc
ncap2 -O -S $SCRIPTS_DIR/H_avgs.nco 4.nc 11.nc 

rm [0-7].nc

# Estimate surface pressures
# Arrays to store results
declare -a H_above=()
declare -a H_below=()
declare -a P_above=()
declare -a P_below=()

# Loop through each gridpoint's file
for file in {8..11}.nc; do
    #echo "Processing $file..."

    # Extract lines containing 'H_avg =' and use ncks to get the values of H_avg, then use AWK to process the output and write to a temporary file
    ncks --trd -H -v H_avg "$file" | awk 'BEGIN {FS="="} /H_/ {print ($3 < 100000. ? $3 : 0)}' > temp_file.txt

    # Read the values from the temporary file into the array
    declare -a H_values=()
    while IFS= read -r value; do
        H_values+=("$value")
    done < temp_file.txt

    # Remove the temporary file
    rm temp_file.txt

    

    # Cut the first two fields (lev and =) and then convert the comma-separated values to an array
    ncks --trd -H -v lev ${SITE}_${MONTH}_${YEAR}.nc | awk 'BEGIN {FS="="} /lev/ {printf("%8.1f\n", $2)}' > temp_file.txt

    # Read the values from the temporary file into the array
    declare -a P_values=()
    while IFS= read -r value; do
        P_values+=("$value")
    done < temp_file.txt

    # Remove the temporary file
    rm temp_file.txt

    h_above=""
    h_below=""
    iterations=0
    skips=0
    for H_value in "${H_values[@]}"; do
        # Skip zero values
        if [ "$(echo "$H_value == 0" | bc -l)" -eq 1 ]; then
            skips=$((skips + 1))
            continue
        fi

        iterations=$((iterations + 1))

        if awk -v h="$H_value" -v site_alt="$SITE_ALT" 'BEGIN { exit !(h <= site_alt) }'; then
            h_below="$H_value"
        else
            h_above="$H_value"
            break
        fi
        
    done
    iterations=$((iterations - 1))
    stop_index=$((iterations + skips))

    H_above+=("$h_above")
    P_above+=("${P_values[$stop_index]}")
    if [ "$(echo "$h_below == 0" | bc -l)" -eq 1 ]; then
        H_below+=(0)
        SLP=$(ncks -s '%f\n' -H -C -v SLP ${SITE}_${MONTH}_${YEAR}.nc | head -n 1)
        P_below+=($(echo "scale=2; $SLP / 100" | bc))
        echo "Warning: No edge heights found below site altitude. Sea-level pressures will be used for interpolation in the vertical dimension. The results will be less reliable."
    else
        H_below+=("$h_below")
        P_below+=("${P_values[$((stop_index - 1))]}")
    fi

done


rm {8,9,10,11}.nc

# Interpolate in vertical dimension
# Function for linear interpolation
function linear_interpolate() {
    local x1=$1
    local y1=$2
    local x2=$3
    local y2=$4
    local x=$5

    local slope=$(bc <<< "scale=10; ($y2 - $y1) / ($x2 - $x1)")
    local intercept=$(bc <<< "scale=10; $y1 - $slope * $x1")
    local result=$(bc <<< "scale=10; $slope * $x + $intercept")

    echo $result
}

# Initialize P_alt array
declare -a P_alt=()

# Loop for each i
for ((i=0; i<4; i++)); do
    h_above=${H_above[i]}
    p_above=${P_above[i]}
    h_below=${H_below[i]}
    p_below=${P_below[i]}

    # Linearly interpolate to get P_alt at SITE_ALT
    if (( $(echo "$h_above >= $SITE_ALT" | bc -l) && $(echo "$h_below <= $SITE_ALT" | bc -l) )); then
        P_alt_i=$(linear_interpolate "$h_above" "$p_above" "$h_below" "$p_below" "$SITE_ALT")
        P_alt+=("$P_alt_i")
        #echo "For i=$i, P_alt at SITE_ALT ($SITE_ALT) is: $P_alt_i"
    else
        P_alt+=("NA")  # Not applicable if SITE_ALT is outside the range
        #echo "For i=$i, SITE_ALT ($SITE_ALT) is outside the range of H_above and H_below values."
    fi
done

PS=$(bc <<< "scale=10; $W2 * ($W4 * ${P_alt[0]} + $W3 * ${P_alt[2]}) + $W1 * ($W4 * ${P_alt[1]} + $W3 * ${P_alt[3]})")


# Compute means
ncap2 -O -S $SCRIPTS_DIR/T_avgs.nco ${SITE}_${MONTH}_${YEAR}.nc ${SITE}_${MONTH}_${YEAR}.nc
ncap2 -O -S $SCRIPTS_DIR/RH_avgs.nco ${SITE}_${MONTH}_${YEAR}.nc ${SITE}_${MONTH}_${YEAR}.nc
ncap2 -O -S $SCRIPTS_DIR/QL_avgs.nco ${SITE}_${MONTH}_${YEAR}.nc ${SITE}_${MONTH}_${YEAR}.nc
ncap2 -O -S $SCRIPTS_DIR/QI_avgs.nco ${SITE}_${MONTH}_${YEAR}.nc ${SITE}_${MONTH}_${YEAR}.nc
ncap2 -O -S $SCRIPTS_DIR/O3_avgs.nco ${SITE}_${MONTH}_${YEAR}.nc ${SITE}_${MONTH}_${YEAR}.nc
ncap2 -O -S $SCRIPTS_DIR/U_avgs.nco ${SITE}_${MONTH}_${YEAR}.nc ${SITE}_${MONTH}_${YEAR}.nc
ncap2 -O -S $SCRIPTS_DIR/V_avgs.nco ${SITE}_${MONTH}_${YEAR}.nc ${SITE}_${MONTH}_${YEAR}.nc

# Extract pressure levels into a single-column file

# As of version 4.6.8, ncks needs the new --trd switch to keep the
# traditional line-by-line format.  Otherwise the new default output
# format is CDL.
ncks --trd -H -v lev ${SITE}_${MONTH}_${YEAR}.nc |
awk 'BEGIN {FS="="} /lev/ {printf("%8.1f\n", $2)}' > lev.col

# Extract corresponding profiles vs. pressure into single-column files,
# converting mass mixing ratios to volume mixing ratios in parts per million.

ncks --trd -H -v T_avg ${SITE}_${MONTH}_${YEAR}.nc |
awk 'BEGIN {FS="="} /T_/ {printf("%8.3f\n", $3 < 1000. ? $3 : 999.999)}' > T_avg.col
ncks --trd -H -v RH_avg ${SITE}_${MONTH}_${YEAR}.nc |
awk 'BEGIN {FS="="} /RH_/ {printf("%8.1f\n", $3)}' > h2o_vpr_avg.col
ncks --trd -H -v QL_avg ${SITE}_${MONTH}_${YEAR}.nc |
awk 'BEGIN {FS="="} /QL_/ {printf("%12.4e\n", $3 < 1e10 ? 1e6 * (28.964 / 18.015) * $3 / (1.0 - $3) : 9.9999e99)}' > lqd_h20_vmr_avg.col
ncks --trd -H -v QI_avg ${SITE}_${MONTH}_${YEAR}.nc |
awk 'BEGIN {FS="="} /QI_/ {printf("%12.4e\n", $3 < 1e10 ? 1e6 * (28.964 / 18.015) * $3 / (1.0 - $3) : 9.9999e99)}' > ice_h2o_vmr_avg.col
ncks --trd -H -v O3_avg ${SITE}_${MONTH}_${YEAR}.nc |
awk 'BEGIN {FS="="} /O3_/ {printf("%12.4e\n", $3 < 1e10 ? 1e6 * (28.964 / 47.997) * $3 : 9.9999e99)}' > o3_vmr_avg.col
ncks --trd -H -v U_avg ${SITE}_${MONTH}_${YEAR}.nc |
awk 'BEGIN {FS="="} /U_/ {printf("%8.3f\n", $3 < 1000. ? $3 : 999.999)}' > U_avg.col
ncks --trd -H -v V_avg ${SITE}_${MONTH}_${YEAR}.nc |
awk 'BEGIN {FS="="} /V_/ {printf("%8.3f\n", $3 < 1000. ? $3 : 999.999)}' > V_avg.col

rm -f ${SITE}_${MONTH}_${YEAR}.nc

# Paste all the columns together into a single file under a header line.
echo "#  P[mb]  T_avg[K] H2O_vpr_avg[1] lqd_H2O_avg[ppm] ice_H2O_avg[ppm] O3_avg[ppm] U_avg[m/s] V_avg[m/s]" \
    > ${OUTDIR_PROFILES}/${SITE}_${MONTH}_${YEAR}_MERRA_means.txt


paste -d "\0" lev.col \
    T_avg.col \
    h2o_vpr_avg.col \
    lqd_h20_vmr_avg.col \
    ice_h2o_vmr_avg.col \
    o3_vmr_avg.col \
    U_avg.col \
    V_avg.col \
    >> ${OUTDIR_PROFILES}/${SITE}_${MONTH}_${YEAR}_MERRA_means.txt

rm *.col

echo "PSURF_${MONTH}_${YEAR}=$PS" >> "$PSURF_FILE"

# Remove rows with illogical temperature values
$SCRIPTS_DIR/./filter_rows.sh ${OUTDIR_PROFILES}/${SITE}_${MONTH}_${YEAR}_MERRA_means.txt

awk -f $SCRIPTS_DIR/extrapolate_to_surface.awk Ptrunc=$PTRUNC Ps=$PS ${OUTDIR_PROFILES}/${SITE}_${MONTH}_${YEAR}_MERRA_means.txt > ${OUTDIR_PROFILES}/${SITE}_${MONTH}_${YEAR}_MERRA_means_ex.txt

done
done