//
//  RootViewController.h
//  Kira
//
//  Created by Andy Sawyer on 13/06/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AsyncUdpSocket.h"

@interface RootViewController : UITableViewController <AsyncUdpSocketDelegate> {
    AsyncUdpSocket *_udpSocket;
    NSMutableArray *_modules;
}

@end
