# get_Pbase.awk - scan through stderr output from am, extract Pbase

/Pbase/ {
    Pbase = $2
}

# print Pbase in mbar
END {
    printf("%.2f\n", Pbase * 1e-3)
}