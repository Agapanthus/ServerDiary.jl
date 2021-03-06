using Dates

include("sysstatDB.jl")
include("../util/util.jl")
include("../../conf.jl")


function sarExe(cmd)
    local res = exe(cmd)
    if strip(res[2]) == "End of system activity file unexpected"
        # TODO: Warning, not Error
    else
        @assert length(res[2]) == 0 "stderr: $(res[2])"
    end
    @assert length(res[1]) > 0 "stdout empty!"
    return res[1]
end

# calculates the cross product over the text-columns
function recursiveCross(data, header, startAt = 2)::Array{Tuple{Any, Array{Array{Any,1},1}}}
    data = convert(Array{Array{Any,1}}, data)

    for i in startAt:length(header)
        length(header[i][3]) > 1 || continue
        local classes = Dict{String,Tuple{Int,String,Any}}()
        for label in header[i][3]
            classes[label] = (i, label, [])
        end
        # Sort rows into categories
        for row in data
            push!(classes[row[i]][3], row)
        end
        # try to multiply even more
        local classClasses = map(map(x -> x[2], collect(classes))) do x
            map(recursiveCross(x[3], header, i + 1)) do y
                ([y[1]..., (x[1], x[2])], y[2])
            end
        end
        # flatten
        return collect(Base.Iterators.flatten(classClasses))
    end

    return [([], data)]
end


# get sar data from a given day
function getSarDay(command::String, keyword::String, useDate::DateTime)
    local res = []
    local myCommands = SAR_DB[command][3]
    local description = command * "\n" * SAR_DB[command][2]
    local date = Dates.format(useDate, "yyyy-mm-dd ")
    local dayfile = "/var/log/sysstat/sa" * Dates.format(useDate, "dd")
    logger("CMD = $command $keyword", "Getting SAR data for $date", true)
    if keyword == ""
        res = sarExe(setenv(`sar -$command -f $dayfile`, "LC_TIME"=>"C"))
    else
        res = sarExe(setenv(`sar -$command $keyword -f $dayfile`, "LC_TIME"=>"C"))
        description *= "\n$keyword\n" * myCommands[keyword][1]
        myCommands = myCommands[keyword][2]
    end
    # Read it two a 2d structure (Array of Array of Any)
    # Slow but simple.
    local data = map(
        x -> convert(
            Array{Any,1},
            map(x -> strip(x), filter(x -> length(x) > 0, split(x, " "))),
        ),
        filter(x -> length(x) > 0, split(res, "\n")),
    )
    data = data[2:end] # drop title

    # filter out averaging rows
    data = filter(x -> x[1] != "Average:", data)

    # Corruption detection 
    # sometimes some values are corrupted... don't know how this happens
    # but at least you don't want your whole plot to be messed up
    local howMany1 = 0
    for i in 1:length(data)
        local found = false

        if data[i][1] == "01:00:00"
            howMany1 += 1
            if howMany1 >= SYSSTAT_CORRUPTION_MARGIN
                found = true
            end
        end

        for el in data[i][2:end]
            if isNumericString(el) && parse(Float64, el) >= SYSSTAT_CORRUPTION_THRESHOLD
                found = true
            end
        end
        if found
            logger("", "Found some strange systemctl values at $useDate. Ignored them.", true)
            logger(data[max(1, i-SYSSTAT_CORRUPTION_MARGIN)+1:end], "Removed these values", false)

            data = data[1:max(1, i-SYSSTAT_CORRUPTION_MARGIN)]

            break
        end
    end
    # TODO: Error log for removed values

    # Parse Dates
    map(x -> begin
        x[1] = DateTime(date * x[1], "yyyy-mm-dd HH:MM:SS")
        x
    end, data)

    @assert length(data) > 0

    # The dates are always increasing, but might continue on the next day. So fix this.
    local lastDate = data[1][1]
    for i in 1:length(data)
        if data[i][1] < lastDate
            data[i][1] += Dates.Day(1)
        end
        lastDate = data[i][1]
    end

    # filter point data, like reboot
    local points = []
    data = filter(x -> begin
        if length(x[2]) >= 5 && x[2][1:5] == "LINUX"
            #@assert length(x) == 2 "invalid LINUX row: $x"
            push!(points, [x[1], join(x[2:end], " ")])
            return false
        end
        #@assert length(x) == length(header) "invalid row length: $x"
        return true
    end, data)

    local header = copy(data[1])
    for x in data
        @assert length(x) == length(header) "invalid row length: $x $header"
    end

    # filter duplicate title rows
    data = filter(x -> x[2:end] != header[2:end], data)

    return description, header, convert(Array{Array{Any,1},1}, data) , myCommands, points
end

# extracts sar data for the given command and keyword for the last days
# and returns 
# - a list of parsed data tables as array of array, where the first columns 
#   is dates and the other ones are text (can be ignored) or Float64
# - points, like "LINUX RESTART"
# - labels for the columns
# - description, what the command did
function collectData(command::String, keyword::String, days::Int, today::DateTime)
    # Collect sar data for several days
    local description, header, myCommands = nothing, nothing, nothing
    local data = []
    local points = []
    for day in 0:days-1
        logException(
            _ -> begin
                local description2, header2, data2, myCommands2, points2 =
                    getSarDay(command, keyword, today - Dates.Day(day))
                @assert header == nothing || header[2:end] == header2[2:end] "$header $header2"
                @assert description == nothing || description == description2
                @assert myCommands == nothing || myCommands == myCommands2
                data = [data2..., data...]
                points = [points2..., points...]
                description = description2
                header = header2
                myCommands = myCommands2
            end,
            "getting sar data from $day days before",
        )
    end

    # detect row types (label or numerical)
    for i in 2:length(header)
        #@assert header[i] in keys(myCommands) "coudln't find $(header[i]) in $(keys(myCommands))"
        header[i] in keys(myCommands) ||
        logger("", "coudln't find $(header[i]) in $(keys(myCommands))")
        if header[i] ∉ keys(myCommands)
            myCommands[header[i]] = ""
        end

        if isNumericString(data[1][i])
            # parse everything if it is numerical
            map(x -> begin
                x[i] = parse(Float64, x[i])
                x
            end, data)
            header[i] = (header[i], myCommands[header[i]], [])
        else
            # collect labels if it is text
            local labels = Set{String}()
            for row in data
                push!(labels, row[i])
            end
            header[i] = (header[i], myCommands[header[i]], labels)
        end
    end

    # cross product along labels
    local datas = convert(Array{Any,1}, recursiveCross(data, header))

    # remove duplicates and log results
    for i in 1:length(datas)
        local data = datas[i]
        datas[i] = (map(data[1]) do x
            (header[x[1]][1], header[x[1]][2], x[2])
        end, unique(data[2]))
        data = datas[i]

        logger(
            "length = $(length(data[2]))\nlabels = $(data[1])\nCMD = $command $keyword\npoints = $(length(points))\ndescription = $description",
            "Created sar table",
        )
        #for d in data[2] println(d) end
    end

    return datas, points, header, description
end




function collectData(command::String, keyword::String, from::DateTime, to::DateTime)
    local days = Dates.days(to - from - Dates.Millisecond(1)) + 1

    local datas, points, header, description = collectData(command, keyword, days, to)

    for data in datas
        data = (data[1], filter(x -> from <= x[1] <= to, data[2]))
    end
    points = filter(x -> from <= x[1] <= to, points)

    return datas, points, header, description
end


function fetchContext!(
    store::DataStore,
    attribute::Sysstat,
    from::DateTime,
    to::DateTime,
)::Dict{String, DataAttributeContext}

    local fqn = ("Sysstat", attribute.property)
    if fqn in keys(store.data)
        return Dict(k=>v[1] for (k,v) in store.data[fqn])
    end

    local cmd, keyword = getCommand(attribute)
    local datas, points, header, description = collectData(cmd, keyword, from, to)

    for p in points
        local i = ("Sysstat", p[2])
        if i ∉ keys(store.points)
            store.points[i] = []
        end
        push!(store.points[i], p[1])
    end

    for h in header[2:end]
        if length(h[2]) > 0
            store.descriptions[("Sysstat", h[1])] = h[2]
        end
    end

    local srcCtx = Dict{String, DataAttributeContext}()
    local localCtx
    for i in 2:length(header)
        fqn = ("Sysstat", header[i][1])
        store.data[fqn] = Dict()
        for data in datas
            local values = pseudoColumn(data[2], i)
            if length(header[i][3]) == 0
                values = convert(Array{Float64,1}, values)
            else
                logger("", "Scipping text column $(header[i][1])", true)
                continue
            end

            localCtx = DataAttributeContext(Set(map(
                x -> ("Sysstat", "$(x[1])", "$(x[3])"),
                data[1],
            )))
            srcCtx["$localCtx"] = localCtx

            store.data[fqn]["$localCtx"] =
                (localCtx, pseudoColumn(data[2], 1), values)
        end
    end

    return srcCtx
end


function fetchData!(
    store::DataStore,
    attribute::Sysstat,
    ctx::DataAttributeContext,
    from::DateTime,
    to::DateTime,
)::Tuple{Array{DateTime,1},Array{Float64,1},Tuple{String,String}}

    #@assert "$(typeof(attribute))" == "Sysstat" "$(typeof(attribute)) Sysstat"

    local fqn = ("Sysstat", attribute.property)

    @assert fqn in keys(store.data) "$fqn in $(keys(store.data))"
    @assert "$ctx" in keys(store.data[fqn]) "$ctx in $(keys(store.data[fqn]))"

    local myData = store.data[fqn]["$ctx"]
    
    myData = filter(x -> from <= x[1] <= to, collect(zip(myData[2], myData[3])))

    return pseudoColumn(myData, 1), pseudoColumn(myData, 2), fqn
end

function getPoints(store::DataStore, from::DateTime, to::DateTime)
    return filter(
        v -> length(last(v)) > 0,
        Dict(key => filter(x -> from <= x <= to, value) for (key, value) in store.points),
    )
end
