using Chrono
using TimeZones
using Base.Test

let s = "2014-01-09T21:48:00.921000"
    @test parsedate(s) == DateTime(s)
end

let s = "2014-01-09T21:48:00.921000+05:30"
    tzd = parsedatetz(s)
    utct = string(ZonedDateTime(tzd, TimeZone("UTC")))
    utct = utct[1:(length(utct)-6)]
    @test tzd.utc_datetime == DateTime(utct)
end

function test_durations()
    h2 = Hours(2)
    @test (h2 + h2) == Hours(4)
    d3 = Days(3)
    @test (h2 + d3) == Hours(74)
    @test convert(Hours, h2) == h2
    @test convert(Seconds, h2) == Seconds(7200)
    @test div(d3, h2) == Hours(36)
    @test rem(d3, h2) == Hours(0)
    @test rem(d3, Hours(5)) == Hours(2)
    @test (d3 < h2) == false
    @test (d3 == h2) == false
    @test d3 != h2
    @test d3 !== h2
    @test d3 > h2
    @test d3 > Hours(48)
    @test (d3 > Hours(72)) == false
    @test d3 >= Hours(72)
    @test d3 == Hours(72)
    @test isequal(d3, Hours(72))
end

test_durations()
