# Site name, date range, and path to directory containing the  data files.
SITE=BMAC
SITE_ALT=2870

#export DATADIR=../../${DATERANGE}_rnd_subset/MERRA2_400.inst3_3d_asm_Np.20220415.SUB.nc

# Site coordinates, and bracketing MERRA-2 grid coordinates
SITE_LAT=-30.533333
SITE_LONG=27.966667

MERRA_LAT0=-31
MERRA_LAT1=-30.5
MERRA_LONG0=27.5
MERRA_LONG1=28.125


# List of directories
directories=(
    "../march_data"
    "../june_data"
)

# Loop through each directory
for directory in "${directories[@]}"; do
    echo "Processing files in directory: $directory"

    if [ -e "$directory/surface_pressure_diffs.txt" ]; then
        rm "$directory/surface_pressure_diffs.txt"
        echo "Deleted existing $directory/surface_pressure_diffs.txt"
    fi
    
    # List files, sort them alphabetically, and then loop through
    for file in $(ls "$directory"/*.nc | sort); do
        # Perform your desired process for each file
        echo "Processing file: $file"

        # split into one file for each neighboring MERRA grid point
        ncks -O -d lon,0 -d lat,0 -d time,0 -d time,1 -d time,6 -d time,7 $file 1.nc
        ncks -O -d lon,1 -d lat,0 -d time,0 -d time,1 -d time,6 -d time,7 $file 2.nc
        ncks -O -d lon,0 -d lat,1 -d time,0 -d time,1 -d time,6 -d time,7 $file 3.nc
        ncks -O -d lon,1 -d lat,1 -d time,0 -d time,1 -d time,6 -d time,7 $file 4.nc

        # Get edge height averages for surface pressure estimation
        ncap2 -O -S H_avgs.nco 1.nc 5.nc
        ncap2 -O -S H_avgs.nco 2.nc 6.nc
        ncap2 -O -S H_avgs.nco 3.nc 7.nc
        ncap2 -O -S H_avgs.nco 4.nc 8.nc

        # Estimate surface pressure
        # Arrays to store results
        # Reset arrays at the beginning of each directory
        declare -a H_above=()
        declare -a H_below=()
        declare -a P_above=()
        declare -a P_below=()

        # Loop through each gridpoint's file
        for gridpoint in {5..8}.nc; do
            #echo "Processing $file..."
            
            # Read H_avg into file, "unphysical" values to zero
            ncks --trd -H -v H_avg "$gridpoint" | awk 'BEGIN {FS="="} /H_/ {print ($3 < 100000. ? $3 : 0)}' > temp_file.txt
            # Read the values from the temporary file into an array
            declare -a H_values=()
            while IFS= read -r value; do
                H_values+=("$value")
            done < temp_file.txt
            # Remove the temporary file
            rm temp_file.txt

            # Read pressure levels into file
            ncks --trd -H -v lev "$gridpoint" | awk 'BEGIN {FS="="} /lev/ {printf("%8.1f\n", $2)}' > temp_file.txt
            # Read the values from the temporary file into an array
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
                # Skip 0 values
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
                SLP=$(ncks -s '%f\n' -H -C -v SLP 15_APRIL_2022_interpolated.nc | head -n 1)
                P_below+=($(echo "scale=2; $SLP / 100" | bc))
                echo "Warning: No edge heights found below site altitude. Sea-level pressures will be used for interpolation in the vertical dimension. The results will be less reliable."
            else
                H_below+=("$h_below")
                P_below+=("${P_values[$((stop_index - 1))]}")
            fi

            #echo "h_above: $h_above"
            #echo "h_below: $h_below"
            #echo "interations: $iterations"
            #echo "index: $stop_index"
        done

        rm [1-8].nc

        #echo "H_above: ${H_above[@]}"
        #echo "H_below: ${H_below[@]}"
        #echo "P_above: ${P_above[@]}"
        #echo "P_below: ${P_below[@]}"

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

        #echo "P_alt array: ${P_alt[@]}"


        # Interpolate to the site position (ncflint segfaults with -i option, so
        # give explicit weights with -w.) Start by computing the weighting factors.
        W1=$(awk -v x=$SITE_LONG -v x0=$MERRA_LONG0 -v x1=$MERRA_LONG1 'BEGIN {print (x1 - x) / (x1 - x0)}')
        W2=$(awk -v w1=$W1 'BEGIN {print 1.0 - w1}')
        W3=$(awk -v y=$SITE_LAT -v y0=$MERRA_LAT0 -v y1=$MERRA_LAT1 'BEGIN {print (y1 - y) / (y1 - y0)}')
        W4=$(awk -v w3=$W3 'BEGIN {print 1.0 - w3}')

        PS=$(bc <<< "scale=10; $W2 * ($W4 * ${P_alt[0]} + $W3 * ${P_alt[2]}) + $W1 * ($W4 * ${P_alt[1]} + $W3 * ${P_alt[3]})")
        
        # Calculate the value $PS-700 and save it in a text file in the parent directory
        P_diff=$(echo "$PS-700" | bc)
        echo "PS: $PS, P_diff: $P_diff"
        echo "$P_diff" >> "$directory/surface_pressure_diffs.txt"
    done
done

# Plot results
source ~/venvs/viper_env/bin/activate
python3 plot_zunckel_comparison.py
deactivate

echo done.