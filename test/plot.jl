# TODO: Make tests that vary the parameters and validate the output.

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
