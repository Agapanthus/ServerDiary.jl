include("base.jl")

function analyze(widget::QGroup, ctx::PlotContext)
    local dates = Array{DateTime,1}()
    local values = nothing
    local srcCtx = Array{String,1}()
    local mini = typemax(Float64)
    local maxi = typemin(Float64)
    local titles = Array{String,1}()

    for attr in widget.data
        local _dates, _values, _srcCtx, _mini, _maxi, _titles = analyze(attr, ctx)

        @assert length(_dates) == length(_values)
        dates = _dates
        for c in _srcCtx
            push!(srcCtx, c)
        end
        if values === nothing
            values = _values
        end
        mini = min(mini, minimum(values), _mini)
        maxi = max(maxi, maximum(values), _maxi)
        titles = [titles..., _titles...]
    end

    return dates, values, srcCtx, mini, maxi, titles
end

function renderWidget!(widget::QGroup, ctx::PlotContext)
    # Check if this group is a specialication
    local dates, values, srcCtx, mini, maxi, titles = analyze(widget, ctx)

    local oPlot = ctx.plot
    local myStyle = ctx.styles
    ctx.group += 1

    if ctx.group == 2
        plot!(oPlot, right_margin = 25mm) # increase margin in parent
        ctx.plot = twinx(ctx.plot)
        plot!(ctx.plot, y_formatter = Y_FORMATTER) # set formatter in child
    end
    plot!(ctx.plot, ylabel = widget.unit)
    if widget.log
        plot!(ctx.plot, yaxis = :log)
    end

    @assert ctx.group <= 2 "Currently only two groups are supported"
    local yMax = maxi
    local yMin = mini
    if widget.min !== nothing
        yMin = widget.min
    end
    if widget.log
        @assert widget.min === nothing || widget.min > 0
        if yMin <= 0
            yMin = 1
        end
        ctx.styles["log"] = yMin
    else
        yMin = min(yMin, 0)
    end

    if widget.max !== nothing
        yMax = widget.max
    end

    for w in widget.data
        ctx.styles = deepcopy(myStyle)
        ctx.styles["ylims"] = (yMin, yMax)
        renderWidget!(w, ctx)
    end

    ctx.plot = oPlot

    return dates, values
end

