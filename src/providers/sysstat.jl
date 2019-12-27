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
function recursiveCross(data, header, startAt = 2)
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
        res = sarExe(`sar -$command -f $dayfile`)
    else
        res = sarExe(`sar -$command $keyword -f $dayfile`)
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

    # filter averaging rows
    data = filter(x -> x[1] != "Average:", data)

    # the last value might be next day
    if length(data) > 1 && data[length(data)÷2][1][1:3] != "00:"
        if data[end][1][1:3] == "00:"
            data[end][1] = "23:59:59"
        end
        if data[end-1][1][1:3] == "00:"
            data[end-1][1] = "23:59:58"
        end
    end

    # Parse Dates
    map(x -> begin
        x[1] = DateTime(date * x[1], "yyyy-mm-dd HH:MM:SS")
        x
    end, data)

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
    #@assert header[1] in ["00:00:01", "00:00:00", "00:00:02"] "first field must be time, but found $(header[1])"

    # filter duplicate title rows
    data = filter(x -> x[2:end] != header[2:end], data)

    return description, header, data, myCommands, points
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
    local description, header, data, myCommands, points = getSarDay(command, keyword, today)
    for day in 1:days-1
        logException(
            _ -> begin
                local description2, header2, data2, myCommands2, points2 =
                    getSarDay(command, keyword, today - Dates.Day(day))
                @assert header[2:end] == header2[2:end] "$header $header2"
                @assert description == description2
                @assert myCommands == myCommands2
                data = [data2..., data...]
                points = [points2..., points...]
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
            myCommands[header[i]] = "unknown"
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
