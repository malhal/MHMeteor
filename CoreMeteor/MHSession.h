//
//  MHSession.h
//  CoreMeteorDemo
//
//  Created by Malcolm Hall on 04/08/2015.
//  Copyright (c) 2015 Malcolm Hall. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MHMeteorJSManagedValue.h"

@interface MHSession : MHMeteorJSManagedValue

- (id)objectForKeyedSubscript:(NSString*)key;

- (void)setObject:(id)object forKeyedSubscript:(NSString*)key;

@end
