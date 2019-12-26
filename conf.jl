# Positive: number of ticks. Negative: Distance in hours between ticks
const NUMBER_OF_TICKS = -3

# Hide the most extreme outliers, 0=disabled
# const CUT_N_TIMES_MEAN = 0

include(joinpath(@__DIR__, "src", "queryStructure.jl"))

# if no size is given, this size is used for the plot
const DEFAULT_SIZE = (1400, 430)

# List of all commands and keywords to generate graphs for
global QUERY = Array{QWidget,1}([

    QPlot(
        "CPU",
        days = 3,
        data = [QStack([
            Sysstat("%steal"),
            Sysstat("%iowait"),
            Sysstat("%system"),
            QStyled(Sysstat("%nice"), Dict("fillalpha" => 0.2)),
            Sysstat("%user"),
        ])]
    ),

    #=
    QPlot(
        "I/O",
        days = 3,
        data = [
            QStack([Sysstat("tps"), Sysstat("rtps"), Sysstat("wtps")]),
            QGroup("blocks/s", data = [Sysstat("bread/s"), Sysstat("bwrtn/s")]),
        ],
    ),

    QPlot(
        "CPU",
        days = 3,
        data = [QGroup(
            "%",
            min = 0,
            max = 100,
            data = [
                QStack([
                    Sysstat("%steal"),
                    Sysstat("%iowait"),
                    Sysstat("%system"),
                    QStyled(Sysstat("%nice"), Dict("fillalpha" => 0.2,)),
                    Sysstat("%user"),
                ]),
            ],
        )],
    ),
    =#

    # TODO: Monthly view


    #["CPU", "u", ""],

    #["I/O", "b", ""],

    #=
    ["Network Devices", "n", "DEV"],   
                                        

    ["", "F", ""], 
    ["RAM", "r", ""], 
    ["Swap", "S", ""], 

    ["", "v", ""], 
    ["", "w", ""], 
    ["", "y", ""],
                                     
    ["", "q", ""], 
                                     
    ["", "n", "EDEV"], 
    ["", "n", "IP"], 
    ["", "n", "EIP"], 
    ["", "n", "IP6"], 
    ["", "n", "SOCK"], 
    ["", "n", "TCP"], 
    ["", "n", "UDP"],
                                     
    ["", "d", ""], 
    ["", "B", ""], 
    ["", "H", ""], 
                                     
    ["CPU", "m", "CPU"], 
    ["Fan", "m", "FAN"], 
    ["Temperature", "m", "TEMP"], 
    ["Frequency", "m", "FREQ"]
    =#

])

# Any subset of these properties occuring in one plot is stacked+filled
#global STACKED = [
#    ["%steal", "%iowait", "%system", "%nice", "%user"],
#    ["tps", "rtps", "wtps"],
#]

# Add some special styling to some data columns
#
# you can override any defaults using this
#   fillrange: nothing to prevent filling (for example when stacked) or a float to fill towards this number
#   color: line color
#   fillcolor: fill color
#   fillalpha: fill alpha
# 
#global STYLES = Dict{String,Dict{String,Any}}(
#    "%user" => Dict("fillalpha"=>0.2),
#)

# Color Theme
# See https://github.com/JuliaPlots/PlotThemes.jl
global PLOT_THEME = :wong

# Show the last n days in the plot.
const SHOW_DAYS = 3

const MAKE_OVERVIEW = true
const OVERVIEW_WIDTH = DEFAULT_SIZE[1] ÷ 3
const OVERVIEW_HEIGHT = DEFAULT_SIZE[2] ÷ 3
