#!/usr/bin/env julia

# Positive: number of ticks. Negative: Distance in hours between ticks
const NUMBER_OF_TICKS = -3

using Colors
# For color preview, look here: https://www.december.com/html/spec/colorsvg.html

include("src/structures.jl")

# if no size is given, this size is used for the plot
const DEFAULT_SIZE = (1400, 430)

# make nights slightly blue
const DRAW_NIGHT_BACKGROUND = true

# List of all commands and keywords to generate graphs for
global QUERY = Array{QWidget,1}([

    #=
    QPlot(
        "Demoplot",
        days = 5,
        data = [
            QGroup(
                "packets/s",
                log = true,
                data = [
                    QStack([
                        QStyle(Sysstat("wtps"), Dict("color" => :red)),
                        QStyle(Sysstat("rtps"), Dict("color" => :royalblue))
                    ]), 
                    QStyle(Sysstat("tps"), Dict("color" => :navy))
                ],
            ),
            QStyle(
                QGroup(
                    "blocks/s",
                    data = [Sysstat("bread/s"), Sysstat("bwrtn/s")]
                ),
                Dict("fillrange" => 0, "fillalpha" => 0.2),
            ),
        ],
    ),
    =#
    



    QPlot(
        "I/O",
        days = 3,
        data = [
            QGroup(
                "packets/s",
                log = true,
                data = [
                    QStack([
                        QStyle(Sysstat("wtps"), Dict("color" => :red)),
                        QStyle(Sysstat("rtps"), Dict("color" => :royalblue))
                    ]), 
                    # QStyle(Sysstat("tps"), Dict("color" => :navy))
                ],
            ),
            QGroup(
                "blocks/s",
                data = [
                    QStyle(QStack([
                        QStyle(Sysstat("bread/s"), Dict("color" => :navy)), 
                        QStyle(Sysstat("bwrtn/s"), Dict("color" => :maroon))
                    ]), Dict("fillalpha" => 0.4))
                ],
            ),
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
                    Sysstat("%nice"),
                    Sysstat("%iowait"),
                    Sysstat("%system"),
                    Sysstat("%user"),
                ]),
            ],
        )],
    ),

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

# Color Theme
# See https://github.com/JuliaPlots/PlotThemes.jl
global PLOT_THEME = :default # :wong

# Show the last n days in the plot.
const SHOW_DAYS = 3

const MAKE_OVERVIEW = true
const OVERVIEW_WIDTH = DEFAULT_SIZE[1] ÷ 3
const OVERVIEW_HEIGHT = DEFAULT_SIZE[2] ÷ 3

# Sysstat Corruption detection
const SYSSTAT_CORRUPTION_THRESHOLD = 1_000_000_000_000
const SYSSTAT_CORRUPTION_MARGIN = 4

const USE_PNGQUANT = true