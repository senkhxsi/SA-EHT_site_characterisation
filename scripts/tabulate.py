"""Tabulates results of MERRA-am simulations and some quantities of interest from MERRA-2 files

Returns:
    csv files: For each month, a csv file containing PWVs, zenith spectral opacities, brightness temperatures and wind speeds.
"""

import os
import sys
import re
import csv
from glob import glob
import numpy as np
import pandas as pd


# cd to directory containing MERRA-am simulations outputs as organised by 'cleanup.py' 
os.chdir(f'{sys.argv[1]}')

site_label = sys.argv[2]


# Make directory for weather data if it does not already exist
if not os.path.exists(f'{sys.argv[1]}/weather_data'):
    os.makedirs(f'{sys.argv[1]}/weather_data')
    print(f'Directory "{sys.argv[1]}/weather_data" created successfully.')
else:
    print(f'Directory "{sys.argv[1]}/weather_data" already exists.')


# Define some variables and functions we'll need
years = [str(year) for year in range(2009, 2023)]
    
freqs = [86, 230, 345]

months = ['01Jan', '02Feb', '03Mar', '04Apr', '05May', '06Jun', '07Jul', '08Aug', '09Sep', '10Oct', '11Nov', '12Dec']


# Read quantities of interest from each month's directory and use data to populate a csv file for each month 
for month in months:
    data = [
        ['Year', 'PWV(mm)', 'tau_86GHz', 'tau_230GHz', 'tau_345GHz', 'T_b(K)_86GHz', 'T_b(K)_230GHz', 'T_b(K)_345GHz', 'Wind_speed(m/s)']
    ]
    
    
    # Get PWVs
    os.chdir(f'{month}/am_models')
    err_files = sorted(glob('*.err'))
    pwvs = []
    
    for err_file in err_files:
        # Open file and read contents into a list of lines
        with open(err_file, 'r') as f:
            lines = f.readlines()

        # Initialize variables
        am_version_found = False

        # Loop through the lines
        for line in lines:
            # Skip lines between '# am version' and '# total'
            if re.match(r'^# am version', line):
                am_version_found = True
            elif re.match(r'^# total', line):
                am_version_found = False
            elif am_version_found:
                continue
                
            # Extract pwv value from line containing 'um_pwv'
            if 'um_pwv' in line:
                pwv = float(re.findall(r'\d*\.?\d+', line)[0])
                break
        
        # Append pwv value in mm to list
        pwvs.append(pwv * 1e-3)
    
    
    # Get zenith spectral opacities
    opacities = [[] for _ in range(3)]
    T_b = [[] for _ in range(3)]
    out_files = sorted(glob('*.out'))
    
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
                    # Extract last field
                    T_b[n].append(float(fields[-1]))
                    break
    
    # Get wind speeds
    os.chdir(f'../profile_stats')
    interp_wind_speeds = []
    
    for year in years:
        # get surface pressure
        with open(f'{site_label}_{month[2:]}_{year}_MERRA_means_ex.txt', 'r') as file:
            file.readline()  # Read and discard the header line

            # Now read the first line of actual data
            first_line = file.readline().strip()  # Read the first data line and remove extra whitespace

            # get pressure as first value in first row of data
            Ps = float(first_line.split()[0])
            
        # create lists to store pressure and windspeed columns
        pressures = []
        wind_speeds = []
        
        # get pressures and wind speeds
        with open(f'{site_label}_{month[2:]}_{year}_MERRA_means.txt', 'r') as file:
            # Iterate over each line in the file
            for line in file:
                # Skip comment lines or empty lines
                if line.startswith('#') or not line.strip():
                    continue
                
                # Split the line into columns
                columns = line.split()
                
                # Append the first and last columns to the respective lists
                pressures.append(float(columns[0]))  # First column (pressure)
                wind_speeds.append(float(columns[-1]))   # Last column (wind speed)
        
        # reverse order in order to use np.interp()
        pressures.reverse()
        wind_speeds.reverse()
        
        # calculate wind speed using linear interpolation
        interp_wind_speed = np.interp(Ps, pressures, wind_speeds)
        
        # Append wind speed to list
        interp_wind_speeds.append(interp_wind_speed)
    
    
    # Join all lists        
    for m, year in enumerate(years):
        row = [year, pwvs[m], opacities[0][m], opacities[1][m], opacities[2][m], T_b[0][m], T_b[1][m], T_b[2][m], interp_wind_speeds[m]]
        data.append(row)
        
    # Write data to csv file
    os.chdir(f'{sys.argv[1]}/weather_data')
    file_name = f'{month}.csv'
    with open(file_name, 'w', newline='') as csvfile:
        csvwriter = csv.writer(csvfile)

        # Write the data to the CSV file
        csvwriter.writerows(data)

    print(f'CSV file "{file_name}" has been created and populated successfully.')
    os.chdir(f'{sys.argv[1]}')
    
    
print('All CSV files have been created and populated successfully.')