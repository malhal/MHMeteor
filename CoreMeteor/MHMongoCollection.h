//
//  MHMongoCollection.h
//  CoreMeteor
//
//  Created by Malcolm Hall on 12/05/2014.
//  Copyright (c) 2014 Malcolm Hall. All rights reserved.
//

#import "MHMeteorJSManagedValue.h"

@class MHMeteor,MHMongoCursor;

// Find option keys
extern NSString * const MHMongoCollectionSortOption;
extern NSString * const MHMongoCollectionSkipOption;
extern NSString * const MHMongoCollectionLimitOption;
extern NSString * const MHMongoCollectionFieldsOption;
extern NSString * const MHMongoCollectionReactiveOption;
extern NSString * const MHMongoCollectionTransformOption;

@interface MHMongoCollection : MHMeteorJSManagedValue

-(MHMongoCursor*)find;
-(MHMongoCursor*)findWithMongoSelector:(NSDictionary*)mongoSelector options:(NSDictionary*)options;

//-(NSDictionary*)findOneWithPredicate:(NSPredicate*)predicate options:(NSDictionary*)options;
-(NSDictionary*)findOneWithMongoSelector:(NSDictionary*)mongoSelector options:(NSDictionary*)options;

// Modify a single document. Example modifier: @{@"$inc":@{@"likes":@1}}
-(void)updateDocumentWithID:(NSString*)documentID modifier:(NSDictionary*)modifier;

// convenience for modifier: @{@"$set" : fields}
-(void)updateDocumentWithID:(NSString*)documentID setFields:(NSDictionary*)fields;

typedef void (^MHMongoCollectionDocumentInserted)(NSError* error, NSString* objectID);
typedef void (^MHMongoCollectionDocumentRemoved)(NSError* error);

//todo: make the callbacks work.
-(void)insertDocument:(NSDictionary*)document documentInserted:(MHMongoCollectionDocumentInserted)documentInserted;
-(void)removeDocumentWithID:(NSString*)documentID documentRemoved:(MHMongoCollectionDocumentRemoved)documentRemoved;

@end
