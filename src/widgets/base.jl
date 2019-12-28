using Dates

include("../structures.jl")

function loadPalette(theme)::Palette
    local palette = PlotThemes.palette(theme) # get_color_palette(:auto, plot_color(:white), 17)
    return Palette(palette, 1)
end

function nextColor!(p::Palette)
    p.index = (p.index + 1) % length(p.palette) + 1
    return p.palette[p.index]
end


function defaultStyles()::Dict{String,Any}
    return Dict{String,Any}(
        "color" => nothing,
        "fillcolor" => nothing,
        "fillalpha" => 0.2,
        "fillrange" => nothing,
        "offset" => 0.0,
    )
end


using Formatting
global Y_FORMATTER = yi -> begin
    if yi > 100
        yi = round(yi)
    end
    replace(format(round(yi, digits=3), commas = true), "," => " ")
end
