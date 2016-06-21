//
//  MHMCollection.h
//  CoreMeteor
//
//  Created by Malcolm Hall on 12/05/2014.
//  Copyright (c) 2014 Malcolm Hall. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MHMeteor/MHMJSManagedValue.h>

@class MHMeteor, MHMCursor;

// Find option keys
extern NSString * const MHMCollectionSortOption;
extern NSString * const MHMCollectionSkipOption;
extern NSString * const MHMCollectionLimitOption;
extern NSString * const MHMCollectionFieldsOption;
extern NSString * const MHMCollectionReactiveOption;
extern NSString * const MHMCollectionTransformOption;

@interface MHMCollection : MHMJSManagedValue

-(MHMCursor*)find;
-(MHMCursor*)findWithMongoSelector:(NSDictionary*)mongoSelector options:(NSDictionary*)options;

//-(NSDictionary*)findOneWithPredicate:(NSPredicate*)predicate options:(NSDictionary*)options;
-(NSDictionary*)findOneWithMongoSelector:(NSDictionary*)mongoSelector options:(NSDictionary*)options;
-(NSDictionary*)findOneWithDocumentID:(NSString*)documentID options:(NSDictionary*)options;

// Modify a single document. Example modifier: @{@"$inc":@{@"likes":@1}}
-(void)updateDocumentWithID:(NSString*)documentID modifier:(NSDictionary*)modifier;

// convenience for modifier: @{@"$set" : fields}
-(void)updateDocumentWithID:(NSString*)documentID setFields:(NSDictionary*)fields;

typedef void (^MHMCollectionDocumentInserted)(NSError* error, NSString* objectID);
typedef void (^MHMCollectionDocumentRemoved)(NSError* error);

//todo: make the callbacks work.
-(void)insertDocument:(NSDictionary*)document documentInserted:(MHMCollectionDocumentInserted)documentInserted;
-(void)removeDocumentWithID:(NSString*)documentID documentRemoved:(MHMCollectionDocumentRemoved)documentRemoved;

@end
