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

    QPlot(
        "Network",
        days = 3,
        data = [
            QGroup(
                "kB",
                log = true,
                min = 1,
                data = [QStack([Sysstat("txpck/s"), Sysstat("rxpck/s")], ctxs = [])],
            ),
            QGroup("%", min = 0, max = 100, ctxs = [], data = [Sysstat("%ifutil")]),
        ],
    ),

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
                        QStyle(Sysstat("rtps"), Dict("color" => :royalblue)),
                    ]),
                    # QStyle(Sysstat("tps"), Dict("color" => :navy))
                ],
            ),
            QGroup(
                "blocks/s",
                data = [QStyle(
                    QStack([
                        QStyle(Sysstat("bread/s"), Dict("color" => :navy)),
                        QStyle(Sysstat("bwrtn/s"), Dict("color" => :maroon)),
                    ]),
                    Dict("fillalpha" => 0.4),
                )],
            ),
        ],
    ),

    QPlot(
        "CPU Long",
        days = 30,
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
                QStyle(Sysstat("%memused"), Dict("color" => :red)),
            ],
        )],
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
                QStyle(Sysstat("%memused"), Dict("color" => :red)),
            ],
        )],
    ),

    QPlot(
        "RAM",
        days = 3,
        data = [
            QGroup(
                "kB",
                data = [
                    Sysstat("kbdirty"),
                    QStack([
                        #Sysstat("kbswpused"), # TODO: I want this!
                        Sysstat("kbinact"),
                        Sysstat("kbactive"),
                        QStyle(
                            Sysstat("kbavail"),
                            Dict("color" => :lightblue, "fillrange" => nothing),
                        ),
                    ]),
                ],
            ),
            QGroup(
                "%",
                min = 0,
                data = [
                #QStyle(Sysstat("%memused"), Dict("color"=>:darkmagenta)),
                QStyle(Sysstat("%commit"), Dict("color" => :red))],
            ),
        ],
    ),

    QPlot(
        "Handles",
        days = 3,
        data = [
            QGroup(
                "Number",
                min = 0,
                max = 50,
                data = [QStack([QStyle(
                    Sysstat("pty-nr"),
                    Dict("color" => :darkmagenta, "fillalpha" => 0.3),
                )])],
            ),
            QGroup(
                "Number",
                min = 0,
                data = [
                    QStack([Sysstat("file-nr"), Sysstat("inode-nr")]),
                    Sysstat("dentunusd"),
                ],
            ),
        ],
    ),


    QPlot(
        "Task Creation & Context Switches",
        days = 3,
        data = [
            QGroup("Number / s", min = 0, data = [QStack([Sysstat("cswch/s")])]),
            QGroup("Number / s", min = 0, data = [QStack([Sysstat("proc/s")])]),
        ],
    ),


    QPlot(
        "Network failures",
        days = 3,
        data = [
            QGroup(
                "Number / s",
                min = 0,
                ctxs = [],
                data = [
                    QStack([
                        Sysstat("coll/s"),
                        Sysstat("rxerr/s"),
                        Sysstat("txerr/s"),
                        Sysstat("rxdrop/s"),
                        Sysstat("txdrop/s"),
                        Sysstat("txcarr/s"),
                        Sysstat("rxfram/s"),
                        Sysstat("rxfifo/s"),
                        Sysstat("txfifo/s"),
                    ]),
                ],
            ),
        ],
    ),

    QPlot(
        "Sockets",
        days = 3,
        data = [
            QGroup(
                "Number",
                min = 0,
                data = [
                    Sysstat("totsck"),
                    QStack([Sysstat("tcpsck"), Sysstat("udpsck"), Sysstat("rawsck")]),
                    Sysstat("tcp-tw"),
                ],
            ),
            QGroup("Number", min = 0, data = [QStack([Sysstat("ip-frag")])]),
        ],
    ),

    QPlot(
        "Disk I/O",
        days = 3,
        data = [
            QGroup(
                "kB",
                log = true,
                data = [QStack([Sysstat("wkB/s"), Sysstat("rkB/s")], ctxs = [])],
            ),
            QGroup("%", min = 0, max = 100, ctxs = [], data = [QStack([Sysstat("%util")])]),
        ],
    ),

    #=
    QPlot(
        "AWS UsageQuantity",
        days = 30,
        data = [QGroup("X",
            min = 0,
            data = [
                QStack([
                    Aws("UsageQuantity AWS Lambda"),
                    Aws("UsageQuantity AWS Key Management Service"),
                    Aws("UsageQuantity AWS Cost Explorer"),
                    Aws("UsageQuantity AWS Budgets"),
                    Aws("UsageQuantity Tax"),
                    Aws("UsageQuantity AmazonCloudWatch"),
                    Aws("UsageQuantity Amazon Simple Storage Service"),
                    Aws("UsageQuantity Amazon Simple Notification Service"),
                    Aws("UsageQuantity Amazon DynamoDB"),
                ]),
            ],
        )],
    ),
        
    QPlot(
        "AWS BlendedCost",
        days = 30,
        data = [QGroup("X",
            min = 0,
            max = 0.2, # TODO: "minmax" - scale it down if there isn't much so if the value increases it stands out immediately!
            data = [
                QStack([
                    Aws("BlendedCost AWS Lambda"),
                    Aws("BlendedCost AWS Key Management Service"),
                    Aws("BlendedCost AWS Cost Explorer"),
                    Aws("BlendedCost AWS Budgets"),
                    Aws("BlendedCost Tax"),
                    Aws("BlendedCost AmazonCloudWatch"),
                    Aws("BlendedCost Amazon Simple Storage Service"),
                    Aws("BlendedCost Amazon Simple Notification Service"),
                    Aws("BlendedCost Amazon DynamoDB"),
                ]),
            ],
        )],
    ),
        
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
