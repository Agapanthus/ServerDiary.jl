include("base.jl")

function analyze(widget::QGroup, ctx::PlotContext)
    local dates = Array{DateTime,1}()
    local srcCtx = Dict{String,DataAttributeContext}()
    local mini = typemax(Float64)
    local maxi = typemin(Float64)
    local titles = Array{String,1}()

    for attr in widget.data
        local _dates, _srcCtx, _mini, _maxi, _titles = analyze(attr, ctx)

        if widget.ctxs !== nothing
            if widget.ctxs |> length === 0
                _srcCtx = Dict()
            end
            for c in widget.ctxs
                if "$c" in _srcCtx
                    mini = min(mini, _mini)
                    maxi = max(maxi, _maxi)
                    delete!(_srcCtx, "$c")
                end
            end
        end

        for (k, v) in _srcCtx
            srcCtx[k] = v
        end
        dates = _dates
        titles = [titles..., _titles...]
    end

    return dates, srcCtx, mini, maxi, titles
end

function renderWidget!(widget::QGroup, ctx::PlotContext)
    # Check if this group is a specialication
    local dates, _, mini, maxi, _ = analyze(widget, ctx)
    local numbers = nothing

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
        delete!(ctx.styles, "source context")
        local _, srcCtx, _, _, _ = analyze(QGroup("", data = widget.data), ctx)

        local ctxs = []
        if widget.ctxs === nothing
            ctxs = [nothing]
        else
            ctxs = collect(values(srcCtx))
            if length(widget.ctxs) > 0
                ctxs = filter(y -> "$y" in map(x -> "$x", widget.ctxs), ctxs)
            end
        end
        # TODO: Does only support single source contexts!

        for c in ctxs
            try
                ctx.styles = deepcopy(myStyle)
                ctx.styles["ylims"] = (yMin, yMax)
                if c !== nothing
                    logger(c, "Plotting where group context is", true)
                    ctx.styles["source context"] = c
                    ctx.styles["append to label"] = ""
                    for cc in c.ctx
                        ctx.styles["append to label"] *= "$(cc[2])=$(cc[3])"
                    end
                end
                _, numbers = renderWidget!(w, ctx)
            catch exception
                @show "Exception in groups"
                bt = catch_backtrace()
                msg = sprint(showerror, exception, bt)
                logger(msg, "failed", true, failed = true)
                # TODO: only catch context-not-found exceptions
            end
        end
    end

    ctx.plot = oPlot

    return dates, numbers
end
