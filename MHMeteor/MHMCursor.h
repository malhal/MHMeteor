//
//  MHMCursor.h
//  CoreMeteor
//
//  Created by Malcolm Hall on 12/05/2014.
//  Copyright (c) 2014 Malcolm Hall. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MHMeteor/MHMJSManagedValue.h>

@class MHMeteor, MHMLiveQueryHandle;

@interface MHMCursor : MHMJSManagedValue

@property (nonatomic, strong, readonly) id selector;

@property (nonatomic, strong, readonly) id options;

//Return all matching documents as an Array.
-(NSArray*)fetch;

/* Observe Document */
typedef void (^MHMCursorDocument)(NSDictionary* document);
typedef void (^MHMCursorDocumentAddedAt)(NSDictionary* document, NSNumber* toIndex, NSDictionary* before);
typedef void (^MHMCursorDocumentChanged)(NSDictionary* newDocument, NSDictionary* oldDocument);
typedef void (^MHMCursorDocumentMoved)(NSDictionary* document, NSNumber* fromIndex, NSNumber* toIndex, NSNumber* before);

-(MHMLiveQueryHandle*)observeDocumentAdded:(MHMCursorDocument)documentAdded;
-(MHMLiveQueryHandle*)observeDocumentAddedAt:(MHMCursorDocumentAddedAt)documentAddedAt;
-(MHMLiveQueryHandle*)observeDocumentChanged:(MHMCursorDocumentChanged)documentChanged;
-(MHMLiveQueryHandle*)observeDocumentRemoved:(MHMCursorDocument)documentRemoved;
-(MHMLiveQueryHandle*)observeDocumentMoved:(MHMCursorDocumentMoved)documentMoved;

/* Observe Document ID changes */

typedef void (^MHMCursorDocumentIDAndFields)(NSString* documentID, NSDictionary* fields);
typedef void (^MHMCursorDocumentIDAddedBefore)(NSString* documentID, NSDictionary* fields, NSString* beforeDocumentID);
typedef void (^MHMCursorDocumentIDMovedBefore)(NSString* documentID, NSString* beforeDocumentID);
typedef void (^MHMCursorDocumentID)(NSString* documentID);

-(MHMLiveQueryHandle*)observeChangesDocumentIDChanged:(MHMCursorDocumentIDAndFields)documentIDChanged;
-(MHMLiveQueryHandle*)observeChangesDocumentIDAdded:(MHMCursorDocumentIDAndFields)documentIDAdded;
-(MHMLiveQueryHandle*)observeChangesDocumentIDAddedBefore:(MHMCursorDocumentIDAddedBefore)documentIDAddedBefore;
-(MHMLiveQueryHandle*)observeChangesDocumentIDMovedBefore:(MHMCursorDocumentIDMovedBefore)documentIDMovedBefore;
-(MHMLiveQueryHandle*)observeChangesDocumentIDRemoved:(MHMCursorDocumentID)documentIDRemoved;

@end
