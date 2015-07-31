//
//  MasterViewController.h
//  CoreMeteorDemo
//
//  Created by Malcolm Hall on 29/07/2015.
//  Copyright (c) 2015 Malcolm Hall. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface MasterViewController : UITableViewController <NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

-(void)reload;

@end

