
#import "Logging.h"

@implementation Logger

+(Logger *)logger
{
    static Logger *instance = nil;
    if( !instance ) {
        instance = [Logger new];
    }
    return instance;
}

-(void)logMessage:(NSString *)message
{
    NSLog(@"%@",message);
}
@end


@implementation NSObject (logging)

-(void)logWithFormat:(NSString *)format arguments:(va_list)args
{
    NSString *msg = [[NSString alloc] initWithFormat:format
                                           arguments:args];
    [[Logger logger] logMessage:msg];
    [msg release];
}

-(void)log:(NSString *)format, ...
{
    va_list args;
    va_start(args,format);
    [self logWithFormat:format
              arguments:args];
    va_end(args);
}
@end
