//
//  MHMongoCursor.h
//  CoreMeteor
//
//  Created by Malcolm Hall on 12/05/2014.
//  Copyright (c) 2014 Malcolm Hall. All rights reserved.
//

#import "MHMeteorJSManagedValue.h"

@class MHMeteor,MHMongoLiveQueryHandle;

@interface MHMongoCursor : MHMeteorJSManagedValue

@property (nonatomic, strong, readonly) id selector;

@property (nonatomic, strong, readonly) id options;

//Return all matching documents as an Array.
-(NSArray*)fetch;

/* Observe Document */
typedef void (^MHMongoCursorDocument)(NSDictionary* document);
typedef void (^MHMongoCursorDocumentAddedAt)(NSDictionary* document, NSNumber* toIndex, NSDictionary* before);
typedef void (^MHMongoCursorDocumentChanged)(NSDictionary* newDocument, NSDictionary* oldDocument);
typedef void (^MHMongoCursorDocumentMoved)(NSDictionary* document, NSNumber* fromIndex, NSNumber* toIndex, NSNumber* before);

-(MHMongoLiveQueryHandle*)observeDocumentAdded:(MHMongoCursorDocument)documentAdded;
-(MHMongoLiveQueryHandle*)observeDocumentAddedAt:(MHMongoCursorDocumentAddedAt)documentAddedAt;
-(MHMongoLiveQueryHandle*)observeDocumentChanged:(MHMongoCursorDocumentChanged)documentChanged;
-(MHMongoLiveQueryHandle*)observeDocumentRemoved:(MHMongoCursorDocument)documentRemoved;
-(MHMongoLiveQueryHandle*)observeDocumentMoved:(MHMongoCursorDocumentMoved)documentMoved;

/* Observe Document ID changes */

typedef void (^MHMongoCursorDocumentIDAndFields)(NSString* documentID, NSDictionary* fields);
typedef void (^MHMongoCursorDocumentIDAddedBefore)(NSString* documentID, NSDictionary* fields, NSString* beforeDocumentID);
typedef void (^MHMongoCursorDocumentIDMovedBefore)(NSString* documentID, NSString* beforeDocumentID);
typedef void (^MHMongoCursorDocumentID)(NSString* documentID);

-(MHMongoLiveQueryHandle*)observeChangesDocumentIDChanged:(MHMongoCursorDocumentIDAndFields)documentIDChanged;
-(MHMongoLiveQueryHandle*)observeChangesDocumentIDAdded:(MHMongoCursorDocumentIDAndFields)documentIDAdded;
-(MHMongoLiveQueryHandle*)observeChangesDocumentIDAddedBefore:(MHMongoCursorDocumentIDAddedBefore)documentIDAddedBefore;
-(MHMongoLiveQueryHandle*)observeChangesDocumentIDMovedBefore:(MHMongoCursorDocumentIDMovedBefore)documentIDMovedBefore;
-(MHMongoLiveQueryHandle*)observeChangesDocumentIDRemoved:(MHMongoCursorDocumentID)documentIDRemoved;

@end
