# Currently Julia gives false for isa([1,2,3], Vector{Real}), so doing manually.
typealias RealVector Union(Vector{Int}, Vector{Float64})
typealias RealMatrix Union(Matrix{Int}, Matrix{Float64})
typealias PlotInputs Union(Vector{Function}, (RealVector, RealMatrix))

# Julia somehow doesn't support the crucial "g" printf type.
# Don't feel like dealing with complex numbers yet.
function format(num::Real, width::Int)
    isint = isinteger(num) || isinteger(round(num, width - 5))
    fmt = isint ? "%$(width)d" : "%$(width).$(width - 3)f"
    eval(:(@sprintf $(fmt) $(num)))
end

# Attempt to produce a meaningful graph label automatically.
function funclabel(f::Function, names=["x"])
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
function plot(data::PlotInputs, start::Real=-10, stop::Real=10;
                 border::Bool=true, labels::Bool=true, title::Bool=true,
                 cols::Int=60, rows::Int=16, margin::Int=9)
    grid = fill(char(0x2800), cols, rows)
    left, right = sides = ((0, 1, 2, 6), (3, 4, 5, 7))
    function showdot(x, y)  # Assumes x & y are already scaled to the grid.
        invy = (rows - y)*0.9999
        col, col2 = int(floor(x)), int(floor(x*2))
        row, row4 = int(floor(invy)), int(floor(invy*4))
        grid[col + 1, row + 1] |= 1 << sides[1 + (col2 & 1)][1 + (row4 & 3)]
    end

    continuous = isa(data, Vector{Function})
    if continuous
        xframes, yframes = cols, rows
        xspread = stop - start
        xstep, xscale = (stop - start)/cols, xframes/xspread
        xvals = collect(start:xstep:stop)
        # Assumes f(x) is defined for all x in the given range.
        yvals = Float64[f(x) for x in xvals, f in data]
    else
        xframes, yframes = cols - 1, rows - 1
        xvals, yvals = data
        @assert length(yvals) >= length(xvals) "Different number of x/y points."
        start, stop = minimum(xvals), maximum(xvals)
        xspread = stop - start
        xstep, xscale = xspread/xframes, xframes/xspread
        isa(yvals, RealVector) && (yvals = reshape(yvals, length(yvals), 1))
    end

    xscaled = xscale*(xvals .- start)
    ystart, ystop = minimum(yvals), maximum(yvals)
    yspread = ystop - ystart
    ystep, yscale = yspread/yframes, yframes/yspread

    for row in 1:size(yvals, 2)
        rowvals = yvals[:, row]
        yscaled = yscale*(rowvals .- ystart)

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

        xstartlabel = strip(format(start, margin - 1))
        xstoplabel = strip(format(stop, margin - 1))
        lblrow = repeat(" ", margin - 1) * lpad(xstartlabel, 2)
        lblrow *= lpad(xstoplabel, length(prefix) + cols - length(lblrow) + 1)
        push!(lines, lblrow)
    end

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
