
# width of images in E-Mail
const WIDTH = 1400
const HEIGHT = 430

# Positive: number of ticks. Negative: Distance in hours between ticks
const NUMBER_OF_TICKS = -3  

# Hide the most extreme outliers, 0=disabled
const CUT_N_TIMES_MEAN = 0

# Hide a single column from plots
global HIDE = ["%idle"]

# List of all commands and keywords to generate graphs for
global QUERY = [    
    ["CPU", "u", ""],
    ["I/O", "b", ""],
    ["Network Devices", "n", "DEV"],   
    
    #=  
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
] 

# Show the last n days in the plot.
const SHOW_DAYS = 3

const MAKE_OVERVIEW = true
const OVERVIEW_WIDTH = WIDTH÷3
const OVERVIEW_HEIGHT = HEIGHT÷3