# get_Tbase.awk - scan through stderr output from am, extract Tbase

/Tbase/ {
    Tbase = $2
}

# print Tbase in K
END {
    printf("%.2f\n", Tbase)
}