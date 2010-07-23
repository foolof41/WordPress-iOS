//
//  AddUsersBlogsViewController.m
//  WordPress
//
//  Created by Chris Boyd on 7/19/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import "AddUsersBlogsViewController.h"

@implementation AddUsersBlogsViewController
@synthesize usersBlogs, selectedBlogs, tableView, buttonAddSelected, buttonSelectAll, hasCompletedGetUsersBlogs;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	self.navigationItem.title = @"Select Blogs";
	selectedBlogs = [[NSMutableArray alloc] init];
	appDelegate = [WordPressAppDelegate sharedWordPressApp];
	
	// Setup WPcom table header
	UIView *headerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 70)] autorelease];
	UIImageView *logo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo_wpcom.png"]];
	logo.frame = CGRectMake(40, 20, 229, 43);
	[headerView addSubview:logo];
	self.tableView.tableHeaderView = headerView;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTableView) 
												 name:@"didUpdateFavicons" object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cancelAddWPcomBlogs) 
												 name:@"didCancelWPcomLogin" object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	if(!appDelegate.isWPcomAuthenticated) {
		WPcomLoginViewController *wpComLogin = [[WPcomLoginViewController alloc] initWithNibName:@"WPcomLoginViewController" bundle:nil];
		[self.navigationController presentModalViewController:wpComLogin animated:YES];
		[wpComLogin release];
	}
	else {
		if([[NSUserDefaults standardUserDefaults] objectForKey:@"WPcomUsersBlogs"] != nil)
			usersBlogs = [[NSUserDefaults standardUserDefaults] objectForKey:@"WPcomUsersBlogs"];
		
		[self performSelectorInBackground:@selector(refreshBlogs) withObject:nil];
	}
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return usersBlogs.count;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
	UIView *footerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 50)] autorelease];
	if((usersBlogs.count == 0) && (!hasCompletedGetUsersBlogs)) {
		UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(80, 0, 20, 20)];
		spinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
		[spinner startAnimating];
		[footerView addSubview:spinner];
		
		UILabel *footerText = [[UILabel alloc] initWithFrame:CGRectMake(110, 0, 200, 20)];
		footerText.backgroundColor = [UIColor clearColor];
		footerText.textColor = [UIColor darkGrayColor];
		footerText.text = @"Loading blogs...";
		[footerView addSubview:footerText];
	}
	else if((usersBlogs.count == 0) && (hasCompletedGetUsersBlogs)) {
		UILabel *footerText = [[UILabel alloc] initWithFrame:CGRectMake(110, 0, 200, 20)];
		footerText.backgroundColor = [UIColor clearColor];
		footerText.textColor = [UIColor darkGrayColor];
		footerText.text = @"No blogs found.";
		[footerView addSubview:footerText];
	}

	return footerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
	return 60;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
	
	cell.textLabel.textAlignment = UITextAlignmentLeft;
	
	Blog *blog = [usersBlogs objectAtIndex:indexPath.row];
	if([selectedBlogs containsObject:blog.blogID])
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	else
		cell.accessoryType = UITableViewCellAccessoryNone;
	cell.textLabel.text = blog.blogName;
	
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	Blog *selectedBlog = [[Blog alloc] init];
	selectedBlog = [usersBlogs objectAtIndex:indexPath.row];
	
	if(![selectedBlogs containsObject:selectedBlog.blogID]) {
		[selectedBlogs addObject:selectedBlog.blogID];
	}
	else {
		int indexToRemove = -1;
		int count = 0;
		for (NSString *blogID in selectedBlogs) {
			if([blogID isEqualToString:selectedBlog.blogID]) {
				indexToRemove = count;
				break;
			}
			count++;
		}
		if(indexToRemove > -1)
			[selectedBlogs removeObjectAtIndex:indexToRemove];
	}
	[tv reloadData];
	
	if(selectedBlogs.count == usersBlogs.count)
		[self selectAllBlogs:self];
	else if(selectedBlogs.count == 0)
		[self deselectAllBlogs:self];

	[tv deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -
#pragma mark Custom methods
									   
- (void)selectAllBlogs:(id)sender {
	[selectedBlogs removeAllObjects];
	for(Blog *blog in usersBlogs) {
		[selectedBlogs addObject:blog.blogID];
	}
	[self reloadTableView];
	buttonSelectAll.title = @"Deselect All";
	buttonSelectAll.action = @selector(deselectAllBlogs:);
}

- (void)deselectAllBlogs:(id)sender {
	[selectedBlogs removeAllObjects];
	[self reloadTableView];
	buttonSelectAll.title = @"Select All";
	buttonSelectAll.action = @selector(selectAllBlogs:);
}

- (void)refreshBlogs {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	NSString *url = kWPcomXMLRPCUrl;
	usersBlogs = [[WPDataController sharedInstance] getBlogsForUsername:url 
															   username:[[NSUserDefaults standardUserDefaults] objectForKey:@"WPcomUsername"]
															   password:[[NSUserDefaults standardUserDefaults] objectForKey:@"WPcomPassword"]];
	hasCompletedGetUsersBlogs = YES;
	if(usersBlogs.count > 0) {
		self.tableView.tableFooterView = nil;
		self.navigationItem.rightBarButtonItem.enabled = YES;
	}
	[self performSelectorInBackground:@selector(updateFavicons) withObject:nil];
	
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[pool release];
}

- (IBAction)saveSelectedBlogs:(id)sender {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	WPProgressHUD *spinner = [[WPProgressHUD alloc] initWithLabel:@"Saving..."];
	[spinner show];
	
	for (Blog *blog in usersBlogs) {
		if([selectedBlogs containsObject:blog.blogID]) {
			[self createBlog:blog];
		}
	}
	NSLog(@"finished saving blogs...");
	
	[spinner dismiss];
	[spinner release];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[appDelegate.navigationController popToRootViewControllerAnimated:YES];
}

- (void)createBlog:(Blog *)blog {
	blog.url = [blog.url stringByReplacingOccurrencesOfString:@"http://" withString:@""];
	//blog.url = [blog.url stringByReplacingOccurrencesOfString:@".wordpress.com" withString:@""];
	NSString *username = blog.username;
	NSString *pwd = blog.password;
	NSString *url = [blog.url stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	NSNumber *value = [NSNumber numberWithBool:NO];
	NSString *authUsername = blog.username;
	NSString *authPassword = blog.password;
	NSNumber *authEnabled = [NSNumber numberWithBool:YES];
	NSString *authBlogURL = [NSString stringWithFormat:@"%@_auth", url];
	
	NSMutableDictionary *newBlog = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
									 username, @"username", 
									 url, @"url", 
									 authEnabled, @"authEnabled", 
									 authUsername, @"authUsername", 
									 nil] retain];
    if ([[BlogDataManager sharedDataManager] doesBlogExist:newBlog]) {
        return;
	}
	else {
		[[BlogDataManager sharedDataManager] resetCurrentBlog];
		
		[newBlog setValue:url forKey:@"url"];
		[newBlog setValue:blog.xmlrpc forKey:@"xmlrpc"];
		[newBlog setValue:blog.blogID forKey:kBlogId];
		[newBlog setValue:blog.blogName forKey:@"blogName"];
		[newBlog setValue:username forKey:@"username"];
		[newBlog setValue:authEnabled forKey:@"authEnabled"];
		[[BlogDataManager sharedDataManager] updatePasswordInKeychain:pwd andUserName:username andBlogURL:url];
		
		[newBlog setValue:authUsername forKey:@"authUsername"];
		[[BlogDataManager sharedDataManager] updatePasswordInKeychain:authPassword
														  andUserName:authUsername
														   andBlogURL:authBlogURL];
		[newBlog setValue:value forKey:kResizePhotoSetting];
		[newBlog setValue:[NSNumber numberWithBool:YES] forKey:kSupportsPagesAndComments];
		
		[BlogDataManager sharedDataManager].isProblemWithXMLRPC = NO;
        [newBlog setObject:[NSNumber numberWithInt:1] forKey:@"kIsSyncProcessRunning"];
        [[BlogDataManager sharedDataManager] wrapperForSyncPostsAndGetTemplateForBlog:[BlogDataManager sharedDataManager].currentBlog];
        [newBlog setObject:[NSNumber numberWithInt:0] forKey:@"kIsSyncProcessRunning"];
		[[BlogDataManager sharedDataManager] setCurrentBlog:newBlog];
		[BlogDataManager sharedDataManager].currentBlogIndex = -1;
        [[BlogDataManager sharedDataManager] saveCurrentBlog];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:@"BlogsRefreshNotification" object:nil];
}

- (void)updateFavicons {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	for(Blog *blog in usersBlogs) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"didUpdateFavicons" object:@"Completed."];
	}
	
	[pool release];
}

- (void)reloadTableView {
	//if(usersBlogs.count > 0) {
	//	// Save usersBlogs to persistent data store.
	//}
	[self.tableView reloadData];
	[self.tableView setNeedsLayout];
}

- (void)cancelAddWPcomBlogs {
	UIViewController *controller = [self.navigationController.viewControllers objectAtIndex:1];
	[self.navigationController popToViewController:controller animated:NO];
}

#pragma mark -
#pragma mark HTTPHelper methods

- (void)httpSuccessWithDataString:(NSString *)data {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)httpFailWithError:(NSError *)error {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
}

- (void)dealloc {
	[usersBlogs release];
	[selectedBlogs release];
	[tableView release];
	[buttonAddSelected release];
	[buttonSelectAll release];
    [super dealloc];
}


@end

