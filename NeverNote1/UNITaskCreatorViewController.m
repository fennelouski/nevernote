//
//  UNITaskCreatorViewController.m
//  NeverNote
//
//  Created by Nathan Fennel on 7/3/14.
//  Copyright (c) 2014 Nathan Fennel. All rights reserved.
//

#import "UNITaskCreatorViewController.h"
#import "UIColor+AppColors.h"

#import "UNIOptionsView.h"
#import "UNISuggestionView.h"
#import "UNICalendarPopOver.h"
#import "UNIAdditionalOptionsView.h"
#import "UNITimeInputView.h"

// screen dimensions
#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height


// Text View
#define TASK_TEXT_FONT_SIZE 15.0f

// Toolbar
#define TOOLBAR_HEIGHT 44.0f
#define OPTIONS_VIEW_CORNER_RADIUS 10.0f

//Animation
#define ANIMATION_DURATION 0.35f

// Additional Options
#define ADDITIONAL_OPTIONS_BUTTON_WIDTH 12.0f
#define ADDITIONAL_OPTIONS_BUTTON_HEIGHT 40.0f

@interface UNITaskCreatorViewController () <UNIOptionsViewDelegate, UNISuggestionViewDelegate, UNICalendarPopOverDelegate, UNIAdditionalOptionsViewDelegate>

@property (nonatomic, strong) UIToolbar *headerToolbar;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UIView *accessoryView, *optionsViewHelper;
@property (nonatomic, strong) UNIOptionsView *optionsView;
@property (nonatomic, strong) UIButton *dueButton, *optionsButton, *saveButton;
@property (nonatomic, strong) UNICalendarPopOver *calendarPopOver;
@property (nonatomic, strong) UITextRange *selectedTextRange;
@property (nonatomic) BOOL optionsViewShowing;
@property (nonatomic, strong) UITextField *categoryTextField;
@property (nonatomic, strong) UNISuggestionView *suggestionView;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UNIAdditionalOptionsView *additionalOptions;
@property (nonatomic) int numberOfAccounts;

@property (nonatomic, strong) UIColor *accountColor;
@property (nonatomic, strong) NSString *dueDateString;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@property (nonatomic, strong) UIView *lastTextInputView;

@end

@implementation UNITaskCreatorViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

- (instancetype)initWithNumberOfAccounts:(int)numberOfAccounts {
    self = [super init];
    
    if (self) {
        self.numberOfAccounts = numberOfAccounts;
        [self setAccountColor:[UIColor randomPastelColor]];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.view addSubview:self.textView];
    [self.textView setInputAccessoryView:self.accessoryView];
    
    [self.view addSubview:self.headerToolbar];
    
    [self.view addSubview:self.closeButton];
    [self.view addSubview:self.additionalOptions];
}

- (void)viewDidAppear:(BOOL)animated {
    [self.textView becomeFirstResponder];
}

- (UITextView *)textView {
    if (!_textView) {
        _textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, kScreenHeight)];
        [_textView setDelegate:self];
        [_textView setFont:[UIFont systemFontOfSize:TASK_TEXT_FONT_SIZE]];
        [_textView setContentInset:UIEdgeInsetsMake(TOOLBAR_HEIGHT, 0, 214.0f, 0)];        
        
        [_textView setAttributedText:[self placeHolderString]];
        [_textView setSelectedRange:NSMakeRange(0, 0)];
        _selectedTextRange = _textView.selectedTextRange;
    }
    
    return _textView;
}

- (UIView *)accessoryView {
    if (!_accessoryView) {
        _accessoryView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, TOOLBAR_HEIGHT)];
        [_accessoryView setBackgroundColor:[UIColor clearColor]];
        
        [_accessoryView addSubview:self.optionsButton];
        [_accessoryView addSubview:self.optionsViewHelper];
        [_accessoryView addSubview:self.optionsView];
        [_accessoryView addSubview:self.saveButton];
    }
    
    return _accessoryView;
}

- (UIButton *)optionsButton {
    if (!_optionsButton) {
        _optionsButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth/5, TOOLBAR_HEIGHT)];
        
        UIImageView *dots = [[UIImageView alloc] initWithFrame:CGRectMake(17, 10, _optionsButton.frame.size.width, _optionsButton.frame.size.height)];
        UIImage *threeDotsImage = [self threeDots];
        [dots setImage:threeDotsImage];
        
        UILabel *buttonLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 8, _optionsButton.frame.size.width, _optionsButton.frame.size.height)];
        [buttonLabel setText:@"options"];
        [buttonLabel setFont:[UIFont systemFontOfSize:11.0f]];
        [buttonLabel setTextColor:[UIColor darkGrayColor]];
        
        
        [_optionsButton addSubview:buttonLabel];
        [_optionsButton addSubview:dots];
        
        [_optionsButton addTarget:self action:@selector(optionsButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        [_optionsButton addTarget:self action:@selector(optionsButtonTapped) forControlEvents:UIControlEventTouchDragExit];
    }
    
    return _optionsButton;
}

- (UIView *)optionsView {
    if (!_optionsView) {
        _optionsView = [[UNIOptionsView alloc] initWithFrame:CGRectMake(-kScreenWidth, 0, kScreenWidth, TOOLBAR_HEIGHT)];
        [_optionsView setBackgroundColor:[UIColor lightKeyboardBackgroundColor]];
        [_optionsView.layer setCornerRadius:OPTIONS_VIEW_CORNER_RADIUS];
        [_optionsView setDelegate:self];
        
        UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(switchOptionsView)];
        [swipe setDirection:UISwipeGestureRecognizerDirectionLeft];
        [_optionsView addGestureRecognizer:swipe];
    }
    
    return _optionsView;
}

- (UIView *)optionsViewHelper {
    if (!_optionsViewHelper) {
        _optionsViewHelper = [[UIView alloc] initWithFrame:CGRectMake(-kScreenWidth, 0, kScreenWidth, TOOLBAR_HEIGHT/2)];
        [_optionsViewHelper setBackgroundColor:[UIColor lightKeyboardBackgroundColor]];
        [_optionsViewHelper.layer setCornerRadius:OPTIONS_VIEW_CORNER_RADIUS];
    }
    
    return _optionsViewHelper;
}
- (UIButton *)saveButton {
    if (!_saveButton) {
        _saveButton = [[UIButton alloc] initWithFrame:CGRectMake(kScreenWidth*4/5, 0, kScreenWidth/5, TOOLBAR_HEIGHT)];
        [_saveButton addTarget:self action:@selector(saveTask) forControlEvents:UIControlEventTouchUpInside];
        
        UIImageView *cloud = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, _saveButton.frame.size.width, _saveButton.frame.size.height)];
        UIImage *cloudImage = [self saveCloud];
        [cloud setImage:cloudImage];
        [cloud setCenter:CGPointMake(_saveButton.frame.size.width/2 + 10, cloud.center.y)];
        [_saveButton addSubview:cloud];
        
        UILabel *saveLabel = [[UILabel alloc] initWithFrame:cloud.frame];
        [saveLabel setFont:[UIFont systemFontOfSize:11.0f]];
        [saveLabel setText:@"save"];
        [saveLabel setTextColor:[UIColor blueAppColor]];
        [saveLabel setCenter:CGPointMake(_saveButton.frame.size.width/2 + 18.0f, saveLabel.center.y + 12.0f)];
        [_saveButton addSubview:saveLabel];
        
        [_saveButton setBackgroundColor:self.textView.backgroundColor];
        [_saveButton.layer setCornerRadius:OPTIONS_VIEW_CORNER_RADIUS];
    }
    
    return _saveButton;
}

- (UIToolbar *)headerToolbar {
    if (!_headerToolbar) {
        _headerToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, TOOLBAR_HEIGHT)];
        [_headerToolbar setBarTintColor:[UIColor whiteColor]];
        [_headerToolbar addSubview:self.categoryTextField];
        
        [_headerToolbar addSubview:self.dueButton];
    }
    
    return _headerToolbar;
}

- (UITextField *)categoryTextField {
    if (!_categoryTextField) {
        _categoryTextField = [[UITextField alloc] initWithFrame:CGRectMake(kScreenWidth/2, 0, kScreenWidth/2, TOOLBAR_HEIGHT)];
        [_categoryTextField setDelegate:self];
        [_categoryTextField setPlaceholder:@"No Category"];
        [_categoryTextField setTextColor:[UIColor darkTextColor]];
        
        [_categoryTextField setInputAccessoryView:self.accessoryView];
    }
    
    return _categoryTextField;
}

- (UNISuggestionView *)suggestionView {
    if (!_suggestionView) {
        _suggestionView = [[UNISuggestionView alloc] initWithPoint:CGPointMake(kScreenWidth*2/3, TOOLBAR_HEIGHT/2)];
        [_suggestionView setSuggestions:[[NSMutableArray alloc] initWithArray:@[@"Work", @"Personal", @"Family", @"Home", @"No Category"]]];
        [_suggestionView setTextSize:15.0f];
        [_suggestionView layoutSubviews];
        [_suggestionView setDelegate:self];
    }
    
    return _suggestionView;
}

- (UIButton *)dueButton {
    if (!_dueButton) {
        _dueButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth/2, TOOLBAR_HEIGHT)];
        
        UILabel *dueButtonLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth/2, TOOLBAR_HEIGHT)];
        [dueButtonLabel setAttributedText:[self dueDateTextString]];
        [_dueButton addSubview:dueButtonLabel];
        
        [_dueButton addTarget:self action:@selector(showCalendar) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _dueButton;
}

- (NSString *)dueDateString {
    if (!_dueDateString) {
        _dueDateString = [NSString stringWithFormat:@"Later"];
    }
    
    return _dueDateString;
}

- (UNICalendarPopOver *)calendarPopOver {
    if (!_calendarPopOver) {
        _calendarPopOver = [[UNICalendarPopOver alloc] init];
        [_calendarPopOver setDelegate:self];
    }
    
    return _calendarPopOver;
}

- (UIButton *)closeButton {
    if (!_closeButton) {
        _closeButton = [[UIButton alloc] initWithFrame:CGRectZero];
        [_closeButton setImage:[UIImage imageNamed:@"pull-close"] forState:UIControlStateNormal];
        [_closeButton sizeToFit];
        [_closeButton setCenter:CGPointMake(kScreenWidth - _closeButton.frame.size.width/2, _closeButton.frame.size.height/2)];
        [_closeButton addTarget:self action:@selector(closeView) forControlEvents:UIControlEventTouchUpInside];
        [_closeButton addTarget:self action:@selector(closeView) forControlEvents:UIControlEventTouchDragInside];
    }
    
    return _closeButton;
}

- (UNIAdditionalOptionsView *)additionalOptions {
    if (!_additionalOptions) {
        _additionalOptions = [[UNIAdditionalOptionsView alloc] initWithAccountCount:self.numberOfAccounts];
        [_additionalOptions setDelegate:self];
    }
    
    return _additionalOptions;
}

#pragma mark - Accessory View Actions

- (void)optionsButtonTapped {
    [self switchOptionsView];
}

- (void)switchOptionsView {
    if (self.optionsViewShowing) {
        [UIView animateWithDuration:0.1f animations:^{
            [self.optionsViewHelper setFrame:CGRectMake(0, TOOLBAR_HEIGHT, 0, 0)];
        }];
    }
    [UIView animateWithDuration:ANIMATION_DURATION animations:^{
        if (self.optionsViewShowing) {
            [self.optionsView setCenter:CGPointMake(-kScreenWidth/2, self.optionsView.center.y)];
            [self setOptionsViewShowing:NO];
        }
        
        else {
            [self.optionsView setCenter:CGPointMake(-self.saveButton.frame.size.width*1 + kScreenWidth/2, self.optionsView.center.y)];
            [self setOptionsViewShowing:YES];
        }
    } completion:^(BOOL finished) {
        if (!self.optionsViewShowing) {
            [self.optionsViewHelper setFrame:CGRectZero];
        }
        
        else {
            [self.optionsViewHelper setFrame:CGRectMake(0, TOOLBAR_HEIGHT/2, kScreenWidth, TOOLBAR_HEIGHT/2)];
        }
    }];
}

- (void) saveTask {
    NSLog(@"Save Task");
}

#pragma mark - Formatted Text and Icons

- (NSAttributedString *) dueDateTextString {
    // Create the attributed string
    NSMutableAttributedString *myString = [[NSMutableAttributedString alloc]initWithString:
                                           [NSString stringWithFormat:@" Due: %@",self.dueDateString]];
    
    // Declare the fonts
    UIFont *myStringFont1 = [UIFont systemFontOfSize:TASK_TEXT_FONT_SIZE];
    
    // Declare the colors
    UIColor *myStringColor1 = [UIColor grayColor];
    UIColor *myStringColor2 = [UIColor lightGrayColor];
    
    // Declare the paragraph styles
    NSMutableParagraphStyle *myStringParaStyle1 = [[NSMutableParagraphStyle alloc]init];
    [myStringParaStyle1 setAlignment:NSTextAlignmentLeft];
    
    
    // Create the attributes and add them to the string
    [myString addAttribute:NSUnderlineColorAttributeName value:myStringColor1 range:NSMakeRange(0,5)];
    [myString addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,5)];
    [myString addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,5)];
    [myString addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(5,6)];
    [myString addAttribute:NSUnderlineColorAttributeName value:myStringColor1 range:NSMakeRange(5,6)];
    [myString addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(5,6)];
    [myString addAttribute:NSForegroundColorAttributeName value:myStringColor2 range:NSMakeRange(5,6)];
    return myString;
}

- (NSAttributedString *)placeHolderString {
    // Create the attributed string
    NSMutableAttributedString *myString = [[NSMutableAttributedString alloc]initWithString:
                                           @"To-do"];
    
    // Declare the fonts
    UIFont *myStringFont1 = [UIFont fontWithName:@"AvenirNext-Regular" size:14.0];
    
    // Declare the colors
    UIColor *myStringColor1 = [UIColor colorWithRed:0.000000 green:0.000000 blue:0.000000 alpha:0.360784];
    UIColor *myStringColor2 = [UIColor colorWithWhite:0.603922 alpha:1.000000];
    
    // Declare the paragraph styles
    NSMutableParagraphStyle *myStringParaStyle1 = [[NSMutableParagraphStyle alloc]init];
    
    
    // Create the attributes and add them to the string
    [myString addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,5)];
    [myString addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,5)];
    [myString addAttribute:NSUnderlineColorAttributeName value:myStringColor1 range:NSMakeRange(0,5)];
    [myString addAttribute:NSForegroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,5)];
    
    return myString;
}

- (UIImage *)threeDots {
    CGSize dotsSize = CGSizeMake(5, 30);
    UIGraphicsBeginImageContext(dotsSize);
    
    UIImage *dots = [[UIImage alloc] init];
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(50, 30), NO, 0.0f);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);

    float ovalSize = 4.5f;
    
    //// Oval drawing
    UIBezierPath *oval = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, ovalSize, ovalSize)];
    
    UIColor *dotColor = [UIColor darkGrayColor];
    //Oval color fill
    [dotColor setFill];
    [oval fill];
    
    //// Oval2 drawing
    UIBezierPath *oval2 = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(8, 0, ovalSize, ovalSize)];
    
    //Oval2 color fill
    [dotColor setFill];
    [oval2 fill];
    
    //// Oval3 drawing
    UIBezierPath *oval3 = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(16, 0, ovalSize, ovalSize)];
    
    //Oval3 color fill
    [dotColor setFill];
    [oval3 fill];

    CGContextRestoreGState(ctx);
    dots = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return dots;
}

- (UIImage *)saveCloud {
    CGSize cloudSize = CGSizeMake(180, 150);
    UIGraphicsBeginImageContext(cloudSize);
    
    UIImage *cloud = [[UIImage alloc] init];
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(150, 100), NO, 0.0f);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    
    
    //// Path drawing
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(57.129, 61.893)];
    [path addLineToPoint:CGPointMake(73.915, 61.893)];
    [path addCurveToPoint:CGPointMake(80.122, 63) controlPoint1:CGPointMake(75.866, 62.611) controlPoint2:CGPointMake(77.953, 63)];
    [path addCurveToPoint:CGPointMake(99.789, 41.221) controlPoint1:CGPointMake(90.984, 63) controlPoint2:CGPointMake(99.789, 53.249)];
    [path addCurveToPoint:CGPointMake(80.122, 19.446) controlPoint1:CGPointMake(99.789, 29.193) controlPoint2:CGPointMake(90.984, 19.446)];
    [path addCurveToPoint:CGPointMake(79.738, 19.446) controlPoint1:CGPointMake(79.994, 19.446) controlPoint2:CGPointMake(79.866, 19.443)];
    [path addLineToPoint:CGPointMake(79.738, 19.446)];
    [path addCurveToPoint:CGPointMake(59.141, 0) controlPoint1:CGPointMake(77.864, 8.366) controlPoint2:CGPointMake(69.355, 0)];
    [path addCurveToPoint:CGPointMake(39.993, 14.205) controlPoint1:CGPointMake(50.614, 0) controlPoint2:CGPointMake(43.275, 5.832)];
    [path addCurveToPoint:CGPointMake(33.851, 12.918) controlPoint1:CGPointMake(38.092, 13.375) controlPoint2:CGPointMake(36.02, 12.918)];
    [path addCurveToPoint:CGPointMake(17.365, 28.488) controlPoint1:CGPointMake(25.509, 12.918) controlPoint2:CGPointMake(18.597, 19.67)];
    [path addLineToPoint:CGPointMake(17.365, 28.488)];
    [path addCurveToPoint:CGPointMake(14.297, 28.102) controlPoint1:CGPointMake(16.377, 28.235) controlPoint2:CGPointMake(15.35, 28.102)];
    [path addCurveToPoint:CGPointMake(0, 44.764) controlPoint1:CGPointMake(6.416, 28.102) controlPoint2:CGPointMake(0, 35.562)];
    [path addCurveToPoint:CGPointMake(13.516, 61.401) controlPoint1:CGPointMake(0, 53.66) controlPoint2:CGPointMake(5.998, 60.927)];
    [path addLineToPoint:CGPointMake(13.516, 61.401)];
    [path addLineToPoint:CGPointMake(13.516, 61.893)];
    [path addLineToPoint:CGPointMake(42.687, 61.893)];
    [path addLineToPoint:CGPointMake(42.687, 41.596)];
    [path addLineToPoint:CGPointMake(28.699, 41.596)];
    [path addLineToPoint:CGPointMake(49.908, 18.118)];
    [path addLineToPoint:CGPointMake(71.117, 41.596)];
    [path addLineToPoint:CGPointMake(57.129, 41.596)];
    [path addLineToPoint:CGPointMake(57.129, 41.596)];
    [path addLineToPoint:CGPointMake(57.129, 61.893)];
    [path closePath];


    
    //Path color fill
    [[UIColor blueAppColor] setFill];
    [path fill];

    
    CGContextRestoreGState(ctx);
    cloud = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return cloud;
}

- (UIImage *)accountCircle {
    CGSize circleSize = CGSizeMake(20, 20);
    UIGraphicsBeginImageContext(circleSize);
    
    UIImage *circle = [UIImage new];
    
    UIGraphicsBeginImageContextWithOptions(circleSize, YES, 0.0f);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    
    //// Oval drawing
    UIBezierPath *oval = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, 20, 20)];
    
    //Oval color fill
    [self.accountColor setFill];
    [oval fill];
    
    return circle;
}

#pragma mark - Text VIEW delegate methods

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if (self.textView.autocapitalizationType == UITextAutocapitalizationTypeAllCharacters) {
        [self.textView setAutocapitalizationType:UITextAutocapitalizationTypeSentences];
    }
    
    if ([self.textView.text isEqualToString:@"To-do"] && text.length > 0) {
        [self.textView setText:@""];
        [self.textView setFont:[UIFont systemFontOfSize:TASK_TEXT_FONT_SIZE]];
        [self.textView setTextColor:[UIColor darkTextColor]];
        [self.textView setAutocapitalizationType:UITextAutocapitalizationTypeSentences];
    }
    
    else {
        
    }
    
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
    if ([self.textView.text isEqualToString:@""]) {
        [self.textView setAttributedText:[self placeHolderString]];
        [_textView setSelectedRange:NSMakeRange(0, 0)];
        [self.textView setAutocapitalizationType:UITextAutocapitalizationTypeAllCharacters];
    }
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    self.lastTextInputView = textView;
    
    if ([self.textView.text isEqualToString:@"To-do"]) {
        [self.textView setAttributedText:[self placeHolderString]];
        [_textView setSelectedTextRange:self.selectedTextRange];
        NSLog(@"Selected text ain't right");
    }
    
    return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    if ([self.textView.text isEqualToString:@"To-do"]) {
        [self.textView setAttributedText:[self placeHolderString]];
        [_textView setSelectedRange:NSMakeRange(0, 0)];
    }
}

#pragma mark - Text FIELD delegate methods

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    self.lastTextInputView = textField;
    
    [self.suggestionView layoutSubviews];
    [self.view addSubview:self.suggestionView];
    
    [UIView animateWithDuration:ANIMATION_DURATION animations:^{
        [self.suggestionView setAlpha:1.0f];
    }];
    
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self closeSuggestionView];
}

#pragma mark - Options View Delegate methods

- (void)assignButtonTouched {
    NSLog(@"Assign button touched");
}

- (void)shareButtonTouched {
    NSLog(@"Share button touched");
}

- (void)attachButtonTouched {
    NSLog(@"Attach button touched");
}

- (void)eventButtonTouched {
    NSLog(@"Event button touched");
}

#pragma mark - Additional Options View Delegate methods

- (void)switchView {
    if (self.additionalOptions.isSmall) {
        [self hideKeyboard];
        [self.view bringSubviewToFront:self.additionalOptions];
        [self.view insertSubview:self.additionalOptions.background belowSubview:self.additionalOptions];
        
        [UIView animateWithDuration:ANIMATION_DURATION animations:^{
            [self.additionalOptions.background setAlpha:0.65f];
        }];
    }
    
    else {
        [self showKeyboard];
        [UIView animateWithDuration:ANIMATION_DURATION animations:^{
            [self.additionalOptions.background setAlpha:0.0f];
        }];
    }
    NSLog(@"switchView");
}

- (void)accountButtonTouched {
    NSLog(@"accountButtonTouched");
}

- (void)alarmButtonTouched {
    NSLog(@"alarmButtonTouched");
}

- (void)repeatButtonTouched {
    NSLog(@"repeatButtonTouched");
}

#pragma mark - Suggestions View delegate methods

- (void)suggestionSelected:(UIButton *)button {
    [self.categoryTextField setText:button.titleLabel.text];
    
    if ([self.categoryTextField.text isEqualToString:self.categoryTextField.placeholder]) {
        [self.categoryTextField setText:@""];
    }
    
    [self closeSuggestionView];
}

- (void)closeSuggestionView {
    [self.categoryTextField resignFirstResponder];
    [self.textView becomeFirstResponder];

    [UIView animateWithDuration:ANIMATION_DURATION animations:^{
        [self.suggestionView setAlpha:0.0f];
    } completion:^(BOOL finished){
    }];
}

#pragma mark - Calendar Pop Over delegate methods

- (void)dateSelected:(UIButton *)button {
    
}

- (void)removeCalendarPopOver {
    [self.calendarPopOver removeFromSuperview];
    [self showKeyboard];
    self.calendarPopOver = nil;
}

- (void)showCalendar {
    [self hideKeyboard];
    
    [self.view addSubview:self.calendarPopOver];
}

#pragma mark - Close View

- (void)closeView {
    [self dismissViewControllerAnimated:YES completion:^{
        NSLog(@"Closed Task Creator");
    }];
}

- (void)hideKeyboard {
    [self.categoryTextField resignFirstResponder];
    [self.textView resignFirstResponder];
}

- (void)showKeyboard {
    [self.lastTextInputView becomeFirstResponder];
}

#pragma mark - Memory Warning

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
