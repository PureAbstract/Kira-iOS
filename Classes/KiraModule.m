//
//  KiraDevice.m
//  Kira
//
//  Created by Andy Sawyer on 20/06/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "KiraModule.h"

@implementation KiraModule
@synthesize discover;
@synthesize bindings = _bindings;

-(void)dealloc {
    [self.discover release];
    [self.bindings release];
    [super dealloc];
}

-(id)initWithDiscovery:(NSArray *)discover_
{
    if (self = [super init]) {
        self.discover = discover_;
        self->_bindings = [NSMutableDictionary new];
    }
    return self;
}

- (NSString *)name {
    return [self.discover objectAtIndex:kKiraIndexName];
}
- (NSString *)address {
    return [self.discover objectAtIndex:kKiraIndexAddress];
}

-(NSString *)port {
    return [self.discover objectAtIndex:kKiraIndexCommandPort];
}

-(void)addBinding:(NSString *)binding
{
    NSString *index = [binding substringToIndex:2];
    NSAssert(index.length==2,@"Bad index");
    NSString *mapping = [binding substringFromIndex:3];
    NSLog(@"[%@][%@]",index,mapping);
    [self->_bindings setObject:mapping forKey:index];
}

@end
