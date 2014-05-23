# TODO: Make tests that vary the parameters and validate the output.

dotplot(rand(15))
dotplot(rand(15, 4))

dotplot(x -> cos(x), 0:1)
dotplot(cos, 0, 1, border=false)
dotplot(x -> sin(x), -15:15)
dotplot([x -> cos(x), x -> cos(x + pi)], 0:5)
dotplot(x -> x^3 - 2x^2 + 3x, -5:5)
dotplot(x -> tanh(x), -1.5:1.5)
dotplot(z -> 3z^2 - 2z^3, 0:1)

dotplot([1, 3, 5])
dotplot(1:10)
dotplot([1, 3, 5], [11, 9, 7])
