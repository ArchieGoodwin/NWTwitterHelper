//
//  twitterHelper.h
//  Reccit
//
//  Created by Nero Wolfe on 5/4/13.
//  Copyright (c) 2013 leeway. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Accounts/Accounts.h>
typedef void (^RCCompleteBlockWithResult)  (BOOL result, NSError *error);

@interface twitterHelper : NSObject

@property(nonatomic, strong)    ACAccountStore *store;
@property (nonatomic, strong)     NSString *stringFriends;

+(id)sharedInstance;
-(void)getFollowersIds:(RCCompleteBlockWithResult)completionBlock;
- (void)storeAccountWithAccessToken:(NSString *)token secret:(NSString *)secret completionBlock:(RCCompleteBlockWithResult)completionBlock;
-(void)getFollowers:(NSString *)username completionBlock:(RCCompleteBlockWithResult)completionBlock;
@end
