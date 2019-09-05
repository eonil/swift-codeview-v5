//
//  File.swift
//  
//
//  Created by Henry Hathaway on 9/4/19.
//

@import Foundation;

@protocol CV5StringImpl <NSObject>
@required
@property (nonatomic,readonly,assign) NSUInteger length;
- (unichar)characterAtIndex:(NSUInteger)index;
@end

@interface CV5String: NSString
- (instancetype)initWithImpl:(NSObject<CV5StringImpl>*)impl;
@end
