import os
import sys
import re
import csv
import numpy as np
from glob import glob

# cd to directory containing MERRA-am simulations outputs as organised by "cleanup.py" 
os.chdir(f"{sys.argv[1]}")


# Make directory for weather data if it does not already exist
if not os.path.exists(f"{sys.argv[1]}/weather_data"):
    os.makedirs(f"{sys.argv[1]}/weather_data")
    print(f"Directory '{sys.argv[1]}/weather_data' created successfully.")
else:
    print(f"Directory '{sys.argv[1]}/weather_data' already exists.")


# Define some variables and functions we'll need
years = []
for year in range(2009, 2023):
    years.append(str(year))
    
freqs = [86, 230, 345]

months = ["01Jan", "02Feb", "03Mar", "04Apr", "05May", "06Jun", "07Jul", "08Aug", "09Sep", "10Oct", "11Nov", "12Dec"]

def magnitude(u, v):
    return np.sqrt(u**2 + v**2)


# Read quantities of interest from each month's directory and use data to populate a csv file for each month 
for month in months:
    data = [
        ["Year", "PWV(mm)", "tau_86GHz", "tau_230GHz", "tau_345GHz", "Windspeed(m/s)"]
    ]
    
    
    # Get PWVs
    os.chdir(f"{month}/am_models")
    err_files = glob("*.err")
    err_files.sort()
    pwvs = []
    for err_file in err_files:
        # Open file and read contents into a list of lines
        with open(err_file, 'r') as f:
            lines = f.readlines()

        # Initialize variables
        am_version_found = False

        # Loop through the lines
        for line in lines:
            # Skip lines between "# am version" and "# total"
            if re.match(r'^# am version', line):
                am_version_found = True
            elif re.match(r'^# total', line):
                am_version_found = False
            elif am_version_found:
                continue
                
            # Extract pwv value from line containing "um_pwv"
            if "um_pwv" in line:
                pwv = float(re.findall(r'\d*\.?\d+', line)[0])
                break
        
        # Append pwv value in mm to list
        pwvs.append(pwv * 1e-3)
    
    
    # Get zenith spectral opacities
    opacities = [[] for _ in range(3)]
    out_files = glob("*.out")
    out_files.sort()
    for out_file in out_files:
        
        # Open file and read contents into a list of lines
        with open(out_file, 'r') as f:
            lines = f.readlines()

        # Initialize variables
        am_version_found = False

        # Loop through the lines
        for line in lines:
            # Extract the first field from the line
            fields = line.strip().split()
            first_field = float(fields[0])
            
            # Compare the first field to the desired frequency values and extract the second field if the first one is equal to any of the desired frequency values
            for n, freq in enumerate(freqs):
                if first_field == freq:
                    # Extract the second field from the line
                    opacities[n].append(float(fields[1]))
                    break
    
    os.chdir("../profile_stats")
    
    
    # Get windspeed components
    med_files = glob("*_ex.txt")
    med_files.sort()
    windspeeds = []
    for med_file in med_files:
        with open(med_file, 'r') as file:
            # Read the lines from the file
            lines = file.readlines()

            # Extract quantities from the second row
            second_row = lines[1].split()
            u = float(second_row[-2])
            v = float(second_row[-1])
            
            # Append windspeed magnitude to list
            windspeeds.append(magnitude(u, v))
    
    
    # Join all lists        
    for m, year in enumerate(years):
        row = [year, pwvs[m], opacities[0][m], opacities[1][m], opacities[2][m], windspeeds[m]]
        data.append(row)
        
    
    # Write data to csv file
    os.chdir(f"{sys.argv[1]}/weather_data")
    file_name = f"{month}.csv"
    with open(file_name, 'w', newline='') as csvfile:
        csvwriter = csv.writer(csvfile)

        # Write the data to the CSV file
        csvwriter.writerows(data)

    print(f'CSV file "{file_name}" has been created and populated successfully.')