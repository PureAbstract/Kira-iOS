//
//  KiraModule.m
//  Kira
//
//  Created by Andy Sawyer on 20/06/2011.
//  Copyright 2011 Andy Sawyer. All rights reserved.
//

#import "KiraModule.h"

@implementation KiraModule
@synthesize discover;
@synthesize bindings = _bindings;

-(void)dealloc {
    [self.discover release];
    [_bindings release];
    [super dealloc];
}


-(id)initWithDiscovery:(NSArray *)discover_
{
    if (self = [super init]) {
        self.discover = discover_;
        _bindings = [[NSMutableDictionary alloc] initWithCapacity:128];
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
    [_bindings setObject:mapping forKey:index];
}

@end
