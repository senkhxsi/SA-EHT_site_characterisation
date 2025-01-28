# get_pwv.awk - scan through stderr output from am, extract total pwv

/^# am version/,/^# total/ {
    next
}

/um_pwv/ {
    gsub(/[()]/,"")
    pwv = $4
    exit
}

# print pwv in mm
END {
    printf("%.2f\n", pwv * 1e-3)
}

