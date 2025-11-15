//
//  NNSettingsViewController.m
//  NeverNote
//
//  Settings view controller
//

#import "NNSettingsViewController.h"
#import "NNSettingsManager.h"
#import "UIColor+AppColors.h"

typedef NS_ENUM(NSInteger, NNSettingsSection) {
    NNSettingsSectionAppearance = 0,
    NNSettingsSectionBehavior,
    NNSettingsSectionKeyboard,
    NNSettingsSectionAdvanced,
    NNSettingsSectionAbout,
    NNSettingsSectionCount
};

@interface NNSettingsViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UINavigationBar *navigationBar;
@property (nonatomic, strong) NNSettingsManager *settingsManager;
@property (nonatomic, strong) NSArray<NSString *> *availableFonts;
@property (nonatomic, strong) UIImpactFeedbackGenerator *feedbackGenerator API_AVAILABLE(ios(10.0));

@end

@implementation NNSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.settingsManager = [NNSettingsManager sharedManager];
    self.availableFonts = [self getAvailableFonts];

    if (@available(iOS 10.0, *)) {
        self.feedbackGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
        [self.feedbackGenerator prepare];
    }

    [self setupUI];
}

- (void)setupUI {
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    // Navigation Bar
    self.navigationBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 88)];
    [self.navigationBar setTranslucent:YES];
    if (@available(iOS 13.0, *)) {
        UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
        [appearance configureWithDefaultBackground];
        self.navigationBar.standardAppearance = appearance;
        self.navigationBar.scrollEdgeAppearance = appearance;
    }

    UINavigationItem *navItem = [[UINavigationItem alloc] initWithTitle:@"Settings"];
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonTapped)];
    navItem.rightBarButtonItem = doneButton;
    [self.navigationBar setItems:@[navItem]];

    [self.view addSubview:self.navigationBar];

    // Table View
    CGFloat navBarHeight = 88;
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, navBarHeight, self.view.bounds.size.width, self.view.bounds.size.height - navBarHeight) style:UITableViewStyleInsetGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor systemBackgroundColor];

    [self.view addSubview:self.tableView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

#pragma mark - Actions

- (void)doneButtonTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)provideFeedback {
    if (@available(iOS 10.0, *)) {
        if (self.settingsManager.hapticFeedbackEnabled) {
            [self.feedbackGenerator impactOccurred];
        }
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return NNSettingsSectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case NNSettingsSectionAppearance:
            return 3; // Theme, Font Name, Font Size
        case NNSettingsSectionBehavior:
            return 4; // Tap to Copy, Clear on Launch, Motion Detection, Auto Save
        case NNSettingsSectionKeyboard:
            return 1; // Show Toolbar
        case NNSettingsSectionAdvanced:
            return 2; // Haptic Feedback, Reset to Defaults
        case NNSettingsSectionAbout:
            return 2; // Version, App Info
        default:
            return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case NNSettingsSectionAppearance:
            return @"Appearance";
        case NNSettingsSectionBehavior:
            return @"Behavior";
        case NNSettingsSectionKeyboard:
            return @"Keyboard";
        case NNSettingsSectionAdvanced:
            return @"Advanced";
        case NNSettingsSectionAbout:
            return @"About";
        default:
            return nil;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    switch (section) {
        case NNSettingsSectionAppearance:
            return @"Customize the look and feel of NeverNote";
        case NNSettingsSectionBehavior:
            return @"Control how NeverNote behaves";
        case NNSettingsSectionKeyboard:
            return @"Keyboard customization options";
        case NNSettingsSectionAdvanced:
            return @"Advanced settings and options";
        default:
            return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"SettingsCell";
    static NSString *switchCellIdentifier = @"SwitchCell";

    UITableViewCell *cell;

    switch (indexPath.section) {
        case NNSettingsSectionAppearance:
            cell = [self appearanceCellForRowAtIndexPath:indexPath tableView:tableView];
            break;
        case NNSettingsSectionBehavior:
            cell = [tableView dequeueReusableCellWithIdentifier:switchCellIdentifier];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:switchCellIdentifier];
            }
            [self configureBehaviorCell:cell forRowAtIndexPath:indexPath];
            break;
        case NNSettingsSectionKeyboard:
            cell = [tableView dequeueReusableCellWithIdentifier:switchCellIdentifier];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:switchCellIdentifier];
            }
            [self configureKeyboardCell:cell forRowAtIndexPath:indexPath];
            break;
        case NNSettingsSectionAdvanced:
            cell = [self advancedCellForRowAtIndexPath:indexPath tableView:tableView];
            break;
        case NNSettingsSectionAbout:
            cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
            }
            [self configureAboutCell:cell forRowAtIndexPath:indexPath];
            break;
        default:
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
            break;
    }

    return cell;
}

#pragma mark - Cell Configuration

- (UITableViewCell *)appearanceCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
    static NSString *cellIdentifier = @"AppearanceCell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
    }

    // Remove any existing accessory views
    cell.accessoryView = nil;

    switch (indexPath.row) {
        case 0: // Theme
            cell.textLabel.text = @"Theme";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            switch (self.settingsManager.themeMode) {
                case NNThemeModeSystem:
                    cell.detailTextLabel.text = @"System";
                    break;
                case NNThemeModeLight:
                    cell.detailTextLabel.text = @"Light";
                    break;
                case NNThemeModeDark:
                    cell.detailTextLabel.text = @"Dark";
                    break;
            }
            break;

        case 1: // Font Name
            cell.textLabel.text = @"Font";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.detailTextLabel.text = self.settingsManager.fontName;
            break;

        case 2: { // Font Size
            cell.textLabel.text = @"Font Size";
            cell.selectionStyle = UITableViewCellSelectionStyleNone;

            UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(0, 0, 150, 30)];
            slider.minimumValue = 12.0f;
            slider.maximumValue = 32.0f;
            slider.value = self.settingsManager.fontSize;
            slider.continuous = YES;
            [slider addTarget:self action:@selector(fontSizeSliderChanged:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = slider;

            cell.detailTextLabel.text = [NSString stringWithFormat:@"%.0f", self.settingsManager.fontSize];
            break;
        }
    }

    return cell;
}

- (void)configureBehaviorCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    UISwitch *switchControl = [[UISwitch alloc] init];
    [switchControl addTarget:self action:@selector(switchValueChanged:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = switchControl;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = @"Tap to Copy";
            switchControl.on = self.settingsManager.tapToCopyEnabled;
            switchControl.tag = 100;
            break;
        case 1:
            cell.textLabel.text = @"Clear on Launch";
            switchControl.on = self.settingsManager.clearOnLaunchEnabled;
            switchControl.tag = 101;
            break;
        case 2:
            cell.textLabel.text = @"Motion Detection";
            switchControl.on = self.settingsManager.motionDetectionEnabled;
            switchControl.tag = 102;
            break;
        case 3:
            cell.textLabel.text = @"Auto Save";
            switchControl.on = self.settingsManager.autoSaveEnabled;
            switchControl.tag = 103;
            break;
    }
}

- (void)configureKeyboardCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    UISwitch *switchControl = [[UISwitch alloc] init];
    [switchControl addTarget:self action:@selector(switchValueChanged:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = switchControl;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    if (indexPath.row == 0) {
        cell.textLabel.text = @"Show Keyboard Toolbar";
        switchControl.on = self.settingsManager.showKeyboardToolbar;
        switchControl.tag = 200;
    }
}

- (UITableViewCell *)advancedCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
    if (indexPath.row == 0) {
        // Haptic Feedback Switch
        static NSString *cellIdentifier = @"SwitchCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        }

        cell.textLabel.text = @"Haptic Feedback";
        UISwitch *switchControl = [[UISwitch alloc] init];
        [switchControl addTarget:self action:@selector(switchValueChanged:) forControlEvents:UIControlEventValueChanged];
        switchControl.on = self.settingsManager.hapticFeedbackEnabled;
        switchControl.tag = 300;
        cell.accessoryView = switchControl;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

        return cell;
    } else {
        // Reset to Defaults Button
        static NSString *cellIdentifier = @"ButtonCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        }

        cell.textLabel.text = @"Reset to Defaults";
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.textColor = [UIColor systemRedColor];
        cell.accessoryView = nil;

        return cell;
    }
}

- (void)configureAboutCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryView = nil;

    if (indexPath.row == 0) {
        cell.textLabel.text = @"Version";
        NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        NSString *build = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ (%@)", version ?: @"1.0", build ?: @"1"];
    } else {
        cell.textLabel.text = @"NeverNote";
        cell.detailTextLabel.text = @"Simple Note Taking";
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == NNSettingsSectionAppearance) {
        if (indexPath.row == 0) {
            // Theme selection
            [self showThemeSelector];
        } else if (indexPath.row == 1) {
            // Font selection
            [self showFontSelector];
        }
    } else if (indexPath.section == NNSettingsSectionAdvanced && indexPath.row == 1) {
        // Reset to Defaults
        [self showResetConfirmation];
    }
}

#pragma mark - Switch Actions

- (void)switchValueChanged:(UISwitch *)sender {
    [self provideFeedback];

    switch (sender.tag) {
        case 100: // Tap to Copy
            self.settingsManager.tapToCopyEnabled = sender.on;
            break;
        case 101: // Clear on Launch
            self.settingsManager.clearOnLaunchEnabled = sender.on;
            break;
        case 102: // Motion Detection
            self.settingsManager.motionDetectionEnabled = sender.on;
            break;
        case 103: // Auto Save
            self.settingsManager.autoSaveEnabled = sender.on;
            break;
        case 200: // Show Keyboard Toolbar
            self.settingsManager.showKeyboardToolbar = sender.on;
            break;
        case 300: // Haptic Feedback
            self.settingsManager.hapticFeedbackEnabled = sender.on;
            break;
    }
}

- (void)fontSizeSliderChanged:(UISlider *)slider {
    self.settingsManager.fontSize = slider.value;

    // Update the detail text label
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:2 inSection:NNSettingsSectionAppearance];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%.0f", slider.value];
}

#pragma mark - Selectors

- (void)showThemeSelector {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Select Theme"
                                                                   message:@"Choose your preferred theme"
                                                            preferredStyle:UIAlertControllerStyleActionSheet];

    [alert addAction:[UIAlertAction actionWithTitle:@"System"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
        self.settingsManager.themeMode = NNThemeModeSystem;
        [self.tableView reloadData];
        [self provideFeedback];
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:@"Light"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
        self.settingsManager.themeMode = NNThemeModeLight;
        [self.tableView reloadData];
        [self provideFeedback];
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:@"Dark"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
        self.settingsManager.themeMode = NNThemeModeDark;
        [self.tableView reloadData];
        [self provideFeedback];
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];

    // For iPad support
    if (alert.popoverPresentationController) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:NNSettingsSectionAppearance];
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        alert.popoverPresentationController.sourceView = cell;
        alert.popoverPresentationController.sourceRect = cell.bounds;
    }

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showFontSelector {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Select Font"
                                                                   message:@"Choose your preferred font"
                                                            preferredStyle:UIAlertControllerStyleActionSheet];

    for (NSString *fontName in self.availableFonts) {
        [alert addAction:[UIAlertAction actionWithTitle:fontName
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * _Nonnull action) {
            self.settingsManager.fontName = fontName;
            [self.tableView reloadData];
            [self provideFeedback];
        }]];
    }

    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];

    // For iPad support
    if (alert.popoverPresentationController) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:1 inSection:NNSettingsSectionAppearance];
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        alert.popoverPresentationController.sourceView = cell;
        alert.popoverPresentationController.sourceRect = cell.bounds;
    }

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showResetConfirmation {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Reset to Defaults"
                                                                   message:@"Are you sure you want to reset all settings to their default values?"
                                                            preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:@"Reset"
                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction * _Nonnull action) {
        [self.settingsManager resetToDefaults];
        [self.tableView reloadData];
        [self provideFeedback];

        UIAlertController *successAlert = [UIAlertController alertControllerWithTitle:@"Reset Complete"
                                                                               message:@"All settings have been reset to defaults"
                                                                        preferredStyle:UIAlertControllerStyleAlert];
        [successAlert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:successAlert animated:YES completion:nil];
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];

    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Helper Methods

- (NSArray<NSString *> *)getAvailableFonts {
    return @[
        @"System Bold",
        @"Helvetica",
        @"Helvetica Neue",
        @"Courier",
        @"Courier New",
        @"Georgia",
        @"Palatino",
        @"Times New Roman",
        @"Trebuchet MS",
        @"Verdana",
        @"American Typewriter",
        @"Avenir",
        @"Baskerville",
        @"Cochin",
        @"Copperplate",
        @"Futura",
        @"Gill Sans",
        @"Marker Felt",
        @"Menlo",
        @"Noteworthy",
        @"Optima",
        @"Papyrus",
        @"Snell Roundhand"
    ];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    if (@available(iOS 13.0, *)) {
        return UIStatusBarStyleDefault;
    } else {
        return UIStatusBarStyleDefault;
    }
}

@end
