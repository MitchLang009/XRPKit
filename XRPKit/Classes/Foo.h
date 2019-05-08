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

@interface Foo : NSObject {
    std::vector<int>* _bar;
}

@property (atomic, readonly) std::vector<int>* bar;
@property (readonly) size_t size;

- (UInt8)generateKP:(UInt8 *) seed;

@end

#endif /* SwiftBridge_h */
