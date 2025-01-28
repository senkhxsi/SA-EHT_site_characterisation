import os
import sys
from glob import glob

os.chdir(f"{sys.argv[1]}")

seasons = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]


# Create new season names to include numbers which can be used to name folders similarly to how they are named in ngehtsim weather data
seasons2 = []
for i in range(1, 13):
    if i<10:
        tmp = f"0{i}"+seasons[i-1]
    else:
        tmp = f"{i}"+seasons[i-1]
    
    seasons2.append(tmp)
    os.makedirs(f"{seasons2[i-1]}/am_models", exist_ok=True)
    os.mkdir(f"{seasons2[i-1]}/profile_stats")


# Move files from "am_models" and "profile_stats" into their respective months' directories
output_dirs = ["am_models", "profile_stats"]
for directory in output_dirs:
    os.chdir(f"{directory}")
    for i in range(len(seasons)):
        tmp_list = glob(f"*{seasons[i]}*")
        for t in tmp_list:
            os.system(f"mv {t} ../{seasons2[i]}/{directory}")
    os.chdir("..")
    os.rmdir(f"{directory}")