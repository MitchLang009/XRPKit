//
//  SwiftBridge.h
//  GenerateKP
//
//  Created by Mitch Lang on 5/7/19.
//  Copyright © 2019 Nitch Ventures LLC. All rights reserved.
//

#ifndef SwiftBridge_h
#define SwiftBridge_h

#import <Foundation/Foundation.h>
#import <vector>

@interface GeneratorWrapper : NSObject {

}

- (NSArray*)generateKP:(UInt8 *) seed;

@end

#endif /* SwiftBridge_h */
