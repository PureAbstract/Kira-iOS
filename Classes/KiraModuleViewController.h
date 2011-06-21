//
//  KiraDeviceViewController.h
//  Kira
//
//  Created by Andy Sawyer on 20/06/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KiraModule.h"
#import "AsyncUdpSocket.h"

@interface KiraModuleViewController : UITableViewController {
    KiraModule *device;
    AsyncUdpSocket *_socket;
}
@property (nonatomic,retain) KiraModule *device;

+ (id)viewControllerForModule:(KiraModule *)device;

@end
