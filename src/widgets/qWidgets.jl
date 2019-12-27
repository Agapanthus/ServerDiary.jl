

include("qPlots.jl")
include("../../conf.jl")



function renderWidget(widget::QWidget, today::DateTime, saveTo::String) #::Array{Tuple{String, Any, String, String},1}

    logger(widget, "Unknwon widget type $(typeof(widget))", true)

    throw("Unknwon widget type $(typeof(widget))")
end


