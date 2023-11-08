# Master script to compute profile statistics, generate am models, and compute
# spectra.

# Site name, date range, and path to directory containing the  data files.
export SITE=BMAC
export SITE_LABEL='BMAC'
export SITE_ALT=3000
export DATERANGE=2009-2022
export SITE_DIR=~/ngeht_site_characterisation/${SITE}
export DATADIR=${SITE_DIR}/${SITE}_${DATERANGE}_subset

# Site coordinates, and bracketing MERRA-2 grid coordinates
export SITE_LAT=-30.648081
export SITE_LONG=27.935199

export MERRA_LAT0=-31
export MERRA_LAT1=-30.5
export MERRA_LONG0=27.5
export MERRA_LONG1=28.125

# The surface pressure at the MERRA-2 grid points may not match the nominal
# site surface pressure.  The following constants control truncation
# of the MERRA-2 profiles to some point above the surface (such that all
# levels have valid data), and interpolation or extrapolation to the
# nominal surface pressure.

# include levels above this pressure level:
export PTRUNC=900. # truncation point [mbar] of MERRA-2 profiles

# Frequency range [GHz] for am models
export F_MIN=80.
export F_MAX=400.
# Frequency interval [MHz]
export DF=500.

# Compute profile statistics.
export OUTDIR_PROFILES=${SITE_DIR}/run_3/profile_stats
if [ ! -d $OUTDIR_PROFILES ]; then
    mkdir $OUTDIR_PROFILES
fi
echo computing seasonal statistics ...
~/ngeht_site_characterisation/scripts/./profile_stats.sh

# Generate am model files and compute spectra.
export OUTDIR_AM=${SITE_DIR}/run_3/am_models
if [ ! -d $OUTDIR_AM ]; then
    mkdir $OUTDIR_AM
fi
echo generating am model files ...
~/ngeht_site_characterisation/scripts/./make_am_models.sh
echo computing am models ...
~/ngeht_site_characterisation/scripts/./run_am_models.sh

# Some housekeeping
rm -r $OUTDIR_AM/am_cache
echo cleaning up...
python3 ~/ngeht_site_characterisation/scripts/cleanup.py ${SITE_DIR}/run_3
source ~/venvs/viper_env/bin/activate
python3 ~/ngeht_site_characterisation/scripts/tabulate.py ${SITE_DIR}/run_3 ${DATADIR}
deactivate

echo done.
