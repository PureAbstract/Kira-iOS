
@interface Logger : NSObject

+(Logger *)logger;
-(void)logMessage:(NSString *)msg;
@end

@interface NSObject (Logging)
-(void)logInfo:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2);
-(void)logInfo:(NSString *)format arguments:(va_list)arguments NS_FORMAT_FUNCTION(1,0);

-(void)logWarning:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2);
-(void)logWarning:(NSString *)format arguments:(va_list)arguments NS_FORMAT_FUNCTION(1,0);

-(void)logError:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2);
-(void)logError:(NSString *)format arguments:(va_list)arguments NS_FORMAT_FUNCTION(1,0);
@end
