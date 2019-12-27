include("base.jl")
include("../providers/data.jl")

function analyze(attr::DataAttribute, ctx::PlotContext)
    local dates, values = fetchData!(ctx.store, attr, ctx.minDate, ctx.maxDate)
    # TODO: Multiply along text columns!
    local srcCtx = []

    return dates, values, srcCtx, minimum(values), maximum(values), [attr.property]
end

import Base.+
+(arr::Array{<:Number,1}, b::Number) = begin
    arr = copy(arr)
    if b == 0
        return arr
    end
    for i in 1:length(arr)
        arr[i] += b
    end
    return arr
end


function renderWidget!(attr::DataAttribute, ctx::PlotContext)

    local dates, values, srcCtx, _ = analyze(attr, ctx)
    @assert length(srcCtx) == 0 "Ambiguos attribute."

    local label = attr.property
    if "stacked" in keys(ctx.styles)
        label *= " (stacked)"
    end

    local color = ctx.styles["color"]
    local fcolor = ctx.styles["fillcolor"]
    if ctx.styles["color"] === nothing
        color = nextColor!(ctx.palette)
    end
    if fcolor === nothing
        fcolor = color
    end

    # For example in stacked plots we need some offset
    values += ctx.styles["offset"]

    local fillrange = ctx.styles["fillrange"]
    # Filling a log plot is tricky! Don't go below the minimum!
    if "log" in keys(ctx.styles)
        local l = ctx.styles["log"]
        if typeof(fillrange) <: Array
            fillrange = map(x -> max(x, l), fillrange)
        elseif typeof(fillrange) <: Number
            fillrange = max(fillrange, l)
        end
    end

    local ylims = nothing
    if "ylims" in keys(ctx.styles)
        ylims = ctx.styles["ylims"]
    end

    # add to graph
    plot!(
        ctx.plot,
        dates,
        values,
        label = label,
        color = color,
        ylims = ylims,
        fillrange = fillrange,
        fillcolor = fcolor,
        fillalpha = ctx.styles["fillalpha"],
    )

    return dates, values
end


