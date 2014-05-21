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
function dotplot(f::Function, border=true, labels=true, title=true,
                 cols=60, rows=16, margin=9; args...)
    # Assumes f(x) is defined for all x in the given range.
    @assert length(args) == 1 "dotplot requires a function of exactly one var."

    var, rng = args[1]
    @assert isa(rng, Range) "dotplot requires a range for each var."
    var = string(var)

    grid = fill(char(0x2800), cols, rows)

    xstop = isdefined(rng, :stop) ? rng.stop : rng.len
    xstart, xspread = rng.start, xstop - rng.start
    xstep, xscale = xspread/cols, cols/xspread

    vals = [f(x) for x in xstart:xstep:xstop]
    ystart, ystop = minimum(vals), maximum(vals)
    yspread = ystop - ystart
    ystep, yscale = yspread/rows, rows/yspread
    scaled = yscale*(vals .- ystart)

    # Interpolate between steps to smooth plot & avoid calling f(x) frequently.
    for col in 1:length(scaled) - 1
        yleftedge, yrightedge = scaled[col:col + 1]
        ydelta = yrightedge - yleftedge
        yleftcol, yrightcol = yleftedge + ydelta*0.25, yrightedge - ydelta*0.25

        leftdotrow, rightdotrow = int(floor(yleftcol)), int(floor(yrightcol))
        dotleftcol = int(floor(3.99*(1.0 - yleftcol + leftdotrow))) + 1
        dotrightcol = int(floor(3.99*(1.0 - yrightcol + rightdotrow))) + 1
        grid[col, rows - leftdotrow] |= 1 << (0, 1, 2, 6)[dotleftcol]
        grid[col, rows - rightdotrow] |= 1 << (3, 4, 5, 7)[dotrightcol]
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

    label = funclabel(f, [string(arg[1]) for arg in args])
    title && println("$padding $label")
    println(join(lines, '\n'))
end
