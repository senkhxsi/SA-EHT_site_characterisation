# This script computes percentile profile statistics for a given site by
# first horizontally interpolating a set of MERRA-2 NetCDF files to the
# site longitude and latitude, then using a set of nco scripts to compute
# the average profiles for temperature, water vapor, ozone.
#!/bin/bash


#if [ -f "psurf_values.txt" ]; then
#    echo ""psurf_values.txt" exists. Deleting..."
#    rm "psurf_values.txt"
#    echo "File deleted."
#else
#    echo "File does not exist."
#fi

#PSURF_FILE="psurf_values.txt"


#for YEAR in {2009..2019}; do
#for SEASON in Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec; do

#echo $SITE $SEASON $YEAR $DATADIR

# Find data files by season, and concatenate
#case $SEASON in
#Jan)
#    find $DATADIR  \( -name *Np.${YEAR}01* \) -print  | sort -t '.' -k 5 | ncrcat -3 -h -O -o 0.nc
#    ;;
#Feb)
#    find $DATADIR  \( -name *Np.${YEAR}02* \) -print  | sort -t '.' -k 5 | ncrcat -3 -h -O -o 0.nc
#    ;;
#Mar)
#    find $DATADIR  \( -name *Np.${YEAR}03* \) -print  | sort -t '.' -k 5 | ncrcat -3 -h -O -o 0.nc
#    ;;
#Apr)
#    find $DATADIR  \( -name *Np.${YEAR}04* \) -print  | sort -t '.' -k 5 | ncrcat -3 -h -O -o 0.nc
#    ;;
#May)
#    find $DATADIR  \( -name *Np.${YEAR}05* \) -print  | sort -t '.' -k 5 | ncrcat -3 -h -O -o 0.nc
#    ;;
#Jun)
#    find $DATADIR  \( -name *Np.${YEAR}06* \) -print  | sort -t '.' -k 5 | ncrcat -3 -h -O -o 0.nc
#    ;;
#Jul)
#    find $DATADIR  \( -name *Np.${YEAR}07* \) -print  | sort -t '.' -k 5 | ncrcat -3 -h -O -o 0.nc
#    ;;
#Aug)
#    find $DATADIR  \( -name *Np.${YEAR}08* \) -print  | sort -t '.' -k 5 | ncrcat -3 -h -O -o 0.nc
#    ;;
#Sep)
#    find $DATADIR  \( -name *Np.${YEAR}09* \) -print  | sort -t '.' -k 5 | ncrcat -3 -h -O -o 0.nc
#    ;;
#Oct)
#    find $DATADIR  \( -name *Np.${YEAR}10* \) -print  | sort -t '.' -k 5 | ncrcat -3 -h -O -o 0.nc
#    ;;
#Nov)
#    find $DATADIR  \( -name *Np.${YEAR}11* \) -print  | sort -t '.' -k 5 | ncrcat -3 -h -O -o 0.nc
#    ;;
#Dec)
#    find $DATADIR  \( -name *Np.${YEAR}12* \) -print  | sort -t '.' -k 5 | ncrcat -3 -h -O -o 0.nc
#    ;;
#esac


#split first time step into separate file
if [ ! -f "0UT_BMAC_MERRA2_400.inst3_3d_asm_Np.20220415.nc" ]; then
    ncks -d time,0 "MERRA2_400.inst3_3d_asm_Np.20220415.nc" 0UT_BMAC_MERRA2_400.inst3_3d_asm_Np.20220415.nc
fi


# split into separate file for each neighboring MERRA grid point
ncks -O -d lon,332 -d lat,118 "0UT_BMAC_MERRA2_400.inst3_3d_asm_Np.20220415.nc" 1.nc
ncks -O -d lon,333 -d lat,118 "0UT_BMAC_MERRA2_400.inst3_3d_asm_Np.20220415.nc" 2.nc
ncks -O -d lon,332 -d lat,119 "0UT_BMAC_MERRA2_400.inst3_3d_asm_Np.20220415.nc" 3.nc
ncks -O -d lon,333 -d lat,119 "0UT_BMAC_MERRA2_400.inst3_3d_asm_Np.20220415.nc" 4.nc
#ncks -O -d lon,$MERRA_LONG0 -d lat,$MERRA_LAT0 "0UT_BMAC_MERRA2_400.inst3_3d_asm_Np.20220415.nc" 1.nc
#ncks -O -d lon,$MERRA_LONG1 -d lat,$MERRA_LAT0 "0UT_BMAC_MERRA2_400.inst3_3d_asm_Np.20220415.nc" 2.nc
#ncks -O -d lon,$MERRA_LONG0 -d lat,$MERRA_LAT1 "0UT_BMAC_MERRA2_400.inst3_3d_asm_Np.20220415.nc" 3.nc
#ncks -O -d lon,$MERRA_LONG1 -d lat,$MERRA_LAT1 "0UT_BMAC_MERRA2_400.inst3_3d_asm_Np.20220415.nc" 4.nc


# Arrays to store results
#H_above=()
#H_below=()
#P_above=()
#P_below=()

# Function to estimate pressure using simple logarithmic extrapolation
# Arguments:
#   $1 - height array (space-separated)
#   $2 - pressure array (space-separated)
#   $3 - target height for extrapolation
extrapolate_to_get_P_alt() {
    # Check if the number of elements in both arrays is the same
    if [ $# -lt 3 ] || [ $(wc -w <<< "$1") -ne $(wc -w <<< "$2") ]; then
        echo "Error: Heights and pressures must have the same number of elements."
        return 1
    fi

    # Arrays from arguments
    heights=($1)
    pressures=($2)
    
    # Target height for extrapolation
    target_height=$3

    # Check if there are at least two data points
    if [ ${#heights[@]} -lt 2 ]; then
        echo "Error: At least two data points are required for extrapolation."
        return 1
    fi

    # Calculate logarithmic constants k and b using the last two data points
    n=${#heights[@]}
    h1=${heights[$((n-2))]}
    h2=${heights[$((n-1))]}
    p1=${pressures[$((n-2))]}
    p2=${pressures[$((n-1))]}

    k=$(awk "BEGIN {print (log($p2) - log($p1)) / ($h2 - $h1)}")
    b=$(awk "BEGIN {print log($p1) - $k * $h1}")

    # Use the constants to estimate pressure at the target height
    estimated_pressure=$(awk "BEGIN {print exp($k * $target_height + $b)}")
    
    #echo "Estimated pressure at $target_height meters: $estimated_pressure"
    printf "%s " "$estimated_pressure"
}


declare -a P_alt

# Loop through each file
for file in {1..4}.nc; do
    #echo "Processing $file..."
    
    # Extract lines containing 'H ='
    H_values=($(ncdump -v H $file | awk '/H =/{p=1; next} p && /\}/{p=0} p' | sed -e 's/,//'))
    #echo "Initial H_values length: ${#H_values[@]}"
    # Extract the values of the 'lev' variable using ncdump, and remove extra characters
    #P_values=$(ncdump -v lev $file | awk '/lev =/{if(++count==2) print;}')

    # Cut the first two fields (lev and =) and then convert the comma-separated values to an array
    #IFS=', ' read -r -a P_values <<< "$(echo $P_values | cut -d' ' -f3-)"

    # Use ncks to get the values of H_med, then use AWK to process the output and write to a temporary file
    #ncks --trd -H -v H "$file" | awk 'BEGIN {FS="="} /H / {print ($3 < 100000. ? $3 : 0)}' > temp_file.txt
    #ncks -H -v H "$file" | awk -F, '/H / {gsub(/=/,""); print ($2 < 100000. ? $2 : 0)}' > temp_file.txt

    # Read the values from the temporary file into the array
    #declare -a H_values=()
    #while IFS= read -r value; do
    #    H_values+=("$value")
    #done < temp_file.txt

    # Remove the temporary file
    #rm temp_file.txt

    #echo ${H_values[@]}

    # Extract the values of the 'lev' variable using ncdump, and remove extra characters
    #P_values=$(ncdump -v lev $file | awk '/lev =/{if(++count==2) print;}')

    # Cut the first two fields (lev and =) and then convert the comma-separated values to an array
    #IFS=', ' read -r -a P_values <<< "$(echo $P_values | cut -d' ' -f3-)"
    ncks --trd -H -v lev "$file" | awk 'BEGIN {FS="="} /lev/ {printf("%8.1f\n", $2)}' > temp_file.txt

    # Read the values from the temporary file into the array
    declare -a P_values=()
    while IFS= read -r value; do
        P_values+=("$value")
    done < temp_file.txt

    #echo "P_values initial length: ${#P_values[@]}"
    # Remove the temporary file
    rm temp_file.txt

    empty_vals=0
    # Loop through the array
    for ((i=0; i<${#H_values[@]}; i++)); do
        # Check if the element starts with "_"
        if [[ "${H_values[i]}" == _* ]]; then
            # Remove the element from the array
            unset 'H_values[i]'
            unset 'P_values[i]'
            # Increment the counter
            ((empty_vals++))
        fi
    done
    unset 'H_values[42]'
    #echo "H_values new length: ${#H_values[@]}"
    #echo ${H_values[@]}
    #echo "New H_values array: ${H_values[@]}"
    #P_values=("${P_values[@]:$empty_vals}")
    #echo "P_values new length: ${#P_values[@]}"
    #echo ${P_values[@]}
    #h_above=""
    #h_below=""
    #iterations=0
    #skips=0

    #for H_value in "${H_values[@]}"; do
        # Skip values with "_"
        #if [ "$H_value" = "_" ]; then
        #    skips=$((skips + 1))
        #    continue
        #fi

        #iterations=$((iterations + 1))

        #if awk -v h="$H_value" -v site_alt="$SITE_ALT" 'BEGIN { exit !(h <= site_alt) }'; then
        #    h_below="$H_value"
        #else
        #    h_above="$H_value"
        #    break
        #fi
        
    #done
    #iterations=$((iterations - 1))
    #stop_index=$((iterations + skips))

    #H_above+=("$h_above")
    #P_above+=("${P_values[$stop_index]}")
    #if [ "$h_below" = "" ]; then
    #    H_below+=(0)
    #    SLP=$(ncks -s '%f\n' -H -C -v SLP 15_APRIL_2022_interpolated.nc | head -n 1)
    #    P_below+=($(echo "scale=2; $SLP / 100" | bc))
    #    echo "Warning: No edge heights found below site altitude. Sea-level pressures will be used for interpolation in the vertical dimension. The results will be less reliable."
    #else
    #    H_below+=("$h_below")
    #    P_below+=("${P_values[$((stop_index - 1))]}")
    #fi

    #echo "h_above: $h_above"
    #echo "h_below: $h_below"
    #echo "interations: $iterations"
    #echo "index: $stop_index"

    P_alt+=( $(extrapolate_to_get_P_alt "${H_values[*]}" "${P_values[*]}" "$SITE_ALT") )
done
#echo "H_above: ${H_above[@]}"
#echo "H_below: ${H_below[@]}"
#echo "P_above: ${P_above[@]}"
#echo "P_below: ${P_below[@]}"

# Interpolate in vertical dimension
# Function for linear interpolation
#function linear_interpolate() {
#    local x1=$1
#    local y1=$2
#    local x2=$3
#    local y2=$4
#    local x=$5

#    local slope=$(bc <<< "scale=10; ($y2 - $y1) / ($x2 - $x1)")
#    local intercept=$(bc <<< "scale=10; $y1 - $slope * $x1")
#    local result=$(bc <<< "scale=10; $slope * $x + $intercept")

#    echo $result
#}






# Initialize P_alt array
#declare -a P_alt

# Loop for each i
#for ((i=0; i<4; i++)); do
#    h_above=${H_above[i]}
#    p_above=${P_above[i]}
#    h_below=${H_below[i]}
#    p_below=${P_below[i]}

    # Linearly interpolate to get P_alt at SITE_ALT
#    if (( $(echo "$h_above >= $SITE_ALT" | bc -l) && $(echo "$h_below <= $SITE_ALT" | bc -l) )); then
#        P_alt_i=$(linear_interpolate "$h_above" "$p_above" "$h_below" "$p_below" "$SITE_ALT")
#        P_alt+=("$P_alt_i")
        #echo "For i=$i, P_alt at SITE_ALT ($SITE_ALT) is: $P_alt_i"
#    else
#        P_alt+=("NA")  # Not applicable if SITE_ALT is outside the range
        #echo "For i=$i, SITE_ALT ($SITE_ALT) is outside the range of H_above and H_below values."
#    fi
#done

echo "P_alt: ${P_alt[@]}"

# Interpolate to the site position (ncflint segfaults with -i option, so
# give explicit weights with -w.) Start by computing the weighting factors.
W1=$(awk -v x=$SITE_LONG -v x0=$MERRA_LONG0 -v x1=$MERRA_LONG1 'BEGIN {print (x1 - x) / (x1 - x0)}')
W2=$(awk -v w1=$W1 'BEGIN {print 1.0 - w1}')
W3=$(awk -v y=$SITE_LAT -v y0=$MERRA_LAT0 -v y1=$MERRA_LAT1 'BEGIN {print (y1 - y) / (y1 - y0)}')
W4=$(awk -v w3=$W3 'BEGIN {print 1.0 - w3}')

PS=$(bc <<< "scale=10; $W2 * ($W4 * ${P_alt[0]} + $W3 * ${P_alt[2]}) + $W1 * ($W4 * ${P_alt[1]} + $W3 * ${P_alt[3]})")
#echo "Bilinear interpolated PS value using explicit weights: $PS"

# Do the interpolation, then use ncap2 to set the lon and lat
# fields in the NetCDF file to the interpolated coordinates.
ncflint -O -w ${W1},${W2} 1.nc 2.nc 7.nc
ncap2 -O -s "lon={${SITE_LONG}}" 7.nc 5.nc
ncflint -O -w ${W1},${W2} 3.nc 4.nc 7.nc
ncap2 -O -s "lon={${SITE_LONG}}" 7.nc 6.nc
ncflint -O -w ${W3},${W4} 5.nc 6.nc 7.nc
ncap2 -O -s "lat={${SITE_LAT}}" 7.nc 15_APRIL_2022_interpolated.nc
rm [1-7].nc 

#PS=$(ncdump -v PS 15_APRIL_2022_interpolated.nc | awk '/PS =/ {p=1; next} p && /;/ {p=0} p {gsub(/,/, ""); print $1/100; exit}')
#SLP=$(ncdump -v SLP 15_APRIL_2022_interpolated.nc | awk '/SLP =/ {p=1; next} p && /;/ {p=0} p {gsub(/,/, ""); print $1/100; exit}')
#SLP=$(ncks -s '%f\n' -H -C -v SLP 15_APRIL_2022_interpolated.nc | head -n 1)
#SLP=$(echo "scale=2; $SLP / 100" | bc)
#echo "Sea-level pressure (mbar):" $SLP


# Extract instantaneous values (0 UT)
ncap2 -O -S T_inst.nco 15_APRIL_2022_interpolated.nc 15_APRIL_2022_interpolated.nc
ncap2 -O -S RH_inst.nco 15_APRIL_2022_interpolated.nc 15_APRIL_2022_interpolated.nc
ncap2 -O -S QL_inst.nco 15_APRIL_2022_interpolated.nc 15_APRIL_2022_interpolated.nc
ncap2 -O -S QI_inst.nco 15_APRIL_2022_interpolated.nc 15_APRIL_2022_interpolated.nc
ncap2 -O -S O3_inst.nco 15_APRIL_2022_interpolated.nc 15_APRIL_2022_interpolated.nc

# Extract pressure levels into a single-column file

# As of version 4.6.8, ncks needs the new --trd switch to keep the
# traditional line-by-line format.  Otherwise the new default output
# format is CDL.
ncks --trd -H -v lev 15_APRIL_2022_interpolated.nc |
awk 'BEGIN {FS="="} /lev/ {printf("%8.1f\n", $2)}' > lev.col
ncks --trd -H -v RH_inst 15_APRIL_2022_interpolated.nc |
awk 'BEGIN {FS="="} /RH_/ {printf("%8.1f\n", $3)}' > h2o_vpr_inst.col

# Extract corresponding profiles vs. pressure into single-column files,
# converting mass mixing ratios to volume mixing ratios in parts per million.

ncks --trd -H -v T_inst 15_APRIL_2022_interpolated.nc |
awk 'BEGIN {FS="="} /T_/ {printf("%8.3f\n", $3 < 1000. ? $3 : 999.999)}' > T_inst.col
ncks --trd -H -v QL_inst 15_APRIL_2022_interpolated.nc |
awk 'BEGIN {FS="="} /QL_/ {printf("%12.4e\n", $3 < 1e10 ? 1e6 * (28.964 / 18.015) * $3 / (1.0 - $3) : 9.9999e99)}' > lqd_h20_vmr_inst.col
ncks --trd -H -v QI_inst 15_APRIL_2022_interpolated.nc |
awk 'BEGIN {FS="="} /QI_/ {printf("%12.4e\n", $3 < 1e10 ? 1e6 * (28.964 / 18.015) * $3 / (1.0 - $3) : 9.9999e99)}' > ice_h2o_vmr_inst.col
ncks --trd -H -v O3_inst 15_APRIL_2022_interpolated.nc |
awk 'BEGIN {FS="="} /O3_/ {printf("%12.4e\n", $3 < 1e10 ? 1e6 * (28.964 / 47.997) * $3 : 9.9999e99)}' > o3_vmr_inst.col

#rm -f 15_APRIL_2022_interpolated.nc

# Paste all the columns together into a single file under a header line.
echo "#  P[mb]  T_inst[K] H2O_vpr_inst[1] lqd_H2O_inst[ppm] ice_H2O_inst[ppm] O3_inst[ppm]" \
    > ${OUTDIR_PROFILES}/15_APRIL_2022_MERRA_inst.txt


paste -d "\0" lev.col \
    T_inst.col \
    h2o_vpr_inst.col \
    lqd_h20_vmr_inst.col \
    ice_h2o_vmr_inst.col \
    o3_vmr_inst.col \
    >> ${OUTDIR_PROFILES}/15_APRIL_2022_MERRA_inst.txt

# Estimate surface-level pressures from atmospheric mean sea level pressures using simplified hypsometric equation

# Constants
#g=9.81      # acceleration due to gravity (m/s^2)
#M=0.0289644 # molar mass of air (kg/mol)
#R=8.31447   # Specific gas constant for air (in J/(mol·K))
#L=-0.0065   # Temperature lapse rate (K/m)

#T0=288.15   # Standard temperature at mean sea level (K)

# Estimate temperature at site 
#T1=$(echo "scale=3; $T0 + $L * $SITE_ALT" | bc -l)
#T=$(echo "scale=3; ($T0 + $T1) / 2" | bc -l)  # Average temperature

# Estimate surface pressure using hypsometric equation
#PS=$(echo "$SLP * e(-$g * $SITE_ALT * $M / ($R * $T))" | bc -l)
export PS
#echo "PSURF_${SEASON}_${YEAR}=$PS2" >> "$PSURF_FILE"
#echo "PSURF_${SEASON}_${YEAR}=$PS" >> "$PSURF_FILE"

# Remove rows with illogical temperature values
./filter_rows.sh ${OUTDIR_PROFILES}/15_APRIL_2022_MERRA_inst.txt

awk -f extrapolate_to_surface.awk Ptrunc=$PTRUNC Ps=$PS ${OUTDIR_PROFILES}/15_APRIL_2022_MERRA_inst.txt > ${OUTDIR_PROFILES}/15_APRIL_2022_MERRA_inst_ex.txt

#done
#done

rm -r lev.col \
    T_inst.col \
    h2o_vpr_inst.col \
    lqd_h20_vmr_inst.col \
    ice_h2o_vmr_inst.col \
    o3_vmr_inst.col \