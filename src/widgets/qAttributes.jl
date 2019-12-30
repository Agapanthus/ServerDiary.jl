include("base.jl")
include("../providers/data.jl")

function analyze(attr::DataAttribute, ctx::PlotContext)    
    local srcCtx
    if "source context" in keys(ctx.styles)
        if typeof(ctx.styles["source context"]) <: Array
            srcCtx = Dict("$x"=>x for x in ctx.styles["source context"])
        else
            @assert typeof(ctx.styles["source context"]) <: DataAttributeContext
            srcCtx = Dict("$(ctx.styles["source context"])"=>ctx.styles["source context"])
        end
    else
        srcCtx = fetchContext!(ctx.store, attr, ctx.minDate, ctx.maxDate)
    end
    
    @assert length(srcCtx) > 0 && typeof(srcCtx) <: Dict{String, DataAttributeContext}
    for (k,lctx) in srcCtx
        if "source context" in keys(ctx.styles)
            lctx = ctx.styles["source context"] 
        end
        local dates, values, title = fetchData!(ctx.store, attr, lctx, ctx.minDate, ctx.maxDate)
        
        # TODO: mini und max
        return dates, srcCtx, minimum(values), maximum(values), [title]
    end
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

    local dates, values, _ = fetchData!(ctx.store, attr, ctx.styles["source context"], ctx.minDate, ctx.maxDate)
        
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


