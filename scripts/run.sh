# Master script to compute profile statistics, generate am models, and compute
# spectra.

# Site name, date range, and path to directory containing the  data files.
export SITE=ALMA
export SITE_LABEL='ALMA'
export SITE_ALT=5070
export DATERANGE=2009-2022
# export DATADIR=../${DATERANGE}
# random subset of data files to speed up demo/testing
export DATADIR=../${DATERANGE}_${SITE}_subset

# Site coordinates, and bracketing MERRA-2 grid coordinates
export SITE_LAT=-23.029
export SITE_LONG=-67.755

export MERRA_LAT0=-23.5
export MERRA_LAT1=-23.0
export MERRA_LONG0=-68.125
export MERRA_LONG1=-67.5

# The surface pressure at the MERRA-2 grid points may not match the nominal
# site surface pressure.  The following constants control truncation
# of the MERRA-2 profiles to some point above the surface (such that all
# levels have valid data), and interpolation or extrapolation to the
# nominal surface pressure.

# include levels above this pressure level:
export PTRUNC=900. # truncation point [mbar] of MERRA-2 profiles

# Plot ranges for profiles.  T in K, mixing ratios in ppm
export T_MIN=190
export T_MAX=310
export XH2O_MIN=1
export XH2O_MAX=30000
export XO3_MIN=0.01
export XO3_MAX=20

# Frequency range [GHz] for am models
export F_MIN=80.
export F_MAX=700.
# Frequency interval [MHz]
export DF=500.

# Compute profile statistics.
export OUTDIR_PROFILES=../profile_stats
if [ ! -d $OUTDIR_PROFILES ]; then
    mkdir $OUTDIR_PROFILES
fi
echo computing seasonal statistics ...
./profile_stats.sh

# Generate am model files and compute spectra.
export OUTDIR_AM=../am_models
if [ ! -d $OUTDIR_AM ]; then
    mkdir $OUTDIR_AM
fi
echo generating am model files ...
./make_am_models.sh
echo computing am models ...
./run_am_models.sh

# Some housekeeping
rm -r $OUTDIR_AM/am_cache
python3 cleanup.py ..


echo done.