# Master script to compute profile statistics, generate am models, and compute
# spectra.

# Site name, date range, and path to directory containing the  data files.
export SITE=BMAC
export SITE_LABEL='BMAC'
export SITE_ALT=3000
export DATERANGE=2009-2022
export DATE=20220415
# random subset of data files to speed up demo/testing
#export DATADIR=../../${DATERANGE}_rnd_subset/MERRA2_400.inst3_3d_asm_Np.20220415.SUB.nc

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
./profile_stats_inst.sh

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
#python3 cleanup.py ..


echo done.