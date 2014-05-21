# TODO: Make tests that vary the parameters and validate the output.

dotplot(x -> cos(x); x=0:1)
dotplot(cos, false; x=0:1)
dotplot(x -> cos(x); x=0:5)
dotplot(x -> sin(x); x=-15:15)
dotplot(x -> x^3 - 2x^2 + 3x; x=-5:5)
dotplot(x -> tanh(x); x=-1.5:1.5)
dotplot(z -> 3z^2 - 2z^3; z=0:1)
