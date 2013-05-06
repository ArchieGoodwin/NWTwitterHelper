//
//  twitterHelper.m
//  Reccit
//
//  Created by Nero Wolfe on 5/4/13.
//  Copyright (c) 2013 leeway. All rights reserved.
//

#import "twitterHelper.h"
#import "RCDefine.h"
#import "AFNetworking.h"
#import <Social/Social.h>
#import <Accounts/Accounts.h>
@implementation twitterHelper
{
    NSMutableArray *ids;
    NSMutableArray *friends;
    int iterations;
    int maxIterations;
}


-(void)getFollowersIds:(RCCompleteBlockWithResult)completionBlock
{
    
    RCCompleteBlockWithResult completeBlockWithResult = completionBlock;

    
    NSString *connectionString = [NSString stringWithFormat:@"https://api.twitter.com/1.1/friends/ids.json?screen_name=%@&oauth_token=%@&oauth_token_secret=%@",[[NSUserDefaults standardUserDefaults] objectForKey:kRCUserName], [[NSUserDefaults standardUserDefaults] objectForKey:@"tKey"], [[NSUserDefaults standardUserDefaults] objectForKey:@"tSecret"]];
    NSLog(@"%@", connectionString);
    NSURL *url = [NSURL URLWithString:connectionString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    AFJSONRequestOperation *operation;
    operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSLog(@"%@", JSON);
        
        
        completeBlockWithResult(YES, nil);
        
        
        
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
        completeBlockWithResult(nil, error);
    }];
    
    [operation start];
    
}


- (void)usersLookUp:(ACAccount *)twitterAccount  shift:(int)shift completionBlock:(RCCompleteBlockWithResult)completionBlock 
{

    NSLog(@"iteration: %i, shift: %i, maxiterations: %i", iterations, shift, maxIterations);
    NSArray *first100 = [NSArray new];
    if((ids.count - shift) < 100)
    {
        first100 = [ids objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(shift, ids.count - shift - 1)]];

    }
    else
    {
        first100 = [ids objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(shift, 100)]];

    }
    //NSLog(@"%@", [first100 componentsJoinedByString:@","]);
    SLRequest *twitterUsersRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodPOST URL:[NSURL URLWithString:@"https://api.twitter.com/1.1/users/lookup.json"] parameters:[NSDictionary dictionaryWithObjectsAndKeys:[first100 componentsJoinedByString:@","], @"user_id", @"false", @"include_entities", nil]];
    [twitterUsersRequest setAccount:twitterAccount];
    [twitterUsersRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        if ([urlResponse statusCode] == 429) {
            NSLog(@"Rate limit reached");
            return;
        }
        // Check if there was an error
        if (error) {
            NSLog(@"twitterUsersRequest Error: %@", error.localizedDescription);
            completionBlock(NO, error);
        }
        // Check if there is some response data
        if (responseData) {
            NSError *error = nil;
            NSArray *data = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableLeaves error:&error];
            // Filter the preferred data
            //NSLog(@"data: %@", data);
            
            [friends addObjectsFromArray:data];
            
            iterations++;
            if(iterations <= maxIterations)
            {
                [self usersLookUp:twitterAccount shift:iterations * 100 completionBlock:completionBlock];
                
            }
            else
            {

                [self buildResult];
                completionBlock(YES, nil);

            }
            
            
            
            
        }
    }];
}



-(void)getFollowers:(NSString *)username completionBlock:(RCCompleteBlockWithResult)completionBlock
{
    // Request access to the Twitter accounts
    
    
    iterations = 0;
    maxIterations = 1;
    
    
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    [accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error){
        if (granted) {
            NSArray *accounts = [accountStore accountsWithAccountType:accountType];
            // Check if the users has setup at least one Twitter account
            if (accounts.count > 0)
            {
                ACAccount *twitterAccount = [accounts objectAtIndex:0];

                for(ACAccount *t in accounts)
                {
                    if([t.username isEqualToString:username])
                    {
                        twitterAccount = t;
                        break;
                    }
                }

                SLRequest *twitterInfoRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodGET URL:[NSURL URLWithString:@"https://api.twitter.com/1.1/friends/ids.json?"] parameters:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%@", username], @"screen_name", @"-1", @"cursor", nil]];
                [twitterInfoRequest setAccount:twitterAccount];
                // Making the request
                [twitterInfoRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        // Check if we reached the reate limit
                        if ([urlResponse statusCode] == 429) {
                            NSLog(@"Rate limit reached");
                            return;
                        }
                        // Check if there was an error
                        if (error) {
                            NSLog(@"Error: %@", error.localizedDescription);
                            return;
                        }
                        // Check if there is some response data
                        if (responseData) {
                            NSError *error = nil;
                            NSArray *TWData = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableLeaves error:&error];

                            
                            ids = [((NSDictionary *)TWData) objectForKey:@"ids"];
                            
                            maxIterations = ids.count / 100;
                            

                            [self usersLookUp:twitterAccount shift:iterations * 100 completionBlock:completionBlock];

                            
                            
                        }
                    });
                }];
            }
        } else {
            NSLog(@"No access granted");
        }
    }];
    

}



-(void)buildResult
{
    NSMutableArray *temp = [NSMutableArray new];
    
    for(NSDictionary *friend in friends)
    {
        NSArray *frArray = [NSArray arrayWithObjects:[self makeStringWithKeyAndValue2:@"id" value:[friend objectForKey:@"id"]],
                             [self makeStringWithKeyAndValue:@"profile_image_url" value:[friend objectForKey:@"profile_image_url"]],
                            [self makeStringWithKeyAndValue:@"name" value:[friend objectForKey:@"name"]],
                            [self makeStringWithKeyAndValue:@"screen_name" value:[friend objectForKey:@"screen_name"]],
                             nil];
        NSString *fr = [NSString stringWithFormat:@"{%@}", [frArray componentsJoinedByString:@","]];

        
        [temp addObject:fr];
    }
    
    NSString *data = [NSString stringWithFormat:@"fb_usercheckin={\"data\":[%@]}",[temp componentsJoinedByString:@","]];
    
    NSLog(@"result for friends twitter send count %i: %@", temp.count, data);
    _stringFriends = [data stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}


- (void)storeAccountWithAccessToken:(NSString *)token secret:(NSString *)secret completionBlock:(RCCompleteBlockWithResult)completionBlock
{
    
    _store = [[ACAccountStore alloc] init];
    //  Each account has a credential, which is comprised of a verified token and secret
    ACAccountCredential *credential =
    [[ACAccountCredential alloc] initWithOAuthToken:token tokenSecret:secret];
    
    //  Obtain the Twitter account type from the store
    ACAccountType *twitterAcctType =
    [_store accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    //  Create a new account of the intended type
    ACAccount *newAccount = [[ACAccount alloc] initWithAccountType:twitterAcctType];
    
    //  Attach the credential for this user
    newAccount.credential = credential;
    
    //  Finally, ask the account store instance to save the account
    //  Note: that the completion handler is not guaranteed to be executed
    //  on any thread, so care should be taken if you wish to update the UI, etc.
    [_store saveAccount:newAccount withCompletionHandler:^(BOOL success, NSError *error) {
        if (success) {
            // we've stored the account!
            NSLog(@"the account was saved!");
            completionBlock(YES,nil);
        }
        else {
            //something went wrong, check value of error
            NSLog(@"the account was NOT saved");
            
            // see the note below regarding errors...
            //  this is only for demonstration purposes
            if ([[error domain] isEqualToString:ACErrorDomain]) {
                
                // The following error codes and descriptions are found in ACError.h
                switch ([error code]) {
                    case ACErrorAccountMissingRequiredProperty:
                        NSLog(@"Account wasn't saved because "
                              "it is missing a required property.");
                        break;
                    case ACErrorAccountAuthenticationFailed:
                        NSLog(@"Account wasn't saved because "
                              "authentication of the supplied "
                              "credential failed.");
                        break;
                    case ACErrorAccountTypeInvalid:
                        NSLog(@"Account wasn't saved because "
                              "the account type is invalid.");
                        break;
                    case ACErrorAccountAlreadyExists:
                        NSLog(@"Account wasn't added because "
                              "it already exists.");
                        completionBlock(YES,nil);

                        break;
                    case ACErrorAccountNotFound:
                        NSLog(@"Account wasn't deleted because"
                              "it could not be found.");
                        break;
                    case ACErrorPermissionDenied:
                        NSLog(@"Permission Denied");
                        break;
                    case ACErrorUnknown:
                    default: // fall through for any unknown errors...
                        NSLog(@"An unknown error occurred.");
                        break;
                }
            } else {
                // handle other error domains and their associated response codes...
                NSLog(@"%@", [error localizedDescription]);
            }
        }
    }];
}

-(NSString *)makeStringWithKeyAndValue:(NSString *)key value:(NSString *)value
{
    
    return [NSString stringWithFormat:@"\"%@\":\"%@\"", key, value];
    
    
    
}

-(NSString *)makeStringWithKeyAndValue2:(NSString *)key value:(NSString *)value
{
    
    return [NSString stringWithFormat:@"\"%@\":%@", key, value];

    
}


- (id)init {
    self = [super init];
    
    ids = [NSMutableArray new];

    friends = [NSMutableArray new];
    
#if !(TARGET_IPHONE_SIMULATOR)
    
    
#else
    
    
#endif
    
    return self;
    
}



+(id)sharedInstance
{
    static dispatch_once_t pred;
    static twitterHelper *sharedInstance = nil;
    dispatch_once(&pred, ^{
        sharedInstance = [[twitterHelper alloc] init];
    });
    return sharedInstance;
}

- (void)dealloc
{
    
    abort();
}
@end
