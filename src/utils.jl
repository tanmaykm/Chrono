import Base: promote_rule, convert, show, *, +, -, div, rem, <, >, <=, >=, ==, isequal, !=, getindex, /

shownth(n) = (n == 1) ? "st" : (n == 2) ? "nd" : (n == 3) ? "rd" : "th" 

# Serial based time points
#
# Duration: time interval
# Epoch: beginning of time
# Timepoint: a point in time relative to epoch
#
# Epochs can have different values based on the kind of clock being used.
# So, timepoints referring to different epochs can't be compared only based on their durations.
# But if all timepoints we deal with are with respect to the same epoch/clock,
#   we can consider durations to effectively be same as timepoints, and
#   not have a timepoint type at all.
abstract Duration{N,T}

immutable Milliseconds <: Duration{1}
    ticks::Int64
end

immutable Seconds <: Duration{1000,Milliseconds}
    ticks::Int64
end

immutable Minutes <: Duration{60,Seconds}
    ticks::Int64
end

immutable Hours <: Duration{60,Minutes}
    ticks::Int64
end

immutable Days <: Duration{24,Hours}
    ticks::Int64
end

immutable Weeks <: Duration{7,Days}
    ticks::Int64
end

immutable Years <: Duration{146097//400,Days}
    ticks::Int64
end

immutable Months <: Duration{1//12,Years}
    ticks::Int64
end

promote_rule{N,T}(::Type{Duration{N,T}}, ::Type) = Duration{N,T}

promote_rule{T}(::Type{Milliseconds}, ::Type{T}) = Milliseconds
promote_rule{T<:Union{Years,Months,Weeks,Days,Hours,Minutes}}(::Type{Seconds}, ::Type{T}) = Seconds
promote_rule{T<:Union{Years,Months,Weeks,Days,Hours}}(::Type{Minutes}, ::Type{T}) = Minutes
promote_rule{T<:Union{Years,Months,Weeks,Days}}(::Type{Hours}, ::Type{T}) = Hours
promote_rule{T<:Union{Years,Months,Weeks}}(::Type{Days}, ::Type{T}) = Days
promote_rule{T<:Union{Years,Months}}(::Type{Weeks}, ::Type{T}) = Weeks
promote_rule(::Type{Months}, ::Type{Years}) = Months

for f in (Milliseconds, Seconds, Minutes, Hours, Days, Weeks, Months, Years)
    @eval convert(::Type{$f}, d::$f) = d
end
function convert{N,T<:Duration}(::Type{T}, d::Duration{N,T})
    @show "convert Duration{$N,$T} to $T"
    @show x = d.ticks * N
    T(d.ticks * N)
end
function convert{N,T1<:Duration,T2<:Duration}(::Type{T1}, d::Duration{N,T2})
    @show "T1: $T1, T2: $T2, d: $d"
    convert(T1, convert(T2, d))
end

show{T<:Duration}(io::IO, d::T) = print(io, d.ticks, " ", lowercase(string(T)))

for f in (:+, :-, :div, :rem)
    @eval begin
        ($f){T<:Duration}(d1::T, d2::T) = T(($f)(d1.ticks, d2.ticks))
        function ($f){T1<:Duration,T2<:Duration}(d1::T1, d2::T2)
            T = promote_type(T1, T2)
            ($f)(convert(T, d1), convert(T, d2))
        end
    end
end

for f in (:<, :>, :<=, :>=, :isequal, :!=)
    @eval begin
        ($f){T<:Duration}(d1::T, d2::T) = ($f)(d1.ticks, d2.ticks)
        function ($f){T1<:Duration,T2<:Duration}(d1::T1, d2::T2)
            T = promote_type(T1, T2)
            ($f)(convert(T, d1), convert(T, d2))
        end
    end
end

=={T<:Duration}(d1::T, d2::T) = (d1.ticks == d2.ticks)
function =={T1<:Duration,T2<:Duration}(d1::T1, d2::T2)
    T = promote_type(T1, T2)
    ==(convert(T, d1), convert(T, d2))
end

for f in (:div, :rem)
    @eval ($f){T<:Duration,I<:Integer}(d1::T, c::I) = T(($f)(d1.ticks, c))
end
*{T<:Duration,I<:Integer}(d::T, c::I) = T(*(d.ticks, c))
*{T<:Duration,I<:Integer}(c::I, d::T) = T(*(c, d.ticks))


# Field based day points

# day of the month
# values: valid: 1:31, allowed: 0:255
immutable Day
    val::UInt8
end
Day(d::Day) = d

# month number
# values: valid: 1:12 for jan:dec, allowed: 0:255
immutable Month
    val::UInt8
end
Month(m::Month) = m

# year
# values: valid: 0:65535
immutable Year
    val::UInt16
end
Year(y::Year) = y

for (T1,T2) in (Day=>Days, Month=>Months, Year=>Years)
    for f in (:+, :-)
        @eval begin
            ($f)(v1::($T1), v2::($T2)) = ($T1)(($f)(v1.val, v2.ticks))
            ($f)(v2::($T2), v1::($T1)) = ($T1)(($f)(v1.val, v2.ticks))
        end
    end
    @eval -(v1::($T1), v2::($T1)) = ($T2)(Int64(v1.val) - Int64(v2.val))
    @eval show(io::IO, d::($T1)) = print(io, Int(d.val))
    @eval convert{I<:Integer}(::Type{$T1}, i::I) = ($T1)(i)
end

for (v,n) in enumerate((:jan, :feb, :mar, :apr, :may, :jun, :jul, :aug, :sep, :oct, :nov, :dec))
    @eval const ($n) = Month($v)
end

# day of the week
# values: valid: 1:7 for sun-sat
immutable Weekday
    val::UInt8
end
function +(v1::Weekday, v2::Days)
    wd = v1.val + v2.ticks
    Weekday((wd > 7) ? rem(wd, 7) : wd)
end 
+(v2::Days, v1::Weekday) = +(v1, v2)
-(v1::Weekday, v2::Weekday) = Days(abs(Int64(v1.val) - Int64(v2.val)))
convert{I<:Integer}(::Type{Weekday}, i::I) = Weekday(i)

for (v,n) in enumerate((:sun, :mon, :tue, :wed, :thu, :fri, :sat))
    @eval const ($n) = Weekday($v)
end

for (T,r) in (Day=>(1:31), Month=>(1:12), Weekday=>(1:7))
    @eval isok(v::($T)) = (v.val in $r)
end
isok(v::Year) = true
show(io::IO, w::Weekday) = print(io, string((:sun, :mon, :tue, :wed, :thu, :fri, :sat)[w.val]))

# first, second, third, fourth or fifth weekday of a month
immutable NthWeekday
    nth::UInt8
    wd::Weekday
end
isok(v::NthWeekday) = ((v.nth in 1:5) && isok(wd))
getindex{I<:Integer}(v::Weekday, nth::I) = NthWeekday(UInt8(nth), v)
show(io::IO, w::NthWeekday) = print(io, w.wd, "[", Int(w.nth), "]") 

# last weekday of a month
immutable WeekdayLast
    wd::Weekday
end
show(io::IO, w::WeekdayLast) = print(io, w.wd, "[last]")
function getindex(v::Weekday, l::Symbol)
    if l == :last
        return WeekdayLast(v)
    end
    error("Invalid Weekday $l")
end

# specific day of a specific month (of an yet unspecified year)
immutable Monthday
    month::Month
    day::Day
end

# last day of the month (of an yet unspecified year)
immutable MonthdayLast
    month::Month
end
show(io::IO, v::MonthdayLast) = print(io, v.month, "[last]")
convert(::Type{MonthdayLast}, m::Month) = MonthdayLast(m)
convert{I<:Integer}(::Type{MonthdayLast}, m::I) = MonthdayLast(Month(m))
function getindex(v::Month, l::Symbol)
    if l == :last
        return MonthdayLast(v)
    end
    error("Invalid Monthday $l")
end

# first, second, third, fourth or fifth weekday of the specified month (of an yet unspecified year)
immutable MonthWeekday
    month::Month
    nth::NthWeekday
end

# the last weekday of a month (of an yet unspecified year)
immutable MonthWeekdayLast
    month::Month
    wd::WeekdayLast
end

# month of a year
immutable YearMonth
    year::Year
    month::Month
end

# a year, month, and day specification
immutable YearMonthday
    year::Year
    mday::Monthday
end
YearMonthday(y, m, d) = YearMonthday(Year(y), Monthday(Month(m), Day(d)))

immutable YearMonthdayLast
    year::Year
    mday::MonthdayLast
end

immutable YearMonthWeekday
    year::Year
    mday::MonthWeekday
end
YearMonthWeekday(y, m, d::NthWeekday) = YearMonthWeekday(Year(y), MonthWeekday(Month(m), d))

immutable YearMonthWeekdayLast
    year::Year
    mday::MonthWeekdayLast
end
YearMonthWeekdayLast(y, m, d::WeekdayLast) = YearMonthWeekdayLast(Year(y), MonthWeekdayLast(Month(m), d))

/(m::Month, d::Day) = Monthday(m, d)
/{I<:Integer}(m::Month, d::I) = Monthday(m, d)
/{I<:Integer}(m::I, d::Day) = Monthday(m, d)

/{I<:Integer}(y::Year, m::I) = YearMonth(y, m)
/(y::Year, m::Month) = YearMonth(y, m)
/{I<:Integer}(y::I, m::Month) = YearMonth(y, m)
/(y::Year, m::MonthdayLast) = YearMonthdayLast(y, m)
/{I<:Integer}(y::I, m::MonthdayLast) = YearMonthdayLast(y, m)
/(y::YearMonth, d::Day) = YearMonthday(y.year, y.month, d)
/{I<:Integer}(y::YearMonth, d::I) = YearMonthday(y.year, y.month, d)
/(y::YearMonth, d::NthWeekday) = YearMonthWeekday(y.year, y.month, d)
/(y::YearMonth, d::WeekdayLast) = YearMonthWeekdayLast(y.year, y.month, d)

typealias OkDelegate Union{WeekdayLast, Monthday, MonthdayLast, MonthWeekday, MonthWeekdayLast, YearMonth, YearMonthday, YearMonthdayLast, YearMonthWeekday, YearMonthWeekdayLast}
@generated function isok{T<:OkDelegate}(v::T)
    ex = :(true)
    names = map(string, fieldnames(T))
    for f in names
        ex = :(isok(getfield(v, symbol($f))) && $ex)
    end
    ex
end

typealias CompareDelegate Union{Day, Month, Year}
@generated function _cmp{T<:CompareDelegate}(v1::T, v2::T, fn::Function)
    ex = :()
    names = reverse!(map(string, fieldnames(T)))
    for f in names
        if ex == :()
            ex = :(fn(getfield(v1, symbol($f)), getfield(v2, symbol($f))))
        else
            ex = :((getfield(v1, symbol($f)) == getfield(v2, symbol($f))) ? ex : fn(getfield(v1, symbol($f)), getfield(v2, symbol($f))))
        end
    end
    ex
end

for T in (Day, Month, Year, Monthday, MonthdayLast, YearMonth, YearMonthday, YearMonthdayLast)
    for f in (:<, :>, :<=, :>=)
        @eval begin
            ($f)(v1::($T), v2::($T)) = _cmp(v1, v2, $f)
        end
    end
end

typealias ShowDelegate Union{Monthday, MonthWeekday, MonthWeekdayLast, YearMonth, YearMonthday, YearMonthdayLast, YearMonthWeekday, YearMonthWeekdayLast}
function show{T<:ShowDelegate}(io::IO, v::T)
    vals = map((n)->getfield(v, n), fieldnames(T))
    print(io, join(vals, "/"))
end

