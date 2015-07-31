//
//  MongoDBPredicateAdaptor.h
//
//  Created by Tim Bansemer on 6/09/13.
//  Copyright (c) 2013 Tim Bansemer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MongoDBPredicateAdaptor : NSObject

+(NSDictionary *)queryDictFromPredicate:(NSPredicate *)predicate
                              orError:(NSError **)error;

@end
