//
//  SwiftBridge.m
//  GenerateKP
//
//  Created by Mitch Lang on 5/7/19.
//  Copyright © 2019 Nitch Ventures LLC. All rights reserved.
//

#import "Foo.h"
#import "GenerateKeyPair.hpp"

@implementation Foo

@synthesize bar;

- (instancetype)init {
    if (self = [super init]) {
        _bar = new std::vector<int>();
    }
    
    return self;
}

- (void)dealloc {
    delete _bar;
}

- (NSArray*)generateKP:(UInt8 *) seed {
    std::array<std::uint8_t, 21> SeedBuffer = { 0 };
    memcpy(&SeedBuffer[1], static_cast<void*>(seed), 16);
    std::vector<std::string> results = generateKeypair(SeedBuffer);
    NSMutableArray *returnArray = [NSMutableArray arrayWithCapacity:results.size()];
    for(int i = 0;i< results.size();i++){
            [returnArray addObject:[NSString stringWithUTF8String:results[i].c_str()]];
    }
    return returnArray;
}

- (void)pushInt:(int)val {
    _bar->push_back(val);
}

- (int)popInt {
    if (_bar->size() == 0) {
        return -1;
    }
    
    auto front = _bar->back();
    _bar->pop_back();
    return front;
}

- (size_t)size {
    return _bar->size();
}

@end
