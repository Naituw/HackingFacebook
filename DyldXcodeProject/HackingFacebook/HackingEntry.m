//
//  HackingEntry.m
//  HackingFacebook
//
//  Created by wutian on 2017/2/14.
//  Copyright © 2017年 Weibo. All rights reserved.
//

#import "HackingEntry.h"
#import "Aspects.h"
#import "FBSSLPinningVerifier.h"
#import "FBLigerConfig.h"

#import <objc/runtime.h>

static void SafeLog(NSString * string);

@implementation HackingEntry

+ (instancetype)sharedEntryPoint
{
    static HackingEntry * instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [HackingEntry new];
    });
    return instance;
}

- (void)run
{
    NSLog(@"+[HackingEntry run]");
    
    {
        // Disable the liger network engine, After this, Facebook will fallback to use FBSSLPinningVerifier to do the pinning
        
        {
            // Find FBLigerConfig's init method, this method changes frequently across versions, so we find the longest method to hook
            
            Class ligerClass = NSClassFromString(@"FBLigerConfig");
            
            SEL longestSelector = @selector(init);
            
            unsigned int mc = 0;
            Method * mlist = class_copyMethodList(ligerClass, &mc);
            for(int i = 0; i < mc; i++) {
                SEL selector = method_getName(mlist[i]);
                NSString * selectorName = NSStringFromSelector(selector);
                if (selectorName.length > NSStringFromSelector(longestSelector).length) {
                    longestSelector = selector;
                }
                NSLog(@"FBLigerConfig find selector: %@", selectorName);
            }
            
            SafeLog([NSString stringWithFormat:@"FBLigerConfig longestSelector is: %@", NSStringFromSelector(longestSelector)]);
            
            NSError * error = NULL;
            [ligerClass aspect_hookSelector:longestSelector withOptions:AspectPositionInstead usingBlock:^(id<AspectInfo> aspectInfo) {
                NSArray * variableNames = [NSStringFromSelector(longestSelector) componentsSeparatedByString:@":"];
                if ([variableNames.lastObject isEqual:@""]) {
                    variableNames = [variableNames subarrayWithRange:NSMakeRange(0, variableNames.count - 1)];
                }
                NSArray * arguments = [aspectInfo arguments];
                if (arguments.count == variableNames.count) {
                    NSMutableDictionary * mapped = [NSMutableDictionary dictionary];
                    [variableNames enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        mapped[obj] = arguments[idx];
                    }];
                    SafeLog([NSString stringWithFormat:@"FBLigerConfig init-mapped: %@", mapped]);
                }
                SafeLog([NSString stringWithFormat:@"FBLigerConfig init: %@", arguments]);
                
                // The prefix is - (id)initConfigWithLigerEnabled:(_Bool)arg1 allRequestsEnabled...
                // So we just change the first argument to "NO"
                
                NSInvocation *invocation = aspectInfo.originalInvocation;
                BOOL ligerEnabled = NO;
                [invocation setArgument:&ligerEnabled atIndex:2];
                
                [invocation invoke];
                
            } error:&error];
            if (error) {
                NSLog(@"Error Hacking Class FBLigerConfig, Error: %@", error);
            }
        }
        
        
        // Kill SSL Pinning for FBSSLPinningVerifier
        
        [NSClassFromString(@"FBSSLPinningVerifier") aspect_hookSelector:@selector(checkPinning:) withOptions:AspectPositionInstead usingBlock:^(id<AspectInfo> info) {
            
            NSLog(@"Check Pinnning Called: %@", [info arguments]);
            
            BOOL success;
            NSInvocation *invocation = info.originalInvocation;
            [invocation invoke];
            [invocation getReturnValue:&success];
            
            if (!success) {
                
                NSLog(@"Check Pinning Failed, Change to Success");
                
                success = YES;
                [invocation setReturnValue:&success];
            }
            
        } error:NULL];
    }
}

@end

__attribute__((constructor))
void WBTEntryPointMain() {
    NSLog(@"WBTEntryPointMain()");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[HackingEntry sharedEntryPoint] run];
    });
}

static void SafeLog(NSString * string) {
    NSMutableArray * logs = [NSMutableArray array];
    NSString * remain = string;
    while (remain.length > 500) {
        [logs addObject:[remain substringToIndex:500]];
        remain = [remain substringFromIndex:500];
    }
    [logs addObject:remain];
    NSUInteger count = logs.count;
    
    [logs enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSLog(@"(%zd/%zd) %@", idx + 1, count, obj);
    }];
}

