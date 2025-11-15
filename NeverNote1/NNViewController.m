//
//  NNViewController.m
//  NeverNote
//
//  Created by Nathan Fennel on 5/4/14.
//  Copyright (c) 2014 Nathan Fennel. All rights reserved.
//

#import "NNViewController.h"
#import <CoreMotion/CoreMotion.h>
#import "NNColorObject.h"

// screen width
#define kScreenWidth [UIScreen mainScreen].bounds.size.width

// screen height
#define kScreenHeight [UIScreen mainScreen].bounds.size.height

// status bar height
#define kStatusBarHeight [[UIApplication sharedApplication] statusBarFrame].size.height

// Sizes 'n Stuff
#define FONT_SIZE 18.0f
#define DEFAULT_KEYBOARD_HEIGHT 216.0f  // Fallback value
#define TOOLBAR_HEIGHT 44.0f

// Background
#define BACKGROUND_TEXT @"NeverNote"
#define BACKGROUND_FONT_SIZE 22.0f
#define BACKGROUND_LABEL_ALPHA 0.4f

// Motion
#define KNOCK_ACCELERATION 5.0f
#define kFilteringFactor 0.1
float prevX;
float prevY;
float prevZ;
BOOL ONE_SHAKE = YES;

// Keyboard specs
#define BUTTON_BORDER_WIDTH 0.5f
#define TIME_BUTTON_FONT_SIZE 30.0f

@interface NNViewController ()

@property (nonatomic, strong) UITextView *textView;

@property (nonatomic, strong) NSString *oldText;

@property (nonatomic) float currentFontSize, tempFontSize;

@property (nonatomic) BOOL isDaylight, isUpdated, isClearing, bumpA, bumpB, bumpC, bumpD, bumpNet;

@property (nonatomic, strong) UIToolbar *keyboardToolbarUpperCaseDark, *keyboardToolbarLowerCaseDark, *keyboardToolbarUpperCaseLight, *keyboardToolbarLowerCaseLight;

@property (nonatomic, strong) NSDate *lastDoubleBump;

@property (nonatomic, strong) UILabel *resetLabelWarning, *labelForCopy, *pasteWarningLabel, *viewBackgroundLabel, *nightModeLabel, *dayModeLabel;

@property (nonatomic, strong) NSMutableArray *allFonts, *lastFont, *nextFont;

@property (nonatomic, strong) NSArray *keyboardTypes;

@property (nonatomic, strong) UIView *timeKeyboard, *minuteKeyboard, *ampmKeyboard, *colorView;

@end

@implementation NNViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _currentFontSize = FONT_SIZE;
        _currentKeyboardHeight = DEFAULT_KEYBOARD_HEIGHT;  // Initialize with default
        _isDaylight = [self isDaylight];
        _lastDoubleBump = [NSDate date];
        _allFonts = [self listAvailableFonts];
        _lastFont = [NSMutableArray new];
        _nextFont = [NSMutableArray new];

        _keyboardTypes = @[@"ABC",@"@",@"#",[self timeStringFromDate:[NSDate date] withRounding:YES]];

        [self.view setBackgroundColor:(_isDaylight) ? [UIColor lightTextColor] : [UIColor darkGrayColor]];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetView) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setUpStatusBar:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

        [self colorText];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpGestures];
    [self.view addSubview:self.viewBackgroundLabel];
    [self.view addSubview:self.textView];
    [self.viewBackgroundLabel setCenter:self.textView.center];
    [self.textView setInputAccessoryView:(_isDaylight) ? self.keyboardToolbarUpperCaseLight : self.keyboardToolbarUpperCaseDark];
    [[UIApplication sharedApplication] setApplicationSupportsShakeToEdit:NO];
    [self setUpLabels];

    [self listAvailableFonts];
}

#pragma mark - Status Bar

- (UIStatusBarStyle)preferredStatusBarStyle {
    return _isDaylight ? UIStatusBarStyleDefault : UIStatusBarStyleLightContent;
}

- (BOOL)prefersStatusBarHidden {
    // Hide status bar in landscape mode when updated
    if (_isUpdated && ([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeLeft ||
        [[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeRight)) {
        return YES;
    }
    return NO;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationFade;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];

    if (@available(iOS 13.0, *)) {
        // Respond to system dark mode changes if user hasn't manually set a preference
        if (self.traitCollection.userInterfaceStyle != previousTraitCollection.userInterfaceStyle) {
            // Optionally update the appearance based on system dark mode
            // For now, we keep the manual day/night toggle via shake gesture
            // Users can still override using the shake gesture
        }
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewSafeAreaInsetsDidChange {
    [super viewSafeAreaInsetsDidChange];
    if (@available(iOS 11.0, *)) {
        // Recalculate text view frame when safe area changes (e.g., rotation)
        CGFloat topInset = self.view.safeAreaInsets.top > 0 ? self.view.safeAreaInsets.top : [[UIApplication sharedApplication] statusBarFrame].size.height;
        CGFloat bottomInset = self.view.safeAreaInsets.bottom;
        [_textView setFrame:CGRectMake(0, topInset, kScreenWidth, kScreenHeight - topInset - _currentKeyboardHeight - bottomInset)];
    }
}

#pragma mark - Keyboard Notifications

- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    CGRect keyboardFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat keyboardHeight = keyboardFrame.size.height;

    // Update the current keyboard height
    _currentKeyboardHeight = keyboardHeight;

    // Update text view frame with actual keyboard height
    CGFloat topInset = 0;
    CGFloat bottomInset = 0;

    if (@available(iOS 11.0, *)) {
        topInset = self.view.safeAreaInsets.top > 0 ? self.view.safeAreaInsets.top : [[UIApplication sharedApplication] statusBarFrame].size.height;
        bottomInset = self.view.safeAreaInsets.bottom;
    } else {
        topInset = ([[UIApplication sharedApplication] statusBarFrame].size.height <= 20.0f) ? [[UIApplication sharedApplication] statusBarFrame].size.height : 20.0f;
    }

    [_textView setFrame:CGRectMake(0, topInset, kScreenWidth, kScreenHeight - topInset - keyboardHeight - bottomInset)];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    // Optionally handle keyboard hiding if needed
}

- (NSMutableArray *)listAvailableFonts
{
    NSMutableArray *allFonts = [[NSMutableArray alloc] initWithCapacity:314];
    NSArray *familyNames = [[NSArray alloc] initWithArray:[UIFont familyNames]];
    NSArray *fontNames;
    NSInteger indFamily, indFont;
    for (indFamily=0; indFamily<[familyNames count]; ++indFamily)
    {
        fontNames = [[NSArray alloc] initWithArray:
                     [UIFont fontNamesForFamilyName:
                      [familyNames objectAtIndex:indFamily]]];
        for (indFont=0; indFont<[fontNames count]; ++indFont)
        {
            [allFonts addObject:[fontNames objectAtIndex:indFont]];
        }
    }
    
    return allFonts;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self startMotionDetect];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
    [self.textView setText:@""];
    [self.textView becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.motionManager stopAccelerometerUpdates];
}

- (void)setUpStatusBar:(NSNotification *)notification {
    // Update status bar appearance using modern API
    [self setNeedsStatusBarAppearanceUpdate];

    if (!([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeLeft ||
        [[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeRight) && _isUpdated) {

        [self.textView setInputAccessoryView:nil];
        [_textView reloadInputViews];
        [_textView setTextContainerInset:UIEdgeInsetsMake(2, 2, 8, 2)];
        [_textView setFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width/2)];
    }

    else if ([self prefersStatusBarHidden]){
        [self.textView setInputAccessoryView:[self currentInputAccessoryView]];
        [_textView reloadInputViews];

        [_textView setFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - [[UIApplication sharedApplication] statusBarFrame].size.height - _currentKeyboardHeight)];

        [_textView setCenter:CGPointMake(_textView.center.x, _textView.center.y + 20.0f)];
        [_textView setTextContainerInset:UIEdgeInsetsMake(0, 2, _textView.inputAccessoryView.frame.size.height + 8, 2)];
    }
    
    [_viewBackgroundLabel setCenter:CGPointMake(_textView.center.x, _textView.center.y - _textView.inputAccessoryView.frame.size.height/2)];
}

- (void)setUpGestures {
    UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeLeft)];
    [swipeLeft setDirection:UISwipeGestureRecognizerDirectionLeft];
    [self.view addGestureRecognizer:swipeLeft];
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRight)];
    [swipeRight setDirection:UISwipeGestureRecognizerDirectionRight];
    [self.view addGestureRecognizer:swipeRight];
    UISwipeGestureRecognizer *swipeDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeDown)];
    [swipeDown setDirection:UISwipeGestureRecognizerDirectionDown];
    [self.view addGestureRecognizer:swipeDown];
    UISwipeGestureRecognizer *swipeUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeUp)];
    [swipeUp setDirection:UISwipeGestureRecognizerDirectionUp];
    [self.view addGestureRecognizer:swipeUp];
    
    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinch:)];
    [self.view addGestureRecognizer:pinch];

    UIRotationGestureRecognizer *rotate = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(rotate:)];
    [self.view addGestureRecognizer:rotate];
}

- (void)setUpLabels {
    [self.view addSubview:self.resetLabelWarning];
    [self.view addSubview:self.labelForCopy];
    [self.view addSubview:self.pasteWarningLabel];
    [self.view addSubview:self.nightModeLabel];
    [self.view addSubview:self.dayModeLabel];
}

#pragma mark - Gesture Actions

- (void)swipeLeft {
    [self goForward];
}

- (void)swipeRight {
    [self goBack];
}

- (void)swipeDown {
    if ([_textView selectedRange].length > 0) {
        [_textView setSelectedTextRange:[_textView textRangeFromPosition:[_textView positionFromPosition:_textView.endOfDocument offset:0] toPosition:[_textView positionFromPosition:_textView.endOfDocument offset:0]]];
    }
    
    else {
        [self updateInputAccessory];
    }
    
    [self updateBackgroundLabelPosition];
}

- (void)swipeUp {
    [self selectAllText];
    
    if (_textView.text.length == 0) {
        [self updateInputAccessory];
    }
    
    else if (_textView.keyboardType == UIKeyboardTypeNamePhonePad) {
        [_textView setInputAccessoryView:(_isDaylight) ? self.keyboardToolbarLowerCaseLight : self.keyboardToolbarLowerCaseDark];
        [_textView reloadInputViews];
    }
    
    else {
        [_textView setInputAccessoryView:(_isDaylight) ? self.keyboardToolbarUpperCaseLight : self.keyboardToolbarUpperCaseDark];
        [_textView reloadInputViews];
    }
    
    [self updateBackgroundLabelPosition];
}

#pragma mark - Input Accessory Views

- (void)updateInputAccessory {
    if (self.textView.inputAccessoryView) {
        [self.textView setInputAccessoryView:nil];
        [_textView reloadInputViews];
        [_textView setTextContainerInset:UIEdgeInsetsMake(0, 2, 8, 2)];
    }
    
    else {
        if (_textView.keyboardType == UIKeyboardTypeNamePhonePad) {
            [_textView setInputAccessoryView:(_isDaylight) ? self.keyboardToolbarLowerCaseLight : self.keyboardToolbarLowerCaseDark];
        }
        
        else {
            [_textView setInputAccessoryView:(_isDaylight) ? self.keyboardToolbarUpperCaseLight : self.keyboardToolbarUpperCaseDark];
        }
        
        [_textView reloadInputViews];
        [_textView setTextContainerInset:UIEdgeInsetsMake(0, 2, _textView.inputAccessoryView.frame.size.height + 8, 2)];
    }
}

- (UIToolbar *)currentInputAccessoryView {
    if (_textView.keyboardType == UIKeyboardTypeNamePhonePad) {
        if (_isDaylight) {
            return self.keyboardToolbarLowerCaseLight;
        }
        
        else {
            return self.keyboardToolbarLowerCaseDark;
        }
    }
    
    else {
        if (_isDaylight) {
            return self.keyboardToolbarUpperCaseLight;
        }
        
        else {
            return self.keyboardToolbarUpperCaseDark;
        }
    }
}

#pragma mark - Back/Forth Actions

- (void)goBack {
    if (![_textView.text isEqualToString:@""]) {
        _oldText = _textView.text;
        [_textView setText:@""];
    }
    
    else {
        [self resetView];
    }
}

- (void)goForward {
    if (![_textView.text isEqualToString:_oldText] && _oldText.length != 0) {
        NSString *tempText = _textView.text;
        [_textView setText:_oldText];
        _oldText = tempText;
    }
    
    else if ([[UIPasteboard generalPasteboard] string] != nil) {
        [_textView setText:[NSString stringWithFormat:@"%@%@",_textView.text,[[UIPasteboard generalPasteboard] string]]];
        [self animateLabel:_pasteWarningLabel];
    }
}

#pragma mark - Reset View

- (void)resetView {
    [_textView setInputAccessoryView:nil];
    [_textView setSelectedTextRange:[_textView textRangeFromPosition:[_textView positionFromPosition:_textView.beginningOfDocument inDirection:UITextLayoutDirectionRight offset:0] toPosition:_textView.beginningOfDocument]];
    [_textView setText:@""];
    [_textView setFont:[UIFont boldSystemFontOfSize:FONT_SIZE]];
    [_textView setBounces:YES];
    [_textView setKeyboardType:UIKeyboardTypeAlphabet];
    [_textView setKeyboardAppearance:UIKeyboardAppearanceDark];
    [_textView setBackgroundColor:[UIColor clearColor]];
    [_textView setTextColor:[UIColor lightTextColor]];
    [_textView setOpaque:NO];
    [self.textView setInputAccessoryView:(_textView.keyboardType == UIKeyboardTypeNamePhonePad) ? self.keyboardToolbarLowerCaseLight : self.keyboardToolbarUpperCaseLight];
    
    if (_isDaylight) {
        [_textView setKeyboardAppearance:UIKeyboardAppearanceLight];
        [_textView setTextColor:[UIColor blackColor]];
        [self.textView setInputAccessoryView:self.keyboardToolbarUpperCaseLight];
        if (_textView.keyboardType == UIKeyboardTypeNamePhonePad) {
            [self.textView setInputAccessoryView:self.keyboardToolbarLowerCaseLight];
        }
    }
    _oldText = @"";
    
    [self.view setBackgroundColor:(_isDaylight) ? [UIColor lightTextColor] : [UIColor darkGrayColor]];
    
    if (!_isDaylight) {
        [self.textView setInputAccessoryView:(_textView.keyboardType == UIKeyboardTypeNamePhonePad) ? self.keyboardToolbarLowerCaseDark : self.keyboardToolbarUpperCaseDark];
    }

    else {
        [self.textView setInputAccessoryView:(_textView.keyboardType == UIKeyboardTypeNamePhonePad) ? self.keyboardToolbarLowerCaseLight : self.keyboardToolbarUpperCaseLight];
    }

    // Update status bar appearance
    [self setNeedsStatusBarAppearanceUpdate];
    [_textView reloadInputViews];
    _isUpdated = YES;
}

#pragma mark - Select All/Copy

- (void)selectAllText {
    if (_textView.text.length > 0) {
        [[UIPasteboard generalPasteboard] setString:[_textView text]];
        [self animateLabel:_labelForCopy];
    }
}

#pragma mark - Pinch/Rotate Gesture

- (void)pinch:(UIPinchGestureRecognizer *)sender {
    if (sender.scale > 1) {
        _tempFontSize = _currentFontSize + sender.scale;
        [_textView setFont:[UIFont boldSystemFontOfSize:_tempFontSize]];
    }
    
    else if (sender.scale < 1) {
        _tempFontSize = _currentFontSize - (1/sender.scale);
        [_textView setFont:[UIFont boldSystemFontOfSize:_tempFontSize]];
    }
    
    if (sender.state == UIGestureRecognizerStateEnded) {
        _currentFontSize = _tempFontSize;
    }
}

- (void)rotate:(UIRotationGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan && sender.rotation > 0) {
        [_lastFont insertObject:_textView.font atIndex:0];
        if (_nextFont.count > 0) {
            [_textView setFont:_nextFont[0]];
            [_nextFont removeObjectAtIndex:0];
        }
        
        else {
            [_textView setFont:[UIFont fontWithName:_allFonts[arc4random()%_allFonts.count] size:_currentFontSize]];
        }
    }
    
    else if (sender.state == UIGestureRecognizerStateBegan && sender.rotation < 0) {
        if (_lastFont.count > 0) {
            [_nextFont insertObject:_textView.font atIndex:0];
            [_textView setFont:_lastFont[0]];
            [_lastFont removeObjectAtIndex:0];
        }
        
        else {
            [_textView setFont:[UIFont boldSystemFontOfSize:_currentFontSize]];
        }
    }
    
    [_textView setFont:[UIFont fontWithName:_textView.font.fontName size:_currentFontSize]];
}

#pragma mark - Text View

- (UITextView *)textView {
    if (!_textView) {
        CGFloat topInset = 0;
        if (@available(iOS 11.0, *)) {
            topInset = self.view.safeAreaInsets.top;
            if (topInset == 0) {
                topInset = [[UIApplication sharedApplication] statusBarFrame].size.height;
            }
        } else {
            topInset = ([[UIApplication sharedApplication] statusBarFrame].size.height <= 20.0f) ? [[UIApplication sharedApplication] statusBarFrame].size.height : 20.0f;
        }

        CGFloat bottomInset = 0;
        if (@available(iOS 11.0, *)) {
            bottomInset = self.view.safeAreaInsets.bottom;
        }

        _textView = [[UITextView alloc] initWithFrame:CGRectMake(0, topInset, kScreenWidth, kScreenHeight - topInset - _currentKeyboardHeight - bottomInset)];
        [_textView setDelegate:self];
        [_textView setFont:[UIFont boldSystemFontOfSize:FONT_SIZE]];
        [_textView setBounces:YES];
        [_textView setKeyboardType:UIKeyboardTypeAlphabet];
        [_textView setKeyboardAppearance:UIKeyboardAppearanceDark];
        [_textView setScrollsToTop:YES];
        [_textView setShowsVerticalScrollIndicator:NO];
        [_textView setBackgroundColor:[UIColor clearColor]];
        [_textView setTextColor:[UIColor lightTextColor]];
        [_textView setOpaque:NO];
        [_textView setScrollsToTop:YES];
        [_textView setTextContainerInset:UIEdgeInsetsMake(0, 2, TOOLBAR_HEIGHT + 8, 2)];
        
        if (_isDaylight) {
            [_textView setKeyboardAppearance:UIKeyboardAppearanceLight];
            [_textView setTextColor:[UIColor blackColor]];
        }
    }
    
    return _textView;
}

#pragma mark - Keyboard Toolbar

- (UIToolbar *)keyboardToolbarUpperCaseLight {
    if (!_keyboardToolbarUpperCaseLight) {
        _keyboardToolbarUpperCaseLight = [[UIToolbar alloc] initWithFrame:CGRectMake(0, kScreenHeight, kScreenWidth, TOOLBAR_HEIGHT)];
        [_keyboardToolbarUpperCaseLight setBackgroundColor:[UIColor clearColor]];
        [_keyboardToolbarUpperCaseLight setTranslucent:YES];
        
        UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"h:mma"];
        NSArray *keyboardTypes = _keyboardTypes;
        NSMutableArray *toolbarItems = [[NSMutableArray alloc] initWithCapacity:keyboardTypes.count];
        int tag = 10;
        for (NSString *name in keyboardTypes) {
            UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:name style:UIBarButtonItemStylePlain target:self action:@selector(changeKeyboard:)];
            NSShadow *shadow = [NSShadow new];
            [shadow setShadowColor: [UIColor colorWithWhite:1.0f alpha:0.750f]];
            [shadow setShadowOffset: CGSizeMake(0.0f, 1.0f)];
            [button setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                            [UIColor colorWithRed:25.0/255.0 green:4.0/255.0 blue:100.0/255.0 alpha:1.0], NSForegroundColorAttributeName,
                                            [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0], NSBackgroundColorAttributeName,
                                            shadow, NSShadowAttributeName,
                                            [UIFont fontWithName:@"AmericanTypewriter" size:FONT_SIZE], NSFontAttributeName,
                                            nil] 
                                  forState:UIControlStateNormal];
            [button setTag:tag];
            tag++;
            [toolbarItems addObject:flex];
            [toolbarItems addObject:button];
        }
        [toolbarItems addObject:flex];
        
        [_keyboardToolbarUpperCaseLight setItems:toolbarItems];
    }
    
    return _keyboardToolbarUpperCaseLight;
}

- (UIToolbar *)keyboardToolbarLowerCaseLight {
    if (!_keyboardToolbarLowerCaseLight) {
        _keyboardToolbarLowerCaseLight = [[UIToolbar alloc] initWithFrame:CGRectMake(0, kScreenHeight, kScreenWidth, TOOLBAR_HEIGHT)];
        [_keyboardToolbarLowerCaseLight setBackgroundColor:[UIColor clearColor]];
        [_keyboardToolbarLowerCaseLight setTranslucent:YES];
        
        UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        NSArray *keyboardTypes = _keyboardTypes;
        NSMutableArray *toolbarItems = [[NSMutableArray alloc] initWithCapacity:keyboardTypes.count];
        int tag = 10;
        for (NSString *name in keyboardTypes) {
            UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:name style:UIBarButtonItemStylePlain target:self action:@selector(changeKeyboard:)];
            NSShadow *shadow = [NSShadow new];
            [shadow setShadowColor: [UIColor colorWithWhite:1.0f alpha:0.750f]];
            [shadow setShadowOffset: CGSizeMake(0.0f, 1.0f)];
            [button setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                            [UIColor colorWithRed:25.0/255.0 green:4.0/255.0 blue:100.0/255.0 alpha:1.0], NSForegroundColorAttributeName,
                                            [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0], NSBackgroundColorAttributeName,
                                            shadow, NSShadowAttributeName,
                                            [UIFont fontWithName:@"AmericanTypewriter" size:FONT_SIZE], NSFontAttributeName,
                                            nil]
                                  forState:UIControlStateNormal];
            [button setTag:tag];
            tag++;
            [toolbarItems addObject:flex];
            [toolbarItems addObject:button];
        }
        [toolbarItems addObject:flex];
        
        [_keyboardToolbarLowerCaseLight setItems:toolbarItems];
    }
    
    return _keyboardToolbarLowerCaseLight;
}

- (UIToolbar *)keyboardToolbarUpperCaseDark {
    if (!_keyboardToolbarUpperCaseDark) {
        _keyboardToolbarUpperCaseDark = [[UIToolbar alloc] initWithFrame:CGRectMake(0, kScreenHeight, kScreenWidth, TOOLBAR_HEIGHT)];
        [_keyboardToolbarUpperCaseDark setBarTintColor:[UIColor blackColor]];
        
        UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        NSArray *keyboardTypes = _keyboardTypes;
        NSMutableArray *toolbarItems = [[NSMutableArray alloc] initWithCapacity:keyboardTypes.count];
        int tag = 10;
        for (NSString *name in keyboardTypes) {
            UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:name style:UIBarButtonItemStylePlain target:self action:@selector(changeKeyboard:)];
            NSShadow *shadow = [NSShadow new];
            [shadow setShadowColor: [UIColor colorWithWhite:1.0f alpha:0.750f]];
            [shadow setShadowOffset: CGSizeMake(0.0f, 1.0f)];
            [button setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                            [UIColor colorWithRed:205.0/255.0 green:204.0/255.0 blue:200.0/255.0 alpha:1.0], NSForegroundColorAttributeName,
                                            [UIFont fontWithName:@"AmericanTypewriter" size:FONT_SIZE], NSFontAttributeName,
                                            nil]
                                  forState:UIControlStateNormal];
            [button setTag:tag];
            tag++;
            [toolbarItems addObject:flex];
            [toolbarItems addObject:button];
        }
        [toolbarItems addObject:flex];
        
        [_keyboardToolbarUpperCaseDark setItems:toolbarItems];
    }
    
    return _keyboardToolbarUpperCaseDark;
}

- (UIToolbar *)keyboardToolbarLowerCaseDark {
    if (!_keyboardToolbarLowerCaseDark) {
        _keyboardToolbarLowerCaseDark = [[UIToolbar alloc] initWithFrame:CGRectMake(0, kScreenHeight, kScreenWidth, TOOLBAR_HEIGHT)];
        [_keyboardToolbarLowerCaseDark setBarTintColor:[UIColor blackColor]];
        
        UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        NSArray *keyboardTypes = _keyboardTypes;
        NSMutableArray *toolbarItems = [[NSMutableArray alloc] initWithCapacity:keyboardTypes.count];
        int tag = 10;
        for (NSString *name in keyboardTypes) {
            UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:name style:UIBarButtonItemStylePlain target:self action:@selector(changeKeyboard:)];
            NSShadow *shadow = [NSShadow new];
            [shadow setShadowColor: [UIColor colorWithWhite:1.0f alpha:0.750f]];
            [shadow setShadowOffset: CGSizeMake(0.0f, 1.0f)];
            [button setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                            [UIColor colorWithRed:205.0/255.0 green:204.0/255.0 blue:200.0/255.0 alpha:1.0], NSForegroundColorAttributeName,
                                            [UIFont fontWithName:@"AmericanTypewriter" size:FONT_SIZE], NSFontAttributeName,
                                            nil]
                                  forState:UIControlStateNormal];
            [button setTag:tag];
            tag++;
            [toolbarItems addObject:flex];
            [toolbarItems addObject:button];
        }
        [toolbarItems addObject:flex];
        
        [_keyboardToolbarLowerCaseDark setItems:toolbarItems];
    }
    
    return _keyboardToolbarLowerCaseDark;
}

#pragma mark - Labels

- (UILabel *)resetLabelWarning {
    if (!_resetLabelWarning) {
        _resetLabelWarning = [[UILabel alloc] initWithFrame:CGRectMake(0, kScreenHeight, kScreenWidth, kScreenWidth)];
        [_resetLabelWarning setText:@"Reset"];
        [_resetLabelWarning setTextAlignment:NSTextAlignmentCenter];
        [_resetLabelWarning setFont:[UIFont systemFontOfSize:FONT_SIZE*2]];
    }
    
    return _resetLabelWarning;
}

- (UILabel *)labelForCopy {
    if (!_labelForCopy) {
        _labelForCopy = [[UILabel alloc] initWithFrame:CGRectMake(0, kScreenHeight, kScreenWidth, kScreenWidth)];
        [_labelForCopy setText:@"Copied to clipboard"];
        [_labelForCopy setTextAlignment:NSTextAlignmentCenter];
        [_labelForCopy setFont:[UIFont systemFontOfSize:FONT_SIZE*2]];
    }
    
    return _labelForCopy;
}

- (UILabel *)pasteWarningLabel {
    if (!_pasteWarningLabel) {
        _pasteWarningLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, kScreenHeight, kScreenWidth, kScreenWidth)];
        [_pasteWarningLabel setText:@"Paste"];
        [_pasteWarningLabel setTextAlignment:NSTextAlignmentCenter];
        [_pasteWarningLabel setFont:[UIFont systemFontOfSize:FONT_SIZE*2]];
    }
    
    return _pasteWarningLabel;
}

-(UILabel *)nightModeLabel {
    if (!_nightModeLabel) {
        _nightModeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, kScreenHeight, kScreenWidth, kScreenWidth)];
        [_nightModeLabel setText:@"Night Mode"];
        [_nightModeLabel setTextAlignment:NSTextAlignmentCenter];
        [_nightModeLabel setFont:[UIFont systemFontOfSize:FONT_SIZE*2]];
        [_nightModeLabel setTextColor:[UIColor yellowColor]];
    }
    
    return _nightModeLabel;
}

- (UILabel *)dayModeLabel {
    if (!_dayModeLabel) {
        _dayModeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, kScreenHeight, kScreenWidth, kScreenWidth)];
        [_dayModeLabel setText:@"Day Mode"];
        [_dayModeLabel setTextAlignment:NSTextAlignmentCenter];
        [_dayModeLabel setFont:[UIFont systemFontOfSize:FONT_SIZE*2]];
    }
    
    return _dayModeLabel;
}

- (UILabel *)viewBackgroundLabel {
	if (!_viewBackgroundLabel) {
		_viewBackgroundLabel = [[UILabel alloc] init];
		
		UIFont *font = [UIFont boldSystemFontOfSize:BACKGROUND_FONT_SIZE];
		
		UIColor *textColor = [UIColor colorWithWhite:0.8 alpha:0.9];
		
		NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
		[paragraphStyle setAlignment:NSTextAlignmentCenter];
		
		NSDictionary *attrs = @{NSForegroundColorAttributeName : textColor,
								NSFontAttributeName : font,
								NSTextEffectAttributeName : NSTextEffectLetterpressStyle,
								NSParagraphStyleAttributeName: paragraphStyle};
		
		NSAttributedString *attrString = [[NSAttributedString alloc]
										  initWithString:BACKGROUND_TEXT
										  attributes:attrs];
		
		[_viewBackgroundLabel setAttributedText:attrString];
		
		CGRect textRect = [attrString boundingRectWithSize:self.view.bounds.size options:0 context:nil];
		
		CGRect integralTextRect = CGRectIntegral(textRect);
		
		[_viewBackgroundLabel setFrame:CGRectMake((kScreenWidth)/2, (kScreenHeight - _currentKeyboardHeight)/2 - TOOLBAR_HEIGHT/2, integralTextRect.size.width, integralTextRect.size.height)];
        
        [_viewBackgroundLabel setAlpha:BACKGROUND_LABEL_ALPHA];
	}
	
	return _viewBackgroundLabel;
}

- (void)animateLabel:(UILabel *)label {
    [UILabel setAnimationBeginsFromCurrentState:YES];
    [label setCenter:_viewBackgroundLabel.center];
    [label setAlpha:0.0f];
    [label setTextColor:(_isDaylight) ? [UIColor darkGrayColor] : [UIColor whiteColor]];
    [UILabel animateWithDuration:0.5f animations:^{
        [label setCenter:CGPointMake(label.center.x, label.center.y + 10.0f)];
        [label setAlpha:0.5f];
        [_viewBackgroundLabel setAlpha:0.07f];
    }completion:^(BOOL finished){
        [UILabel animateWithDuration:0.5f animations:^{
            [label setCenter:CGPointMake(label.center.x, label.center.y + 10.0f)];
            [label setAlpha:0.0f];
            [_viewBackgroundLabel setAlpha:BACKGROUND_LABEL_ALPHA];
        }];
    }];
}

- (void)updateBackgroundLabelPosition {
    [UILabel animateWithDuration:0.33 animations:^{
        [_viewBackgroundLabel setCenter:CGPointMake(_viewBackgroundLabel.center.x, _textView.center.y - _textView.inputAccessoryView.bounds.size.height/2)];
    }];
}

#pragma mark - Change Keyboard Type

- (void)changeKeyboard:(UIBarButtonItem *)sender {
    if (sender.tag != 13) {
        [_textView setInputView:nil];
    }
    
    switch (sender.tag) {
        case 10:
            if (_textView.keyboardType == UIKeyboardTypeAlphabet) {
                [_textView setKeyboardType:UIKeyboardTypeNamePhonePad];
                [self.textView setInputAccessoryView:(_isDaylight) ? self.keyboardToolbarLowerCaseLight : self.keyboardToolbarLowerCaseDark];
                [_textView reloadInputViews];
            }
            
            else {
                [_textView setKeyboardType:UIKeyboardTypeAlphabet];
                [self.textView setInputAccessoryView:(_isDaylight) ? self.keyboardToolbarUpperCaseLight : self.keyboardToolbarUpperCaseDark];
                [_textView reloadInputViews];
            }
            break;
            
        case 11:
            if (_textView.keyboardType != UIKeyboardTypeEmailAddress) {
                [_textView setKeyboardType:UIKeyboardTypeEmailAddress];
            }
            
            else {
                [_textView setKeyboardType:UIKeyboardTypeTwitter];
            }
            break;
            
        case 12:
            if (_textView.keyboardType != UIKeyboardTypeDecimalPad) {
                [_textView setKeyboardType:UIKeyboardTypeDecimalPad];
            }
            
            else {
                [_textView setKeyboardType:UIKeyboardTypeNumberPad];
            }
            break;
            
        case 13:
            [_textView setInputView:self.timeKeyboard];
            break;
            
        default:
            break;
    }
    [self updateKeyboard];
}

- (void)updateKeyboard {
    [_textView resignFirstResponder];
    [_textView becomeFirstResponder];
}

- (UIView *)timeKeyboard {
    if (!_timeKeyboard) {
        CGFloat buttonHeight = _currentKeyboardHeight / 4;
        _timeKeyboard = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, _currentKeyboardHeight)];
        int digits = 12;
        int x = 0;
        int y = 0;

        for (int i = 0; i < digits; i++) {
            UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(kScreenWidth * (2*x)/6, buttonHeight * (2*y)/2, kScreenWidth/3, buttonHeight)];
            [button setTitle:[NSString stringWithFormat:@"%d",(i+1)] forState:UIControlStateNormal];
            [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [button.layer setBorderColor:[UIColor lightGrayColor].CGColor];
            [button.layer setBorderWidth:BUTTON_BORDER_WIDTH];
            [button setBackgroundColor:[UIColor whiteColor]];
            [button.titleLabel setFont:[UIFont systemFontOfSize:TIME_BUTTON_FONT_SIZE]];
            [button setBackgroundImage:[self imageWithColor:[UIColor lightGrayColor]] forState:UIControlStateHighlighted];
            [button setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
            [button setTag:i];
            
            if (x == 2) {
                x = 0;
                y++;
            }
            
            else {
                x++;
            }
            
            [button addTarget:self action:@selector(buttonTouched:) forControlEvents:UIControlEventTouchUpInside];
            
            [_timeKeyboard addSubview:button];
        }
    }
    
    return _timeKeyboard;
}

- (UIView *)minuteKeyboard {
    if (!_minuteKeyboard) {
        CGFloat buttonHeight = _currentKeyboardHeight / 4;
        _minuteKeyboard = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, _currentKeyboardHeight)];
        int digits = 12;
        int x = 0;
        int y = 0;

        for (int i = 0; i < digits; i++) {
            UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(kScreenWidth * (2*x)/6, buttonHeight * (2*y)/2, kScreenWidth/3, buttonHeight)];
            [button setTitle:[NSString stringWithFormat:(i < 2) ? @"0%d" : @"%d",(i*5)] forState:UIControlStateNormal];
            [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [button.layer setBorderColor:[UIColor lightGrayColor].CGColor];
            [button.layer setBorderWidth:BUTTON_BORDER_WIDTH];
            [button setBackgroundColor:[UIColor whiteColor]];
            [button.titleLabel setFont:[UIFont systemFontOfSize:TIME_BUTTON_FONT_SIZE]];
            [button setBackgroundImage:[self imageWithColor:[UIColor lightGrayColor]] forState:UIControlStateHighlighted];
            [button setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
            [button setTag:i];
            
            if (x == 2) {
                x = 0;
                y++;
            }
            
            else {
                x++;
            }
            
            [button addTarget:self action:@selector(buttonTouched:) forControlEvents:UIControlEventTouchUpInside];
            
            [_minuteKeyboard addSubview:button];
        }
    }
    
    return _minuteKeyboard;
}

- (UIView *)ampmKeyboard {
    if (!_ampmKeyboard) {
        _ampmKeyboard = [[UIView alloc] initWithFrame:_timeKeyboard.frame];
        NSArray *periods = @[@"AM",@"PM"];
        int i = 0;
        for (NSString *period in periods) {
            UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, _ampmKeyboard.frame.size.height/2 * i, kScreenWidth, _ampmKeyboard.frame.size.height/2)];
            [button setTitle:period forState:UIControlStateNormal];
            [button setTag:(i + 1)];
            [button setBackgroundColor:[UIColor colorWithRed:(1 - i) green:(1 - i)/2 blue:(i)/2 alpha:1.0f]];
            [button setBackgroundImage:[self imageWithColor:[UIColor lightGrayColor]] forState:UIControlStateHighlighted];
            [button addTarget:self action:@selector(buttonTouched:) forControlEvents:UIControlEventTouchUpInside];
            i++;
            
            [_ampmKeyboard addSubview:button];
        }
    }
    
    return _ampmKeyboard;
}

- (void) buttonTouched:(id)sender {
    if ([_textView.inputView isEqual:self.timeKeyboard]) {
        [self pasteText:[NSString stringWithFormat:@"%lu",(long)[sender tag] + 1] inTextView:_textView];
        [_textView setInputView:nil];
        [_textView resignFirstResponder];
        [_textView setInputView:self.minuteKeyboard];
        [_textView becomeFirstResponder];
    }

    else if ([_textView.inputView isEqual:self.minuteKeyboard]) {
        [self pasteText:[NSString stringWithFormat:([sender tag] < 2) ? @":0%lu" : @":%lu",(long)([sender tag] * 5)] inTextView:_textView];
        [_textView setInputView:nil];
        [_textView resignFirstResponder];
        [_textView setInputView:self.ampmKeyboard];
        [_textView becomeFirstResponder];
    }
    
    else if ([_textView.inputView isEqual:self.ampmKeyboard]) {
        [self pasteText:[NSString stringWithFormat:([sender tag]%2 == 1) ? @"a" : @"p"] inTextView:_textView];
        [_textView setInputView:nil];
        [_textView resignFirstResponder];
        [_textView becomeFirstResponder];
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        if ([textView.text rangeOfString:@"color"].location != NSNotFound) {
            [textView setText:[self colorText]];
            return NO;
        }
        
        NSArray *testWords = @[@"black",@"blue",@"brown",@"cyan",@"green",@"orange",@"purple",@"red",@"white",@"yellow"];
        for (NSString *word in testWords) {
            if ([[textView.text lowercaseString] rangeOfString:@"set"].location != NSNotFound && [[textView.text lowercaseString] rangeOfString:word].location != NSNotFound) {
                NSDictionary *colorValues = @{@"black" : [UIColor blackColor], @"blue" : [UIColor blueColor], @"cyan" : [UIColor cyanColor], @"brown" : [UIColor brownColor], @"green" : [UIColor greenColor], @"orange" : [UIColor orangeColor], @"purple" : [UIColor purpleColor], @"red" : [UIColor redColor], @"white" : [UIColor whiteColor], @"yellow" : [UIColor yellowColor]};
                [self.view setBackgroundColor:[colorValues objectForKey:[word lowercaseString]]];
                if ([word isEqualToString:@"white"] || [word isEqualToString:@"yellow"]) {
                    [self.textView setTextColor:[UIColor blackColor]];
                }
                
                else {
                    [self.textView setTextColor:[UIColor whiteColor]];
                }
                break;
                break;
            }
        }
    }
    
    
    return YES;
}

- (NSString *)colorText {
    NSMutableString *r = [[NSMutableString alloc] initWithCapacity:1000];
    
    NSString *s = @"\n    Earth Yellow	#E1A95F	88COLOR	66COLOR	37COLOR	3468COLOR	63COLOR	58COLOR	88COLOR\n  	Ebony	#555D50	33COLOR	36COLOR	31COLOR	97COLOR	8COLOR	34COLOR	14COLOR	36COLOR\n  	Ecru	#C2B280	76COLOR	70COLOR	50COLOR	45COLOR	35COLOR	63COLOR	34COLOR	76COLOR\n  	Eerie Black	#1B1B1B	11COLOR	11COLOR	11COLOR	0COLOR	11COLOR	0COLOR	11COLOR\n  	Eggplant	#614051	38COLOR	25COLOR	32COLOR	329COLOR	20COLOR	32COLOR	34COLOR	38COLOR\n  	Eggshell	#F0EAD6	94COLOR	92COLOR	84COLOR	46COLOR	46COLOR	89COLOR	11COLOR	94COLOR\n  	Egyptian Blue	#1034A6	6COLOR	20COLOR	65COLOR	226COLOR	82COLOR	36COLOR	90COLOR	65COLOR\n  	Electric Blue	#7DF9FF	49COLOR	98COLOR	100COLOR	183COLOR	100COLOR	75COLOR	51COLOR	100COLOR\n  	Electric Crimson	#FF003F	100COLOR	0COLOR	25COLOR	345COLOR	100COLOR	50COLOR	100COLOR	100COLOR\n  	Electric Cyan	#00FFFF	0COLOR	100COLOR	100COLOR	180COLOR	100COLOR	50COLOR	100COLOR	100COLOR\n  	Electric Green	#00FF00	0COLOR	100COLOR	0COLOR	120COLOR	100COLOR	50COLOR	100COLOR	100COLOR\n  	Electric Indigo	#6F00FF	44COLOR	0COLOR	100COLOR	266COLOR	100COLOR	50COLOR	100COLOR	100COLOR\n  	Electric Lavender	#F4BBFF	96COLOR	73COLOR	100COLOR	290COLOR	100COLOR	87COLOR	27COLOR	100COLOR\n  	Electric Lime	#CCFF00	80COLOR	100COLOR	0COLOR	72COLOR	100COLOR	50COLOR	100COLOR	100COLOR\n  	Electric Purple	#BF00FF	75COLOR	0COLOR	100COLOR	285COLOR	100COLOR	50COLOR	100COLOR	100COLOR\n  	Electric Ultramarine	#3F00FF	25COLOR	0COLOR	100COLOR	255COLOR	100COLOR	50COLOR	100COLOR	100COLOR\n  	Electric Violet	#8F00FF	56COLOR	0COLOR	100COLOR	274COLOR	100COLOR	50COLOR	100COLOR	100COLOR\n  	Electric Yellow	#FFFF33	100COLOR	100COLOR	20COLOR	60COLOR	100COLOR	60COLOR	80COLOR	100COLOR\n  	Emerald	#50C878	31COLOR	78COLOR	47COLOR	140COLOR	52COLOR	55COLOR	60COLOR	78COLOR\n  	Eminence	#6C3082	42COLOR	19COLOR	51COLOR	284COLOR	46COLOR	35COLOR	63COLOR	51COLOR\n  	English Green	#1B4D3E	11COLOR	30COLOR	24COLOR	162COLOR	48COLOR	20COLOR	65COLOR	30COLOR\n  	English Lavender	#B48395	71COLOR	51COLOR	58COLOR	338COLOR	25COLOR	61COLOR	27COLOR	71COLOR\n  	English Red	#AB4B52	67COLOR	29COLOR	32COLOR	356COLOR	39COLOR	48COLOR	56COLOR	67COLOR\n  	English Violet	#563C5C	34COLOR	24COLOR	36COLOR	289COLOR	21COLOR	30COLOR	35COLOR	36COLOR\n  	Eton Blue	#96C8A2	59COLOR	78COLOR	64COLOR	134COLOR	31COLOR	69COLOR	25COLOR	78COLOR\n  	Eucalyptus	#44D7A8	27COLOR	84COLOR	66COLOR	161COLOR	65COLOR	55COLOR	68COLOR	84COLOR\n  	Fallow	#C19A6B	76COLOR	60COLOR	42COLOR	33COLOR	41COLOR	59COLOR	45COLOR	76COLOR\n  	Falu Red	#801818	50COLOR	9COLOR	9COLOR	0COLOR	68COLOR	30COLOR	81COLOR	50COLOR\n  	Fandango	#B53389	71COLOR	20COLOR	54COLOR	320COLOR	56COLOR	45COLOR	72COLOR	71COLOR\n  	Fandango Pink	#DE5285	87COLOR	32COLOR	52COLOR	338COLOR	68COLOR	60COLOR	63COLOR	87COLOR\n  	Fashion Fuchsia	#F400A1	96COLOR	0COLOR	63COLOR	320COLOR	100COLOR	48COLOR	100COLOR	96COLOR\n  	Fawn	#E5AA70	90COLOR	67COLOR	44COLOR	30COLOR	69COLOR	67COLOR	51COLOR	90COLOR\n  	Feldgrau	#4D5D53	30COLOR	36COLOR	33COLOR	143COLOR	9COLOR	33COLOR	17COLOR	36COLOR\n  	Feldspar	#FDD5B1	99COLOR	84COLOR	69COLOR	28COLOR	95COLOR	84COLOR	30COLOR	99COLOR\n  	Fern Green	#4F7942	31COLOR	47COLOR	26COLOR	106COLOR	29COLOR	37COLOR	45COLOR	47COLOR\n  	Ferrari Red	#FF2800	100COLOR	16COLOR	0COLOR	9COLOR	100COLOR	50COLOR	100COLOR	100COLOR\n  	Field Drab	#6C541E	42COLOR	33COLOR	12COLOR	42COLOR	57COLOR	27COLOR	72COLOR	42COLOR\n  	Firebrick	#B22222	70COLOR	13COLOR	13COLOR	0COLOR	68COLOR	42COLOR	81COLOR	70COLOR\n  	Fire Engine Red	#CE2029	81COLOR	13COLOR	16COLOR	357COLOR	73COLOR	47COLOR	84COLOR	81COLOR\n  	Flame	#E25822	89COLOR	35COLOR	13COLOR	17COLOR	77COLOR	51COLOR	85COLOR	89COLOR\n  	Flamingo Pink	#FC8EAC	99COLOR	56COLOR	67COLOR	344COLOR	95COLOR	77COLOR	44COLOR	99COLOR\n  	Flattery	#6B4423	42COLOR	27COLOR	14COLOR	28COLOR	51COLOR	28COLOR	67COLOR	42COLOR\n  	Flavescent	#F7E98E	97COLOR	91COLOR	56COLOR	52COLOR	87COLOR	76COLOR	43COLOR	97COLOR\n  	Flax	#EEDC82	93COLOR	86COLOR	51COLOR	50COLOR	76COLOR	72COLOR	45COLOR	93COLOR\n  	Flirt	#A2006D	64COLOR	0COLOR	43COLOR	320COLOR	100COLOR	32COLOR	100COLOR	64COLOR\n  	Floral White	#FFFAF0	100COLOR	98COLOR	94COLOR	40COLOR	100COLOR	97COLOR	6COLOR	100COLOR\n  	Fluorescent Orange	#FFBF00	100COLOR	75COLOR	0COLOR	45COLOR	100COLOR	50COLOR	100COLOR	100COLOR\n  	Fluorescent Pink	#FF1493	100COLOR	8COLOR	58COLOR	328COLOR	100COLOR	54COLOR	92COLOR	100COLOR\n  	Fluorescent Yellow	#CCFF00	80COLOR	100COLOR	0COLOR	72COLOR	100COLOR	50COLOR	100COLOR	100COLOR\n  	Folly	#FF004F	100COLOR	0COLOR	31COLOR	341COLOR	100COLOR	50COLOR	100COLOR	100COLOR\n  	Forest Green (Traditional)	#014421	0COLOR	27COLOR	13COLOR	149COLOR	97COLOR	14COLOR	99COLOR	27COLOR\n  	Forest Green (Web)	#228B22	13COLOR	55COLOR	13COLOR	120COLOR	61COLOR	34COLOR	76COLOR	55COLOR\n  	French Beige	#A67B5B	65COLOR	48COLOR	36COLOR	26COLOR	30COLOR	50COLOR	45COLOR	65COLOR\n  	French Bistre	#856D4D	52COLOR	43COLOR	30COLOR	34COLOR	27COLOR	41COLOR	42COLOR	52COLOR\n  	French Blue	#0072BB	0COLOR	45COLOR	73COLOR	203COLOR	100COLOR	37COLOR	100COLOR	73COLOR\n  	French Fuchsia	#FD3F92	99COLOR	25COLOR	57COLOR	334COLOR	98COLOR	62COLOR	75COLOR	99COLOR\n  	French Lilac	#86608E	53COLOR	38COLOR	56COLOR	290COLOR	19COLOR	47COLOR	32COLOR	56COLOR\n 	French Lime	#9EFD38	62COLOR	99COLOR	22COLOR	89COLOR	98COLOR	61COLOR	78COLOR	99COLOR\n 	French Mauve	#D473D4	83COLOR	45COLOR	83COLOR	300COLOR	53COLOR	64COLOR	46COLOR	83COLOR\n 	French Pink	#FD6C9E	99COLOR	42COLOR	62COLOR	339COLOR	97COLOR	71COLOR	57COLOR	99COLOR\n  	French Plum	#811453	51COLOR	8COLOR	33COLOR	325COLOR	73COLOR	29COLOR	84COLOR	51COLOR\n  	French Puce	#4E1609	31COLOR	9COLOR	4COLOR	11COLOR	79COLOR	17COLOR	88COLOR	31COLOR\n  	French Raspberry	#C72C48	78COLOR	17COLOR	28COLOR	349COLOR	64COLOR	48COLOR	78COLOR	78COLOR\n 	French Rose	#F64A8A	96COLOR	29COLOR	54COLOR	338COLOR	91COLOR	63COLOR	70COLOR	96COLOR\n 	French Sky Blue	#77B5FE	47COLOR	71COLOR	100COLOR	212COLOR	99COLOR	73COLOR	53COLOR	100COLOR\n  	French Violet	#8806CE	53COLOR	2COLOR	81COLOR	279COLOR	94COLOR	42COLOR	97COLOR	81COLOR\n  	French Wine	#AC1E44	67COLOR	12COLOR	27COLOR	344COLOR	70COLOR	40COLOR	83COLOR	67COLOR\n  	Fresh Air	#A6E7FF	65COLOR	91COLOR	100COLOR	196COLOR	100COLOR	83COLOR	35COLOR	100COLOR\n  	Fuchsia	#FF00FF	100COLOR	0COLOR	100COLOR	300COLOR	100COLOR	50COLOR	100COLOR	100COLOR\n  	Fuchsia (Crayola)	#C154C1	76COLOR	33COLOR	76COLOR	300COLOR	47COLOR	54COLOR	56COLOR	76COLOR\n  	Fuchsia Pink	#FF77FF	100COLOR	47COLOR	100COLOR	300COLOR	100COLOR	73COLOR	53COLOR	100COLOR\n  	Fuchsia Purple	#CC397B	80COLOR	22COLOR	48COLOR	333COLOR	59COLOR	51COLOR	72COLOR	80COLOR\n 	Fuchsia Rose	#C74375	78COLOR	26COLOR	46COLOR	337COLOR	54COLOR	52COLOR	66COLOR	78COLOR\n 	Fulvous	#E48400	89COLOR	52COLOR	0COLOR	35COLOR	100COLOR	45COLOR	100COLOR	89COLOR\n 	Fuzzy Wuzzy	#CC6666	80COLOR	40COLOR	40COLOR	0COLOR	50COLOR	60COLOR	50COLOR	80COLOR";
//    s = [[s componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] componentsJoinedByString:@""];
    NSString *tempString;
    NSMutableArray *props = [[NSMutableArray alloc] initWithCapacity:1000];
    while ([s rangeOfString:@"\n"].location != NSNotFound && [[s substringFromIndex:[s rangeOfString:@"\n"].location] rangeOfString:@"#"].location != NSNotFound) {
        long titlePosition = [s rangeOfString:@"\n"].location + 1;
        long colorEnd = s.length - titlePosition - 1;
        tempString = [s substringWithRange:NSMakeRange(titlePosition, colorEnd)];
        NNColorObject *color = [NNColorObject new];
        
        if ([tempString rangeOfString:@"#"].location != NSNotFound) {
            tempString = [[tempString substringFromIndex:1] substringToIndex:[tempString rangeOfString:@"#"].location];
//            [self removeString:@" " fromString:tempString];
            while (![[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember:[tempString characterAtIndex:0]]) {
                tempString = [tempString substringFromIndex:1];
            }
            
            long titleEnd = [[tempString substringFromIndex:1] rangeOfString:@"#" options:NSBackwardsSearch].location;

            tempString = [tempString substringToIndex:titleEnd];
            
            tempString = [[tempString componentsSeparatedByCharactersInSet:[NSCharacterSet punctuationCharacterSet]] componentsJoinedByString:@""];
            [color setName:tempString];
            
            NSString *ts = [s substringWithRange:NSMakeRange(titlePosition, colorEnd)];
            if ([ts rangeOfString:@"\n"].location != NSNotFound) {
                ts = [s substringWithRange:NSMakeRange([ts rangeOfString:@"#"].location, [ts rangeOfString:@"\n"].location)];
            }
            
            color.hexValue = [[s substringWithRange:NSMakeRange(titlePosition, colorEnd)] substringWithRange:NSMakeRange([[s substringWithRange:NSMakeRange(titlePosition, colorEnd)] rangeOfString:@"#"].location + 1, 6)];
            
            [color updateHex];
        }
        
        else {
            NSLog(@"%@", tempString);
        }
        
        s = [s substringFromIndex:titlePosition];
        
        [props addObject:color];
    }
    
    NSMutableString *ps = [NSMutableString new];
    
    for (NNColorObject *color in props) {
        [ps appendFormat:@"\n#%@ \t%d \t%d \t%d \t%d \t%d \t%d", color.hexValue, (int) (color.red*255), (int) (color.blue*255), (int) (color.green*255), (int) (color.hue*360), (int) (color.saturation*255), (int) (color.brightness*255)];
    }
    
    NSLog(@"%@",ps);
    
    return r;
}

- (void)removeString:(NSString *)takeAway fromString:(NSString *)s {
    while ([s rangeOfString:takeAway].location != NSNotFound) {
        s = [NSString stringWithFormat:@"%@%@",[s substringToIndex:[s rangeOfString:takeAway].location], [s substringFromIndex:[s rangeOfString:takeAway].location + takeAway.length]];
    }
}

/**
 *  Inserts text at the current caret position of the textview.
 *
 *  @param text     Text to be inserted at the current caret position.
 *  @param textView UITextView to have text inserted into.
 */
- (void)pasteText:(NSString *)text inTextView:(UITextView *)textView {
    // Incompatible with voice over
    UIPasteboard* lPasteBoard = [UIPasteboard generalPasteboard];
    NSArray* lPasteBoardItems = [lPasteBoard.items copy];
    [lPasteBoard setString:text];
    [textView paste:self];
    lPasteBoard.items = lPasteBoardItems;
}

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

#pragma mark - Motion Detection

- (void)startMotionDetect {
    [self.motionManager
     startAccelerometerUpdatesToQueue:[[NSOperationQueue alloc] init]
     withHandler:^(CMAccelerometerData *data, NSError *error)
     {
         dispatch_async(dispatch_get_main_queue(),
                        ^{
                            int x = abs(self.motionManager.accelerometerData.acceleration.x);
                            int y = abs(self.motionManager.accelerometerData.acceleration.y);
                            int z = abs(self.motionManager.accelerometerData.acceleration.z);
                            
                            if (ONE_SHAKE) {
                                if (x + y + z > KNOCK_ACCELERATION && _textView.text.length > 0) {
                                    [self resetView];
                                    [self animateLabel:_resetLabelWarning];
                                    _isClearing = YES;
                                }
                                
                                else if (x + y + z > KNOCK_ACCELERATION && _isUpdated && !_isClearing) {
                                    if (_isDaylight) {
                                        _isDaylight = NO;
                                        [self animateLabel:_nightModeLabel];
                                    }
                                    
                                    else {
                                        _isDaylight = YES;
                                        [self animateLabel:_dayModeLabel];
                                    }
                                    _isUpdated = NO;
                                }
                                
                                else if (x + y + z < 0.3 && !_isUpdated) {
                                    [self resetView];
                                }
                                
                                else if (x + y + z < 0.3 && _isClearing) {
                                    _isClearing = NO;
                                }
                            }
                            
                            else {
                                if (x + y + z > KNOCK_ACCELERATION) {
                                    // Isolate Instantaneous Motion from Acceleration Data
                                    // (using a simplified high-pass filter)
                                    CMAcceleration acceleration = data.acceleration;
                                    float prevAccelX = prevX;
                                    float prevAccelY = prevY;
                                    float prevAccelZ = prevZ;
                                    prevX = acceleration.x - ( (acceleration.x * kFilteringFactor) +
                                                              (prevX * (1.0 - kFilteringFactor)) );
                                    prevY = acceleration.y - ( (acceleration.y * kFilteringFactor) +
                                                              (prevY * (1.0 - kFilteringFactor)) );
                                    prevZ = acceleration.z - ( (acceleration.z * kFilteringFactor) +
                                                              (prevZ * (1.0 - kFilteringFactor)) );
                                    
                                    // Compute the derivative (which represents change in acceleration).
                                    float deltaX = ABS((prevX - prevAccelX));
                                    float deltaY = ABS((prevY - prevAccelY));
                                    float deltaZ = ABS((prevZ - prevAccelZ));
                                    
                                    // Check if the derivative exceeds some sensitivity threshold
                                    // (Bigger value indicates stronger bump)
                                    // (Probably should use length of the vector instead of componentwise)
                                    if ((deltaX > 1 || deltaY > 1 || deltaZ > 1)) {
                                        _bumpNet = YES;
                                    }
                                    
                                    else {
                                        _bumpNet = NO;
                                    }
                                    
                                    if (!_bumpB && !_bumpC && !_bumpD && _bumpNet) {
                                        _bumpA = YES;
                                    }
                                    
                                    else if (_bumpA && !_bumpC && !_bumpD && !_bumpNet) {
                                        _bumpB = YES;
                                    }
                                    
                                    else if (_bumpA && _bumpB && !_bumpD && _bumpNet) {
                                        _bumpC = YES;
                                        if (abs([_lastDoubleBump timeIntervalSinceNow]) > 1.5) {
                                            _bumpA = NO;
                                            _bumpB = NO;
                                            _bumpC = NO;
                                            _bumpD = NO;
                                            _lastDoubleBump = [NSDate date];
                                        }
                                    }
                                    
                                    else if (_bumpA && _bumpB && _bumpC && !_bumpNet) {
                                        _bumpD = YES;
                                    }
                                    
                                    if (_bumpA && _bumpB && _bumpC && _bumpD) {
                                        if (abs([_lastDoubleBump timeIntervalSinceNow]) > 0.5) {
                                            _bumpA = NO;
                                            _bumpB = NO;
                                            _bumpC = NO;
                                            _bumpD = NO;
                                            _lastDoubleBump = [NSDate date];
                                            
                                            if (_textView.text.length == 0) {
                                                if (_isDaylight) {
                                                    _isDaylight = NO;
                                                    [self animateLabel:_nightModeLabel];
                                                }
                                                
                                                else {
                                                    _isDaylight = YES;
                                                    [self animateLabel:_dayModeLabel];
                                                }
                                            }
                                            
                                            [self resetView];
                                        }
                                    }
                                }
                            }
                            
                            
                        });
     }];
}

- (CMMotionManager *)motionManager {
    CMMotionManager *motionManager = nil;
    
    id appDelegate = [UIApplication sharedApplication].delegate;
    
    if ([appDelegate respondsToSelector:@selector(motionManager)]) {
        motionManager = [appDelegate motionManager];
    }
    
    return motionManager;
}

#pragma mark - Is it daylight

- (BOOL)isDaylight {
    NSString *ds1 = @"07:00:00";
    NSString *ds2 = @"21:00:00";
    
    // parse given dates into NSDate objects
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"HH:mm:ss"];
    NSDate *date1 = [df dateFromString:ds1];
    NSDate *date2 = [df dateFromString:ds2];
    
    // get time interval from earlier to later given date
    NSDate *earlierDate = date1;
    NSTimeInterval ti = [date2 timeIntervalSinceDate:date1];
    
    if (ti < 0) {
        earlierDate = date2;
        ti = [date1 timeIntervalSinceDate:date2];
    }
    
    // get current date/time
    NSDate *now = [NSDate date];

    // create an NSDate for today at the earlier given time
    NSDateComponents *todayDateComps = [[NSCalendar currentCalendar]
                                        components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay
                                        fromDate:now];
    NSDateComponents *earlierTimeComps = [[NSCalendar currentCalendar]
                                          components:NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond
                                          fromDate:earlierDate];
    NSDateComponents *todayEarlierTimeComps = [[NSDateComponents alloc] init];
    [todayEarlierTimeComps setYear:[todayDateComps year]];
    [todayEarlierTimeComps setMonth:[todayDateComps month]];
    [todayEarlierTimeComps setDay:[todayDateComps day]];
    [todayEarlierTimeComps setHour:[earlierTimeComps hour]];
    [todayEarlierTimeComps setMinute:[earlierTimeComps minute]];
    [todayEarlierTimeComps setSecond:[earlierTimeComps second]];
    NSDate *todayEarlierTime = [[NSCalendar currentCalendar]
                                dateFromComponents:todayEarlierTimeComps];
    
    // create an NSDate for yesterday at the earlier given time
    NSDateComponents *minusOneDayComps = [[NSDateComponents alloc] init];
    [minusOneDayComps setDay:-1];
    NSDate *yesterday = [[NSCalendar currentCalendar]
                         dateByAddingComponents:minusOneDayComps
                         toDate:now
                         options:0];
    NSDateComponents *yesterdayDateComps = [[NSCalendar currentCalendar]
                                            components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay
                                            fromDate:yesterday];
    NSDateComponents *yesterdayEarlierTimeComps = [[NSDateComponents alloc] init];
    [yesterdayEarlierTimeComps setYear:[yesterdayDateComps year]];
    [yesterdayEarlierTimeComps setMonth:[yesterdayDateComps month]];
    [yesterdayEarlierTimeComps setDay:[yesterdayDateComps day]];
    [yesterdayEarlierTimeComps setHour:[earlierTimeComps hour]];
    [yesterdayEarlierTimeComps setMinute:[earlierTimeComps minute]];
    [yesterdayEarlierTimeComps setSecond:[earlierTimeComps second]];
    NSDate *yesterdayEarlierTime = [[NSCalendar currentCalendar]
                                    dateFromComponents:yesterdayEarlierTimeComps];
    
    // check time interval from [today at the earlier given time] to [now]
    NSTimeInterval ti_todayEarlierTimeTillNow = [now timeIntervalSinceDate:todayEarlierTime];
    
    if (0 <= ti_todayEarlierTimeTillNow && ti_todayEarlierTimeTillNow <= ti) {
        return YES;
    }
    
    // check time interval from [yesterday at the earlier given time] to [now]
    NSTimeInterval ti_yesterdayEarlierTimeTillNow = [now timeIntervalSinceDate:yesterdayEarlierTime];
    
    if (0 <= ti_yesterdayEarlierTimeTillNow && ti_yesterdayEarlierTimeTillNow <= ti) {
        return YES;
    }
    
    return NO;
}
/**
 *  AM and PM are expressed as a and p
 *  Times on the hour do not have minutes
 *  Minutes are rounded to the nearest fifteen minutes
 *
 *  @param date Date with all parameters set
 *
 *  @return Time formatted
 */
- (NSString *)timeStringFromDate:(NSDate *)date withRounding:(BOOL)rounding {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"mm"];
    
    NSString *alarmTimeString, *ampm;
    
    int unRoundedMinutes = [[dateFormatter stringFromDate:date] intValue];
    if (rounding) {
        unRoundedMinutes = (unRoundedMinutes + 7.5)/15;
        unRoundedMinutes *= 15;
        unRoundedMinutes %= 60;
    }
    
    alarmTimeString = [dateFormatter stringFromDate:date];
    if (unRoundedMinutes == 0) {
        [dateFormatter setDateFormat:@"h"];
        alarmTimeString = [dateFormatter stringFromDate:date];
    } else {
        [dateFormatter setDateFormat:@"h"];
        alarmTimeString = [NSString stringWithFormat:@"%@:%i",[dateFormatter stringFromDate:date],unRoundedMinutes];
    }
    
    [dateFormatter setDateFormat:@"a"];
    if ([[dateFormatter stringFromDate:date] isEqualToString:@"AM"]) {
        ampm = @"a";
    } else {
        ampm = @"p";
    }
    
    alarmTimeString = [NSString stringWithFormat:@"%@%@",alarmTimeString,ampm];
    
    return alarmTimeString;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated. If I have to.
    NSLog(@"Memory Warning");
}


@end
