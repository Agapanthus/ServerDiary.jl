using Base64
using Random

# Will convert all relative links in th E-Mail to cid links 
# and return a list of HTML-multipart sections containing the images
function encodeImages(html::String, imgPath::String)::Tuple{String, Array{String,1}}

    local pos = 1    
    local plotId = 1
    local parts = []

    while true
        local range = findnext(r"src=\"[^\"]+\"", html, pos)
        range === nothing && break
        pos = range.start + 5

        # Base64-encode the image file
        local io = IOBuffer();
        local iob64_encode = Base64EncodePipe(io);
        open( joinpath(imgPath, html[range][6:end-1]) ) do file
            local str =  read(file)
            write(iob64_encode, str)
        end
        close(iob64_encode);
        local base64 = String(take!(io))

        # Generate a beautiful cid
        local cid = "plot$(plotId)"
        plotId += 1

        push!(parts, """Content-Type: image/png;
 name="file.png"
Content-Transfer-Encoding: base64
Content-ID: <$cid>
Content-Disposition: inline;
 filename="file.png"

$base64
""")

        html = replace(html, html[range]=>"src=\"cid:$cid\"", count=1)
    end

    return html, parts
end

# given a html and a path relative to which images can be found on the disk,
# generate a e-mail with given subject and recipient
function makeEmail(html::String, imgPath::String, to::String, subject::String)::String
    logger("subject=$subject, to=$to", "Generating Email")
    local html2, parts = encodeImages(html, imgPath)

    # we have two kinds of boundaries - those of the "multipart/alternative" and 
    # those of the embedded "multipart/related"
    local boundary = "----------" * randstring(14)    
    local boundaryA = "----------" * randstring(14)

    # insert boundary between parts
    local moreParts = ""
    for part in parts
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

$html2

$moreParts
--$boundary--

--$boundaryA--
"""

end
