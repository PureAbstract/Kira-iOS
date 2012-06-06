//
//  UITableView+UpdateHelper.h
//  Kira
//
//  Created by Andy Sawyer on 06/06/2012.
//  Copyright 2012 Andy Sawyer. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface UITableView (UpdateHelper)
- (void)reloadRow:(int)row inSection:(int)section;
- (void)reloadRow:(int)row inSection:(int)section withAnimation:(UITableViewRowAnimation)animation;

- (void)insertRow:(int)row inSection:(int)section;
- (void)insertRow:(int)row inSection:(int)section withAnimation:(UITableViewRowAnimation)animation;
@end
