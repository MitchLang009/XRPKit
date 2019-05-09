//
//  Foo+Swift.h
//  GenerateKP
//
//  Created by Mitch Lang on 5/7/19.
//  Copyright © 2019 Nitch Ventures LLC. All rights reserved.
//

#ifndef Foo_Swift_h
#define Foo_Swift_h

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCrypto.h>

@interface Foo : NSObject

- (NSArray*)generateKP:(UInt8 *) seed;

@end

#endif /* Foo_Swift_h */
