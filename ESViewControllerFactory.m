
#import "ESViewControllerFactory.h"
#import <objc/runtime.h>

@interface ESViewControllerFactory ()
@property (nonatomic, strong) NSCache *controllers;
@end

@implementation ESViewControllerFactory

- (id)init{
    self = [super init];
    if(!self){
        return nil;
    }
    self.viewControllerClasses = [NSMutableArray new];
    self.controllers = [NSCache new];
    _controllers.delegate = self;
    
    return self;
}

+ (id)createFactoryWithControllerClasses:(Class)class,... NS_REQUIRES_NIL_TERMINATION{
    static dispatch_once_t pred;
    static ESViewControllerFactory *shared = nil;
    
    NSMutableArray *classes = [NSMutableArray new];
    va_list args;
    va_start(args, class);
    
    Class viewControllerClass = class;
    if(![viewControllerClass isSubclassOfClass:[UIViewController class]]){
        va_end(args);
        return nil;
    }
    
    while(viewControllerClass){
        viewControllerClass = va_arg(args, Class);
        if([viewControllerClass isSubclassOfClass:[UIViewController class]]){
            [classes addObject:viewControllerClass];
        }
    }
    
    if([classes count]==0){
        va_end(args);
        return nil;
    }
    va_end(args);
    
    
    dispatch_once(&pred, ^{
        shared = [[ESViewControllerFactory alloc] init];
        shared.viewControllerClasses = classes;
        [[NSNotificationCenter defaultCenter] addObserver:shared
                                                 selector:@selector(applicationDidReceiveMemoryWarning::)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
    });
    return shared;
}

- (UIViewController *)viewControllerForClass:(Class)class{
    UIViewController *viewController = [_controllers objectForKey:class];
    if(!viewController){
        viewController = [[class alloc] initWithNibName:nil bundle:nil];
        
        // cache the viewController
        [self.controllers setObject:viewController forKey:class];
    }
    return viewController;
}

#pragma mark -
#pragma mark Handle Memory Pressure

- (void)applicationDidReceiveMemoryWarning:(NSNotification *)notif{
    
}

#pragma mark -
#pragma mark NSCacheDelegate
- (void)cache:(NSCache *)cache willEvictObject:(id)obj{
    
}

#pragma mark -
#pragma mark Dynamic Convenience Method Builder
+ (BOOL)resolveInstanceMethod:(SEL)aSEL {
    IMP getterIMP = imp_implementationWithBlock(^id(id _s) {
        for(Class class in [_s viewControllerClasses]){
            NSString *className = NSStringFromClass(class);
            if([className hasSuffix:NSStringFromSelector(aSEL)]){
                return [[_s controllers] objectForKey:class];
            }
        }
        
        return nil;

    });
    
    class_addMethod(self, aSEL, getterIMP, "@@:");
    
    return [super resolveInstanceMethod:aSEL];
}


@end
