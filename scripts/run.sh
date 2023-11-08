# Master script to compute profile statistics, generate am models, and compute
# spectra.

# Site name, date range, and path to directory containing the  data files.
export SITE=STL
export SITE_LABEL='STL'
export SITE_ALT=1800
export DATERANGE=2009-2022
export SITE_DIR=~/ngeht_site_characterisation/${SITE}
export DATADIR=${SITE_DIR}/${SITE}_${DATERANGE}_subset
export SCRIPTS_DIR=~/ngeht_site_characterisation/scripts
export VENV=~/venvs/viper_env

# Site coordinates, and bracketing MERRA-2 grid coordinates
export SITE_LAT=-32.376
export SITE_LONG=20.811

export MERRA_LAT0=-32.5
export MERRA_LAT1=-32.0
export MERRA_LONG0=20.625
export MERRA_LONG1=21.25

# The surface pressure at the MERRA-2 grid points may not match the nominal
# site surface pressure.  The following constants control truncation
# of the MERRA-2 profiles to some point above the surface (such that all
# levels have valid data), and interpolation or extrapolation to the
# nominal surface pressure.

# include levels above this pressure level:
export PTRUNC=900. # truncation point [mbar] of MERRA-2 profiles

# Frequency range [GHz] for am models
export F_MIN=80.
export F_MAX=700.
# Frequency interval [MHz]
export DF=500.

# Compute profile statistics.
export OUTDIR_PROFILES=${SITE_DIR}/profile_stats
if [ ! -d $OUTDIR_PROFILES ]; then
    mkdir $OUTDIR_PROFILES
fi
echo computing seasonal statistics ...
$SCRIPTS_DIR/./profile_stats.sh

# Generate am model files and compute spectra.
export OUTDIR_AM=${SITE_DIR}/am_models
if [ ! -d $OUTDIR_AM ]; then
    mkdir $OUTDIR_AM
fi
echo generating am model files ...
$SCRIPTS_DIR/./make_am_models.sh
echo computing am models ...
$SCRIPTS_DIR/./run_am_models.sh

# Some housekeeping
rm -r $OUTDIR_AM/am_cache
echo cleaning up ...
python3 $SCRIPTS_DIR/cleanup.py ${SITE_DIR}
source $VENV/bin/activate
python3 $SCRIPTS_DIR/tabulate.py ${SITE_DIR} ${DATADIR}
deactivate

echo done.