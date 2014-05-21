DotPlot.jl
==========

Fancy terminal plotting for Julia using Braille characters.
Inspired by [Drawille](https://github.com/asciimoo/drawille) but not based on it
due to its restrictive license (AGPL). DotPlot.jl is free for all under the MIT
license.

DotPlot.jl aims for as much elegance and aesthetics as possible for a terminal
(unicode) plotting library. It should be able to plot any continuous real-valued
function.

![DotPlot.jl screenshot 1](doc/img/dotplot-screenshot-1.png)
![DotPlot.jl screenshot 2](doc/img/dotplot-screenshot-2.png)
![DotPlot.jl screenshot 3](doc/img/dotplot-screenshot-3.png)

Screenshots taken in iTerm2 on a Mac using the
[Adobe Source Code Pro font](https://github.com/adobe/source-code-pro).

### INSTALLATION

```julia
Pkg.add("DotPlot")
```

### USAGE

DotPlot.jl is very simple to use: just pass a function and a range to dotplot().

```julia
using DotPlot

dotplot(x -> cos(x); x=-1:1)
```
