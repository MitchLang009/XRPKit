
struct sRange {
    BIGNUM* mRangeHigh;
    BIGNUM* mRangeLow;
    BIGNUM* mDifficulty;

    sRange() {
        mRangeHigh = BN_new();
        mRangeLow = BN_new();
        mDifficulty = BN_new();
    }

    ~sRange() {
        BN_free(mRangeHigh);
        BN_free(mRangeLow);
        BN_free(mDifficulty);
    }

    BIGNUM* Difficulty() {

        BN_clear(mDifficulty);

        if (!isZero())
            BN_sub(mDifficulty, mRangeHigh, mRangeLow);

        return mDifficulty;
    }

    bool isZero() {
        return (BN_is_zero(mRangeHigh) && BN_is_zero(mRangeLow));
    }
};

struct sPrefix {
    std::string mPrefix;
    sRange mRange1;
    sRange mRange2;
    BIGNUM* mDifficulty;

    sPrefix() {
        mDifficulty = BN_new();
    }

    ~sPrefix() {
        BN_free(mDifficulty);
    }

    BIGNUM* Difficulty() {
        BN_clear(mDifficulty);

        BN_add(mDifficulty, mDifficulty, mRange1.Difficulty());
        BN_add(mDifficulty, mDifficulty, mRange2.Difficulty());
        return mDifficulty;
    }
};


void calculate_range_difficulty();
sPrefix* get_prefix_ranges(int addrtype, const char *pfx, BN_CTX *bnctx);
void vg_output_timing_console(double count, double rate, unsigned long long total);
