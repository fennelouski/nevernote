# Onboarding System

## Overview

The NeverNote app now includes a comprehensive onboarding system that guides new users and re-engages returning users who haven't used the app in 30+ days.

## Features

- **Smart Triggering**: Onboarding appears for:
  - First-time users
  - Users who haven't used the app in 30 days or more

- **One Tooltip at a Time**: Shows only one tooltip/guide at a time to avoid overwhelming users
- **Step-by-Step Flow**: Guides users through key features in a logical sequence
- **Skip Anytime**: Users can skip the onboarding flow at any point
- **Persistent State**: Remembers progress and completion status using NSUserDefaults

## Architecture

The onboarding system consists of three main components:

### 1. NNOnboardingManager
**Location**: `NeverNote1/NNOnboardingManager.{h,m}`

Singleton manager that tracks onboarding state:
- Determines if onboarding should be shown
- Manages current step progression
- Persists state to NSUserDefaults
- Posts notifications for state changes

**Key Methods**:
- `shouldShowOnboarding` - Returns YES if onboarding should be triggered
- `startOnboarding` - Initiates the onboarding flow
- `nextStep` - Advances to the next step
- `completeOnboarding` - Marks onboarding as finished
- `updateLastAppUseDate` - Records app usage (called on app activation)

**NSUserDefaults Keys**:
- `com.nevernote.onboardingCompleted` - Whether onboarding is complete
- `com.nevernote.lastAppUseDate` - Last time the app was used
- `com.nevernote.currentOnboardingStep` - Current step in the flow

### 2. NNOnboardingTooltipView
**Location**: `NeverNote1/NNOnboardingTooltipView.{h,m}`

Reusable tooltip UI component that displays onboarding guidance:
- Semi-transparent overlay
- Animated content card with title and description
- Optional spotlight effect to highlight target areas
- "Next" and "Skip" buttons

**Features**:
- Spring animation on presentation
- Automatic positioning (avoids covering target areas)
- Customizable spotlight with rounded corners
- Delegate pattern for handling user interactions

### 3. NNOnboardingCoordinator
**Location**: `NeverNote1/NNOnboardingCoordinator.{h,m}`

Orchestrates the onboarding flow:
- Listens to NNOnboardingManager notifications
- Presents appropriate tooltips for each step
- Ensures only one tooltip is shown at a time
- Manages transitions between steps

**Key Methods**:
- `checkAndStartOnboarding` - Checks conditions and starts if needed
- `startOnboarding` - Manually initiates onboarding
- `stopOnboarding` - Ends the current onboarding session

## Onboarding Steps

1. **Welcome** - Introduction to NeverNote
2. **Text Editing** - Quick note-taking features
3. **Gestures** - Swipe and pinch gestures
4. **Settings** - Customization options (two-finger double-tap)
5. **Task Creation** - Creating tasks with due dates
6. **Completed** - Final message with shake-to-toggle tip

## Integration

The onboarding system is integrated with the app lifecycle in `NNAppDelegate.m`:

```objc
- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Update last app use date
    [[NNOnboardingManager sharedManager] updateLastAppUseDate];

    // Check if onboarding should be shown
    [[NNOnboardingCoordinator sharedCoordinator] checkAndStartOnboarding];
}
```

## Testing

To test the onboarding flow:

1. **First Launch**: Onboarding appears automatically on first app launch
2. **Reset for Testing**: Use `[[NNOnboardingManager sharedManager] resetOnboarding]` to clear state
3. **30-Day Trigger**: Change the device date to 31+ days in the future to test re-engagement

## Customization

### Adding New Steps

To add new onboarding steps:

1. Add a new case to `NNOnboardingStep` enum in `NNOnboardingManager.h`
2. Implement `titleForStep:` and `descriptionForStep:` in `NNOnboardingManager.m`
3. Configure the tooltip appearance in `configureTooltipView:forStep:` in `NNOnboardingCoordinator.m`

### Changing the Inactivity Threshold

Modify `kInactivityThresholdDays` in `NNOnboardingManager.m` (currently set to 30.0 days)

### Customizing Tooltip Appearance

Edit `NNOnboardingTooltipView.m`:
- Colors and fonts in `setupViews`
- Animation parameters in `show` and `dismissWithCompletion:`
- Layout logic in `layoutSubviews`

## Notifications

The system posts the following notifications:

- `NNOnboardingDidStartNotification` - When onboarding begins
- `NNOnboardingStepDidChangeNotification` - When moving to a new step
- `NNOnboardingDidCompleteNotification` - When onboarding finishes

Subscribe to these notifications to trigger custom behavior during onboarding.

## Design Principles

The onboarding system follows these key principles:

1. **Non-Intrusive**: Users can skip at any time
2. **Progressive Disclosure**: One concept at a time
3. **Contextual**: Shows features in relevant contexts
4. **Persistent**: Remembers state across sessions
5. **Re-Engaging**: Helps users who return after a long absence
