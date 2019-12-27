include("base.jl")

function analyze(widget::QStyle, ctx::PlotContext)
    return analyze(widget.data, ctx)
end


function renderWidget!(widget::QStyle, ctx::PlotContext)
    for (k, v) in widget.overloads
        ctx.styles[k] = v
    end
    return renderWidget!(widget.data, ctx)
end

