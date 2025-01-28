# SA-EHT Site Characterisation

Code for estimating millimetre site quality indicators such as precipitable water vapour, zenith optical depth, zenith brightness temperature and wind speed. 
This code uses [MERRA-2 data](https://disc.gsfc.nasa.gov/datasets/M2I3NPASM_5.12.4/summary) and the [_am_ atmospheric model](https://zenodo.org/records/13748403)
software to estimate these indicators. The procedure followed is described in [this letter](https://arxiv.org/abs/2409.08003). 

Many of the scripts are modified versions of scripts from Scott Paine's "ex4_MaunaKea_radio_climatology" folder, which used to be available along
with `am` user manual, but I can no longer find it.

## Installation

"Install" the code by running
```bash
git clone https://github.com/senkhxsi/SA-EHT_site_characterisation.git
```

## Requirements

To run these scripts, one must have the netCDF Operators (NCO) installed. Instructions for installation can be found [here](https://nco.sourceforge.net/#bld).
Additionally, one must ensure that they have an installation of `awk`, which is typically available by default on Unix systems. If not, it can be easily installed
via the relevant package manager, e.g. `apt` or `brew`. Finally, in a Python 3 virtual environment, one can install the required Python packages by navigating to the cloned
repository using
```bash
cd path/to/cloned/repo
```
and then running 
```bash
pip install -r requirements.txt
```


## Usage

To run the scripts with minimal editing, one should:
1. Create a directory for the site
2. Place in the directory from the first step a MERRA-2 data subset and a copy of the `/scripts/example_run.sh` script
3. Configure their `am` simulations by editing the copy of `scripts/example_run.sh` in the site directory. This entails simply changing the variables initialised in all the lines beginning with `export`
4. Run the copy of `scripts/example_run.sh` in the site directory.

