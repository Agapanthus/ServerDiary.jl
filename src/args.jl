using ArgParse

struct StatsArgsException
    msg::String
end


function error_handler(settings::ArgParseSettings, err, err_code::Int = 1)
    println(stderr, err.text)
    println(stderr, usage_string(settings))
    # exit(err_code)
    throw(StatsArgsException(err.text))
end

function getArguments()
    try
        s = ArgParseSettings()
        s.exc_handler = error_handler
        @add_arg_table s begin
            #"--email"
            #    help = "the e-mail-address to which the report should be send"
            #    arg_type = String
            #    default = "asd"

            "email"
                help = "the e-mail-address to which the report should be send"
                required = true
        end

        return parse_args(s)
    catch exception
        # TODO: Dev only!
        return Dict("email" => "accounting@skaliks.dev")
    end
end