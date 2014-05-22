# Julia somehow doesn't support the crucial "g" printf type.
# Don't feel like dealing with complex numbers yet.
function format(num::Real, width::Int)
    isint = isinteger(num) || isinteger(round(num, width - 5))
    fmt = isint ? "%$(width)d" : "%$(width).$(width - 3)f"
    eval(:(@sprintf $(fmt) $(num)))
end

# Attempt to produce a meaningful graph label automatically.
function funclabel(f, names=["x"])
    if isa(f.env, MethodTable) && isdefined(f.env, :name)
        return "$(f.env.name)($(join(names, ", ")))"
    end

    fsrc = isdefined(f, :code) ? f.code : code_lowered(f, (Number,))[1]
    if isdefined(fsrc, :ast)
        if isa(fsrc.ast, Array)
            fsrc = ccall(:jl_uncompress_ast, Any, (Any,Any), fsrc, fsrc.ast)
        else
            fsrc = fsrc.ast
        end
    end
    codes = fsrc.args[end].args
    if length(codes) == 1 || (length(codes) == 2 && codes[1].head == :line)
        # Extract the return expression
        return string(codes[end].args[end])
    end

    return "(unlabeled)"
end

# Fancy terminal plotting for Julia using Braille characters.
function dotplot(fs::Vector{Function}, border=true, labels=true, title=true,
                 cols=60, rows=16, margin=9; args...)
    # Assumes f(x) is defined for all x in the given range.
    @assert length(args) == 1 "dotplot requires a function of exactly one var."

    var, rng = args[1]
    @assert isa(rng, Range) "dotplot requires a range for each var."
    var = string(var)

    xstop = isdefined(rng, :stop) ? rng.stop : rng.len
    xstart, xspread = rng.start, xstop - rng.start
    xstep, xscale = xspread/cols, cols/xspread

    xvals = collect(xstart:xstep:xstop)
    xscaled = xscale*(xvals .- xstart)

    fvals = Float64[f(x) for f in fs, x in xstart:xstep:xstop]
    ystart, ystop = minimum(fvals), maximum(fvals)
    yspread = ystop - ystart
    ystep, yscale = yspread/rows, rows/yspread

    grid = fill(char(0x2800), cols, rows)
    left, right = sides = ((0, 1, 2, 6), (3, 4, 5, 7))
    function showdot(x, y)  # Assumes x & y are already scaled to the grid.
        invy = rows - y
        col, col2 = int(floor(x)), int(floor(x*2))
        row, row4 = int(floor(invy)), int(floor(invy*4))
        grid[col + 1, row + 1] |= 1 << sides[1 + (col2 & 1)][1 + (row4 & 3)]
    end

    for (row, f) in enumerate(fs)
        yvals = fvals[row, :]
        yscaled = yscale*(yvals .- ystart)

        # Interpolate between steps to smooth plot & avoid frequent f(x) calls.
        for (col, x) in enumerate(xscaled[1:end - 1])
            yleftedge, yrightedge = yscaled[col:col + 1]
            ydelta = yrightedge - yleftedge
            yleftcol, yrightcol = yleftedge + ydelta*0.25, yrightedge - ydelta*0.25
            showdot(x + eps(x), yleftcol)
            showdot(x + 0.5 + eps(x), yrightcol)
        end
    end

    lines = String[]
    padding = labels ? repeat(" ", margin) : ""
    prefix, suffix = border ? (padding * "⡇", "⢸") : (padding * "", "")
    border && push!(lines, padding * "⡤" * repeat("⠤", cols) * "⢤")
    append!(lines, [prefix * join(grid[:, row], "") * suffix for row in 1:rows])
    border && push!(lines, padding * "⠓" * repeat("⠒", cols) * "⠚")

    if labels
        ystartlabel = format(ystart, margin - 1)
        ystoplabel = format(ystop, margin - 1)
        lines[1] = "$ystoplabel $(lines[1][margin + 1:end])"
        lines[end] = "$ystartlabel $(lines[end][margin + 1:end])"

        xstartlabel = strip(format(xstart, margin - 1))
        xstoplabel = strip(format(xstop, margin - 1))
        lblrow = repeat(" ", margin - 1) * lpad(xstartlabel, 2)
        lblrow *= lpad(xstoplabel, length(prefix) + cols - length(lblrow) + 1)
        push!(lines, lblrow)
    end

    if title
        names = [funclabel(f, [string(arg[1]) for arg in args]) for f in fs]
        nametag = join(names, ", ")
        println("$padding $nametag")
    end
    println(join(lines, '\n'))
end

dotplot(f::Function, etc...; args...) = dotplot([f], etc...; args...)
