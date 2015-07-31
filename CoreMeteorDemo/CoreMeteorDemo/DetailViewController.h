//
//  DetailViewController.h
//  CoreMeteorDemo
//
//  Created by Malcolm Hall on 29/07/2015.
//  Copyright (c) 2015 Malcolm Hall. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;
@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@end

