//
//  KiraModuleViewController.h
//  Kira
//
//  Created by Andy Sawyer on 20/06/2011.
//  Copyright 2011 Andy Sawyer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KiraModule.h"
//#import "AsyncUdpSocket.h"
#import "UdpSocket.h"

@interface KiraModuleViewController : UITableViewController {
    KiraModule *module;
    //AsyncUdpSocket *_socket;
    UdpSocket *_socket;
}
@property (nonatomic,retain) KiraModule *module;

+ (id)viewControllerForModule:(KiraModule *)module;

@end
