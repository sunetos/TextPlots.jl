# Currently Julia gives false for isa([1,2,3], Vector{Real}), so doing manually.
typealias RealVector Union(Vector{Int}, Vector{Float64})
typealias RealMatrix Union(Matrix{Int}, Matrix{Float64})
typealias PlotInputs Union(Vector{Function}, (RealVector, RealMatrix))

SUPER = utf16("\u2070\u00b9\u00b2\u00b3\u2074\u2075\u2076\u2077\u2078\u2079")

# Find magnitude of difference between 2 nums, as digits before/after decimal.
function magnitude(num1::Real, num2::Real)
    -iround(log10(abs(num2 - num1)))
end

# See if this float happens to match common uses of constants like n*pi.
function findsymbolic(num::Real)
    num == 0 && return ""

    # Format strings for minus sign, superscript, multiples, and exponents.
    dash(x, super=false) = x >= 0 ? "" : super ? "⁻" : "-"
    sup(x) = dash(x, true) * join([SUPER[d + 1] for d in reverse(digits(iround(abs(x))))])
    multiple(x) = iround(x) == 0 ? "0" : iround(x) == 1 ? "" : "$(iround(x))"
    topower(n, x) = iround(x) == 0 ? "1" : iround(x) == 1 ? n : "$n$(sup(x))"

    # Split number between the absolute value and the minus sign, if any
    anum, sgn = abs(num), dash(num)

    isinteger(num/π)        && return "$(multiple(num/π))π"
    isinteger(num/e)        && return "$(multiple(num/e))e"
    isinteger(log(anum))    && return "$(sgn)$(topower("e", log(anum)))"
    isinteger(log10(anum))  && return "$(sgn)$(topower("10", log10(anum)))"

    return ""
end

# Julia somehow doesn't support the crucial "g" printf type.
# Don't feel like dealing with complex numbers yet.
function format(num::Real, width::Int, precision::Int=typemax(Int))
    str = findsymbolic(num)  # Check for a prettier format for num.
    if length(str) > 0
        str = lpad(str, width)  # Pretty format found, just fit in the space.
    else
        # Attempt multiple rounding levels to fit in available characters.
        precision < width && (num = round(num, precision + 1))
        isint = isinteger(num) || isinteger(round(num, width - 5))
        fmt = isint ? "%$(width)d" : "%$(width).$(width - 3)f"
        str = eval(:(@sprintf $(fmt) $(num)))
    end

    # Whatever the output was, number or symbol, truncate if too large.
    if length(str) > width
        str[end] == '.' && return " $(str[1:end - 1])"
        1 < search(str, '.') <= width && return str[1:width]
        width >= 4 && return str[1:width - 1] * "…"
    end
    str
end

# Attempt to produce a meaningful graph label automatically.
function funclabel(f::Function, names=["x"])
    if isa(f.env, MethodTable) && isdefined(f.env, :name)
        return "$(f.env.name)($(join(names, ", ")))"
    end

    # Julia uses different types for lambdas, named funcs, and inline funcs.
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
function plot(data::PlotInputs, start::Real=-10, stop::Real=10;
                 border::Bool=true, labels::Bool=true, title::Bool=true,
                 cols::Int=60, rows::Int=16, margin::Int=9,
                 invert::Bool=false, gridlines::Bool=false,
                 scalefunc::Function=identity)

    # The unicode braille chars are conveniently structured to support bitwise
    # manipulation, so we can just OR specific bits to set that dot to filled.
    grid = fill(char(gridlines ? 0x2812 : 0x2800), cols, rows)
    left, right = sides = ((0, 1, 2, 6), (3, 4, 5, 7))
    function showdot(x, y)  # Assumes x & y are already scaled to the grid.
        invy = (rows - y)*0.9999
        col, col2 = ifloor(x), ifloor(x*2)
        row, row4 = ifloor(invy), ifloor(invy*4)
        # This does the bitwise OR to fill in a single dot out of the 8.
        grid[col + 1, row + 1] |= 1 << sides[1 + (col2 & 1)][1 + (row4 & 3)]
    end

    # If input is a function, sample it at each row & col to fill xvals & yvals.
    continuous = isa(data, Vector{Function})
    if continuous
        xframes, yframes = cols, rows
        xspread = stop - start
        xstep, xscale = (stop - start)/cols, xframes/xspread
        xvals = collect(start:xstep:stop)
        # Assumes f(x) is defined for all x in the given range.
        yvals = Float64[f(x) for x in xvals, f in data]
    else
        # Unfortunately much of this is redundant with the above code, but a few
        # things have to be done in a different order, making cleanup tricky.
        xframes, yframes = cols - 1, rows - 1
        xvals, yvals = data
        @assert length(yvals) >= length(xvals) "Different number of x/y points."
        start, stop = minimum(xvals), maximum(xvals)
        xspread = stop - start
        xstep, xscale = xspread/xframes, xframes/xspread
        isa(yvals, RealVector) && (yvals = reshape(yvals, length(yvals), 1))
    end

    # Rescaling and setting boundaries must happen after the sampling above.
    xscaled = xscale*(xvals .- start)
    ystart, ystop = minimum(yvals), maximum(yvals)
    yspread = ystop - ystart
    ystep, yscale = yspread/yframes, yframes/yspread

    # Finally, iterate through the grid, scaling & interpolating, to set dots.
    for row in 1:size(yvals, 2)
        rowvals = yvals[:, row]
        yscaled = yscale*(rowvals .- ystart)
        if scalefunc != identity
            yrescaled = [scalefunc(y) for y in rowvals]
            yrestart, yrestop = minimum(yrescaled), maximum(yrescaled)
            yrespread = yrestop - yrestart
            yrescale = rows/yrespread
            yscaled = yrescale*(yrescaled .- yrestart)
        end

        # Interpolate between steps to smooth plot & avoid frequent f(x) calls.
        for (col, x) in enumerate(xscaled[1:(continuous ? end - 1 : end)])
            if continuous
                yleftedge, yrightedge = yscaled[col:col + 1]
                ydelta = yrightedge - yleftedge
                showdot(x + eps(x), yleftedge + ydelta*0.25)
                showdot(x + 0.5 + eps(x), yrightedge - ydelta*0.25)
            else
                y = yscaled[col]
                showdot(x, y + 1)
            end
        end
    end

    # Exploit the bitwise nature of the braille chars to invert.
    invert && (grid = map(c -> char(c $ 0xFF), grid))

    # Build the plot decorations based on configuration params.
    lines = String[]
    padding = labels ? repeat(" ", margin) : ""
    prefix, suffix = border ? (padding * "⡇", "⢸") : (padding * "", "")
    border && push!(lines, padding * "⡤" * repeat("⠤", cols) * "⢤")
    append!(lines, [prefix * join(grid[:, row], "") * suffix for row in 1:rows])
    border && push!(lines, padding * "⠓" * repeat("⠒", cols) * "⠚")

    # Try pretty hard to fit rounded axis labels into available chars.
    if labels
        yprecision = magnitude(ystart, ystop)
        ystartlabel = format(ystart, margin - 1, yprecision)
        ystoplabel = format(ystop, margin - 1, yprecision)
        lines[1] = "$ystoplabel $(lines[1][margin + 1:end])"
        lines[end] = "$ystartlabel $(lines[end][margin + 1:end])"

        xprecision = magnitude(start, stop)
        xstartlabel = strip(format(start, margin - 1, xprecision))
        xstoplabel = strip(format(stop, margin - 1, xprecision))
        xstartlabel[1] != '-' && (xstartlabel = " $xstartlabel")
        lblrow = repeat(" ", margin - 1) * xstartlabel
        lblrow *= lpad(xstoplabel, length(prefix) + cols - length(lblrow) + 1)
        push!(lines, lblrow)
    end

    # The title is mostly useful when plotting repeatedly in a single session.
    if title
        if isa(data, Vector{Function})
            nametag = join([funclabel(f) for f in data], ", ")
        else
            nametag = "scatter plot"
        end
        println("$padding $nametag")
    end
    println(join(lines, '\n'))
end

# Overloads for a variety of different parameter specifications.
function plot(data::PlotInputs, rng::Range, etc...; args...)
    stop = isdefined(rng, :stop) ? rng.stop : rng.len
    plot(data, rng.start, stop, etc...; args...)
end
function plot(f::Function, etc...; args...)
    plot([f], etc...; args...)
end
function plot(xvals::RealVector, yvals::RealMatrix, etc...; args...)
    plot((xvals, yvals), etc...; args...)
end
function plot(xvals::RealVector, yvals::RealVector, etc...; args...)
    plot((xvals, reshape(yvals, length(yvals), 1)), etc...; args...)
end
function plot(data::RealVector, etc...; args...)
    plot(collect(1:length(data)), data, etc...; args...)
end
function plot(data::RealMatrix, etc...; args...)
    plot((collect(1:size(data, 1)), data), etc...; args...)
end
function plot(rng::Range, etc...; args...)
    plot(collect(rng))
end
# Shorthand for a logarithm plot scale.
function logplot(etc...; args...)
    plot(etc...; scalefunc=log10, args...)
end
