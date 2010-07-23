//
//  WelcomeViewController.h
//  WordPress
//
//  Created by Dan Roundhill on 5/5/10.
//  
//

#import <UIKit/UIKit.h>
#import "WordPressAppDelegate.h"
#import "BlogsViewController.h"
#import "WebSignupViewController.h"
#import "AddUsersBlogsViewController.h"
#import "EditBlogViewController.h"
#import "BlogDataManager.h"

@interface WelcomeViewController : UIViewController<UITableViewDelegate> {
	IBOutlet UITableView *tableView;
	WordPressAppDelegate *appDelegate;
	AddUsersBlogsViewController *addUsersBlogsView;
}

@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) WordPressAppDelegate *appDelegate;
@property (nonatomic, retain) AddUsersBlogsViewController *addUsersBlogsView;

@end
