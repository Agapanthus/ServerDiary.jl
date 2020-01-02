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
        mini = min(mini, _mini)
        maxi = Inf # We can't calculate the maximum. Inf is "automatic" in plot.jl ylims

        titles = [titles..., _titles...]
    end

    return dates, srcCtx, mini, maxi, titles
end

function renderWidget!(widget::QStack, ctx::PlotContext)

    local myStyle = ctx.styles
    local i = 1
    local accum = 0.0

    # TODO: What about stacking lines with different resolution?
    # One would have to interpolate values and sort the dates...

    for attr in widget.stacked
        ctx.styles = deepcopy(myStyle)
        delete!(ctx.styles, "source context")
        local _, srcCtx, _, _, _ = analyze(QStack(widget.stacked), ctx)

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

                if c !== nothing
                    logger(c, "Plotting where stack context is", true)
                    ctx.styles["source context"] = c
                    ctx.styles["append to label"] = ""
                    for cc in c.ctx
                        ctx.styles["append to label"] *= "$(cc[2])=$(cc[3])"
                    end
                end

                ctx.styles["fillrange"] = accum
                ctx.styles["offset"] = accum
                ctx.styles["stacked"] = true
                local dates, numbers = renderWidget!(attr, ctx)
                accum = numbers
            catch exception
                @show "exception in stacks"
                bt = catch_backtrace()
                msg = sprint(showerror, exception, bt)
                logger(msg, "failed", true, failed = true)
                # TODO: only catch context-not-found exceptions
            end
        end
    end

    return dates, accum
end
