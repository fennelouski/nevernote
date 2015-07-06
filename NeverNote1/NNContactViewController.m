//
//  NNContactViewController.m
//  NeverNote
//
//  Created by Nathan Fennel on 5/17/14.
//  Copyright (c) 2014 Nathan Fennel. All rights reserved.
//

#import "NNContactViewController.h"

// screen width
#define kScreenWidth [UIScreen mainScreen].bounds.size.width

// screen height
#define kScreenHeight [UIScreen mainScreen].bounds.size.height

// status bar height
#define kStatusBarHeight [[UIApplication sharedApplication] statusBarFrame].size.height

// Contact Image
#define CONTACT_IMAGE_Y_OFFSET 18.0f
#define CONTACT_IMAGE_SIZE 82.0f
#define CONTACT_CORNER_RADIUS 5.0f
#define CONTACT_BORDER_WIDTH 0.5f

// Scroll View
#define SCROLL_VIEW_EDGE_MARGIN 10.0f
#define SCROLL_VIEW_CONTENT_SIZE 10000.0f

// Text Field
#define TEXT_FIELD_HEIGHT 44.0f
#define TEXT_FIELD_LEFT_MARGIN 10.0f
#define KEYBOARD_HEIGHT 216.0f
#define INPUT_ACCESSORY_VIEW_HEIGHT 44.0f
#define NAME_TEXT_FIELD_HEIGHT 50.0f
#define NAME_TEXT_FIELD_FONT_SIZE 22.0f
#define NAME_TEXT_FIELD_Y_OFFSET CONTACT_IMAGE_Y_OFFSET + CONTACT_IMAGE_SIZE - SCROLL_VIEW_EDGE_MARGIN/4
#define TITLE_TEXT_FIELD_HEIGHT 45.0f
#define TITLE_TEXT_FIELD_WIDTH kScreenWidth/4 + SCROLL_VIEW_EDGE_MARGIN
#define TITLE_TEXT_FIELD_MAX_WIDTH kScreenWidth - TEXT_FIELD_LEFT_MARGIN
#define TITLE_TEXT_FIELD_FONT_SIZE 18.0f
#define TITLE_TEXT_FIELD_Y_OFFSET CONTACT_IMAGE_Y_OFFSET + CONTACT_IMAGE_SIZE + NAME_TEXT_FIELD_HEIGHT/2 + SCROLL_VIEW_EDGE_MARGIN/4
#define TITLE_TEXT_FIELD_X_OFFSET kScreenWidth/4 - SCROLL_VIEW_EDGE_MARGIN
#define FONT_SIZE 15.0f
#define TEXT_FIELD_SEPARATOR_WIDTH 1.0f
#define EMAIL_TAG 987
#define PHONE_TAG 9876
#define ADDRESS_TAG 98765
#define TEXT_FIELD_Y_OFFSET NAME_TEXT_FIELD_HEIGHT/2 + SCROLL_VIEW_EDGE_MARGIN/4

// At Label
#define AT_LABEL_WIDTH 25.0f
#define AT_LABEL_FONT_SIZE 17.0f

// Keyboard specs
#define BUTTON_HEIGHT KEYBOARD_HEIGHT/4
#define BUTTON_BORDER_WIDTH 0.45f
#define TIME_BUTTON_FONT_SIZE 28.0f


typedef NS_ENUM(NSUInteger, KeyboardType) {
	KeyboardTypeEmailAddress,
	KeyboardTypePhoneNumber,
	KeyboardTypeAddress,
	KeyboardTypeName
};

@interface NNContactViewController ()

@property (nonatomic, strong) UIScrollView *contactScrollView;

@property (nonatomic, strong) UIImageView *contactImage;

@property (nonatomic, strong) UIView *textFieldView;

@property (nonatomic, strong) UITextField *nameTextField, *titleTextField, *titleTextField2, *companyTextField, *companyTextField2, *emailTextField, *phoneTextField, *addressTextField, *currentTextField;


@property (nonatomic, strong) UILabel *nameLabel, *titleLabel, *atLabel;

@property (nonatomic, strong) UIToolbar *keyboardTypeToolbar;

@property (nonatomic, strong) UIButton *lastKeyboardButton;

@property (nonatomic, strong) UIView *addressKeyboardStreetNumber;

@property (nonatomic) BOOL addressStreetNumberEntered, addressStreetNameEntered, addressCityEntered, addressStateEntered, addressZipCodeEntered, addedTitleTextField2, addedCompanyTextField2;

@property (nonatomic) NSInteger currentInitialInput;

@property (nonatomic) float periodWidth;

@property (nonatomic, strong) NSMutableArray *listOfTextFields;

@end

@implementation NNContactViewController
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _currentInitialInput = KeyboardTypeEmailAddress;
        _listOfTextFields = [[NSMutableArray alloc] initWithCapacity:12];
        _periodWidth = [@"." sizeWithAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:TITLE_TEXT_FIELD_FONT_SIZE]}].width;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(checkForEmptyTextField)
                                                     name:UITextFieldTextDidChangeNotification
                                                   object:_titleTextField2];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setUpGestureRecognizers];
    
    [self.view addSubview:self.contactScrollView];
    [self.nameTextField becomeFirstResponder];
}

- (void) setUpGestureRecognizers {
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRight)];
    [swipeRight setDirection:UISwipeGestureRecognizerDirectionRight];
    [self.view addGestureRecognizer:swipeRight];
}

- (UIScrollView *)contactScrollView {
    if (!_contactScrollView) {
        _contactScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, kScreenHeight)];
        [_contactScrollView setContentInset:UIEdgeInsetsMake(SCROLL_VIEW_EDGE_MARGIN, 0, KEYBOARD_HEIGHT, 0)];
        [_contactScrollView setScrollEnabled:YES];
        [_contactScrollView setScrollsToTop:YES];
        [_contactScrollView setUserInteractionEnabled:YES];
        [_contactScrollView setKeyboardDismissMode:UIScrollViewKeyboardDismissModeOnDrag];
        
        [_contactScrollView addSubview:self.contactImage];
        [_contactScrollView addSubview:self.nameTextField];
        [_contactScrollView addSubview:self.titleTextField];
        [_contactScrollView addSubview:self.atLabel];
        [_contactScrollView addSubview:self.companyTextField];
        [_contactScrollView addSubview:self.textFieldView];
        
        [_contactScrollView setContentSize:self.textFieldView.frame.size];
    }
    
    return _contactScrollView;
}

// Contact Picture
- (UIImageView *)contactImage {
    if (!_contactImage) {
        _contactImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, CONTACT_IMAGE_Y_OFFSET, CONTACT_IMAGE_SIZE, CONTACT_IMAGE_SIZE)];
        [_contactImage setCenter:CGPointMake(kScreenWidth/2, CONTACT_IMAGE_SIZE/2 + SCROLL_VIEW_EDGE_MARGIN)];
        [_contactImage setImage:[self imageWithColor:[UIColor colorWithHue:(arc4random()%255)/255.0f saturation:(arc4random()%255)/255.0f brightness:(arc4random()%255)/255.0f alpha:1.0f]]];
        [_contactImage.layer setCornerRadius:CONTACT_CORNER_RADIUS];
        [_contactImage.layer setBorderColor:[UIColor colorWithWhite:0.91f alpha:0.5f].CGColor];
        [_contactImage.layer setBorderWidth:CONTACT_BORDER_WIDTH];
        [_contactImage.layer setMasksToBounds:YES];
        // get gravatar
    }
    
    return _contactImage;
}

#pragma mark - Name TextField
- (UITextField *)nameTextField {
    if (!_nameTextField) {
        _nameTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, NAME_TEXT_FIELD_Y_OFFSET, kScreenWidth, NAME_TEXT_FIELD_HEIGHT)];
        [_nameTextField setPlaceholder:@"Name"];
        [_nameTextField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
        [_nameTextField setAutocorrectionType:UITextAutocorrectionTypeNo];
        [_nameTextField setTextAlignment:NSTextAlignmentCenter];
        [_nameTextField setFont:[UIFont systemFontOfSize:NAME_TEXT_FIELD_FONT_SIZE]];
        
        [_nameTextField setDelegate:self];
    }
    
    return _nameTextField;
}

#pragma mark - Job Title TextField
- (UITextField *)titleTextField {
    if (!_titleTextField) {
        _titleTextField = [[UITextField alloc] initWithFrame:CGRectMake(TITLE_TEXT_FIELD_X_OFFSET, TITLE_TEXT_FIELD_Y_OFFSET, TITLE_TEXT_FIELD_WIDTH, TITLE_TEXT_FIELD_HEIGHT)];
        [_titleTextField setPlaceholder:@"Title  "];
        [_titleTextField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
        [_titleTextField setAutocorrectionType:UITextAutocorrectionTypeYes];
        [_titleTextField setTextAlignment:NSTextAlignmentLeft];
        [_titleTextField setFont:[UIFont systemFontOfSize:TITLE_TEXT_FIELD_FONT_SIZE]];
        
        UIView *leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 40.0f, TEXT_FIELD_HEIGHT)];
        leftView.backgroundColor = [UIColor clearColor];
        [_titleTextField setLeftView:leftView];
        [_titleTextField setLeftViewMode:UITextFieldViewModeAlways];
        
        [_titleTextField setDelegate:self];
    }
    
    return _titleTextField;
}

#pragma mark - Job Title TextField2
- (UITextField *)titleTextField2 {
    if (!_titleTextField2) {
        _titleTextField2 = [[UITextField alloc] initWithFrame:CGRectMake(TEXT_FIELD_LEFT_MARGIN, 0, kScreenWidth - TEXT_FIELD_LEFT_MARGIN*2, TITLE_TEXT_FIELD_HEIGHT)];
        [_titleTextField2 setAutocapitalizationType:UITextAutocapitalizationTypeWords];
        [_titleTextField2 setAutocorrectionType:UITextAutocorrectionTypeYes];
        [_titleTextField2 setTextAlignment:NSTextAlignmentCenter];
        [_titleTextField2 setFont:[UIFont systemFontOfSize:TITLE_TEXT_FIELD_FONT_SIZE]];
        
        [_titleTextField2 setDelegate:self];
        
        [_companyTextField setCenter:CGPointMake(kScreenWidth/2, _companyTextField.center.y + TITLE_TEXT_FIELD_HEIGHT)];
        [_companyTextField setPlaceholder:[NSString stringWithFormat:@"@%@",_companyTextField.placeholder]];
    }
    
    return _titleTextField2;
}

#pragma mark - Company TextField
- (UITextField *)companyTextField {
    if (!_companyTextField) {
        _companyTextField = [[UITextField alloc] initWithFrame:CGRectMake(kScreenWidth/2, _titleTextField.frame.origin.y, kScreenWidth/2, TITLE_TEXT_FIELD_HEIGHT)];
        [_companyTextField setPlaceholder:@"  Company"];
        [_companyTextField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
        [_companyTextField setAutocorrectionType:UITextAutocorrectionTypeNo];
        [_companyTextField setTextAlignment:NSTextAlignmentLeft];
        [_companyTextField setFont:[UIFont systemFontOfSize:TITLE_TEXT_FIELD_FONT_SIZE]];
        
        [_companyTextField setDelegate:self];
    }
    
    return _companyTextField;
}

#pragma mark - Company TextField2
- (UITextField *)companyTextField2 {
    if (!_companyTextField2) {
        _companyTextField2 = [[UITextField alloc] initWithFrame:CGRectMake(TEXT_FIELD_LEFT_MARGIN, _companyTextField.frame.origin.y + TITLE_TEXT_FIELD_HEIGHT, kScreenWidth - TEXT_FIELD_LEFT_MARGIN*2, TITLE_TEXT_FIELD_HEIGHT)];
        [_companyTextField2 setAutocapitalizationType:UITextAutocapitalizationTypeWords];
        [_companyTextField2 setAutocorrectionType:UITextAutocorrectionTypeNo];
        [_companyTextField2 setTextAlignment:NSTextAlignmentLeft];
        [_companyTextField2 setFont:[UIFont systemFontOfSize:TITLE_TEXT_FIELD_FONT_SIZE]];
        
        [_companyTextField2 setDelegate:self];
    }
    
    return _companyTextField;
}

#pragma mark - At Symbol Label
- (UILabel *)atLabel {
    if (!_atLabel) {
        _atLabel = [[UILabel alloc] initWithFrame:CGRectMake(kScreenWidth/2, _titleTextField.frame.origin.y, AT_LABEL_WIDTH, TITLE_TEXT_FIELD_HEIGHT)];
        [_atLabel setCenter:CGPointMake(kScreenWidth/2, _titleTextField.center.y)];
        [_atLabel setText:@"@"];
        [_atLabel setTextAlignment:NSTextAlignmentCenter];
        [_atLabel setTextColor:[UIColor lightGrayColor]];
    }
    
    return _atLabel;
}

#pragma mark - View Container for Text Fields
-(UIView *)textFieldView {
    if (!_textFieldView) {
        _textFieldView = [[UIView alloc] initWithFrame:CGRectMake(0, _titleTextField.frame.origin.y + TEXT_FIELD_HEIGHT, kScreenWidth, (TEXT_FIELD_HEIGHT + TEXT_FIELD_SEPARATOR_WIDTH) * 30 + TEXT_FIELD_SEPARATOR_WIDTH)];
        [_textFieldView setBackgroundColor:[UIColor colorWithWhite:0.84f alpha:1.0f]];
        
        UITextField *emailTextFieldInitial = [self emailTextField];
        [emailTextFieldInitial setCenter:CGPointMake(emailTextFieldInitial.center.x, emailTextFieldInitial.center.y + TEXT_FIELD_SEPARATOR_WIDTH)];
        [emailTextFieldInitial setTag:EMAIL_TAG];
        _currentTextField = emailTextFieldInitial;
        [_listOfTextFields addObject:emailTextFieldInitial];
        [_textFieldView addSubview:emailTextFieldInitial];
        
        UITextField *phoneTextFieldInitial = [self phoneTextField];
        [phoneTextFieldInitial setCenter:CGPointMake(phoneTextFieldInitial.center.x, emailTextFieldInitial.center.y + TEXT_FIELD_HEIGHT + TEXT_FIELD_SEPARATOR_WIDTH)];
        [phoneTextFieldInitial setTag:PHONE_TAG];
        [_listOfTextFields addObject:phoneTextFieldInitial];
        [_textFieldView addSubview:phoneTextFieldInitial];
        
        UITextField *addressTextFieldInitial = [self addressTextField];
        [addressTextFieldInitial setCenter:CGPointMake(addressTextFieldInitial.center.x, phoneTextFieldInitial.center.y + TEXT_FIELD_HEIGHT + TEXT_FIELD_SEPARATOR_WIDTH)];
        [addressTextFieldInitial setTag:ADDRESS_TAG];
        [_listOfTextFields addObject:addressTextFieldInitial];
        [_textFieldView addSubview:addressTextFieldInitial];
    }
    
    return _textFieldView;
}

#pragma mark - Email TextField Generator
- (UITextField *)emailTextField {
    _emailTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, TEXT_FIELD_HEIGHT)];
    [_emailTextField setPlaceholder:@"email@domain.com"];
    [_emailTextField setKeyboardType:UIKeyboardTypeEmailAddress];
    [_emailTextField setAutocorrectionType:UITextAutocorrectionTypeNo];
    [_emailTextField setFont:[UIFont systemFontOfSize:FONT_SIZE]];
    [_emailTextField setDelegate:self];
    [_emailTextField setBackgroundColor:[UIColor whiteColor]];
    
    UIView *leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 40.0f, TEXT_FIELD_HEIGHT)];
    leftView.backgroundColor = [UIColor clearColor];
    [_emailTextField setLeftView:leftView];
    [_emailTextField setLeftViewMode:UITextFieldViewModeAlways];
    
    return _emailTextField;
}

#pragma mark - Phone Number TextField Generator
- (UITextField *)phoneTextField {
    _phoneTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, TEXT_FIELD_HEIGHT)];
    [_phoneTextField setPlaceholder:@"Work"];
    [_phoneTextField setKeyboardType:UIKeyboardTypePhonePad];
    [_phoneTextField setFont:[UIFont systemFontOfSize:FONT_SIZE]];
    [_phoneTextField setDelegate:self];
    [_phoneTextField setBackgroundColor:[UIColor whiteColor]];
    
    UIView *leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 40.0f, TEXT_FIELD_HEIGHT)];
    leftView.backgroundColor = [UIColor clearColor];
    [_phoneTextField setLeftView:leftView];
    [_phoneTextField setLeftViewMode:UITextFieldViewModeAlways];
    
    return _phoneTextField;
}

#pragma mark - Address TextField Generator
- (UITextField *)addressTextField {
    _addressTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, TEXT_FIELD_HEIGHT)];
    [_addressTextField setPlaceholder:@"123 Main St"];
    [_addressTextField setKeyboardType:UIKeyboardTypeNumbersAndPunctuation];
    [_addressTextField setAutocorrectionType:UITextAutocorrectionTypeDefault];
    [_addressTextField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
    [_addressTextField setFont:[UIFont systemFontOfSize:FONT_SIZE]];
    [_addressTextField setDelegate:self];
    [_addressTextField setBackgroundColor:[UIColor whiteColor]];
    
    UIView *leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 40.0f, TEXT_FIELD_HEIGHT)];
    leftView.backgroundColor = [UIColor clearColor];
    [_addressTextField setLeftView:leftView];
    [_addressTextField setLeftViewMode:UITextFieldViewModeAlways];
    
    return _addressTextField;
}

#pragma mark - Swipe Right
- (void) swipeRight {
    [self dismissViewControllerAnimated:YES completion:^{}];
}

- (void)checkForEmptyTextField {
    if ([_titleTextField2.text isEqualToString:@""]) {
        NSLog(@"2 empty");
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if ([string isEqualToString:@"\n"]) {
        
        if ([textField isEqual:_nameTextField]) {
            [_nameTextField resignFirstResponder];
            [_titleTextField becomeFirstResponder];
        }
        
        else if ([textField isEqual:_titleTextField]) {
            [_titleTextField resignFirstResponder];
            [_companyTextField becomeFirstResponder];
        }
        
        else if ([textField isEqual:_titleTextField2]) {
            [_titleTextField2 resignFirstResponder];
            [_companyTextField becomeFirstResponder];
        }
        
        else if ([textField isEqual:_companyTextField]) {
            [_companyTextField resignFirstResponder];
            [_currentTextField becomeFirstResponder];
        }
        
        else if ([textField isEqual:_companyTextField2]) {
            [_companyTextField2 resignFirstResponder];
            [_currentTextField becomeFirstResponder];
        }
        
        else {
            [self addNewTextFieldFromTextField:textField];
        }
    }
    
    
    else if ([textField isEqual:_titleTextField] || [textField isEqual:_titleTextField2] || [textField isEqual:_companyTextField] || [textField isEqual:_companyTextField2]) {
        float newStringWidth = [[NSString stringWithFormat:@"%@.",[textField.text stringByReplacingCharactersInRange:range withString:string]] sizeWithAttributes:@{NSFontAttributeName:textField.font}].width - _periodWidth;
        
        if ([textField isEqual:_titleTextField]) {
            if (newStringWidth <= TITLE_TEXT_FIELD_WIDTH) {
                [_titleTextField setFrame:CGRectMake(kScreenWidth/4, TITLE_TEXT_FIELD_Y_OFFSET, newStringWidth, TITLE_TEXT_FIELD_HEIGHT)];
                [_titleTextField setTextAlignment:NSTextAlignmentLeft];
            }
            
            else if (newStringWidth > TITLE_TEXT_FIELD_WIDTH && newStringWidth < kScreenWidth/2 - TEXT_FIELD_LEFT_MARGIN) {
                [_titleTextField setFrame:CGRectMake((_titleTextField.frame.origin.x - (newStringWidth - _titleTextField.frame.size.width) > TEXT_FIELD_LEFT_MARGIN) ? _titleTextField.frame.origin.x - (newStringWidth - _titleTextField.frame.size.width) : TEXT_FIELD_LEFT_MARGIN, TITLE_TEXT_FIELD_Y_OFFSET, newStringWidth, TITLE_TEXT_FIELD_HEIGHT)];
                [_titleTextField setTextAlignment:NSTextAlignmentRight];
                
                if (_companyTextField.text.length > 0 && [[NSString stringWithFormat:@"%@.",[textField.text stringByReplacingCharactersInRange:range withString:string]] sizeWithAttributes:@{NSFontAttributeName:textField.font}].width - _periodWidth + _titleTextField.frame.size.width < TITLE_TEXT_FIELD_MAX_WIDTH) {
                    [_companyTextField setFrame:CGRectMake(_titleTextField.frame.origin.x + _titleTextField.frame.size.width + AT_LABEL_WIDTH, TITLE_TEXT_FIELD_Y_OFFSET, _companyTextField.frame.size.width, TITLE_TEXT_FIELD_HEIGHT)];
                }
            }
            
            else if (newStringWidth < kScreenWidth - TEXT_FIELD_LEFT_MARGIN*2) {
                [_titleTextField setFrame:CGRectMake(TEXT_FIELD_LEFT_MARGIN, TITLE_TEXT_FIELD_Y_OFFSET, newStringWidth, TITLE_TEXT_FIELD_HEIGHT)];
                [_titleTextField setTextAlignment:NSTextAlignmentLeft];
            }
            
            else {
                [_titleTextField setTextAlignment:NSTextAlignmentCenter];
                
                if (!_addedTitleTextField2) {
                    // add second line to job title field
                    [_contactScrollView addSubview:self.titleTextField2];
                    if ([textField.text rangeOfString:@" "].location != NSNotFound) {
                        [self.titleTextField2 setText:[NSString stringWithFormat:@"%@%@", [[textField.text stringByReplacingCharactersInRange:range withString:string] substringFromIndex:[textField.text rangeOfString:@" " options:NSBackwardsSearch].location], self.titleTextField2.text]];
                        [textField setText:[textField.text substringToIndex:[textField.text rangeOfString:@" " options:NSBackwardsSearch].location + 1]];
                    }
                    
                    // center line already entered
                    [_titleTextField resignFirstResponder];
                    [self.titleTextField2 becomeFirstResponder];
                    _addedTitleTextField2 = YES;
                    
                    // animate the new line
                    [UIView beginAnimations:@"Sure" context:nil];
                    [UIView setAnimationDuration:0.35f];
                    
                    [textField setCenter:CGPointMake(kScreenWidth/2, TITLE_TEXT_FIELD_Y_OFFSET + TITLE_TEXT_FIELD_HEIGHT/2)];
                    [self.textFieldView setFrame:CGRectMake(_textFieldView.frame.origin.x, _textFieldView.frame.origin.y + TITLE_TEXT_FIELD_HEIGHT, _textFieldView.frame.size.width, _textFieldView.frame.size.height)];
                    [_contactScrollView setContentSize:_textFieldView.frame.size];
                    [_companyTextField setCenter:CGPointMake(_companyTextField.center.x, _companyTextField.center.y + TITLE_TEXT_FIELD_HEIGHT/2)];
                    [self.atLabel removeFromSuperview];
                    [_titleTextField2 setCenter:CGPointMake(kScreenWidth/2, _titleTextField.center.y + TITLE_TEXT_FIELD_HEIGHT/2)];
                    
                    [UIView commitAnimations];
                    
                    return NO;
                }
            }
        }
        
        else if ([textField isEqual:_titleTextField2]) {
            if (newStringWidth > kScreenWidth - TEXT_FIELD_LEFT_MARGIN*2) {
                return NO;
            }
            
            else if (string.length == 0 && _titleTextField2.text.length < 5) {
                if ([[NSString stringWithFormat:@"%@%@.", _titleTextField.text, [_titleTextField2.text stringByReplacingCharactersInRange:range withString:string]] sizeWithAttributes:@{NSFontAttributeName:textField.font}].width - _periodWidth) {
                    [_titleTextField setText:[NSString stringWithFormat:@"%@%@", _titleTextField.text, [textField.text stringByReplacingCharactersInRange:range withString:string]]];
                    
                    [_titleTextField setFrame:CGRectMake(TEXT_FIELD_LEFT_MARGIN, TITLE_TEXT_FIELD_Y_OFFSET, kScreenWidth - TEXT_FIELD_LEFT_MARGIN*2, TITLE_TEXT_FIELD_HEIGHT)];
                    [_titleTextField2 resignFirstResponder];
                    [_titleTextField becomeFirstResponder];
                    
                    [UIView beginAnimations:@"Sure" context:nil];
                    [UIView setAnimationDuration:0.35f];
                    
                    [_titleTextField setCenter:CGPointMake(kScreenWidth/2, TITLE_TEXT_FIELD_Y_OFFSET + TITLE_TEXT_FIELD_HEIGHT/2)];
                    [self.textFieldView setFrame:CGRectMake(_textFieldView.frame.origin.x, _textFieldView.frame.origin.y - TITLE_TEXT_FIELD_HEIGHT, _textFieldView.frame.size.width, _textFieldView.frame.size.height)];
                    [_contactScrollView setContentSize:_textFieldView.frame.size];
                    [_companyTextField setCenter:CGPointMake(_companyTextField.center.x, _companyTextField.center.y - TITLE_TEXT_FIELD_HEIGHT/2)];
                    [_companyTextField2 setCenter:CGPointMake(_companyTextField.center.x, _companyTextField2.center.y - TITLE_TEXT_FIELD_HEIGHT/2)];
                    [self.atLabel removeFromSuperview];
                    [self.titleTextField2 removeFromSuperview];
                    
                    [UIView commitAnimations];
                    
                    _addedTitleTextField2 = NO;
                    
                    return YES;
                }
            }
        }
    }
    
    else if ([string isEqualToString:@" "]) {
        if ([textField isEqual:_titleTextField]) {
            [_titleTextField setAutocorrectionType:UITextAutocorrectionTypeNo];
        }
        
        else if (textField.keyboardType == UIKeyboardTypeNumbersAndPunctuation) {
            [textField setKeyboardType:UIKeyboardTypeAlphabet];
            [self updateKeyboard:textField];
        }
    }
    
    return YES;
}

/**
 *  Creates a new textfield and moves all graphically lower textfields to a new position
 *  Sets the new
 *
 *  @param textField The currently selected textField
 */
- (void)addNewTextFieldFromTextField:(UITextField *)textField {
    BOOL foundCurrentTextField = NO;
    BOOL switchedFirstResponder = NO;
    for (UITextField *viewTextField in _textFieldView.subviews) {
        if (foundCurrentTextField && !switchedFirstResponder) {
            [textField resignFirstResponder];
            [viewTextField becomeFirstResponder];
            switchedFirstResponder = YES;
            _currentTextField = viewTextField;
            
            if (textField.text.length > 0) {
                [_contactScrollView setContentOffset:CGPointMake(0, _contactScrollView.contentOffset.y + TEXT_FIELD_HEIGHT) animated:YES];
                
                UITextField *newTextField;
                
                if (textField.tag == EMAIL_TAG) {
                    newTextField = [self emailTextField];
                    [newTextField setTag:EMAIL_TAG];
                }
                
                else if (textField.tag == PHONE_TAG) {
                    newTextField = [self phoneTextField];
                    [newTextField setTag:PHONE_TAG];
                }
                
                else if (textField.tag == ADDRESS_TAG) {
                    newTextField = [self addressTextField];
                    [newTextField setTag:ADDRESS_TAG];
                }
                
                [newTextField setCenter:textField.center];
                [_listOfTextFields addObject:newTextField];
                [_textFieldView insertSubview:newTextField belowSubview:textField];
                
                [UIView beginAnimations:@"ToggleViews" context:nil];
                [UIView setAnimationDuration:0.5f];
                
                [_textFieldView setFrame:CGRectMake(_textFieldView.frame.origin.x, _textFieldView.frame.origin.y, _textFieldView.frame.size.width, _textFieldView.frame.size.height + TEXT_FIELD_HEIGHT + TEXT_FIELD_SEPARATOR_WIDTH)];
                [_contactScrollView setContentSize:_textFieldView.frame.size];
                
                [newTextField setCenter:CGPointMake(textField.center.x, textField.center.y + TEXT_FIELD_HEIGHT + TEXT_FIELD_SEPARATOR_WIDTH)];
                
                [viewTextField setCenter:CGPointMake(viewTextField.center.x, viewTextField.center.y + TEXT_FIELD_HEIGHT + TEXT_FIELD_SEPARATOR_WIDTH)];
                
            }
        }
        
        else if ([textField isEqual:viewTextField]) {
            foundCurrentTextField = YES;
        }
        
        else if (textField.text.length > 0 && viewTextField.center.y > textField.center.y) {
            [viewTextField setCenter:CGPointMake(viewTextField.center.x, viewTextField.center.y + TEXT_FIELD_HEIGHT + TEXT_FIELD_SEPARATOR_WIDTH)];
        }
    }
    if (foundCurrentTextField && !switchedFirstResponder) {
        UITextField *newTextField = [self addressTextField];
        [newTextField setTag:ADDRESS_TAG];
        [_listOfTextFields addObject:newTextField];
        [_textFieldView insertSubview:newTextField belowSubview:textField];
        
        [UIView beginAnimations:@"ToggleViews" context:nil];
        [UIView setAnimationDuration:0.5f];
        
        [_textFieldView setFrame:CGRectMake(_textFieldView.frame.origin.x, _textFieldView.frame.origin.y, _textFieldView.frame.size.width, _textFieldView.frame.size.height + TEXT_FIELD_HEIGHT + TEXT_FIELD_SEPARATOR_WIDTH)];
        [_contactScrollView setContentSize:_textFieldView.frame.size];
        
        [newTextField setCenter:CGPointMake(textField.center.x, textField.center.y + TEXT_FIELD_HEIGHT + TEXT_FIELD_SEPARATOR_WIDTH)];
        [newTextField becomeFirstResponder];
    }
    
    [UIView commitAnimations];
    [_contactScrollView setContentSize:CGSizeMake(kScreenWidth, _textFieldView.frame.size.height - _listOfTextFields.count * (TEXT_FIELD_HEIGHT + TEXT_FIELD_SEPARATOR_WIDTH) - TEXT_FIELD_SEPARATOR_WIDTH)];
}

- (void)updateKeyboard:(UITextField *)textField {
    [textField resignFirstResponder];
    [textField becomeFirstResponder];
}

/**
 *  Creates UIImage from color
 *
 *  @param color Color for the entire image
 *
 *  @return UIImage of just the color
 */
- (UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end