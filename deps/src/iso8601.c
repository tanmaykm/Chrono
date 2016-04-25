#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct stISOTZ {
    char isvalid;
    char hour;
    char minute;
} tISOTZ;

static const int M2DAYS[] = {0, 306, 337, 0, 31, 61, 92, 122, 153, 184, 214, 245, 275};

int64_t totaldays(int y, int m, int d) {
    /* set start of year to march by moving jan and feb to previous year */
    if (m < 3) {
        y -= 1;
    }
    /* days + (days till last month in year) + (days till last year) */
    return (int64_t)(d + M2DAYS[m] + (365 * y) + (y / 4) - (y / 100) + (y / 400) - 306);
}

int64_t parseiso8601(const char *buf, tISOTZ *ptz) {
    int year = 0, month = 0, day = 0, hour = 0, minute = 0, second = 0, usecond = 0, i = 0;
    const char* c = buf;

    /* Year */
    for (i = 0; i < 4; i++) {
        if (*c >= '0' && *c <= '9')
            year = 10 * year + *c++ - '0';
        else
            return -1;
    }

    if (*c == '-') /* Optional separator */
        c++;

    /* Month */
    for (i = 0; i < 2; i++) {
        if (*c >= '0' && *c <= '9')
            month = 10 * month + *c++ - '0';
        else
            return -1;
    }

    if ((month < 1) || (month > 12)) {
        return -1;
    }

    if (*c == '-') /* Optional separator */
        c++;

    /* Day */
    for (i = 0; i < 2; i++) {
        if (*c >= '0' && *c <= '9')
            day = 10 * day + *c++ - '0';
        else
            break;
    }
    if (day == 0) day = 1; /* YYYY-MM format */

    if (*c == 'T' || *c == ' ') /* Time separator */
    {
        c++;

        /* Hour */
        for (i = 0; i < 2; i++) {
            if (*c >= '0' && *c <= '9')
                hour = 10 * hour + *c++ - '0';
            else
                return -1;
        }

        if (*c == ':') /* Optional separator */
            c++;

        /* Minute (optional) */
        for (i = 0; i < 2; i++) {
            if (*c >= '0' && *c <= '9')
                minute = 10 * minute + *c++ - '0';
            else
                break;
        }

        if (*c == ':') /* Optional separator */
            c++;

        /* Second (optional) */
        for (i = 0; i < 2; i++) {
            if (*c >= '0' && *c <= '9')
                second = 10 * second + *c++ - '0';
            else
                break;
        }

        if (*c == '.' || *c == ',') /* separator */
        {
            c++;

            /* Parse fraction of second up to 6 places */
            for (i = 0; i < 6; i++) {
                if (*c >= '0' && *c <= '9')
                    usecond = 10 * usecond + *c++ - '0';
                else
                    break;
            }

            /* Omit excessive digits */
            while (*c >= '0' && *c <= '9')
                c++;

            /* If we break early, fully expand the usecond */
            while (i++ < 6)
                usecond *= 10;
        }

        if(ptz) {
            char tztype = *c++;
            if (tztype == 'Z') {
                ptz->isvalid = 1;
                ptz->hour = ptz->minute = 0;
            }
            else if((tztype == '+') || (tztype == '-')) {
                ptz->isvalid = 1;
                char tzhour = 0;
                char tzminute = 0;

                for (i = 0; i < 2; i++) {
                    if (*c >= '0' && *c <= '9')
                        tzhour = (char)(10 * tzhour + *c++ - '0');
                    else
                        break;
                }

                if (*c == ':') // Optional separator
                    c++;

                for (i = 0; i < 2; i++) {
                    if (*c >= '0' && *c <= '9')
                        tzminute = (char)(10 * tzminute + *c++ - '0');
                    else
                        break;
                }
                ptz->hour = (tztype == '-') ? -tzhour : tzhour;
                ptz->minute = (tztype == '-') ? -tzminute : tzminute;
            }
            else {
                ptz->isvalid = 0;
            }
        }
    }
    return (int64_t)usecond + 1000000*(int64_t)(second + 60*minute + 3600*hour + 86400*totaldays(year, month, day));
}

#ifdef __cplusplus
}
#endif
