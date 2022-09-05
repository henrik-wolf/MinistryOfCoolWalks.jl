#= Functions to calculate the sun position, adapted from
    Roberto Grena (2012), Five new algorithms for the computation of sun position
    from 2010 to 2110, Solar Energy, 86(5):1323–1337, doi:10.1016/j.solener.2012.01.024.

    some of the inputs where omitted, since we do not need the precision to launch satellites
    =#

# omitted: TT-UT, pressure, temperature
function sunposition(time, day, month, year, longitude, latitude, timezone=1, daylight_saving=true)
    #=local time in hours. You have to convert miniutes and seconds to fractions of an hour. from 0 to 24.
    longitude in radians from 0 to 2π, starting at greenwith, goint to the east.
    latitude in radians from -π/2 to π/2, starting from the south pole, going north.=#

    ut = time - timezone
    if daylight_saving
        ut -= 1
    end

    t_2060 = date_from_2060(ut, day, month, year)
    right_ascension, declination, hour_angle = algorithm_1(t_2060, longitude)
    elevation, azimuth = get_local_sun_pos(latitude, declination, hour_angle)
    # convert sun position from spherical coordinates to cartesian coordinates
    x = -sin(azimuth) * cos(elevation)
    y = -cos(azimuth) * cos(elevation)
    z = sin(elevation)
    
    return [x,y,z]
end

function date_from_2060(ut, day, month, year)
    if month <= 2
        m̃ = month + 12
        ỹ = year - 1
    else
        m̃ = month
        ỹ = year
    end
    t = trunc(365.25 * (ỹ - 2000)) + trunc(30.6001 * (m̃ + 1)) - trunc(0.01ỹ) + day + ut/24 - 21958
    # universal time
    return t
end

function algorithm_1(t_2060, longitude)
    # assuming t = t_e for all our usecases
    ω_t = 0.017202786 * t_2060
    s1 = sin(ω_t)
    c1 = cos(ω_t)
    s2 = 2 * s1 * c1
    c2 = (c1 + s1) * (c1 - s1)

    right_ascension = -1.38880 + 1.72027920e-2 * t_2060 + 
                        3.199e-2 * s1 - 2.65e-3 * c1 + 
                        4.050e-2 * s2 + 1.525e-2 * c2
    right_ascension = mod(right_ascension, 2π)
    declination = 6.57e-3 + 7.347e-2 * s1 - 3.9919e-1 * c1 + 
                              7.3e-4 * s2 - 6.60e-3 * c2
    hour_angle = 1.75283 + 6.3003881 * t_2060 + longitude - right_ascension
    hour_angle = mod(hour_angle + π, 2π) - π
    return right_ascension, declination, hour_angle
end

function get_local_sun_pos(latitude, declination, hour_angle)
    #= returns the sun position in spherical coordinates. The vertical axis points upwards.
    The elevation is the heigth of the sun above the horizon, in radians.
    The azimuth is the horizontal position of the sun in a polar coordinate system,
    where azimuth=0 points to the south pole. negative angles point to the east, positive to the west.
    again, in radians.=#
    sp = sin(latitude)
    cp = sqrt(1 - sp^2)
    sd = sin(declination)
    cd = sqrt(1 - sd^2)
    sH = sin(hour_angle)
    cH = cos(hour_angle)
    se0 = sp * sd + cp * cd * cH
    elevation = asin(se0) - 4.26e-5 * sqrt(1- se0^2)
    azimuth = atan(sH, cH * sp - sd*cp / cd)
    return elevation, azimuth
end