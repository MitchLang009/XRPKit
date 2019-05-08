//
//  GenerateKeyPair.hpp
//  GenerateKP
//
//  Created by Mitch Lang on 5/7/19.
//  Copyright © 2019 Nitch Ventures LLC. All rights reserved.
//

#ifndef GenerateKeyPair_hpp
#define GenerateKeyPair_hpp

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

int generateKeypair(std::array<std::uint8_t, 21> seed);

class bignum
{
    private:
    BIGNUM* ptr;
    
    // non-copyable
    bignum           (bignum const&) = delete;
    bignum& operator=(bignum const&) = delete;
    
    void assign_new (uint8_t const* data, size_t size);
    
    public:
    bignum();
    
    ~bignum()
    {
        if ( ptr != nullptr)
        {
            BN_free (ptr);
        }
    }
    
    bignum (uint8_t const* data, size_t size)
    {
        assign_new (data, size);
    }
    
    template <class T>
    explicit bignum (T const& thing)
    {
        assign_new (thing.data(), thing.size());
    }
    
    bignum(bignum&& that) noexcept : ptr( that.ptr )
    {
        that.ptr = nullptr;
    }
    
    bignum& operator= (bignum&& that) noexcept
    {
        using std::swap;
        
        swap( ptr, that.ptr );
        
        return *this;
    }
    
    BIGNUM      * get()        { return ptr; }
    BIGNUM const* get() const  { return ptr; }
    
    bool is_zero() const  { return BN_is_zero (ptr); }
    
    void clear()  { BN_clear (ptr); }
    
    void assign (uint8_t const* data, size_t size);
};

class bn_ctx
{
    private:
    BN_CTX* ptr;
    
    // non-copyable
    bn_ctx           (bn_ctx const&);
    bn_ctx& operator=(bn_ctx const&);
    
    public:
    bn_ctx();
    
    ~bn_ctx()
    {
        BN_CTX_free (ptr);
    }
    
    BN_CTX      * get()        { return ptr; }
    BN_CTX const* get() const  { return ptr; }
};

#endif /* GenerateKeyPair_hpp */

