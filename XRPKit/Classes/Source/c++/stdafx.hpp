#include <array>
#include <string>
#include <vector>
#include <iostream>
#include <thread>
#include <iomanip>
#include <ctime>
#include <mutex>
#include <atomic>
#include <math.h>

#include <stdio.h>
#include <cstring>

#include <openssl/bn.h>
#include <openssl/pem.h>
#include <openssl/sha.h>
#include <openssl/ec.h>
#include <openssl/ripemd.h>
#include <openssl/rand.h>

#include "prefix.hpp"

typedef struct bignum_st BIGNUM;
typedef struct ec_point_st EC_POINT;

extern EC_GROUP* g_CurveGroup;
extern BIGNUM* g_CurveOrder;

extern BIGNUM* g_Base;
extern BIGNUM* g_Difficulty;
extern BN_CTX* g_Ctx;
extern double g_Chance;

extern std::vector<sPrefix*> g_Prefixes;
