# TODO: Make tests that vary the parameters and validate the output.

plot(exp, 0, 30)
plot(sinpi, -2, 2)
plot(rand(15))
plot(rand(15, 4))

plot(x -> cos(x), 0:1)
plot(cos, 0, 1, border=false)
plot(x -> sin(x), -15:15)
plot([x -> cos(x), x -> cos(x + pi)], 0:5)
plot(x -> x^3 - 2x^2 + 3x, -5, 5)
plot(x -> tanh(x), -1.5:1.5)
plot(z -> 3z^2 - 2z^3, 0:1)

plot([1, 3, 5])
plot(1:10)
plot([1, 3, 5, 7], [13, 11, 9, 7])
plot([1:2:20], rand(10, 3))

plot(exp, 0.1:20)
logplot(exp, 0.1:20)
plot(x -> exp(-x/5), 0.01:20)
logplot(x -> exp(-x/5), 0.01:20)

plot(sinpi, -2, 2, invert=false, gridlines=false)
plot(sinpi, -2, 2, invert=true, gridlines=false)
plot(sinpi, -2, 2, invert=false, gridlines=true)
plot(sinpi, -2, 2, invert=true, gridlines=true)

# Test rounding and symoblic label display.
plot(sin, -6pi, 6pi, cols=140)
