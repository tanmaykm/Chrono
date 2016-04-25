module Chrono

using TimeZones

export parsedate, parsedatetz
export Years, Months, Weeks, Days, Hours, Minutes, Seconds, Milliseconds
export Year, Month, Day, Weekday, NthWeekday, WeekdayLast, Monthday, MonthdayLast, MonthWeekday, MonthWeekdayLast
export YearMonth, YearMonthday, YearMonthdayLast, YearMonthWeekday, YearMonthWeekdayLast
export isok
export jan, feb, mar, apr, may, jun, jul, aug, sep, oct, nov, dec
export sun, mon, tue, wed, thu, fri, sat

const depfile = joinpath(dirname(@__FILE__), "..", "deps", "deps.jl")
if isfile(depfile)
    include(depfile)
else
    error("Chrono not properly installed. Please run Pkg.build(\"Chrono\")")
end

include("parse.jl")
include("utils.jl")

end # module
