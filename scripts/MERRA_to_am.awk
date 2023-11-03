# Make an am model configuration file from a table of quantile profiles

BEGIN {
    P_col = 1       # column number for pressure [mbar]
    T_col = 2       # column number for temperature [K]
    x_H2O_vpr_col = 3   # column number for H2O vmr in ppmv
    x_lqd_H2O_col = 4   # column number for liquid water vmr in ppm
    x_ice_H2O_col = 5   # column number for ice water vmr in ppm
    x_O3_col = 6    # column number for O3 vmr in ppmv
    P_ground = 1000.0        # surface pressure [mbar]
    P_tropopause = 100.0    # tropopause pressure [mbar] 
    P_stratopause = 1.0     # stratopause pressure [mbar]
    P_Voigt = 1.1   # Pressure [mbar] below which Voigt lineshape will be used
                    # 1 mbar is a suitable choice for f < 300 GHz.
    n = 0
}

/#/ {
    next
}

{
    if (n > 0 && P[n-1] > P_ground && $P_col < P_ground) {
        # insert an interpolated level at P_ground.
        r = (P_ground - $P_col) / (P[n-1] - $P_col)
        P[n] = P_ground
        T[n] = r * T[n-1] + (1.0 - r) * $T_col
        x_H2O_vpr[n] = r * x_H2O_vpr[n-1] + (1.0 - r) * $x_H2O_vpr_col
        x_lqd_H2O[n] = r * x_lqd_H2O[n-1] + (1.0 - r) * $x_lqd_H2O_col
        x_ice_H2O[n] = r * x_ice_H2O[n-1] + (1.0 - r) * $x_ice_H2O_col
        x_O3[n] = r * x_O3[n-1] + (1.0 - r) * $x_O3_col
        ++n
    }
    P[n] = $P_col
    T[n] = $T_col
    x_H2O_vpr[n] = $x_H2O_vpr_col
    x_lqd_H2O[n] = $x_lqd_H2O_col
    x_ice_H2O[n] = $x_ice_H2O_col
    x_O3[n] = $x_O3_col
    ++n
}

END {
    # replace x_H2O_vpr and x_O3 with their layer midpoint values, 
    # except for the top layer.
    for (i = 0; i < n-1; ++i) {
        x_H2O_vpr[i] = 0.5 * (x_H2O_vpr[i] + x_H2O_vpr[i+1])
        x_lqd_H2O[i] = 0.5 * (x_lqd_H2O[i] + x_lqd_H2O[i+1])
        x_ice_H2O[i] = 0.5 * (x_ice_H2O[i] + x_ice_H2O[i+1])
        x_O3[i] = 0.5 * (x_O3[i] + x_O3[i+1])
    }
    print "f %1 %2  %3 %4  %5 %6"
    print "output f GHz  tau  tx  Trj K  Tb K"
    print "za %7 %8"
    print "tol 1e-4"
    print ""
    print "Nscale troposphere h2o %9"
    print ""
    print "T0 2.7 K"
    for (i = n-1; i >= 0; --i) {
        if (P[i] > P_ground)
            break
        print ""
        if (P[i] < P_stratopause)
            print "layer mesosphere"
        else if (P[i] < P_tropopause)
            print "layer stratosphere"
        else
            print "layer troposphere"
        printf("Pbase %g mbar\n", P[i])
        printf("Tbase %.1f K\n", T[i])
        if (P[i] <= P_Voigt)
            print "lineshape Voigt-Kielkopf"
        print "column dry_air vmr"
        printf("column h2o RH %.2f%%\n", x_H2O_vpr[i] * 100)
        if (T[i] > 242 && x_lqd_H2O[i] > 0)
            printf("column lwp_abs_Rayleigh vmr %.2e\n", x_lqd_H2O[i] * 1e-6)
        if (T[i] < 273 && x_ice_H2O[i] > 0)
            printf("column iwp_abs_Rayleigh vmr %.2e\n", x_ice_H2O[i] * 1e-6)
        printf("column o3 vmr %.2e\n", x_O3[i] * 1e-6)
    }
}