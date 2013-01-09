#import <Foundation/Foundation.h>

@interface ESViewControllerFactory : NSObject <NSCacheDelegate>
@property (nonatomic, strong) NSMutableArray *viewControllerClasses;

+ (id)createFactoryWithControllerClasses:(Class)class,... NS_REQUIRES_NIL_TERMINATION;
- (UIViewController *)viewControllerForClass:(Class)class;
@end
