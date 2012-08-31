//
//  NotesListViewController.m
//  client
//
//  Evernote API sample code is provided under the terms specified in the file LICENSE.txt which was included with this distribution.
//

#import "NotesListViewController.h"
#import "RootViewController.h"
//#import "Evernote.h"
#import "SettingsViewController.h"
#import "SignInViewController.h"
#import "NoteViewController.h"
#import "Keys.h"
#import "EvernoteSDK.h"
@implementation NotesListViewController

 

//viewDidLoad method declared in RootViewController.m
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Noteprise";
    
    //Initialize the arrays
    listOfItems = [[NSMutableArray alloc] init];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Logout" style:UIBarButtonItemStyleBordered target:self action:@selector(logout)];
    backgroundImgView.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    backgroundImgView.contentMode = UIViewContentModeScaleAspectFill;
    [self changeBkgrndImgWithOrientation];
    [self fetchNoteBasedOnSelectedSegement];
}
-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
}
-(void)changeBkgrndImgWithOrientation {
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone){
        if(self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft || self.interfaceOrientation == UIInterfaceOrientationLandscapeRight)
            backgroundImgView.image = [UIImage imageNamed:@"bgE-480x287.png"];
        else {
            backgroundImgView.image = [UIImage imageNamed:@"bgE-320x480.png"];
        }
    } else {
        if(self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft || self.interfaceOrientation == UIInterfaceOrientationLandscapeRight)
            backgroundImgView.image = [UIImage imageNamed:@"bgE-1024x572.png"];
        else {
            backgroundImgView.image = [UIImage imageNamed:@"bgE-768x1024.png"];
        }
    }
}
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration{
     [self changeBkgrndImgWithOrientation];
}
-(IBAction)showSettings:(id)sender{
    SettingsViewController *settingsView = [[SettingsViewController alloc]initWithStyle:UITableViewStyleGrouped];
    settingsView.popover_delegate = self;
    UINavigationController *settingsNavCntrl = [[UINavigationController alloc] initWithRootViewController:settingsView];
	settingsNavCntrl.navigationBar.barStyle = UIBarStyleBlackOpaque;
    
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
		//sendSubView.view.frame=CGRectMake(0, 0, 300, 400);
		[self dissmissPopover];
		UIPopoverController *popoverSettings = [[UIPopoverController alloc] initWithContentViewController:settingsNavCntrl]; 
		//popoverSend.delegate = self;
		settingsView.contentSizeForViewInPopover =CGSizeMake(300, 400);
		popoverController = popoverSettings;
		[popoverSettings presentPopoverFromBarButtonItem:settingsBtn 
                                permittedArrowDirections:UIPopoverArrowDirectionAny 
                                                animated:YES];
        //[popoverSettings release];
        
	} else {
		UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleBordered
																		target:self action:@selector(dismissModalView)];      
		settingsView.navigationItem.leftBarButtonItem = cancelButton;
		[self.navigationController presentModalViewController:settingsNavCntrl animated:YES];
        [cancelButton release];
	}
    
    
}
-(IBAction)showNotes:(id)sender{
    if(searchOptionsChoiceCntrl.selectedSegmentIndex == 0){
        searchBar.userInteractionEnabled = NO;
        searchBar.alpha = 0.75;
        searchBar.text = @"";
        [Utility showCoverScreen];
        [self showLoadingLblWithText:LOADING_MSG];
        [listOfItems removeAllObjects];
        //[indexArray removeAllObjects];
        [searchBar resignFirstResponder];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^(void) {
            // Loading all the notebooks linked to the account using the evernote API
            [self fetchDataFromEverNote];
        });
    }
    else {
        searchBar.alpha = 1.0;
        searchBar.userInteractionEnabled = YES;
        [searchBar becomeFirstResponder];
    }
}
-(void)logout
{
    [[EvernoteSession sharedSession] logout];
    SignInViewController *loginView = [[SignInViewController alloc]init];
    [[[UIApplication sharedApplication]delegate]window].rootViewController = loginView;
    [loginView release];
}
-(void)fetchDataFromEverNote{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^(void) {
        // Loading all the notebook & tags linked to the account using the evernote API
        @try {
        EvernoteNoteStore *noteStore = [EvernoteNoteStore noteStore];
        [noteStore listNotebooksWithSuccess:^(NSArray *noteBooksArr) {
            DebugLog(@"notebooks fetched: %@", noteBooksArr);
            noteBooks = [noteBooksArr retain];
                    DebugLog(@"notebooks: %@", noteBooks);
        }
            failure:^(NSError *error) {
                            DebugLog(@"error %@", error);                                            
        }];
        [noteStore listTagsWithSuccess: ^(NSArray *tagsArr) {
                DebugLog(@"tagsArr fetched: %@", tagsArr);
                tags = [tagsArr retain];
                DebugLog(@"tagsArr: %@", tagsArr);
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    switch (searchOptionsChoiceCntrl.selectedSegmentIndex) {
                        case 0:
                            [searchBar resignFirstResponder];
                            [self listAllNotes];
                            break;
                        case 1:
                            [self searchByNotebook:searchBar.text];
                            break;
                        case 2:
                            [self searchByTag:searchBar.text];
                            break;
                        case 3:
                            [self searchByKeyword:searchBar.text];
                            break;
                        default:
                            break;
                    }  
                });
            }
        failure:^(NSError *error) {
               DebugLog(@"error %@", error);                                            
           }];

        }
        @catch (EDAMUserException *exception) {
            DebugLog(@"Recvd Exception:%d",exception.errorCode );
            [Utility showAlert:EVERNOTE_LOGIN_FAILED_MSG];
        }
        @catch (EDAMSystemException *exception) {
            [Utility showExceptionAlert:exception.description];
        }   
        @catch (EDAMNotFoundException *exception) {
            [Utility showExceptionAlert:SOME_ERROR_OCCURED_MESSAGE];
        }
    });
}


-(void)fetchNoteBasedOnSelectedSegement {
    [Utility showCoverScreen];
    [self showLoadingLblWithText:LOADING_MSG];
    //loadingLbl.text = LOADING_MSG;
    //loadingLbl.hidden = NO;
    [listOfItems removeAllObjects];
    [searchBar resignFirstResponder];
    // Loading all the notebooks linked to the account using the evernote API
    [self fetchDataFromEverNote];
}
-(void)showLoadingLblWithText:(NSString*)Loadingtext{
    dialog_imgView.hidden = NO;
    loadingLbl.text = Loadingtext;
    loadingLbl.hidden = NO;
}
-(void)hideDoneToastMsg:(id)sender{
	dialog_imgView.hidden = YES;
    loadingLbl.hidden = YES;
}
-(void)listAllNotes
{
    searchBar.userInteractionEnabled = NO;
    [listOfItems removeAllObjects];
    searchBar.alpha = 0.75;
    @try {
        for (int i = 0; i < [noteBooks count]; i++)
        {
            
            // listing all the notes for every notebook
            
            // Accessing notebook
            EDAMNotebook* notebook = (EDAMNotebook*)[noteBooks objectAtIndex:i];
            // Creating & configuring filter to load specific notebook 
            EDAMNoteFilter * filter = [[EDAMNoteFilter alloc] init];
            [filter setNotebookGuid:[notebook guid]];
            [filter setOrder:NoteSortOrder_TITLE];
            [filter setAscending:YES];
            
            // Searching on the Evernote API
             EvernoteNoteStore *noteStore = [EvernoteNoteStore noteStore];
            [noteStore findNotesWithFilter:filter offset:0 maxNotes:100 success:^(EDAMNoteList *noteList){
                for (EDAMNote *noteRead in noteList.notes) {
                    // Populating the arrays
                    NSMutableDictionary *noteListDict = [[NSMutableDictionary alloc]init];
                    [noteListDict setValue:[noteRead title] forKey:NOTE_KEY];
                    [noteListDict setValue:[noteRead guid] forKey:NOTE_GUID_KEY];
                    [listOfItems addObject:noteListDict];
                    [noteListDict release];
                }
                NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:NOTE_KEY  ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
                listOfItems = [[listOfItems sortedArrayUsingDescriptors:[NSArray arrayWithObjects:descriptor,nil]]mutableCopy];
                DebugLog(@"SORTED list Of all Notes: new%@",listOfItems);
                [self reloadNotesTable];
            } failure:^(NSError *error) {
                DebugLog(@" findNotesWithFilter error %@", error);    
                [Utility showExceptionAlert:error.description];
            }];
        }
    }
    @catch (EDAMSystemException *exception) {
        [Utility showExceptionAlert:exception.description];
    }   
    @catch (EDAMNotFoundException *exception) {
        [Utility showExceptionAlert:SOME_ERROR_OCCURED_MESSAGE];
    }
    @catch (id exception) {
        DebugLog(@"Recvd Exception");
        [Utility showExceptionAlert:ERROR_LISTING_NOTE_MSG];
    }
   
}
-(void)reloadNotesTable {
    [Utility hideCoverScreen];
    [searchBar resignFirstResponder];
    notesTbl.delegate =self;
    notesTbl.dataSource =self;
    [self hideDoneToastMsg:nil];
    loadingLbl.hidden = YES;
    [notesTbl reloadData];
}
-(void)searchByTag:(NSString*)searchTag {
   
    [listOfItems removeAllObjects];
    EDAMNoteFilter * filter  = nil;
    EDAMTag * tag = nil;
   
    for(EDAMTag * aTag in tags)
    {
        if([[aTag name] rangeOfString:searchTag options:NSCaseInsensitiveSearch].location!=NSNotFound){
            tag = aTag;
        }
    }
    if((!tag && ![Utility isBlank:searchTag]) || tag){
        @try {
            [Utility showCoverScreen];
            [self showLoadingLblWithText:progress_dialog_tag_search_message];
            for (int i = 0; i < [noteBooks count]; i++) {
                
                // Accessing notebook
                EDAMNotebook* notebook = (EDAMNotebook*)[noteBooks objectAtIndex:i];
                EvernoteNoteStore *noteStore = [EvernoteNoteStore noteStore];
                // Creating & configuring filter to load specific notebook 
                filter = [[EDAMNoteFilter alloc] init];
                [filter setNotebookGuid:[notebook guid]];
                
                //Search By Tag
                if([tag guid])
                    [filter setTagGuids:[NSArray arrayWithObject:[tag guid]]];
                
                // Searching on the Evernote API
                [noteStore findNotesWithFilter:filter offset:0 maxNotes:100 success:^(EDAMNoteList *noteList){
                    for (EDAMNote *noteRead in noteList.notes) {
                        // Populating the arrays
                        NSMutableDictionary *noteListDict = [[NSMutableDictionary alloc]init];
                        [noteListDict setValue:[noteRead title] forKey:NOTE_KEY];
                        [noteListDict setValue:[noteRead guid] forKey:NOTE_GUID_KEY];
                        [listOfItems addObject:noteListDict];
                        [noteListDict release];
                    }
                    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:NOTE_KEY  ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
                    listOfItems = [[listOfItems sortedArrayUsingDescriptors:[NSArray arrayWithObjects:descriptor,nil]]mutableCopy];
                    DebugLog(@"listOfItems: tag%@",listOfItems);
                    [self reloadNotesTable];
                } failure:^(NSError *error) {
                    [Utility hideCoverScreen];
                    loadingLbl.hidden = YES;
                    DebugLog(@" findNotesWithFilter error %@", error);    
                    [Utility showExceptionAlert:error.description];
                }];
        }
        }
        @catch (EDAMSystemException *exception) {
            [Utility hideCoverScreen];
            [self hideDoneToastMsg:nil];
            [Utility showExceptionAlert:exception.description];
        }   
        @catch (EDAMNotFoundException *exception) {
            [Utility hideCoverScreen];
            [self hideDoneToastMsg:nil];
            [Utility showExceptionAlert:SOME_ERROR_OCCURED_MESSAGE];
        }
        @catch (id exception) {
            [Utility hideCoverScreen];
            [self hideDoneToastMsg:nil];
            DebugLog(@"Recvd Exception");
            [Utility showExceptionAlert:ERROR_LISTING_NOTE_MSG];
        }
    }
    else{ 
        [Utility hideCoverScreen];
        [self hideDoneToastMsg:nil];
        [Utility showAlert:note_please_enter_text_for_search_message];
        [self reloadNotesTable];
    }
}
-(void)searchByNotebook:(NSString*)searchNotebook {
    @try {
        
        for (int i = 0; i < [noteBooks count]; i++)
        {
            
            // Accessing notebook
            EDAMNotebook* notebook = (EDAMNotebook*)[noteBooks objectAtIndex:i];
            EvernoteNoteStore *noteStore = [EvernoteNoteStore noteStore];
            // Creating & configuring filter to load specific notebook 
            EDAMNoteFilter * filter = [[EDAMNoteFilter alloc] init];
            [filter setNotebookGuid:[notebook guid]];
            
            //By NoteBookName
            DebugLog(@"noteBook Name %@",[notebook name]);

            
            if([[notebook name] rangeOfString:searchNotebook options:NSCaseInsensitiveSearch].location==NSNotFound)
            {
                if(i == [noteBooks count]- 1) {
                    [Utility showAlert:note_please_enter_text_for_search_message];
                    [self reloadNotesTable];
                }
                continue;
                
            }
            
            // Searching on the Evernote API
            [noteStore findNotesWithFilter:filter offset:0 maxNotes:100 success:^(EDAMNoteList *noteList){
                for (EDAMNote *noteRead in noteList.notes) {
                    // Populating the arrays
                    NSMutableDictionary *noteListDict = [[NSMutableDictionary alloc]init];
                    //EDAMNote* note = (EDAMNote*)[[notes notes] objectAtIndex:j];
                    [noteListDict setValue:[noteRead title] forKey:NOTE_KEY];
                    [noteListDict setValue:[noteRead guid] forKey:NOTE_GUID_KEY];
                    [listOfItems addObject:noteListDict];
                    [noteListDict release];
                }
                NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:NOTE_KEY  ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
                listOfItems = [[listOfItems sortedArrayUsingDescriptors:[NSArray arrayWithObjects:descriptor,nil]]mutableCopy];
                DebugLog(@"sorted list Of noted search by notebook%@",listOfItems);
                [self reloadNotesTable];
            } failure:^(NSError *error) {
                [Utility hideCoverScreen];
                loadingLbl.hidden = YES;
                DebugLog(@" findNotesWithFilter error %@", error);
                [Utility showExceptionAlert:error.description];
            }];
    }
    }
    @catch (EDAMSystemException *exception) {
        [Utility showExceptionAlert:exception.description];
    }   
    @catch (EDAMNotFoundException *exception) {
        [Utility showExceptionAlert:SOME_ERROR_OCCURED_MESSAGE];
    }
    @catch (id exception) {
        DebugLog(@"Recvd Exception");
        [Utility showExceptionAlert:ERROR_LISTING_NOTE_MSG];
    }
    
}
-(void)searchByKeyword:(NSString*)searchKeyword {
    if((![Utility isBlank:searchKeyword])){
        @try {
            [Utility showCoverScreen];
            [self showLoadingLblWithText:progress_dialog_keyword_search_message];
            for (int i = 0; i < [noteBooks count]; i++) {
                
                // Accessing notebook
                EDAMNotebook* notebook = (EDAMNotebook*)[noteBooks objectAtIndex:i];
                EvernoteNoteStore *noteStore = [EvernoteNoteStore noteStore];
                // Creating & configuring filter to load specific notebook 
                EDAMNoteFilter * filter = [[EDAMNoteFilter alloc] init];
                [filter setNotebookGuid:[notebook guid]];
                
                //Search Function.
                [filter setWords:searchKeyword]; 
                
                // Searching on the Evernote API
                [noteStore findNotesWithFilter:filter offset:0 maxNotes:100 success:^(EDAMNoteList *noteList){
                    for (EDAMNote *noteRead in noteList.notes) {
                        // Populating the arrays
                        NSMutableDictionary *noteListDict = [[NSMutableDictionary alloc]init];
                        [noteListDict setValue:[noteRead title] forKey:NOTE_KEY];
                        [noteListDict setValue:[noteRead guid] forKey:NOTE_GUID_KEY];
                        [listOfItems addObject:noteListDict];
                        [noteListDict release];
                    }
                    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:NOTE_KEY ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
                    listOfItems = [[listOfItems sortedArrayUsingDescriptors:[NSArray arrayWithObjects:descriptor,nil]]mutableCopy];
                    DebugLog(@"sorted listOf notes search by keyword %@",listOfItems);
                    [self reloadNotesTable];
                } failure:^(NSError *error) {
                    [Utility hideCoverScreen];
                    loadingLbl.hidden = YES;
                    DebugLog(@" findNotesWithFilter error %@", error);   
                    [Utility showExceptionAlert:error.description];
                }];
            }
        }
        @catch (EDAMSystemException *exception) {
            [self hideDoneToastMsg:nil];
            [Utility hideCoverScreen];
            [Utility showExceptionAlert:exception.description];
        }   
        @catch (EDAMNotFoundException *exception) {
            [self hideDoneToastMsg:nil];
            [Utility hideCoverScreen];
            [Utility showExceptionAlert:SOME_ERROR_OCCURED_MESSAGE];
        }
        @catch (id exception) {
            [self hideDoneToastMsg:nil];
            [Utility hideCoverScreen];
            DebugLog(@"Recvd Exception");
            [Utility showExceptionAlert:ERROR_LISTING_NOTE_MSG];
        }
    } else {
        [self hideDoneToastMsg:nil];
        [Utility hideCoverScreen];
        [Utility showAlert:note_please_enter_text_for_search_message];
        [self reloadNotesTable];
    }
}
#pragma mark -
#pragma mark UISearchBar Delegate
- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar{
    DebugLog(@"searchBarShouldBeginEditing");
    return YES;
}

- (void) searchBarTextDidEndEditing:(UISearchBar *)searchBar:(UISearchBar *)theSearchBar {
}
- (void)searchBarCancelButtonClicked:(UISearchBar *) searchBar{
    
}

-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBarContent {
    [Utility showCoverScreen];
    [self showLoadingLblWithText:LOADING_MSG];
    [listOfItems removeAllObjects];
    //[indexArray removeAllObjects];
    [searchBar resignFirstResponder];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^(void) {
        // Loading all the notebooks linked to the account using the evernote API
        [self fetchDataFromEverNote];
        
    });

}
-(IBAction)addNote:(id)sender {
    AddNoteViewController *addNoteVCntrl = [[AddNoteViewController alloc]init];
    addNoteVCntrl.delegate =self;
    UINavigationController *addNoteNavCntrl = [[UINavigationController alloc] initWithRootViewController:addNoteVCntrl];
	addNoteNavCntrl.navigationBar.barStyle = UIBarStyleBlackOpaque;
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
		[self dissmissPopover];
		UIPopoverController *popoverSettings = [[UIPopoverController alloc] initWithContentViewController:addNoteNavCntrl]; 
		addNoteVCntrl.contentSizeForViewInPopover =CGSizeMake(300, 400);
		popoverController = popoverSettings;
		[popoverSettings presentPopoverFromBarButtonItem:addNoteBtn 
                                permittedArrowDirections:UIPopoverArrowDirectionAny 
                                                animated:YES];
        
	} else {
		UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleBordered
																		target:self action:@selector(dismissModalView)];      
		addNoteVCntrl.navigationItem.leftBarButtonItem = cancelButton;
		[self.navigationController presentModalViewController:addNoteNavCntrl animated:YES];
        [cancelButton release];
	}
}
-(void)dismissModalView {
    [self.navigationController dismissModalViewControllerAnimated:YES];
}
-(void)dissmissPopover {
    if(popoverController!=nil)
        [popoverController dismissPopoverAnimated:YES];
}
- (void)evernoteCreatedSuccessfullyListener{
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        [self dissmissPopover];
    else {
        [self.navigationController dismissModalViewControllerAnimated:YES];
    }
    [self fetchNoteBasedOnSelectedSegement];
}
- (void)evernoteCreationFailedListener{
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        [self dissmissPopover];
    else {
        [self.navigationController dismissModalViewControllerAnimated:YES];
    }
}
/************************************************************
 *
 *  Function opening the next view
 *
 ************************************************************/
#pragma mark -
#pragma mark UITableView delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    selectedRowIndex = indexPath.row;
    NSString * guid = (NSString *)[ [listOfItems objectAtIndex:indexPath.row]valueForKey:NOTE_GUID_KEY]; 
    NoteViewController* noteViewController = [[NoteViewController alloc] init];
    noteViewController.title = (NSString *)[ [listOfItems objectAtIndex:indexPath.row]valueForKey:NOTE_KEY];
    [noteViewController setGuid:guid];
    [self.navigationController pushViewController:noteViewController animated:YES];
}

/************************************************************
 *
 *  Function deleting a note
 *
 ************************************************************/

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString * guid = (NSString *)[[listOfItems objectAtIndex:[indexPath row]]valueForKey:NOTE_GUID_KEY]; 
    EvernoteNoteStore *noteStore = [EvernoteNoteStore noteStore];
    // As an example, we are going to show the first element if it is an image
    [noteStore deleteNoteWithGuid:guid success:^(int32_t success)
     {
         [Utility showAlert:NOTE_DELETE_SUCCESS_MSG];
         DebugLog(@"deleteNoteWithGuid %d ::::",success);
         [Utility hideCoverScreen];
         loadingLbl.hidden = YES;
     }failure:^(NSError *error) {
         DebugLog(@"note::::::::error %@", error);	
        [Utility showAlert:NOTE_DELETE_FAILED_MSG];
         [Utility hideCoverScreen];
         loadingLbl.hidden = YES;
     }];
    
    // Removing the note from our cache
    [listOfItems removeObjectAtIndex:[indexPath row]];
    [self fetchNoteBasedOnSelectedSegement];
    
}



/************************************************************
 *
 *  Functions configuring the listView
 *
 ************************************************************/

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [listOfItems count];
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    //[self initConextAndFetchController];
	return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier]autorelease];
    }
    
    NSString *cellValue = [[listOfItems objectAtIndex:indexPath.row]valueForKey:NOTE_KEY];
    cell.textLabel.text = cellValue;
    cell.textLabel.font = [UIFont fontWithName:@"ChalkboardSE-Regular" size:16];
    cell.textLabel.textColor = [UIColor blackColor];
    cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    return cell;
}
#pragma mark -
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}
//dealloc method declared in RootViewController.m
- (void)dealloc {
    
    [listOfItems release];
    [super dealloc];
}

@end
