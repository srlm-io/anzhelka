#
# To generate graph, use >>> load './pwm_vs_rpm.gp'

set ylabel "RPM"
set yrange [0:12500]

#set ytics nomirror
#set y2tics

set xlabel "PWM (uS)"

set style data lines

set terminal png

set output 'pwm_vs_rpm.png'

set key right bottom



#
plot "./pwm_vs_rpm.dat" using 1:2 title "Up", "./pwm_vs_rpm.dat" using 3:4 title "Down"
