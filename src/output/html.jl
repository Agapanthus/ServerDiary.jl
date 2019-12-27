include("../../conf.jl")

mutable struct StatsDocument
    parts::Dict{String,String}
    order::Array{String,1}
    css::String
end
StatsDocument() = StatsDocument(Dict(), [], "")

function appendGraph(doc::StatsDocument, path::String, titles::Array{Tuple{String,String,String},1}, description::String, title::String)::StatsDocument
    if MAKE_OVERVIEW
        if "overview" ∉ keys(doc.parts)
            doc.parts["overview"] = ""
            push!(doc.order, "overview")
        end
        doc.parts["overview"] *= "<img src=\"$path\" title=\"$title\" alt=\"$title\" height=\"$OVERVIEW_HEIGHT\" width=\"$OVERVIEW_WIDTH\">"
    end
    
    if title ∉ keys(doc.parts)
        doc.parts[title] = ""
        push!(doc.order, title)
    end
    doc.parts[title] *= "<p>" * replace("$description", "\n"=>"\n<br>") * 
            "</p><p><img src=\"$path\" title=\"$title\" alt=\"$title\"></p><p><ul>\n" *
            reduce(*, map(x->"<li><i><b>$(x[1])</b> ($(x[2]))</i> $(x[3])</li>\n", titles)) * "</ul></p>"

    return doc
end

function generateHTML(doc::StatsDocument)::String
    return """<html>
<head>
<meta http-equiv="content-type" content="text/html; charset=UTF-8">
<style>
$(doc.css)
</style>
</head>
<body>
$(reduce(*, map(x->"<h2>$(x)</h2><div>$(doc.parts[x])</div>", doc.order)))
</body>
</html>
"""
end
