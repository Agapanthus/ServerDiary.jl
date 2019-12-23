println("Loading Plots...")
@time begin 
    using Plots 
    # Don't try to open windows for the plots
    ENV["GKSwstype"]="nul"
    gr()
    # init it now
    plot([0],[0])
end

using Dates

include(joinpath(@__DIR__, "util.jl"))
include(joinpath(@__DIR__, ".." , "conf.jl"))


function makeDiagram(data, points, header, description, title, saveTo)
    logger(description, "Plotting")

    local first = true
    local dates = map(pseudoColumn(data, 1)) do x
        Dates.value(Dates.DateTime(x)) # To milliseconds
    end

    local mean(x) = reduce(+, map(v->v/length(x),x))
    local limitByNTimesMean(x, mean) = map(v->min(mean*CUT_N_TIMES_MEAN, v), x)
    # mean of all variables
    local totalMean = 0
    if CUT_N_TIMES_MEAN > 0
        totalMean = mean(map(filter(i->length(header[i][3]) == 0, 2:length(header))) do i
            mean(pseudoColumn(data, i))
        end)
    end

    for i in 2:length(header)
        # only numeric columns
        length(header[i][3]) == 0 || continue
        # hidden
        header[i][1] in HIDE && continue

        # prepare values
        local values = pseudoColumn(data, i)
        if CUT_N_TIMES_MEAN > 0
            values = limitByNTimesMean(values, totalMean)
        end
        
        # add to graph
        if first 
            plot(dates, values, label=header[i][1], title=title, size=(WIDTH,HEIGHT), legend=:topleft)
            first = false
        else
            plot!(dates, values, label=header[i][1])
        end
    end

    # group points by label
    local pointClasses = Dict{String, Array{Float64,1}}()
    for point in points
        local v = Dates.value(Dates.DateTime(point[1]))
        if point[2] ∉ keys(pointClasses)
            pointClasses[point[2]] = [v]
        else
            push!(pointClasses[point[2]], v)
        end
    end
    # plot points
    for (label, ps) in pointClasses
        scatter!(ps,[0 for _ in 1:length(ps)], label=label)
    end
    
    # Add x-tick-labels
    local datesTicks = Array{Float64,1}()
    local datesLabels = Array{String,1}()
    sort!(dates)
    local lastDay = 0
    local tickDistance = (dates[end]-dates[1]) ÷ NUMBER_OF_TICKS
    local lastTick = 0
    # add interval and day based ticks
    for date in dates
        local datet = Dates.DateTime(Dates.UTM(date))
        local day = Dates.format(datet, "dd")
        if day != lastDay
            push!(datesLabels, Dates.format(datet, "yy/mm/dd HH:MM"))
            push!(datesTicks, date)
            lastDay = day
            lastTick = date
        elseif NUMBER_OF_TICKS > 0 && date - lastTick >= tickDistance
            push!(datesLabels, Dates.format(datet, "HH:MM"))
            push!(datesTicks, date)
            lastTick = date
        end
    end
    # add hour based ticks
    if NUMBER_OF_TICKS < 0
        local cpDatesTicks = copy(datesTicks)
        for i in 1:length(cpDatesTicks)
            local date = cpDatesTicks[i]
            local now = date
            while now < date + (24+NUMBER_OF_TICKS)*3600*1000 && now < dates[end] && (i == length(cpDatesTicks) || now < cpDatesTicks[i+1]+(NUMBER_OF_TICKS)*3600*1000)
                now -= NUMBER_OF_TICKS*3600*1000
                push!(datesLabels, Dates.format(Dates.DateTime(Dates.UTM(now)), "HH:MM"))
                push!(datesTicks, now)
            end
        end
    end
    plot!(xticks=(datesTicks,datesLabels))

    savefig("$saveTo.png")
end