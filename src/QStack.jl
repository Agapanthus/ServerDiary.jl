

function analyze(widget::QStack, ctx::PlotContext)
    local dates = Array{DateTime,1}()
    local values = nothing
    local srcCtx = Array{String,1}()
    local mini = typemax(Float64)
    local maxi = typemin(Float64)
    local titles = Array{String,1}()

    for attr in widget.stacked
        local _dates, _values, _srcCtx, _mini, _maxi, _titles = analyze(attr, ctx)

        # TODO: What about stacking lines with different resolution?
        # One would have to interpolate values and sort the dates...

        @assert length(_dates) == length(_values)
        if length(dates) > 0
            @assert length(dates) == length(_dates) "$(length(dates)) == $(length(_dates))"
        end
        dates = _dates
        for c in _srcCtx
            push!(srcCtx, c)
        end
        if values === nothing
            values = _values
        else
            @assert length(values) == length(_values)
            values += _values
        end
        mini = min(mini, minimum(values), minimum(_values), _mini)
        maxi = max(maxi, maximum(values), maximum(_values), _maxi)

        titles = [titles..., _titles...]
    end

    return dates, values, srcCtx, mini, maxi, titles
end

function renderWidget!(widget::QStack, ctx::PlotContext)

    local myStyle = ctx.styles
    local i = 1
    local dates = nothing
    local values = nothing
    local accum = 0.0
    
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
