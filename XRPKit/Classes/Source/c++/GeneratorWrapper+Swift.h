//
//  GeneratorWrapper+Swift.h
//  GenerateKP
//
//  Created by Mitch Lang on 5/7/19.
//  Copyright © 2019 Nitch Ventures LLC. All rights reserved.
//

#ifndef GeneratorWrapper_Swift_h
#define GeneratorWrapper_Swift_h

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCrypto.h>

@interface GeneratorWrapper : NSObject

- (NSArray*)generateKP:(UInt8 *) seed;

@end

#endif /* GeneratorWrapper_Swift_h */
