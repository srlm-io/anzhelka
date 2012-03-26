#
# To generate graph, use >>> load './volts_vs_rpm.gp'

set ylabel "RPM"
set yrange [8640:12480]

set y2label "Amps"
set y2range [.6:.78]
set ytics nomirror
set y2tics

set xlabel "Volts"

set style data linespoints

set terminal png

set output 'volts_vs_rpm.png'

#
plot "./volts_vs_rpm.dat" using 1:2 axes x1y1 title "RPM", "./volts_vs_rpm.dat" using 1:3 axes x1y2 title "Amps"
