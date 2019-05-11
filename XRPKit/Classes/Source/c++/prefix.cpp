/**
 * (c) Ripple
 * (c) https://github.com/samr7/vanitygen
 * (c) Bitcoin
 */

#include "stdafx.hpp"

signed char g_Alphabet_B58_ReverseMap[256] = {
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, 50, 33, 7, 21, 41, 40, 27, 45, 8, -1, -1, -1, -1, -1, -1,
    -1, 54, 10, 38, 12, 14, 47, 15, 16, -1, 17, 18, 19, 20, 13, -1,
    22, 23, 24, 25, 26, 11, 28, 29, 30, 31, 32, -1, -1, -1, -1, -1,
    -1, 5, 34, 35, 36, 37, 6, 39, 3, 49, 42, 43, -1, 44, 4, 46,
    1, 48, 0, 2, 51, 52, 53, 9, 55, 56, 57, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
};

/*
* Find the bignum ranges that produce a given prefix.
*/
sPrefix* get_prefix_ranges(int addrtype, const char *pfx, BN_CTX *bnctx) {
    int i, c;
    int zero_prefix = 0;
    int check_upper = 0;
    int b58pow, b58ceil, b58top = 0;
    int ret = -1;
    size_t p;

    BIGNUM *bntarg, *bnceil, *bnfloor;
    BIGNUM *bnap, *bnbp, *bntp;
    BIGNUM *bnhigh = NULL, *bnlow = NULL, *bnhigh2 = NULL, *bnlow2 = NULL;
    BIGNUM *bntmp, *bntmp2;

    sPrefix* Prefix = new sPrefix();

    bntarg = BN_new();
    bnceil = BN_new();
    bnfloor = BN_new();
    bntmp = BN_new();
    bntmp2 = BN_new();

    p = strlen(pfx);

    for (i = 0; i < p; i++) {
        c = g_Alphabet_B58_ReverseMap[(int)pfx[i]];
        if (c == -1) {
            fprintf(stderr,
                "Invalid character '%c' in prefix '%s'\n",
                pfx[i], pfx);

            delete Prefix;
            return 0;
        }
        if (i == zero_prefix) {
            if (c == 0) {
                /* Add another zero prefix */
                zero_prefix++;
                if (zero_prefix > 19) {
                    fprintf(stderr,
                        "Prefix '%s' is too long\n",
                        pfx);
                    goto out;
                }
                continue;
            }

            /* First non-zero character */
            b58top = c;
            BN_set_word(bntarg, c);

        }
        else {
            BN_set_word(bntmp2, c);
            BN_mul(bntmp, bntarg, g_Base, bnctx);
            BN_add(bntarg, bntmp, bntmp2);
        }
    }

    /* Power-of-two ceiling and floor values based on leading 1s */
    BN_clear(bntmp);
    BN_set_bit(bntmp, 200 - (zero_prefix * 8));
    BN_sub(bnceil, bntmp, BN_value_one());
    BN_set_bit(bnfloor, 192 - (zero_prefix * 8));

    bnlow = BN_new();
    bnhigh = BN_new();

    if (b58top) {
        /*
        * If a non-zero was given in the prefix, find the
        * numeric boundaries of the prefix.
        */

        BN_copy(bntmp, bnceil);
        bnap = bntmp;
        bnbp = bntmp2;
        b58pow = 0;
        while (BN_cmp(bnap, g_Base) > 0) {
            b58pow++;
            BN_div(bnbp, NULL, bnap, g_Base, bnctx);
            bntp = bnap;
            bnap = bnbp;
            bnbp = bntp;
        }
        b58ceil = (int)BN_get_word(bnap);

        if ((b58pow - (p - zero_prefix)) < 6) {
            /*
            * Do not allow the prefix to constrain the
            * check value, this is ridiculous.
            */
            fprintf(stderr, "Prefix '%s' is too long\n", pfx);
            goto out;
        }

        BN_set_word(bntmp2, b58pow - (p - zero_prefix));
        BN_exp(bntmp, g_Base, bntmp2, bnctx);
        BN_mul(bnlow, bntmp, bntarg, bnctx);
        BN_sub(bntmp2, bntmp, BN_value_one());
        BN_add(bnhigh, bnlow, bntmp2);

        if (b58top <= b58ceil) {
            /* Fill out the upper range too */
            check_upper = 1;
            bnlow2 = BN_new();
            bnhigh2 = BN_new();

            BN_mul(bnlow2, bnlow, g_Base, bnctx);
            BN_mul(bntmp2, bnhigh, g_Base, bnctx);
            BN_set_word(bntmp, 57);
            BN_add(bnhigh2, bntmp2, bntmp);

            /*
            * Addresses above the ceiling will have one
            * fewer "1" prefix in front than we require.
            */
            if (BN_cmp(bnceil, bnlow2) < 0) {
                /* High prefix is above the ceiling */
                check_upper = 0;
                BN_free(bnhigh2);
                bnhigh2 = NULL;
                BN_free(bnlow2);
                bnlow2 = NULL;
            }
            else if (BN_cmp(bnceil, bnhigh2) < 0)
                /* High prefix is partly above the ceiling */
                BN_copy(bnhigh2, bnceil);

            /*
            * Addresses below the floor will have another
            * "1" prefix in front instead of our target.
            */
            if (BN_cmp(bnfloor, bnhigh) >= 0) {

                check_upper = 0;
                BN_free(bnhigh);
                bnhigh = bnhigh2;
                bnhigh2 = NULL;
                BN_free(bnlow);
                bnlow = bnlow2;
                bnlow2 = NULL;
            }
            else if (BN_cmp(bnfloor, bnlow) > 0) {
                /* Low prefix is partly below the floor */
                BN_copy(bnlow, bnfloor);
            }
        }

    }
    else {
        BN_copy(bnhigh, bnceil);
        BN_clear(bnlow);
    }

    /* Limit the prefix to the address type */
    BN_clear(bntmp);
    BN_set_word(bntmp, addrtype);
    BN_lshift(bntmp2, bntmp, 192);

    if (check_upper) {
        if (BN_cmp(bntmp2, bnhigh2) > 0) {
            check_upper = 0;
            BN_free(bnhigh2);
            bnhigh2 = NULL;
            BN_free(bnlow2);
            bnlow2 = NULL;
        }
        else if (BN_cmp(bntmp2, bnlow2) > 0)
            BN_copy(bnlow2, bntmp2);
    }

    if (BN_cmp(bntmp2, bnhigh) > 0) {
        if (!check_upper)
            goto not_possible;
        check_upper = 0;
        BN_free(bnhigh);
        bnhigh = bnhigh2;
        bnhigh2 = NULL;
        BN_free(bnlow);
        bnlow = bnlow2;
        bnlow2 = NULL;
    }
    else if (BN_cmp(bntmp2, bnlow) > 0) {
        BN_copy(bnlow, bntmp2);
    }

    BN_set_word(bntmp, addrtype + 1);
    BN_lshift(bntmp2, bntmp, 192);

    if (check_upper) {
        if (BN_cmp(bntmp2, bnlow2) < 0) {
            check_upper = 0;
            BN_free(bnhigh2);
            bnhigh2 = NULL;
            BN_free(bnlow2);
            bnlow2 = NULL;
        }
        else if (BN_cmp(bntmp2, bnhigh2) < 0)
            BN_copy(bnlow2, bntmp2);
    }

    if (BN_cmp(bntmp2, bnlow) < 0) {
        if (!check_upper)
            goto not_possible;
        check_upper = 0;
        BN_free(bnhigh);
        bnhigh = bnhigh2;
        bnhigh2 = NULL;
        BN_free(bnlow);
        bnlow = bnlow2;
        bnlow2 = NULL;
    }
    else if (BN_cmp(bntmp2, bnhigh) < 0) {
        BN_copy(bnhigh, bntmp2);
    }

    /* Address ranges are complete */
    //assert(check_upper || ((bnlow2 == NULL) && (bnhigh2 == NULL)));
    Prefix->mPrefix = pfx;

    BN_copy(Prefix->mRange1.mRangeLow, bnlow);
    BN_copy(Prefix->mRange1.mRangeHigh, bnhigh);

    if (bnlow2 != NULL) {
        BN_copy(Prefix->mRange2.mRangeLow, bnlow2);
        BN_copy(Prefix->mRange2.mRangeHigh, bnhigh2);
    }

    ret = 0;

    if (0) {
    not_possible:
        ret = -2;
    }

out:
    BN_free(bntarg);
    BN_free(bnceil);
    BN_free(bnfloor);
    BN_free(bntmp);
    BN_free(bntmp2);

    if (bnhigh)
        BN_free(bnhigh);
    if (bnlow)
        BN_free(bnlow);
    if (bnhigh2)
        BN_free(bnhigh2);
    if (bnlow2)
        BN_free(bnlow2);

    return Prefix;
}


void calculate_range_difficulty() {
    BIGNUM *bntmp, *bntmp2;

    bntmp = BN_new();
    bntmp2 = BN_new();

    BN_clear(g_Difficulty);

    BN_clear(bntmp2);
    BN_set_bit(bntmp2, 192);

    // 
    for (auto& Prefix : g_Prefixes) {

        // Add all difficulties together
        BN_add(g_Difficulty, g_Difficulty, Prefix->Difficulty());

        BN_div(bntmp, NULL, bntmp2, Prefix->Difficulty(), g_Ctx);

        char* dbuf = BN_bn2dec(bntmp);
        fprintf(stderr,
            "Prefix difficulty: %20s %s\n",
            dbuf, Prefix->mPrefix.c_str());
        OPENSSL_free(dbuf);
    }

    BN_div(bntmp, NULL, bntmp2, g_Difficulty, g_Ctx);

    char *dbuf = BN_bn2dec(bntmp);
    g_Chance = atof(dbuf);
    OPENSSL_free(dbuf);

    std::cout << "\n";

    BN_free(bntmp);
    BN_free(bntmp2);
}

void vg_output_timing_console(double count, double rate, unsigned long long total) {
    double prob, time, targ;
    char const *unit;
    char linebuf[80];
    int rem, p, i;

    const double targs[] = { 0.5, 0.75, 0.8, 0.9, 0.95, 1.0 };

    targ = rate;
    unit = "key/s";
    if (targ > 1000) {
        unit = "Kkey/s";
        targ /= 1000.0;
        if (targ > 1000) {
            unit = "Mkey/s";
            targ /= 1000.0;
        }
    }

    rem = sizeof(linebuf);
    p = snprintf(linebuf, rem, "[%.2f %s][total %lld]",
        targ, unit, total);

    rem -= p;
    if (rem < 0)
        rem = 0;

    if (g_Chance >= 1.0) {
        prob = 1.0f - exp(-count / g_Chance);

        if (prob <= 0.999) {
            p = snprintf(&linebuf[p], rem, "[Prob %.1f%%]",
                prob * 100);

            rem -= p;
            if (rem < 0)
                rem = 0;
            p = sizeof(linebuf) - rem;
        }

        for (i = 0; i < sizeof(targs) / sizeof(targs[0]); i++) {
            targ = targs[i];
            if ((targ < 1.0) && (prob <= targ))
                break;
        }

        if (targ < 1.0) {
            time = ((-g_Chance * log(1.0 - targ)) - count) /
                rate;
            unit = "s";
            if (time > 60) {
                time /= 60;
                unit = "min";
                if (time > 60) {
                    time /= 60;
                    unit = "h";
                    if (time > 24) {
                        time /= 24;
                        unit = "d";
                        if (time > 365) {
                            time /= 365;
                            unit = "y";
                        }
                    }
                }
            }

            if (time > 1000000) {
                p = snprintf(&linebuf[p], rem,
                    "[%d%% in %e%s]",
                    (int)(100 * targ), time, unit);
            }
            else {
                p = snprintf(&linebuf[p], rem,
                    "[%d%% in %.1f%s]",
                    (int)(100 * targ), time, unit);
            }

            rem -= p;
            if (rem < 0)
                rem = 0;
            p = sizeof(linebuf) - rem;
        }
    }

    if (rem) {
        memset(&linebuf[sizeof(linebuf) - rem], 0x20, rem);
        linebuf[sizeof(linebuf) - 1] = '\0';
    }

    std::cout << linebuf << "\r" << std::flush;
}
