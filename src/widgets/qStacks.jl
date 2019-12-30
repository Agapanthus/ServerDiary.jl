include("base.jl")

function analyze(widget::QStack, ctx::PlotContext)
    local dates = Array{DateTime,1}()
    local srcCtx = Dict{String,DataAttributeContext}()
    local mini = typemax(Float64)
    local maxi = typemin(Float64)
    local titles = Array{String,1}()

    for attr in widget.stacked
        local _dates, _srcCtx, _mini, _maxi, _titles = analyze(attr, ctx)

        if length(dates) > 0
            @assert length(dates) == length(_dates) "$(length(dates)) == $(length(_dates))"
        end
        dates = _dates
        for (k,v) in _srcCtx
            srcCtx[k] = v
        end
        mini = min(mini, _mini)
        maxi = Inf # We can't calculate the maximum. Inf is "automatic" in plot.jl ylims

        titles = [titles..., _titles...]
    end

    return dates, srcCtx, mini, maxi, titles
end

function renderWidget!(widget::QStack, ctx::PlotContext)

    local myStyle = ctx.styles
    local i = 1
    local dates = nothing
    local values = nothing
    local accum = 0.0
    
    # TODO: What about stacking lines with different resolution?
    # One would have to interpolate values and sort the dates...
    
    for attr in widget.stacked
        ctx.styles = deepcopy(myStyle)
        ctx.styles["fillrange"] = accum
        ctx.styles["offset"] = accum
        ctx.styles["stacked"] = true
        dates, values = renderWidget!(attr, ctx)
        accum = values
    end

    return dates, accum
end

