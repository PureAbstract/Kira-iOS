//
//  UITableView+UpdateHelper.m
//  Kira
//
//  Created by Andy Sawyer on 06/06/2012.
//  Copyright 2012 Andy Sawyer. All rights reserved.
//

#import "UITableView+UpdateHelper.h"

@implementation UITableView (UpdateHelper)
- (void)reloadRow:(int)row inSection:(int)section withAnimation:(UITableViewRowAnimation)animation
{
    NSIndexPath *path = [NSIndexPath indexPathForRow:row
                                           inSection:section];
    [self reloadRowsAtIndexPaths:[NSArray arrayWithObject:path]
                withRowAnimation:animation];
}

- (void)insertRow:(int)row inSection:(int)section withAnimation:(UITableViewRowAnimation)animation
{
    NSIndexPath *path = [NSIndexPath indexPathForRow:row
                                           inSection:section];
    [self insertRowsAtIndexPaths:[NSArray arrayWithObject:path]
                withRowAnimation:animation];
}


- (void)reloadRow:(int)row inSection:(int)section
{
    [self reloadRow:row inSection:section withAnimation:UITableViewRowAnimationFade];
}

- (void)insertRow:(int)row inSection:(int)section
{
    [self insertRow:row inSection:section withAnimation:UITableViewRowAnimationFade];
}

@end
