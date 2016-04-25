const LOCALZONE = localzone()

immutable Tz
   isvalid::Int8
   hour::Int8
   minute::Int8
end

# parse a timezone agnostic datetime
function parsedate(s)
    useconds = ccall((:parseiso8601, libfdt), Int64, (Ptr{UInt8}, Ptr{Void}), s, C_NULL)
    DateTime(Base.Dates.UTM(Base.Dates.Millisecond(div(useconds, 1000))))
end
parsedate{T<:AbstractString}(a::Vector{T}) = map(parsedate, a)

# parse a timezone aware datetime
function parsedatetz(s)
    tz = Tz(0,0,0)
    useconds = ccall((:parseiso8601, libfdt), Int64, (Ptr{UInt8}, Ptr{Void}), s, pointer_from_objref(tz))
    d = DateTime(Base.Dates.UTM(Base.Dates.Millisecond(div(useconds, 1000))))
    if tz.isvalid == 1
        z = FixedTimeZone("", TimeZones.Offset(tz.hour*60*60 + tz.minute*60, 0))
    else
        z = LOCALZONE
    end
    ZonedDateTime(d, z)
end
parsedatetz{T<:AbstractString}(a::Vector{T}) = map(parsedatetz, a)
