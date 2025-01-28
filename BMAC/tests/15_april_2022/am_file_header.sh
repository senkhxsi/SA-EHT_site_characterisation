FILENAME=$(printf "15_APRIL_2022.amc")
ACCESS_DATE=$(
    #ls -lT ../../2009-2022_rnd_subset/*MERRA* | head -n 1 | awk '{printf "%s %s %s", $9, $6, $7}'
    ls -lT *SUB.nc | awk '{printf "%s %s %s", $9, $6, $7}'
)
ACCESS_DOI=$(
    ncdump -h *SUB.nc |
    awk 'BEGIN {FS="\""} /identifier_product_doi =/ {print $2}'
)
printf "# File %s - am model configuration file for\n" ${FILENAME}
printf "#\n"
printf "#            site: %s (lat %s, lon %s)\n"\
    ${SITE_LABEL} ${SITE_LAT} ${SITE_LONG}

printf "#          season: APRIL 2022\n"
#printf "#     H2O profile: %sth percentile\n" $1
#printf "#      O3 profile: median\n"
printf "#\n"
printf "# Climatological statistics to produce this model were compiled from\n"
printf "# NASA MERRA-2 reanalysis data for the period 15 April 2022 @ 0UT.\n"
printf "#\n"
printf "# MERRA references:\n"
printf "#   M. M. Rienecker et al. (2011), MERRA: NASA's Modern-Era Retrospective\n"
printf "#   Analysis for Research and Applications. J. Climate 24:3624.\n"
printf "#\n"
printf "#   A. Molod et al (2015), Development of the GEOS-5 atmospheric general\n"
printf "#   circulation model: evolution from MERRA to MERRA2.  Geoscience Model\n"
printf "#   Development 8:1339. \n"
printf "#\n"
printf "# MERRA is produced by the NASA/Goddard Global Modeling and Assimilation\n"
printf "# Office (GMAO).  MERRA-2 data are archived and distributed by the Goddard\n"
printf "# Earth Sciences Data and Information Services Center (GES DISC).\n"
printf "#\n"
printf "# Data reference:\n"
printf "#   Global Modeling and Assimilation Office (GMAO) (2015),\n"
printf "#   MERRA-2 inst3_3d_asm_Np: 3d,3-Hourly,Instantaneous,Pressure-Level,\n"
printf "#   Assimilation,Assimilated Meteorological Fields,version 5.12.4,\n"
printf "#   Greenbelt, MD, USA:Goddard Space Flight Center Distributed Active\n"
printf "#   Archive Center (GSFC DAAC),\n"
printf "#   Accessed %s at doi:%s\n" "${ACCESS_DATE}" ${ACCESS_DOI}
printf "?\n"
printf "? Usage:\n"
printf "?  am %s  f_min  f_max  df  zenith_angle  trop_h2o_scale_factor\n"\
    $FILENAME
printf "?\n"
printf "? Example:\n"
printf "?  am %s  0 GHz  300 GHz  10 MHz  0 deg  1.0\n" $FILENAME
printf "?\n"
