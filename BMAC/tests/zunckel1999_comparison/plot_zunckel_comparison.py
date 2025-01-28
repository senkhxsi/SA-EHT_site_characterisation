import os
import sys
import pandas as pd
import matplotlib.pyplot as plt


months = ["march", "june"]

dates = [[i+0.5 for i in range(8, 23)], [i+0.5 for i in range(8, 25)]]

for m, month in enumerate(months):
    # Read our data into lists
    # Open the file in read mode
    with open(f'./{month}_data/surface_pressure_diffs.txt', 'r') as file:
        # Read the lines from the file
        lines = file.readlines()

    # Convert the lines to a list of floats
    psurf_diffs = [float(line.strip()) for line in lines]
    
    # Read Zunckel data into lists
    # Read the CSV file into a DataFrame
    df = pd.read_csv(f"./zunckel1999_{month}.csv", header=None, names=['dates', 'psurf_diffs'])

    # Extract columns into lists
    zunckel_dates = df['dates'].tolist()
    zunckel_psurf_diffs = df['psurf_diffs'].tolist()


    # Plot comparisons
    plt.scatter(zunckel_dates, zunckel_psurf_diffs, label="In situ measurements")
    plt.scatter(dates[m], psurf_diffs, label = "MERRA-2-derived prediction")
    plt.axhline(y=0, color='black', linestyle='--')
    plt.ylim(-150, 150)
    if month == "march":
        plt.xlabel("March")
    else:
        plt.xlabel("June")
    plt.ylabel("Pressure difference (hPa)")
    plt.legend(fontsize=8)
    plt.savefig(f"./zunckel_{month}_comparison.png", dpi = 200)
    plt.close()
