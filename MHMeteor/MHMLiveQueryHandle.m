//
//  MHMLiveQueryHandle.m
//  CoreMeteor
//
//  Created by Malcolm Hall on 12/05/2014.
//  Copyright (c) 2014 Malcolm Hall. All rights reserved.
//

#import "MHMLiveQueryHandle.h"

@implementation MHMLiveQueryHandle

- (instancetype)_initWithType:(NSString*)type block:(id)block container:(MHMContainer*)container value:(JSValue*)value{
    self = [super initWithContainer:container value:value];
    if(self) {
        _block = block;
        _type = type;
    }
    return self;
}

-(void)stop{
    [self invokeMethod:@"stop" withArguments:nil];
}

-(void)dealloc{
    [self stop];
}

@end
