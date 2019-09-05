//
//  File.swift
//  
//
//  Created by Henry Hathaway on 9/4/19.
//

#import "CV5String.h"

@implementation CV5String {
    NSObject<CV5StringImpl>* _impl;
}
- (instancetype)initWithImpl:(NSObject<CV5StringImpl>*)impl {
    if (self = [super init]) {
        _impl = impl;
    }
    return self;
}
- (NSUInteger)length {
    return [_impl length];
}
- (unichar)characterAtIndex:(NSUInteger)index {
    return [_impl characterAtIndex:index];
}
@end
