# This script reads in a table of profiles, throwing out any rows at pressure
# greater than Ptrunc, and writes out the truncated table with an extra row
# extrapolated (on log P) to the surface pressure Ps.

BEGIN {
    Ptrunc = 525.
    Ps = 550.
    i = 0
}

/^#/ {
    print
    next
}

$1 > Ptrunc {
    next
}

{
    ++i
    for (j = 1; j <= NF; ++j)
        tab[i,j] = $j + 0
}

END {
    n = i
    log_Ps = log(Ps)
    log_P1 = log(tab[1,1])
    log_P2 = log(tab[2,1])
    dlog_P = log_P1 - log_P2
    tab[0,1] = Ps
    for (j = 2; j <= NF; ++j) {
        du = tab[1,j] - tab[2,j]
        tab[0,j] = tab[1,j] + (log_Ps - log_P1) * du / dlog_P
    }
    # Set negative values in the extrapolated row to zero, excluding last two columns
    for (j = 2; j <= NF; ++j) {
        if (tab[0,j] < 0 && j < NF-1) {
            tab[0,j] = 0
        }
    }
    for (i = 0; i <= n; ++i) {
        if (tab[i,1] > Ps)
            continue
        printf("%8.1f", tab[i,1])
        for (j = 2; j <= NF; ++j) {
            printf(" %e", tab[i,j])
        }
        printf("\n")
    }
}