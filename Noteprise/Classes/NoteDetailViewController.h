//  NoteDetailViewController.h
//
//

#import <UIKit/UIKit.h>
#import "SFRestAPI.h"

#define kAnimationDuration  0.2f
#define kEditButtonTag      1

@class NotesListViewController;
@class NotesViewController;


//static int editBtnTag = 1;
//static int saveBtnTag = 2;


@interface NoteDetailViewController : UIViewController <UIWebViewDelegate,SFRestDelegate,UIActionSheetDelegate,UITextFieldDelegate, UIAlertViewDelegate, UIGestureRecognizerDelegate, UISplitViewControllerDelegate>
{
     NSString *orgNoteTitle;
     UINavigationBar * noteNavigation;
     //UITextView * noteContent;
     UIWebView * noteContent;
     //UIImageView * noteImage;
     IBOutlet UIActivityIndicatorView *loadingSpinner;
//     IBOutlet UIImageView *dialog_imgView;
//     IBOutlet UILabel *loadingLbl;
     IBOutlet UIImageView *backgroundImgView;
     
          //UIBarButtonItem *saveButton;
          //UIBarButtonItem *editButton;
          //UIToolbar* toolbar;
     UITextField *editTitleField;
//     IBOutlet UIImageView *doneImgView;
     UIActionSheet *postToChatterOptionActionSheet;
		//IBOutlet
	IBOutlet UIToolbar *bottomBar;
	UIBarButtonItem *flexible;

	UIBarButtonItem *saveToSFBarBtn;
		// IBOutlet
	UIBarButtonItem *postToChatterBarBtn;
    NSString *tempTitle;
    
    NSString * oldContent;
    NSString * oldTitle;
    
    UIView * borderView;
    
    bool isEditNoteCancelled;
    
    BOOL updateNotesListAfterNoteEditing;
    
    BOOL isWebViewInitialized;
}


@property (strong, nonatomic) NotesListViewController * masterViewController;
@property (strong, nonatomic) NotesViewController * notesViewController;
@property(nonatomic, assign) NSString * guid;
@property(nonatomic, assign) NSString *readProp;

//@property (nonatomic, retain) IBOutlet UIImageView * noteImage;

@property (nonatomic, retain) IBOutlet UINavigationBar * noteNavigation;
//@property (nonatomic, retain) IBOutlet UITextView * noteContent;
@property (nonatomic, retain) IBOutlet UIWebView * noteContent;
@property (nonatomic, retain) NSMutableString * textContent;
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
@property (nonatomic, retain) IBOutlet UIImageView * logoImageView;


-(void)goBack:(id)sender;
-(void)moveToSF;
-(void)setContentEditable:(BOOL)isEditable;
-(void)setWebViewKeyPressDetectionEnabled:(BOOL)isEnabled ;
-(void)setWebViewTapDetectionEnabled:(BOOL)isEnabled ;
-(void)increaseZoomFactorRange;
-(void)updateNoteEvernote;
     //-(void)setupNavigationButtons ;
-(void)changeBkgrndImgWithOrientation;
-(void)hideDoneToastMsg:(id)sender;
- (NSString *)getDataBetweenFromString:(NSString *)data leftString:(NSString *)leftData rightString:(NSString *)rightData leftOffset:(NSInteger)leftPos;
-(void)dismissPreviousPopover;
//-(void)showLoadingLblWithText:(NSString*)Loadingtext;
-(void)postToChatterWall ;
-(void)showSelectedNoteContent;
-(void)reloadNoteDetailsAfterUpdatingNote;

@end
