NWTwitterHelper
===============

Twitter helper to drill down user friends with SLRequest (iOS6)

Example require AFNetworking : https://github.com/AFNetworking/AFNetworking

Usage:

If you used external OAth you may store internal twitter account to iOS:

 [[twitterHelper sharedInstance] storeAccountWithAccessToken:access_token secret:token_secret completionBlock:^(BOOL result, NSError *error) {
  //some code          
 }];
 
 
 To get friends from twitter using twitter username (screen_name):
 
  [[twitterHelper sharedInstance] getFollowers:@"screen_name" completionBlock:^(BOOL result, NSError *error) {
                //here is code
  }];
  
  
  You will get a sample NSString with friends user_id, name, screen_name, profile_image_url in ((twitterHelper *)[twitterHelper sharedInstance]).stringFriends
