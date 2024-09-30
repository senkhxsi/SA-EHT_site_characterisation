"""Tabulates results of MERRA-am simulations and some quantities of interest from MERRA-2 files

Returns:
    csv files: For each month, a csv file containing PWVs and zenith spectral opacities. Additionally, a single csv file containing daily windspeed
    averages for every day in the date range of interest. 
"""

import os
import sys
import re
import csv
from glob import glob
import numpy as np
import pandas as pd
import xarray as xr

# Get directory in which data is stored
data_dir = f'{sys.argv[2]}'

# cd to directory containing MERRA-am simulations outputs as organised by 'cleanup.py' 
os.chdir(f'{sys.argv[1]}')


# Make directory for weather data if it does not already exist
if not os.path.exists(f'{sys.argv[1]}/weather_data'):
    os.makedirs(f'{sys.argv[1]}/weather_data')
    print(f'Directory "{sys.argv[1]}/weather_data" created successfully.')
else:
    print(f'Directory "{sys.argv[1]}/weather_data" already exists.')


# Define some variables and functions we'll need
years = []
for year in range(2009, 2023):
    years.append(str(year))
    
freqs = [86, 230, 345]

months = ['01Jan', '02Feb', '03Mar', '04Apr', '05May', '06Jun', '07Jul', '08Aug', '09Sep', '10Oct', '11Nov', '12Dec']

def magnitude(u, v):
    return np.sqrt(u**2 + v**2)

def merra2_file_sorting(file_name):
    return file_name.split('.')[4]


# Read quantities of interest from each month's directory and use data to populate a csv file for each month 
for month in months:
    data = [
        ['Year', 'PWV(mm)', 'tau_86GHz', 'tau_230GHz', 'tau_345GHz', 'T_b(K)_86GHz', 'T_b(K)_230GHz', 'T_b(K)_345GHz']
    ]
    
    
    # Get PWVs
    os.chdir(f'{month}/am_models')
    err_files = glob('*.err')
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
    out_files = glob('*.out')
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
                    # Extract last field
                    T_b[n].append(float(fields[-1]))
                    break
    
    
    # Join all lists        
    for m, year in enumerate(years):
        row = [year, pwvs[m], opacities[0][m], opacities[1][m], opacities[2][m], T_b[0][m], T_b[1][m], T_b[2][m]]
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
    
    
# Now create separate csv files to store daily windspeed averages
   
# Use glob to get a list of NetCDF files in the directory
print('tabulating windspeeds ...')
merra2_files = glob(os.path.join(data_dir, '*.nc'))
merra2_files.sort(key=merra2_file_sorting)

# Initialize empty lists to store results
dates = [[] for _ in range(3)]
windspeed_avgs = []

# Loop through each file
for file in merra2_files:

    # Extract date information from the file name (assuming the format 'YYYYMMDD.SUB.nc')
    file_name = os.path.basename(file)
    # Assuming the format 'MERRA2_400.inst3_3d_asm_Np.20220415.SUB.nc', get the date part
    date = file_name.split('.')[2]
    dates[0].append(int(date[:4]))
    dates[1].append(int(date[4:6]))
    dates[2].append(int(date[6:8]))

    # Open the NetCDF file using xarray
    ds = xr.open_dataset(file, engine='netcdf4')

    # Calculate the averages of 'U' and 'V' variables
    u_avg = ds['U'].mean().values.item()
    v_avg = ds['V'].mean().values.item()
    windspeed = magnitude(u_avg, v_avg)

    # Append the results to the lists
    windspeed_avgs.append(windspeed)

    # Close the dataset to free up resources
    ds.close()

# Create a DataFrame to store the results
df = pd.DataFrame({'Year': dates[0], 'Month': dates[1], 'Day': dates[2], 'Windspeed[m/s]': windspeed_avgs})

# Save the DataFrame to a CSV file
csv_file_path = f'{sys.argv[1]}/weather_data/mean_windspeed.csv'
df.to_csv(csv_file_path, index=False)

print(f'Windspeeds have been saved to {csv_file_path}')