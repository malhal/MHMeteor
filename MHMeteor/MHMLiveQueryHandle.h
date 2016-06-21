//
//  MHMLiveQueryHandle.h
//  CoreMeteor
//
//  Created by Malcolm Hall on 12/05/2014.
//  Copyright (c) 2014 Malcolm Hall. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MHMeteor/MHMJSManagedValue.h>

@interface MHMLiveQueryHandle : MHMJSManagedValue

@property (nonatomic, strong, readonly) id block;

@property (nonatomic, strong, readonly) NSString* type;

-(void)stop;

@end
