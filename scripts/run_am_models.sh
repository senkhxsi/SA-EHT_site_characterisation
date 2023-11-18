# set up a local cache directory for am (speeds up re-runs):
if [ ! -d ${OUTDIR_AM}/am_cache ]; then
    mkdir ${OUTDIR_AM}/am_cache
fi
export AM_CACHE_PATH=${OUTDIR_AM}/am_cache
export AM_CACHE_HASH_MODULUS=7001

for YEAR in {2009..2022}; do
for MONTH in Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec; do
am ${OUTDIR_AM}/${SITE}_${MONTH}_${YEAR}.amc  $F_MIN GHz $F_MAX GHz $DF MHz 0 deg 1.0 > ${OUTDIR_AM}/${SITE}_${MONTH}_${YEAR}.out  2>${OUTDIR_AM}/${SITE}_${MONTH}_${YEAR}.err
done
done