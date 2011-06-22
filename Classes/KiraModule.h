//
//  KiraModule.h
//  Kira
//
//  Created by Andy Sawyer on 20/06/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KiraModule : NSObject {
    NSArray *discover;
    NSMutableDictionary *_bindings;
}
@property (readonly) NSString *name;
@property (readonly) NSString *address;
@property (readonly) NSString *port;
@property (nonatomic,retain) NSArray *discover;
@property (readonly) NSDictionary *bindings;

typedef enum {
    kKiraIndexName,
    kKiraIndexAddress,
    kKiraIndexMacAddress,
    kKiraIndexMode,
    kKiraIndexCommandPort,
} KiraIndexType;


- (id)initWithDiscovery:(NSArray *)discover_;
- (void)addBinding:(NSString *)binding;
@end
