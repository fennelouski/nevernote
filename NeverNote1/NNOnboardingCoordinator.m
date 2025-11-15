//
//  NNOnboardingCoordinator.m
//  NeverNote
//
//  Coordinates the onboarding flow by showing tooltips one at a time.
//

#import "NNOnboardingCoordinator.h"
#import "NNOnboardingManager.h"
#import "NNOnboardingTooltipView.h"

@interface NNOnboardingCoordinator () <NNOnboardingTooltipViewDelegate>

@property (nonatomic, strong, nullable) NNOnboardingTooltipView *currentTooltipView;
@property (nonatomic, assign) BOOL isShowingTooltip;

@end

@implementation NNOnboardingCoordinator

#pragma mark - Singleton

+ (instancetype)sharedCoordinator {
    static NNOnboardingCoordinator *sharedCoordinator = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedCoordinator = [[self alloc] init];
    });
    return sharedCoordinator;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _isShowingTooltip = NO;
        [self setupNotificationObservers];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Setup

- (void)setupNotificationObservers {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

    [center addObserver:self
               selector:@selector(onboardingDidStart:)
                   name:NNOnboardingDidStartNotification
                 object:nil];

    [center addObserver:self
               selector:@selector(onboardingStepDidChange:)
                   name:NNOnboardingStepDidChangeNotification
                 object:nil];

    [center addObserver:self
               selector:@selector(onboardingDidComplete:)
                   name:NNOnboardingDidCompleteNotification
                 object:nil];
}

#pragma mark - Public Methods

- (void)checkAndStartOnboarding {
    NNOnboardingManager *manager = [NNOnboardingManager sharedManager];

    if (manager.shouldShowOnboarding && !manager.isOnboardingActive) {
        // Delay slightly to ensure UI is ready
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self startOnboarding];
        });
    }
}

- (void)startOnboarding {
    NNOnboardingManager *manager = [NNOnboardingManager sharedManager];

    if (manager.isOnboardingActive) {
        return; // Already active
    }

    [manager startOnboarding];
    // The notification will trigger showing the first step
}

- (void)stopOnboarding {
    [self dismissCurrentTooltip];
    [[NNOnboardingManager sharedManager] completeOnboarding];
}

#pragma mark - Notification Handlers

- (void)onboardingDidStart:(NSNotification *)notification {
    [self showCurrentStep];
}

- (void)onboardingStepDidChange:(NSNotification *)notification {
    // Dismiss current tooltip and show next step
    [self dismissCurrentTooltip];

    // Show next step after a brief delay
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self showCurrentStep];
    });
}

- (void)onboardingDidComplete:(NSNotification *)notification {
    [self dismissCurrentTooltip];
}

#pragma mark - Tooltip Management

- (void)showCurrentStep {
    if (self.isShowingTooltip) {
        return; // Already showing a tooltip
    }

    NNOnboardingManager *manager = [NNOnboardingManager sharedManager];

    if (!manager.isOnboardingActive) {
        return;
    }

    NNOnboardingStep currentStep = manager.currentStep;

    NSString *title = [manager titleForStep:currentStep];
    NSString *description = [manager descriptionForStep:currentStep];

    NNOnboardingTooltipView *tooltipView = [[NNOnboardingTooltipView alloc] initWithTitle:title
                                                                                description:description];
    tooltipView.delegate = self;

    // Configure tooltip based on step
    [self configureTooltipView:tooltipView forStep:currentStep];

    self.currentTooltipView = tooltipView;
    self.isShowingTooltip = YES;

    [tooltipView show];
}

- (void)configureTooltipView:(NNOnboardingTooltipView *)tooltipView forStep:(NNOnboardingStep)step {
    switch (step) {
        case NNOnboardingStepWelcome:
            tooltipView.showsSpotlight = NO;
            tooltipView.showsSkipButton = YES;
            break;

        case NNOnboardingStepTextEditing:
            tooltipView.showsSpotlight = NO;
            tooltipView.showsSkipButton = YES;
            break;

        case NNOnboardingStepGestures:
            tooltipView.showsSpotlight = NO;
            tooltipView.showsSkipButton = YES;
            break;

        case NNOnboardingStepSettings:
            tooltipView.showsSpotlight = NO;
            tooltipView.showsSkipButton = YES;
            break;

        case NNOnboardingStepTaskCreation:
            tooltipView.showsSpotlight = NO;
            tooltipView.showsSkipButton = YES;
            break;

        case NNOnboardingStepCompleted:
            tooltipView.showsSpotlight = NO;
            tooltipView.showsSkipButton = NO;
            [tooltipView.nextButton setTitle:@"Get Started" forState:UIControlStateNormal];
            break;

        default:
            break;
    }
}

- (void)dismissCurrentTooltip {
    if (!self.currentTooltipView) {
        return;
    }

    __weak typeof(self) weakSelf = self;
    [self.currentTooltipView dismissWithCompletion:^{
        weakSelf.currentTooltipView = nil;
        weakSelf.isShowingTooltip = NO;
    }];
}

#pragma mark - NNOnboardingTooltipViewDelegate

- (void)onboardingTooltipViewDidTapNext:(NNOnboardingTooltipView *)tooltipView {
    [[NNOnboardingManager sharedManager] nextStep];
}

- (void)onboardingTooltipViewDidTapSkip:(NNOnboardingTooltipView *)tooltipView {
    [self stopOnboarding];
}

@end
