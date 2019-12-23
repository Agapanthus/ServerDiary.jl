using Base64
using Random

mutable struct Email
    parts::Array{String,1}
    body::String
    cidId::Int
    overview::String
end

Email() = Email([], "", 1, "")

function finish(email::Email, to::String, subject::String)

    local boundary = "----------" * randstring(14)    
    local boundaryA = "----------" * randstring(14)

    local moreParts = ""
    for part in email.parts
        moreParts *= "\n--$boundary\n"
        moreParts *= part
    end

    # return the E-Mail

    return """To: $to
Subject: $subject
MIME-Version: 1.0
Content-Type: multipart/alternative;
    boundary="$boundaryA"
Content-Language: en-US

This is a multi-part message in MIME format.
--$boundaryA
Content-Type: text/plain; charset=utf-8; format=flowed
Content-Transfer-Encoding: 7bit

Message is in the HTML Section.


--$boundaryA
Content-Type: multipart/related;
    boundary="$boundary"


--$boundary
Content-Type: text/html; charset=utf-8
Content-Transfer-Encoding: 7bit

<html>
    <head>
    <meta http-equiv="content-type" content="text/html; charset=UTF-8">
    <style>
    .time {
        color: grey;
    }
    .body {
        color: blue;
    }
    .details {
        color: black;
    }
    .error {
        color: red;
        font-weight: bold;
    }
    </style>
    </head>
    <body>
    <p>
        $(email.overview)
    </p>
    $(email.body)
    </body>
</html>

$moreParts
--$boundary--

--$boundaryA--
"""

end

function appendGraphToEmail(email, path, header, description)
    local cid = "part$(email.cidId).06090408.01060107"
    email.cidId += 1

    header = header[2:end]
    email.body *= "<p>" * replace("$description", "\n"=>"\n<br>") * "</p><p><img src=\"cid:$cid\" alt=\"\"></p><p>\n" * reduce(*, map(x->"$(x[1]) - $(x[2]) <br>\n", header)) * "</p>"

    email.overview *= "<img src=\"cid:$cid\" alt=\"\" height=\"$(HEIGHT÷3)\" width=\"$(WIDTH÷3)\">"

    # Encode the image file
    local io = IOBuffer();
    local iob64_encode = Base64EncodePipe(io);
    open(path) do file
        local str =  read(file)
        write(iob64_encode, str)
    end
    close(iob64_encode);
    local base64 = String(take!(io))

    push!(email.parts, """Content-Type: image/png;
    name="file.png"
Content-Transfer-Encoding: base64
Content-ID: <$cid>
Content-Disposition: inline;
    filename="file.png"

$base64
""")

    return email
end
