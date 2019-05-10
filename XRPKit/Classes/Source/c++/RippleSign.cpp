//
//  RippleSign.cpp
//  Alamofire
//
//  Created by Mitch Lang on 5/8/19.
//

#include "RippleSign.hpp"

//std::vector<int8_t>
//sign (std::vector<int8_t> pk,
//      std::vector<int8_t> sk, std::vector<int8_t> m)
//{
////    auto const type =
////    publicKeyType(pk.slice());
////    if (! type)
////    LogicError("sign: invalid type");
//    sha512_half_hasher h;
//    h(m.data(), m.size());
//    auto const digest =
//    sha512_half_hasher::result_type(h);
//    
//    secp256k1_ecdsa_signature sig_imp;
//    if(secp256k1_ecdsa_sign(
//                            secp256k1Context(),
//                            &sig_imp,
//                            reinterpret_cast<unsigned char const*>(
//                                                                   digest.data()),
//                            reinterpret_cast<unsigned char const*>(
//                                                                   sk.data()),
//                            secp256k1_nonce_function_rfc6979,
//                            nullptr) != 1)
//    LogicError("sign: secp256k1_ecdsa_sign failed");
//    
//    unsigned char sig[72];
//    size_t len = sizeof(sig);
//    if(secp256k1_ecdsa_signature_serialize_der(
//                                               secp256k1Context(),
//                                               sig,
//                                               &len,
//                                               &sig_imp) != 1)
//    LogicError("sign: secp256k1_ecdsa_signature_serialize_der failed");
//    
//    return Buffer{sig, len};
//}
