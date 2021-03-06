     //
     //  FirstViewController.h
     //  client
     //

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreLocation/CoreLocation.h>
#import "ProgressIndicatorView.h"

@protocol AddNotesViewDelegate <NSObject>
- (void)evernoteCreatedSuccessfullyListener;
- (void)evernoteCreationFailedListener;
@end
@interface AddNoteViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPickerViewDelegate,UIPickerViewDataSource,CLLocationManagerDelegate,UIWebViewDelegate, UIAlertViewDelegate> {
          //UIPickerView * notebookPicker;
     CLLocationManager *locationManager;
     NSMutableArray *listOfItems;
     NSMutableArray *indexArray;
     UIButton * doneButtonPicker;
     UITextField * titleNote;
     UIButton * sendNote;
     IBOutlet UIWebView *bodyTxtView;
     UIImageView * imageView;
     UIActionSheet *sortTypeActionSheet;
     int selectedNotebookIndex;
//     IBOutlet UIActivityIndicatorView *loadingSpinner;
//     IBOutlet UIImageView *dialog_imgView;
//     IBOutlet UILabel *loadingLbl;
     IBOutlet UITableView *notebooksTbl;
     UIPopoverController *popController;
     id <AddNotesViewDelegate> delegate;
//     IBOutlet UIImageView *doneImgView;
     CGFloat animatedDistance; //textfield correction when keyboard is out
    
    ProgressIndicatorView * progressIndicatorView;
    
    UIView * layerView;
    
    BOOL areNotebooksLoaded;
}

@property (nonatomic, assign) id <NSObject, AddNotesViewDelegate > delegate;
@property (nonatomic, retain) IBOutlet UITextField * titleNote;
@property (nonatomic, retain) IBOutlet UIButton * sendNote;
@property (nonatomic, retain) UITableViewController * popoverContent;
@property (nonatomic, retain) IBOutlet UIImageView * imageView;
@property (nonatomic, retain) IBOutlet UIButton * selectNotebooksButton;


- (IBAction) getPhoto:(id) sender;
-(IBAction)createNoteEvernote:(id)sender;
-(void)addProgressIndicatorView;

@end
