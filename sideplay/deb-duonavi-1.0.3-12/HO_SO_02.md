    _iconImageView : @"UIImageView" offset=8 size=8
    _fallbackIconLabel : @"UILabel" offset=16 size=8
    _valueLabel : @"UILabel" offset=24 size=8
  properties:
    iconImageView  attrs=T@"UIImageView",&,N,V_iconImageView
    fallbackIconLabel  attrs=T@"UILabel",&,N,V_fallbackIconLabel
    valueLabel  attrs=T@"UILabel",&,N,V_valueLabel
  instance methods (11):
    - initWithFrame:  types=@48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16
    - layoutSubviews  types=v16@0:8
    - setIconSystemName:fallbackEmoji:  types=v32@0:8@16@24
    - setValue:color:  types=v32@0:8@16@24
    - iconImageView  types=@16@0:8
    - setIconImageView:  types=v24@0:8@16
    - fallbackIconLabel  types=@16@0:8
    - setFallbackIconLabel:  types=v24@0:8@16
    - valueLabel  types=@16@0:8
    - setValueLabel:  types=v24@0:8@16
    - .cxx_destruct  types=v16@0:8

--- @interface CBDockSystemMonitorView : UIView (instanceSize=66, ro_flags=0x194) ---
  ivars:
    _battItem : @"CBDockMetricItemView" offset=8 size=8
    _tempItem : @"CBDockMetricItemView" offset=16 size=8
    _cpuItem : @"CBDockMetricItemView" offset=24 size=8
    _ramItem : @"CBDockMetricItemView" offset=32 size=8
    _refreshTimer : @"NSTimer" offset=40 size=8
    _prevCpuUser : I offset=48 size=4
    _prevCpuSystem : I offset=52 size=4
    _prevCpuNice : I offset=56 size=4
    _prevCpuIdle : I offset=60 size=4
    _hasCpuHistory : B offset=64 size=1
    _showAll : B offset=65 size=1
  properties:
    isMonitoring  attrs=TB,R,N
    showAll  attrs=TB,N,V_showAll
    detailedMode  attrs=TB,N
  instance methods (19):
    - initWithFrame:  types=@48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16
    - dealloc  types=v16@0:8
    - detailedMode  types=B16@0:8
    - setDetailedMode:  types=v20@0:8B16
    - setShowAll:  types=v20@0:8B16
    - willMoveToWindow:  types=v24@0:8@16
    - handleTapGesture:  types=v24@0:8@16
    - layoutSubviews  types=v16@0:8
    - startMonitoring  types=v16@0:8
    - stopMonitoring  types=v16@0:8
    - isMonitoring  types=B16@0:8
    - handleBatteryNotification:  types=v24@0:8@16
    - updateBatteryMetric  types=v16@0:8
    - updateMetrics  types=v16@0:8
    - readDeviceTemperature  types=f16@0:8
    - readCpuUsage  types=f16@0:8
    - readRamUsage:total:  types=f32@0:8^Q16^Q24
    - showAll  types=B16@0:8
    - .cxx_destruct  types=v16@0:8

--- @interface CBSplitSplashScreenView : UIView (instanceSize=112, ro_flags=0x194) ---
  ivars:
    _glowImageView : @"UIImageView" offset=8 size=8
    _horizonLineView : @"UIView" offset=16 size=8
    _horizonGradient : @"CAGradientLayer" offset=24 size=8
    _horizonDashedMask : @"CAShapeLayer" offset=32 size=8
    _logoImageView : @"UIImageView" offset=40 size=8
    _trackView : @"UIView" offset=48 size=8
    _progressView : @"UIView" offset=56 size=8
    _progressGradient : @"CAGradientLayer" offset=64 size=8
    _badgeLabel : @"UILabel" offset=72 size=8
    _isDismissing : B offset=80 size=1
    _hasStartedAnimation : B offset=81 size=1
    _animationStartTime : d offset=88 size=8
    _onWillDismiss : @? offset=96 size=8
    _onDismissed : @? offset=104 size=8
  properties:
    isDismissing  attrs=TB,R,N
    onWillDismiss  attrs=T@?,C,N,V_onWillDismiss
    onDismissed  attrs=T@?,C,N,V_onDismissed
  instance methods (13):
    - initWithFrame:  types=@48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16
    - layoutSubviews  types=v16@0:8
    - startLoadingAnimation  types=v16@0:8
    - handleTap:  types=v24@0:8@16
    - isDismissing  types=B16@0:8
    - dismissAnimated:  types=v20@0:8B16
    - dismissAnimated:completion:  types=v28@0:8B16@?20
    - dealloc  types=v16@0:8
    - onWillDismiss  types=@?16@0:8
    - setOnWillDismiss:  types=v24@0:8@?16
    - onDismissed  types=@?16@0:8
    - setOnDismissed:  types=v24@0:8@?16
    - .cxx_destruct  types=v16@0:8
  class methods (3):
    + logoImage  types=@16@0:8
    + appIconImage  types=@16@0:8
    + radialGlowImageForDiameter:  types=@24@0:8d16

--- @interface CBLicenseShieldIconView : UIView (instanceSize=8, ro_flags=0x90) ---
  instance methods (2):
    - initWithFrame:  types=@48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16
    - drawRect:  types=v48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16

--- @interface CBLicenseWarningModalView : UIView (instanceSize=96, ro_flags=0x194) ---
  ivars:
    _blurBackdrop : @"UIVisualEffectView" offset=8 size=8
    _scrimView : @"UIView" offset=16 size=8
    _cardView : @"UIView" offset=24 size=8
    _shieldIconView : @"CBLicenseShieldIconView" offset=32 size=8
    _titleLabel : @"UILabel" offset=40 size=8
    _bodyLabel : @"UILabel" offset=48 size=8
    _dismissButton : @"UIButton" offset=56 size=8
    _lastTapTimestamp : d offset=64 size=8
    _isDismissing : B offset=72 size=1
    _onDismiss : @? offset=80 size=8
    _modalType : q offset=88 size=8
  properties:
    onDismiss  attrs=T@?,C,N,V_onDismiss
    modalType  attrs=Tq,N,V_modalType
  instance methods (12):
    - initWithFrame:modalType:  types=@56@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16q48
    - setupSubviews  types=v16@0:8
    - setModalType:  types=v24@0:8q16
    - updateContentForType:  types=v24@0:8q16
    - layoutSubviews  types=v16@0:8
    - handleDismissButtonTap:  types=v24@0:8@16
    - showAnimated:  types=v20@0:8B16
    - dismissAnimated:  types=v20@0:8B16
    - onDismiss  types=@?16@0:8
    - setOnDismiss:  types=v24@0:8@?16
    - modalType  types=q16@0:8
    - .cxx_destruct  types=v16@0:8

--- @interface CBBridgedApp : NSObject (instanceSize=32, ro_flags=0x194) ---
  ivars:
    _bundleIdentifier : @"NSString" offset=8 size=8
    _view : @"UIView" offset=16 size=8
    _delegate : @"CBBridgeManager" offset=24 size=8
  properties:
    bundleIdentifier  attrs=T@"NSString",C,N,V_bundleIdentifier
    view  attrs=T@"UIView",&,N,V_view
    delegate  attrs=T@"CBBridgeManager",W,N,V_delegate
  instance methods (12):
    - initWithBundleIdentifier:frame:  types=@56@0:8@16{CGRect={CGPoint=dd}{CGSize=dd}}24
    - start  types=v16@0:8
    - startInParentViewController:  types=v24@0:8@16
    - stop  types=v16@0:8
    - noteUserActivity  types=v16@0:8
    - bundleIdentifier  types=@16@0:8
    - setBundleIdentifier:  types=v24@0:8@16
    - view  types=@16@0:8
    - setView:  types=v24@0:8@16
    - delegate  types=@16@0:8
    - setDelegate:  types=v24@0:8@16
    - .cxx_destruct  types=v16@0:8

--- @interface CBBridgedPortalApp : CBBridgedApp (instanceSize=16, ro_flags=0x194) ---
  ivars:
    _portalView : @"CBBridgedPortalAppView" offset=8 size=8
  properties:
    portalView  attrs=T@"CBBridgedPortalAppView",&,N,V_portalView
  instance methods (6):
    - initWithBundleIdentifier:frame:  types=@56@0:8@16{CGRect={CGPoint=dd}{CGSize=dd}}24
    - start  types=v16@0:8
    - stop  types=v16@0:8
    - portalView  types=@16@0:8
    - setPortalView:  types=v24@0:8@16
    - .cxx_destruct  types=v16@0:8

--- @interface CBUIAppContainerView : UIView (instanceSize=16, ro_flags=0x194) ---
  ivars:
    _uiApp : @"CBBridgedUIApp" offset=8 size=8
  properties:
    uiApp  attrs=T@"CBBridgedUIApp",W,N,V_uiApp
  instance methods (6):
    - layoutSubviews  types=v16@0:8
    - hitTest:withEvent:  types=@40@0:8{CGPoint=dd}16@32
    - touchesBegan:withEvent:  types=v32@0:8@16@24
    - uiApp  types=@16@0:8
    - setUiApp:  types=v24@0:8@16
    - .cxx_destruct  types=v16@0:8

--- @interface CBBridgedUIApp : CBBridgedApp (instanceSize=48, ro_flags=0x194) ---
  ivars:
    _notchIdleTimer : @"NSTimer" offset=8 size=8
    _lastActivityTime : d offset=16 size=8
    _appView : @"CBBridgedUIAppView" offset=24 size=8
    _notchPill : @"CBSlotPillView" offset=32 size=8
    _customScale : d offset=40 size=8
  properties:
    appView  attrs=T@"CBBridgedUIAppView",&,N,V_appView
    notchPill  attrs=T@"CBSlotPillView",&,N,V_notchPill
    customScale  attrs=Td,N,V_customScale
  instance methods (16):
    - initWithBundleIdentifier:frame:  types=@56@0:8@16{CGRect={CGPoint=dd}{CGSize=dd}}24
    - renderSize  types={CGSize=dd}16@0:8
    - layoutSubviews  types=v16@0:8
    - noteUserActivity  types=v16@0:8
    - showNotchPillSession  types=v16@0:8
    - hideNotchPill  types=v16@0:8
    - start  types=v16@0:8
    - startInParentViewController:  types=v24@0:8@16
    - stop  types=v16@0:8
    - appView  types=@16@0:8
    - setAppView:  types=v24@0:8@16
    - notchPill  types=@16@0:8
    - setNotchPill:  types=v24@0:8@16
    - customScale  types=d16@0:8
    - setCustomScale:  types=v24@0:8d16
    - .cxx_destruct  types=v16@0:8

--- @interface CBDividerButtonInfo : NSObject (instanceSize=40, ro_flags=0x194) ---
  ivars:
    _iconName : @"NSString" offset=8 size=8
    _relativePos : d offset=16 size=8
    _onSwap : @? offset=24 size=8
    _onRotate : @? offset=32 size=8
  properties:
    iconName  attrs=T@"NSString",C,N,V_iconName
    relativePos  attrs=Td,N,V_relativePos
    onSwap  attrs=T@?,C,N,V_onSwap
    onRotate  attrs=T@?,C,N,V_onRotate
  instance methods (9):
    - iconName  types=@16@0:8
    - setIconName:  types=v24@0:8@16
    - relativePos  types=d16@0:8
    - setRelativePos:  types=v24@0:8d16
    - onSwap  types=@?16@0:8
    - setOnSwap:  types=v24@0:8@?16
    - onRotate  types=@?16@0:8
    - setOnRotate:  types=v24@0:8@?16
    - .cxx_destruct  types=v16@0:8

--- @interface CBDividerView : UIView (instanceSize=48, ro_flags=0x194) ---
  ivars:
    _isVertical : B offset=8 size=1
    _isBlinking : B offset=9 size=1
    _moveButtons : @"NSMutableArray" offset=16 size=8
    _buttonConfigs : @"NSMutableArray" offset=24 size=8
    _onPanChanged : @? offset=32 size=8
    _onActivity : @? offset=40 size=8
  properties:
    isVertical  attrs=TB,N,V_isVertical
    isBlinking  attrs=TB,N,V_isBlinking
    moveButtons  attrs=T@"NSMutableArray",&,N,V_moveButtons
    buttonConfigs  attrs=T@"NSMutableArray",&,N,V_buttonConfigs
    onPanChanged  attrs=T@?,C,N,V_onPanChanged
    onActivity  attrs=T@?,C,N,V_onActivity
    hash  attrs=TQ,R
    superclass  attrs=T#,R
    description  attrs=T@"NSString",R,C
    debugDescription  attrs=T@"NSString",R,C
  instance methods (27):
    - initWithFrame:isVertical:  types=@52@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16B48
    - gestureRecognizer:shouldRecognizeSimultaneouslyWithGestureRecognizer:  types=B32@0:8@16@24
    - configureWithButtonConfigs:  types=v24@0:8@16
    - layoutSubviews  types=v16@0:8
    - updateGripLayout  types=v16@0:8
    - pointInside:withEvent:  types=B40@0:8{CGPoint=dd}16@32
    - hitTest:withEvent:  types=@40@0:8{CGPoint=dd}16@32
    - moveButtonTouchDown:  types=v24@0:8@16
    - moveButtonTouchUp:  types=v24@0:8@16
    - moveButtonTouchCancelled:  types=v24@0:8@16
    - handleMoveButtonLongPress:  types=v24@0:8@16
    - startBlinking  types=v16@0:8
    - stopBlinking  types=v16@0:8
    - handlePan:  types=v24@0:8@16
    - isVertical  types=B16@0:8
    - setIsVertical:  types=v20@0:8B16
    - isBlinking  types=B16@0:8
    - setIsBlinking:  types=v20@0:8B16
    - moveButtons  types=@16@0:8
    - setMoveButtons:  types=v24@0:8@16
    - buttonConfigs  types=@16@0:8
    - setButtonConfigs:  types=v24@0:8@16
    - onPanChanged  types=@?16@0:8
    - setOnPanChanged:  types=v24@0:8@?16
    - onActivity  types=@?16@0:8
    - setOnActivity:  types=v24@0:8@?16
    - .cxx_destruct  types=v16@0:8

--- @interface CBSplitContainerView : UIView (instanceSize=16, ro_flags=0x194) ---
  ivars:
    _splitApp : @"CBBridgedSplitApp" offset=8 size=8
  properties:
    splitApp  attrs=T@"CBBridgedSplitApp",W,N,V_splitApp
  instance methods (6):
    - layoutSubviews  types=v16@0:8
    - hitTest:withEvent:  types=@40@0:8{CGPoint=dd}16@32
    - touchesBegan:withEvent:  types=v32@0:8@16@24
    - splitApp  types=@16@0:8
    - setSplitApp:  types=v24@0:8@16
    - .cxx_destruct  types=v16@0:8

--- @interface CBSlotPlaceholderView : UIView (instanceSize=48, ro_flags=0x194) ---
  ivars:
    _slotIndex : q offset=8 size=8
    _onTap : @? offset=16 size=8
    _iconView : @"UIImageView" offset=24 size=8
    _titleLabel : @"UILabel" offset=32 size=8
    _tapButton : @"UIButton" offset=40 size=8
  properties:
    slotIndex  attrs=Tq,N,V_slotIndex
    onTap  attrs=T@?,C,N,V_onTap
    iconView  attrs=T@"UIImageView",&,N,V_iconView
    titleLabel  attrs=T@"UILabel",&,N,V_titleLabel
    tapButton  attrs=T@"UIButton",&,N,V_tapButton
  instance methods (16):
    - initWithSlotIndex:  types=@24@0:8q16
    - dealloc  types=v16@0:8
    - updateLocalizedTexts  types=v16@0:8
    - layoutSubviews  types=v16@0:8
    - placeholderTapped:  types=v24@0:8@16
    - slotIndex  types=q16@0:8
    - setSlotIndex:  types=v24@0:8q16
    - onTap  types=@?16@0:8
    - setOnTap:  types=v24@0:8@?16
    - iconView  types=@16@0:8
    - setIconView:  types=v24@0:8@16
    - titleLabel  types=@16@0:8
    - setTitleLabel:  types=v24@0:8@16
    - tapButton  types=@16@0:8
    - setTapButton:  types=v24@0:8@16
    - .cxx_destruct  types=v16@0:8

--- @interface CBBridgedSplitApp : CBBridgedApp (instanceSize=120, ro_flags=0x194) ---
  ivars:
    _dragStartRatio : d offset=8 size=8
    _isBlinking : B offset=16 size=1
    _blinkingIdleTimer : @"NSTimer" offset=24 size=8
    _lastActivityTime : d offset=32 size=8
    _isTransitioningFocus : B offset=40 size=1
    _splashScreenView : @"CBSplitSplashScreenView" offset=48 size=8
    _appViews : @"NSMutableArray" offset=56 size=8
    _placeholders : @"NSMutableArray" offset=64 size=8
    _containers : @"NSMutableArray" offset=72 size=8
    _dividers : @"NSMutableArray" offset=80 size=8
    _slotPills : @"NSMutableArray" offset=88 size=8
    _splitPreset : q offset=96 size=8
    _splitRatio : d offset=104 size=8
    _focusedSlotIndex : q offset=112 size=8
  properties:
    splashScreenView  attrs=T@"CBSplitSplashScreenView",&,N,V_splashScreenView
    appViews  attrs=T@"NSMutableArray",&,N,V_appViews
    placeholders  attrs=T@"NSMutableArray",&,N,V_placeholders
    containers  attrs=T@"NSMutableArray",&,N,V_containers
    dividers  attrs=T@"NSMutableArray",&,N,V_dividers
    slotPills  attrs=T@"NSMutableArray",&,N,V_slotPills
    splitPreset  attrs=Tq,N,V_splitPreset
    splitRatio  attrs=Td,N,V_splitRatio
    focusedSlotIndex  attrs=Tq,N,V_focusedSlotIndex
    isTransitioningFocus  attrs=TB,N,V_isTransitioningFocus
  instance methods (49):
    - initWithBundleIdentifier:frame:  types=@56@0:8@16{CGRect={CGPoint=dd}{CGSize=dd}}24
    - initWithBundleIdentifier:frame:showSplash:  types=@60@0:8@16{CGRect={CGPoint=dd}{CGSize=dd}}24B56
    - handleDividerPan:isVertical:state:  types=v44@0:8{CGPoint=dd}16B32q36
    - layoutSplitViews  types=v16@0:8
    - focusSlot:animated:  types=v28@0:8q16B24
    - restoreSplitAnimated:  types=v20@0:8B16
    - toggleFocusForSlot:  types=v24@0:8q16
    - rotateAllSlotsClockwise  types=v16@0:8
    - configureDividerButtons  types=v16@0:8
    - updateScale:forSlot:  types=v32@0:8d16q24
    - moveSlot:direction:  types=v32@0:8q16q24
    - handleDividerSwapPressed:  types=v24@0:8q16
    - swapSlot:withSlot:  types=v32@0:8q16q24
    - replaceAppInSlot:withBundleIdentifier:  types=v32@0:8q16@24
    - restartSlot:  types=v24@0:8q16
    - restartAppWithBundleIdentifier:  types=v24@0:8@16
    - removeAppWithBundleIdentifier:  types=v24@0:8@16
    - closeSlot:  types=v24@0:8q16
    - closeAllSlots  types=v16@0:8
    - persistSlotOrder  types=v16@0:8
    - start  types=v16@0:8
    - startInParentViewController:  types=v24@0:8@16
    - stop  types=v16@0:8
    - noteUserActivity  types=v16@0:8
    - startBlinkingSession  types=v16@0:8
    - stopBlinkingSession  types=v16@0:8
    - startContainerBorderBlinking:  types=v24@0:8@16
    - stopContainerBorderBlinking:  types=v24@0:8@16
    - splashScreenView  types=@16@0:8
    - setSplashScreenView:  types=v24@0:8@16
    - appViews  types=@16@0:8
    - setAppViews:  types=v24@0:8@16
    - placeholders  types=@16@0:8
    - setPlaceholders:  types=v24@0:8@16
    - containers  types=@16@0:8
    - setContainers:  types=v24@0:8@16
    - dividers  types=@16@0:8
    - setDividers:  types=v24@0:8@16
    - slotPills  types=@16@0:8
    - setSlotPills:  types=v24@0:8@16
    - splitPreset  types=q16@0:8
    - setSplitPreset:  types=v24@0:8q16
    - splitRatio  types=d16@0:8
    - setSplitRatio:  types=v24@0:8d16
    - focusedSlotIndex  types=q16@0:8
    - setFocusedSlotIndex:  types=v24@0:8q16
    - isTransitioningFocus  types=B16@0:8
    - setIsTransitioningFocus:  types=v20@0:8B16
    - .cxx_destruct  types=v16@0:8

--- @interface CBBridgedAssistantView : UIView (instanceSize=40, ro_flags=0x194) ---
  ivars:
    _micIcon : @"UIImageView" offset=8 size=8
    _titleLabel : @"UILabel" offset=16 size=8
    _subtitleLabel : @"UILabel" offset=24 size=8
    _pulseAnimation : @"CABasicAnimation" offset=32 size=8
  properties:
    micIcon  attrs=T@"UIImageView",&,N,V_micIcon
    titleLabel  attrs=T@"UILabel",&,N,V_titleLabel
    subtitleLabel  attrs=T@"UILabel",&,N,V_subtitleLabel
    pulseAnimation  attrs=T@"CABasicAnimation",&,N,V_pulseAnimation
  instance methods (15):
    - initWithFrame:  types=@48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16
    - startSession  types=v16@0:8
    - stopSession  types=v16@0:8
    - tapMicToggled  types=v16@0:8
    - startPulse  types=v16@0:8
    - stopPulse  types=v16@0:8
    - micIcon  types=@16@0:8
    - setMicIcon:  types=v24@0:8@16
    - titleLabel  types=@16@0:8
    - setTitleLabel:  types=v24@0:8@16
    - subtitleLabel  types=@16@0:8
    - setSubtitleLabel:  types=v24@0:8@16
    - pulseAnimation  types=@16@0:8
    - setPulseAnimation:  types=v24@0:8@16
    - .cxx_destruct  types=v16@0:8

--- @interface CBBridgedAssistantApp : CBBridgedApp (instanceSize=16, ro_flags=0x194) ---
  ivars:
    _assistantView : @"CBBridgedAssistantView" offset=8 size=8
  properties:
    assistantView  attrs=T@"CBBridgedAssistantView",&,N,V_assistantView
  instance methods (6):
    - initWithBundleIdentifier:frame:  types=@56@0:8@16{CGRect={CGPoint=dd}{CGSize=dd}}24
    - start  types=v16@0:8
    - stop  types=v16@0:8
    - assistantView  types=@16@0:8
    - setAssistantView:  types=v24@0:8@16
    - .cxx_destruct  types=v16@0:8

--- @interface CBBridgeRequest : NSObject (instanceSize=24, ro_flags=0x194) ---
  ivars:
    _activate : B offset=8 size=1
    _bundleIdentifier : @"NSString" offset=16 size=8
  properties:
    bundleIdentifier  attrs=T@"NSString",C,N,V_bundleIdentifier
    activate  attrs=TB,N,V_activate
  instance methods (6):
    - initWithDictionary:  types=@24@0:8@16
    - bundleIdentifier  types=@16@0:8
    - setBundleIdentifier:  types=v24@0:8@16
    - activate  types=B16@0:8
    - setActivate:  types=v20@0:8B16
    - .cxx_destruct  types=v16@0:8

--- @interface CBDashboardShared : NSObject (instanceSize=8, ro_flags=0x90) ---
  class methods (12):
    + setCurrentDashboardRootVC:  types=v24@0:8@16
    + currentDashboardRootVC  types=@16@0:8
    + setCurrentAppDockVC:  types=v24@0:8@16
    + currentAppDockVC  types=@16@0:8
    + setCurrentRootStatusBarVC:  types=v24@0:8@16
    + currentRootStatusBarVC  types=@16@0:8
    + carApp  types=@16@0:8
    + dashboard  types=@16@0:8
    + rootVC  types=@16@0:8
    + homeVC  types=@16@0:8
    + folderController  types=@16@0:8
    + appDockVC  types=@16@0:8

--- @interface CBBridgeManager : NSObject (instanceSize=144, ro_flags=0x194) ---
  ivars:
    _activated : B offset=8 size=1
    _isAutoResuming : B offset=9 size=1
    _autoResumeRetryCount : q offset=16 size=8
    _isApplyingSplitMode : B offset=24 size=1
    _sessionBridgedBundleIDs : @"NSMutableSet" offset=32 size=8
    _disconnectWatchdogToken : Q offset=40 size=8
    _autoResumeBundleID : @"NSString" offset=48 size=8
    _bundleIdentifier : @"NSString" offset=56 size=8
    _window : @"CBWindow" offset=64 size=8
    _currentApp : @"CBBridgedApp" offset=72 size=8
    _licenseWarningModal : @"CBLicenseWarningModalView" offset=80 size=8
    _licenseWatchdogTimer : @"NSTimer" offset=88 size=8
    _appFrame : {CGRect="origin"{CGPoint="x"d"y"d}"size"{CGSize="width"d"height"d}} offset=96 size=32
    _renderSize : {CGSize="width"d"height"d} offset=128 size=16
  properties:
    window  attrs=T@"CBWindow",&,N,V_window
    currentApp  attrs=T@"CBBridgedApp",&,N,V_currentApp
    licenseWarningModal  attrs=T@"CBLicenseWarningModalView",&,N,V_licenseWarningModal
    bundleIdentifier  attrs=T@"NSString",C,N,V_bundleIdentifier
    activated  attrs=TB,N,V_activated
    appFrame  attrs=T{CGRect={CGPoint=dd}{CGSize=dd}},N,V_appFrame
    renderSize  attrs=T{CGSize=dd},N,V_renderSize
    autoResumeBundleID  attrs=T@"NSString",C,N,V_autoResumeBundleID
  instance methods (73):
    - trackBridgedBundleID:  types=v24@0:8@16
    - runningBridgedApplications  types=@16@0:8
    - renderSizeForBundleID:  types={CGSize=dd}24@0:8@16
    - supportsInterfaceOrientation:forBundleID:  types=B32@0:8q16@24
    - switchToSplitWithLeft:right:ratio:  types=v40@0:8@16@24d32
    - switchToMultiSplitMode:apps:ratio:  types=v40@0:8q16@24d32
    - handleSettingsChanged  types=v16@0:8
    - showAppPickerForSlot:  types=v24@0:8q16
    - showLayoutChooser  types=v16@0:8
    - updateScale:forSlot:  types=v32@0:8d16q24
    - showRecentApps  types=v16@0:8
    - registerForNotifications  types=v16@0:8
    - receivedDashboardReadyNotification:  types=v24@0:8@16
    - receivedMetricsUpdatedNotification:  types=v24@0:8@16
    - sendStateToApp:shouldBridge:  types=v28@0:8@16B24
    - saveBridgeStateToDisk  types=v16@0:8
    - clearBridgeStateOnDisk  types=v16@0:8
    - syncDashboardPolicySignalToDisk  types=v16@0:8
    - receivedAppRequestNotification:  types=v24@0:8@16
    - isUIAppBridging  types=B16@0:8
    - shouldBridge:  types=B24@0:8@16
    - isCurrentlyBridging:  types=B24@0:8@16
    - receivedStateChangeRequestNotificiation:  types=v24@0:8@16
    - receivedDockTapNotification:  types=v24@0:8@16
    - notifyStateUpdated  types=v16@0:8
    - evictAppFromPhoneScreen:completion:  types=v32@0:8@16@?24
    - scheduleMandatoryDisconnectWatchdog  types=v16@0:8
    - cancelMandatoryDisconnectWatchdog  types=v16@0:8
    - enforceMandatoryDisconnectKill  types=v16@0:8
    - terminateApplicationWithBundleID:  types=v24@0:8@16
    - restartApplicationWithBundleID:  types=v24@0:8@16
    - terminateAllBridgedApplications  types=v16@0:8
    - collectActiveAndSessionAppBundleIDs  types=@16@0:8
    - killProcessesForBundleIdentifiers:  types=v24@0:8@16
    - acquireCarPlaySleepAssertion  types=v16@0:8
    - releaseCarPlaySleepAssertion  types=v16@0:8
    - effectiveAutoLaunchBundleID  types=@16@0:8
    - scheduleAutoResumeFallback  types=v16@0:8
    - performAutoResume  types=v16@0:8
    - handleGenericScreenOrCarPlayNotification:  types=v24@0:8@16
    - handleScreenDidDisconnect:  types=v24@0:8@16
    - handleScreenDidConnect:  types=v24@0:8@16
    - handleCarPlayConnectionChanged:  types=v24@0:8@16
    - init  types=@16@0:8
    - renderSize  types={CGSize=dd}16@0:8
    - requestStateChangeWithDictionary:  types=v24@0:8@16
    - requestStateChange:  types=v24@0:8@16
    - loadNewAppFromCurrentRequest:  types=v24@0:8@16
    - presentLicenseWarningModalWithType:  types=v24@0:8q16
    - dismissLicenseWarningModal  types=v16@0:8
    - startLicenseWatchdogTimer  types=v16@0:8
    - stopLicenseWatchdogTimer  types=v16@0:8
    - licenseWatchdogTimerFired:  types=v24@0:8@16
    - deactivateCurrentApp  types=v16@0:8
    - dismiss:  types=v24@0:8@?16
    - terminate  types=v16@0:8
    - appForBundleIdentifier:frame:  types=@56@0:8@16{CGRect={CGPoint=dd}{CGSize=dd}}24
    - window  types=@16@0:8
    - setWindow:  types=v24@0:8@16
    - currentApp  types=@16@0:8
    - setCurrentApp:  types=v24@0:8@16
    - licenseWarningModal  types=@16@0:8
    - setLicenseWarningModal:  types=v24@0:8@16
    - bundleIdentifier  types=@16@0:8
    - setBundleIdentifier:  types=v24@0:8@16
    - activated  types=B16@0:8
    - setActivated:  types=v20@0:8B16
    - appFrame  types={CGRect={CGPoint=dd}{CGSize=dd}}16@0:8
    - setAppFrame:  types=v48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16
    - setRenderSize:  types=v32@0:8{CGSize=dd}16
    - autoResumeBundleID  types=@16@0:8
    - setAutoResumeBundleID:  types=v24@0:8@16
    - .cxx_destruct  types=v16@0:8
  class methods (2):
    + sharedInstance  types=@16@0:8
    + sharedInstanceIfExists  types=@16@0:8

--- @interface CBAppMetadataItem : NSObject (instanceSize=32, ro_flags=0x194) ---
  ivars:
    _isUserApp : B offset=8 size=1
    _displayName : @"NSString" offset=16 size=8
    _icon : @"UIImage" offset=24 size=8
  properties:
    displayName  attrs=T@"NSString",C,N,V_displayName
    icon  attrs=T@"UIImage",&,N,V_icon
    isUserApp  attrs=TB,N,V_isUserApp
  instance methods (7):
    - displayName  types=@16@0:8
    - setDisplayName:  types=v24@0:8@16
    - icon  types=@16@0:8
    - setIcon:  types=v24@0:8@16
    - isUserApp  types=B16@0:8
    - setIsUserApp:  types=v20@0:8B16
    - .cxx_destruct  types=v16@0:8

--- @interface CBBridgeManagerDashboard : NSObject (instanceSize=24, ro_flags=0x194) ---
  ivars:
    _activated : B offset=8 size=1
    _pending : B offset=9 size=1
    _pendingCompletion : @? offset=16 size=8
  properties:
    activated  attrs=TB,N,V_activated
    pending  attrs=TB,N,V_pending
    pendingCompletion  attrs=T@?,C,N,V_pendingCompletion
  instance methods (33):
    - init  types=@16@0:8
    - registerForNotifications  types=v16@0:8
    - handleScreenDidDisconnect:  types=v24@0:8@16
    - handleScreenDidConnect:  types=v24@0:8@16
    - startBridging:  types=v24@0:8@16
    - startBridging:withCompletion:  types=v32@0:8@16@?24
    - stopBridging  types=v16@0:8
    - stopBridgingWithCompletion:  types=v24@0:8@?16
    - prepareAndRequestActivation:  types=v24@0:8@16
    - prepareHomeScreenForBridge:  types=v24@0:8@?16
    - closeOfficialTopApp:  types=v24@0:8@?16
    - requestActivation:  types=v24@0:8@16
    - requestDismiss  types=v16@0:8
    - requestStateChange:  types=v24@0:8@16
    - handleSBStateChange:  types=v24@0:8@16
    - handleStateDict:  types=v24@0:8@16
    - bridgeDidActivate:  types=v24@0:8@16
    - bridgeDidDeactivate  types=v16@0:8
    - handleDockIconTap:  types=v24@0:8@16
    - setAppDockActiveBundleID:  types=v24@0:8@16
    - setHomeButtonInApp:  types=v20@0:8B16
    - updateCarPlayMetrics  types=v16@0:8
    - getAppFrame  types={CGRect={CGPoint=dd}{CGSize=dd}}16@0:8
    - getDockDimension  types=d16@0:8
    - getDockWidth  types=d16@0:8
    - getDockEdge  types=@16@0:8
    - activated  types=B16@0:8
    - setActivated:  types=v20@0:8B16
    - pending  types=B16@0:8
    - setPending:  types=v20@0:8B16
    - pendingCompletion  types=@?16@0:8
    - setPendingCompletion:  types=v24@0:8@?16
    - .cxx_destruct  types=v16@0:8
  class methods (6):
    + sharedInstance  types=@16@0:8
    + isOfficialApp:  types=B24@0:8@16
    + isBridgedApp:  types=B24@0:8@16
    + isDashboardPolicySignalActive  types=B16@0:8
    + shouldInterceptLaunchForApp:  types=B24@0:8@16
    + bridgedApps  types=@16@0:8

--- @interface CBAppStateListener : NSObject (instanceSize=8, ro_flags=0x90) ---
  instance methods (5):
    - init  types=@16@0:8
    - checkStateFile  types=v16@0:8
    - sendStateRequest  types=v16@0:8
    - handleAppDidBecomeActive:  types=v24@0:8@16
    - handleAppStateNotification:  types=v24@0:8@16
  class methods (1):
    + sharedInstance  types=@16@0:8
```


### 4.3 DuoFaceFullscreenBridge — 4 class, 61 method + 15 hàm C export

```

--- @interface DFHostSnapshot : NSObject (instanceSize=240, ro_flags=0x184) ---
  ivars:
    _manager : @"CBBridgeManager" offset=8 size=8
    _window : @"CBWindow" offset=16 size=8
    _app : @"CBBridgedSplitApp" offset=24 size=8
    _content : @"UIView" offset=32 size=8
    _appView : @"UIView" offset=40 size=8
    _renderSize : {CGSize="width"d"height"d} offset=48 size=16
    _managerFrame : {CGRect="origin"{CGPoint="x"d"y"d}"size"{CGSize="width"d"height"d}} offset=64 size=32
    _windowFrame : {CGRect="origin"{CGPoint="x"d"y"d}"size"{CGSize="width"d"height"d}} offset=96 size=32
    _contentFrame : {CGRect="origin"{CGPoint="x"d"y"d}"size"{CGSize="width"d"height"d}} offset=128 size=32
    _appViewFrame : {CGRect="origin"{CGPoint="x"d"y"d}"size"{CGSize="width"d"height"d}} offset=160 size=32
    _appViewTransform : {CGAffineTransform="a"d"b"d"c"d"d"d"tx"d"ty"d} offset=192 size=48
  properties:
    manager  attrs=T@"CBBridgeManager",W,N,V_manager
    window  attrs=T@"CBWindow",W,N,V_window
    app  attrs=T@"CBBridgedSplitApp",W,N,V_app
    content  attrs=T@"UIView",W,N,V_content
    appView  attrs=T@"UIView",W,N,V_appView
    managerFrame  attrs=T{CGRect={CGPoint=dd}{CGSize=dd}},N,V_managerFrame
    renderSize  attrs=T{CGSize=dd},N,V_renderSize
    windowFrame  attrs=T{CGRect={CGPoint=dd}{CGSize=dd}},N,V_windowFrame
    contentFrame  attrs=T{CGRect={CGPoint=dd}{CGSize=dd}},N,V_contentFrame
    appViewFrame  attrs=T{CGRect={CGPoint=dd}{CGSize=dd}},N,V_appViewFrame
    appViewTransform  attrs=T{CGAffineTransform=dddddd},N,V_appViewTransform
  instance methods (23):
    - manager  types=@16@0:8
    - setManager:  types=v24@0:8@16
    - window  types=@16@0:8
    - setWindow:  types=v24@0:8@16
    - app  types=@16@0:8
    - setApp:  types=v24@0:8@16
    - content  types=@16@0:8
    - setContent:  types=v24@0:8@16
    - appView  types=@16@0:8
    - setAppView:  types=v24@0:8@16
    - managerFrame  types={CGRect={CGPoint=dd}{CGSize=dd}}16@0:8
    - setManagerFrame:  types=v48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16
    - renderSize  types={CGSize=dd}16@0:8
    - setRenderSize:  types=v32@0:8{CGSize=dd}16
    - windowFrame  types={CGRect={CGPoint=dd}{CGSize=dd}}16@0:8
    - setWindowFrame:  types=v48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16
    - contentFrame  types={CGRect={CGPoint=dd}{CGSize=dd}}16@0:8
    - setContentFrame:  types=v48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16
    - appViewFrame  types={CGRect={CGPoint=dd}{CGSize=dd}}16@0:8
    - setAppViewFrame:  types=v48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16
    - appViewTransform  types={CGAffineTransform=dddddd}16@0:8
    - setAppViewTransform:  types=v64@0:8{CGAffineTransform=dddddd}16
    - .cxx_destruct  types=v16@0:8

--- @interface DFFullscreenTransport : NSObject (instanceSize=96, ro_flags=0x184) ---
  ivars:
    _host : B offset=8 size=1
    _pendingEnabled : B offset=9 size=1
    _ownsFullscreen : B offset=10 size=1
    _desiredExpanded : B offset=11 size=1
    _center : @ offset=16 size=8
    _client : @"NSString" offset=24 size=8
    _sequence : Q offset=32 size=8
    _pendingID : @"NSString" offset=40 size=8
    _pendingCompletion : @? offset=48 size=8
    _stateChanged : @? offset=56 size=8
    _timer : @"NSTimer" offset=64 size=8
    _leaseOwner : @"NSString" offset=72 size=8
    _leaseDeadline : d offset=80 size=8
    _lastSequences : @"NSMutableDictionary" offset=88 size=8
  properties:
    center  attrs=T@,&,N,V_center
    host  attrs=TB,N,V_host
    client  attrs=T@"NSString",C,N,V_client
    sequence  attrs=TQ,N,V_sequence
    pendingID  attrs=T@"NSString",C,N,V_pendingID
    pendingEnabled  attrs=TB,N,V_pendingEnabled
    pendingCompletion  attrs=T@?,C,N,V_pendingCompletion
    stateChanged  attrs=T@?,C,N,V_stateChanged
    ownsFullscreen  attrs=TB,N,V_ownsFullscreen
    desiredExpanded  attrs=TB,N,V_desiredExpanded
    timer  attrs=T@"NSTimer",&,N,V_timer
    leaseOwner  attrs=T@"NSString",C,N,V_leaseOwner
    leaseDeadline  attrs=Td,N,V_leaseDeadline
    lastSequences  attrs=T@"NSMutableDictionary",&,N,V_lastSequences
  instance methods (36):
    - post:info:  types=v32@0:8@16@24
    - send:enabled:requestID:  types=v36@0:8@16B24@28
    - publish:client:reason:  types=v40@0:8@16@24@32
    - received:  types=v24@0:8@16
    - handleCommand:  types=v24@0:8@16
    - handleState:  types=v24@0:8@16
    - tick  types=v16@0:8
    - center  types=@16@0:8
    - setCenter:  types=v24@0:8@16
    - host  types=B16@0:8
    - setHost:  types=v20@0:8B16
    - client  types=@16@0:8
    - setClient:  types=v24@0:8@16
    - sequence  types=Q16@0:8
    - setSequence:  types=v24@0:8Q16
    - pendingID  types=@16@0:8
    - setPendingID:  types=v24@0:8@16
    - pendingEnabled  types=B16@0:8
    - setPendingEnabled:  types=v20@0:8B16
    - pendingCompletion  types=@?16@0:8
    - setPendingCompletion:  types=v24@0:8@?16
    - stateChanged  types=@?16@0:8
    - setStateChanged:  types=v24@0:8@?16
    - ownsFullscreen  types=B16@0:8
    - setOwnsFullscreen:  types=v20@0:8B16
    - desiredExpanded  types=B16@0:8
    - setDesiredExpanded:  types=v20@0:8B16
    - timer  types=@16@0:8
    - setTimer:  types=v24@0:8@16
    - leaseOwner  types=@16@0:8
    - setLeaseOwner:  types=v24@0:8@16
    - leaseDeadline  types=d16@0:8
    - setLeaseDeadline:  types=v24@0:8d16
    - lastSequences  types=@16@0:8
    - setLastSequences:  types=v24@0:8@16
    - .cxx_destruct  types=v16@0:8

--- @interface DFZoomAction : NSObject (instanceSize=8, ro_flags=0x80) ---
  instance methods (1):
    - pressed:  types=v24@0:8@16

--- @interface DFZoomReceiver : NSObject (instanceSize=8, ro_flags=0x80) ---
  instance methods (1):
    - received:  types=v24@0:8@16
```


**Class ngoài (framework) mà FullscreenBridge tham chiếu qua `__objc_classrefs`** (đã giải mã chained fixups): NSBundle, NSThread, NSAssertionHandler, NSString, NSProcessInfo, DFHostSnapshot, NSNumber, NSDictionary, NSUUID, DFFullscreenTransport, NSMutableDictionary, NSTimer, NSHashTable, NSMapTable, DFZoomAction, UIButton, UIColor, NSArray, UIFont, UIImageView, UILabel, UIImage, UIScrollView, UIImageSymbolConfiguration, DFZoomReceiver.

**15 hàm C export** (địa chỉ là địa chỉ ảo trong slice arm64; toàn bộ 23 symbol định nghĩa của dylib — gồm 15 hàm này + 8 symbol class/metaclass — đều nằm trong exports trie):

| Hàm | Địa chỉ | Vai trò suy ra từ tên + chuỗi log đi kèm |
|---|---|---|
| `_DFHostCanExpand` | 0x4444 | Kiểm tra host có mở rộng được không |
| `_DFHostIsExpanded` | 0x47ec | Trạng thái host đang mở rộng |
| `_DFHostSetLifecycleCallback` | 0x4aa0 | Đăng ký callback vòng đời host |
| `_DFHostRestore` | 0x4af0 | Khôi phục host về khung gốc |
| `_DFHostSetExpanded` | 0x4e74 | Đặt host sang trạng thái mở rộng/thu |
| `_DFInstallHostGeometryHooks` | 0x5638 | Cài hook hình học của host |
| `_DFStartFullscreenTransport` | 0x6ffc | Khởi động kênh vận chuyển lệnh fullscreen |
| `_DFQueryFullscreenHost` | 0x73d0 | Truy vấn trạng thái host |
| `_DFRequestHostFullscreen` | 0x74c8 | Yêu cầu host fullscreen |
| `_DFDashboardRestoreChrome` | 0x7888 | Khôi phục chrome (thanh viền UI) của Dashboard |
| `_DFDashboardSetChromeHidden` | 0x7aa0 | Ẩn/hiện chrome của Dashboard |
| `_DFInstallDashboardChromeHooks` | 0x7ea0 | Cài hook chrome Dashboard |
| `_DFInstallPickerZoomMenuHooks` | 0x82f8 | Cài hook menu zoom trong picker |
| `_DFPickerZoomMenuRefresh` | 0x84f0 | Làm mới menu zoom |
| `_DFStartFullscreenAdapter` | 0x9eb4 | Khởi động adapter fullscreen (điểm vào chính; chuỗi log: `[DuoFaceFullscreen] candidate adapter started in %@`) |

### 4.4 DuoFaceVisualHook — 0 class ObjC; toàn bộ là hàm C

Các hàm nghiệp vụ (tiền tố `DF`, địa chỉ ảo slice arm64; danh sách symbol đầy đủ gồm cả `objc_msgSend$…` stubs và biến `__bss` ở Mục 9.4):

| Hàm | Địa chỉ | Hàm | Địa chỉ |
|---|---|---|---|
| `_DFInit` | 0x4000 | `_DFSessionStopHook` | 0x5568 |
| `_DFImageAdded` | 0x4030 | `_DFFocusSlotHook` | 0x5708 |
| `_DFInstall` | 0x408c | `_DFRestoreSplitHook` | 0x577c |
| `_DFSetButtonBackgroundColor` | 0x43d8 | `_DFUpdateFocusBorders` | 0x57e0 |
| `_DFSetLayerBorderWidth` | 0x4444 | `_DFFocusHidden` | 0x599c |
| `_DFSetLayerBorderColor` | 0x44a4 | `_DFKnownBorderViewsFor` | 0x59d0 |
| `_DFInstallBorderRunner` | 0x4518 | `_DFSetBorderVisible` | 0x5a40 |
| `_DFPillLayout` | 0x4a9c | `_DFRemoveLegacyBorderEffects` | 0x5b60 |
| `_DFDividerLayout` | 0x4d74 | `_DFBorderLogoRed` | 0x5dac |
| `_DFSplashLayout` | 0x4f64 | `_DFTrackBorderView` | 0x5ed8 |
| `_DFSplitLayoutHook` | 0x5224 | `_DFApplyButton` | 0x6094 |
| `_DFBorderStartHook` | 0x5260 | `_DFObjectIvar` | 0x6564 |
| `_DFBorderStopHook` | 0x5308 | `_DFImage` | 0x660c |

**Biến trạng thái toàn cục (`__DATA,__bss`) — bằng chứng trực tiếp của cơ chế thay IMP thủ công và callback liên dylib** *(symbol)*:
- Ô lưu IMP gốc: `_oldButtonSetBackgroundColor` (0xc268), `_oldLayerSetBorderWidth` (0xc270), `_oldLayerBorderColor`→`_oldLayerSetBorderColor` (0xc278), `_oldPillLayout` (0xc280), `_oldDividerLayout` (0xc288), `_oldSplashLayout` (0xc290).
- Cờ đã cài: `_pillInstalled`, `_dividerInstalled`, `_splashInstalled`, `_DFBorderHooksInstalled`, `_visualSetterHooksInstalled`, `_DFInstall.triedLibrary`.
- Ô callback do bên ngoài đăng ký vào (khớp chuỗi log `[DuoFaceBorder] install %@ start=%p stop=%p focus=%p restore=%p`): `_DFNativeSplitLayout` (0xc2a0), `_DFNativeBorderStart` (0xc2a8), `_DFNativeBorderStop` (0xc2b0), `_DFNativeSessionStart` (0xc2b8), `_DFNativeSessionStop` (0xc2c0), `_DFNativeFocusSlot` (0xc2c8), `_DFNativeRestoreSplit` (0xc2d0).
- Khóa associated-object: `_kVisualOnlyKey`, `_DFKnownBorderViewsKey`, `_kOverlayKey`, `_DFRunningAssociation`, `_DFFocusAssociation`; cache ảnh `_DFImage.cache`; các cờ log `_pickerLogged`, `_fullscreenLogged`, `_swapLogged`, `_splashLogged`.

### 4.5 duoface_cboptimize_helper — 0 class ObjC

Executable C thuần: symtab chỉ còn `_main` (0x1000063ac ở slice arm64 / 0x100006420 ở slice arm64e) và `__mh_execute_header`; toàn bộ API ngoài liệt kê ở Mục 3.5 và Mục 9.5. Không có hàm nội bộ nào khác có tên trong symtab.

---

## 5. Điểm hook và mức bằng chứng

### 5.1 Cơ chế hook theo từng binary (bằng chứng symbol/API)

| Binary | API hook import trực tiếp | API runtime đi kèm | Kết luận cơ chế |
|---|---|---|---|
| DuoFaceDashboard | `_MSHookFunction`, `_MSHookMessageEx` | `class_addMethod`, `class_getInstanceMethod`, `class_getInstanceVariable`, `class_getName`, `class_getSuperclass`, `method_getTypeEncoding`, `objc_getClass`, `objc_setAssociatedObject`, `dlopen`, `dlsym` | Hook bằng Cydia Substrate (liên kết thẳng `@rpath/CydiaSubstrate.framework/CydiaSubstrate`) + thao tác runtime ObjC |
| DuoFaceFullscreenBridge | `_MSHookMessageEx` | `class_getInstanceVariable`, `objc_getClass`, `objc_setAssociatedObject` | Hook bằng Substrate (liên kết CydiaSubstrate) |
| DuoFaceVisualHook | **không có** `MSHook*` | `_dyld_register_func_for_add_image`, `dlopen`, `dlsym`, `class_getInstanceMethod`, `class_getInstanceVariable`, `method_getTypeEncoding`, `method_getNumberOfArguments`, `method_copyArgumentType`, `object_getIvar`, `objc_getClass`, `objc_setAssociatedObject`, `objc_getAssociatedObject` | Tự phân giải Substrate lúc chạy (chuỗi đường dẫn `/usr/lib/libsubstrate.dylib`, `/var/jb/usr/lib/libsubstrate.dylib`) và/hoặc thay IMP thủ công — chứng cứ: các ô `__bss` lưu IMP gốc `_oldButtonSetBackgroundColor`, `_oldLayerSetBorderWidth`, `_oldLayerSetBorderColor`, `_oldPillLayout`, `_oldDividerLayout`, `_oldSplashLayout` *(symbol)* và chuỗi kiểm tra chữ ký `[DuoFaceBorder] signature mismatch start=%s stop=%s` *(chuỗi)* |
| DuoFaceUI (app) | không có | `objc_getClass`, Darwin notify (Mục 5.3) | App thường, không hook |
| duoface_cboptimize_helper | không có | — | CLI thuần |

### 5.2 Class/selector đích mà Dashboard tự ghi trong chuỗi log của nó

Dashboard chứa 231 chuỗi log có tiền tố `[DuoFace…]` (toàn bộ ở Mục 6.2). Một nhóm chuỗi ghi thẳng tên class + selector tại điểm can thiệp — đây là bằng chứng *chuỗi log* (binary tự mô tả điểm nó xử lý), không phải bảng hook đọc từ mã máy; địa chỉ IMP đích và việc selector nào đi qua `MSHookMessageEx` hay qua đường khác không tách riêng được vì symtab đã bị strip (Mục 10).

**Nhóm Dashboard/Home (tiền tố `[DuoFaceDB]`):**
- `CARIconManager` — `iconTapped:`, `iconTapped:modifierFlags:`, `launchIcon:`, `launchIcon:location:animated:completionHandler:`, `launchIconForIconView:`, `launchIconForIconView:withActions:`
- `SBHIconManager` — `iconTapped:`, `iconTapped:modifierFlags:`, `launchIconForIconView:`, `launchIconForIconView:withActions:`
- `SBIconView`, `CARIconView`, `DBIconView` — `_handleTapGesture:`; riêng `SBIconView` còn `touchesEnded…`
- `CARAppDockViewController` — `_dockButtonPressed:`
- `CARApplication` — `+_newApplicationLibrary:`, `-_newApplicationLibrary:`
- `FBSApplicationLibrary` — `allInstalledApplications` (log: "injected special app")
- `CARIconModel` — `addIcon`, `loadAllIcons`, `leafIconForIdentifier:`
- `CARRootStatusBarViewController`, `DBRootStatusBarViewController` — `homeButtonUp:`
- `_CARDashboardHomeViewController` — `iconManager:launchIcon:`, `iconManager:launchIcon:location:`, `iconManager:launchIcon:location:animated:`, `iconManager:launchIconForIconView:`
- `_CARDashboardRootViewController` — `viewSafeAreaInsetsDidChange:`
- Hàm C nội bộ (chỉ còn tên trong chuỗi log): `CBUpdateApplicationLibrary`, `CBBundleIDForIconView`, `CBDumpViewHierarchy`, `CBExtractBundleIDFromScene`

**Nhóm SpringBoard (tiền tố `[DuoFaceSB]`):** quản lý scene/app trên màn xe — log nhắc tới `updateSettings:withTransitionContext:` (của FBScene), terminate/kill tiến trình app (`Killing process %d`, `kill(%d, SIGKILL)`), auto-resume/auto-launch khi CarPlay connect, watchdog ngắt kết nối 60 giây ("MANDATORY 1-MIN WATCHDOG"), và đường kill khi license hết hạn (`[LICENSE_KILL_TRACE]`) — chi tiết luồng ở Mục 7.

**Nhóm bàn phím (tiền tố `[DuoFaceKB]`):** `UIKeyboardLayoutStar` — `setKeyboardName:appearance:`, `setKeyplaneName:`, `showKeyboard`; `UIKeyboardImpl` — `setDelegate:force:`, `showKeyboard`; `UIRemoteKeyboardWindow` — `setAlpha:`, `setHidden:`; `UITextEffectsWindow` — `setAlpha:`, `setHidden:`; `UIInputWindowController` — `viewWillAppear:`/`viewDidAppear:`; `UIResponder` — `becomeFirstResponder`/`resignFirstResponder`. Cơ chế ghi trong log: thêm tiền tố vào tên bàn phím (`Added prefix to setKeyboardName:`), sửa giá trị nil/(null) của keyboard name, ép input mode dự phòng (`forcing fallback inputMode identifier`), dump cây view bàn phím (`[DuoFaceKB-Tree]`).

**Nhóm trong app được bridge (tiền tố `[DuoFaceApp]`):** nhận thông báo trạng thái (`Received handleAppStateNotification:`), đọc file trạng thái trên đĩa (`checkStateFile: bid=%@, dict=%@`, `Activated via disk state file`), "đánh thức app về foreground để trình diễn trên CarPlay" (`Waking app to active foreground state for CarPlay presentation: %@`), gửi `NOTIFY_APP_REQUEST`.

**Nhóm của FullscreenBridge (tiền tố `[DuoFaceFullscreen]`, Mục 6.3):** hook hình học host (`host geometry applied`), ẩn/hiện chrome Dashboard, menu zoom trong picker (`native picker zoom requested=%d`, `picker sheet width invalid %.1f`), cơ chế rollback khi adapter không dùng được (`candidate adapter unavailable… after class-load retries`, `rollback restored=%d`).

**Nhóm của VisualHook (tiền tố `[DuoFaceBorder]` / `[DuoFaceVisual12]`, Mục 6.4):** bật/tắt viền đỏ theo hoạt động người dùng (`RED ON user activity view=%p focus=%d`, `RED OFF native idle view=%p`), áp splash (`splash %@ applied; original loading untouched`).

### 5.3 Kênh thông báo Darwin / notify

- **Dashboard** import cả 3 họ: `CFNotificationCenterGetDarwinNotifyCenter` + `CFNotificationCenterAddObserver` + `CFNotificationCenterPostNotification`, và `notify_post` + `notify_register_dispatch` *(symbol)*.
- **DuoFaceUI** import `CFNotificationCenterGetDarwinNotifyCenter/AddObserver/PostNotification/RemoveObserver` + `notify_post` *(symbol)*.
- Tên thông báo hệ thống xuất hiện dạng chuỗi tĩnh trong Dashboard *(chuỗi)*: `com.apple.CarPlay.screenConnected`, `com.apple.CarPlay.screenDisconnected`, `com.apple.springboard.displayChanged`, `com.apple.springboard.screenStateChanged`, `com.apple.carkit.sessionStatusChanged`, và tên riêng `CarBridge.CarPlaySessionActive`.
- Tên kênh riêng của FullscreenBridge *(chuỗi, nguyên văn)*: `com.duoface.fullscreen.command.v1`, `com.duoface.fullscreen.state.v1`, `com.duoface.fullscreen.picker.v1` — đi cùng class `DFFullscreenTransport` (36 method, Mục 4.3).
- Trong chuỗi log của Dashboard xuất hiện 2 định danh dạng macro `NOTIFY_APP_REQUEST` và `NOTIFY_APP_STATE` ("Sending NOTIFY_APP_REQUEST for %@", "Posting NOTIFY_APP_STATE to %@") — tên Darwin literal tương ứng không nằm dạng rõ trong bảng chuỗi đã trích (Mục 10).
- Hai định danh queue/kênh khác *(chuỗi)*: `com.duoface.license.sync`, `com.duoface.http.client` (xuất hiện trong cả Dashboard và DuoFaceUI — khớp hai class dùng chung `CBLicenseSyncManager`, `CBHttpClient`).

---

## 6. Chuỗi quan trọng đã phân loại (trích từ `strings` toàn binary, đã khử trùng lặp)

Phân loại: định danh dạng reverse-DNS (bundle id / tên thông báo / queue), URL & scheme, đường dẫn file, và chuỗi log có định dạng (`%`). Toàn bộ chuỗi thô của từng binary được giữ ở file làm việc (`out/<tên>.allstrings.txt`) — mục này in các nhóm có ý nghĩa nghiệp vụ. Lưu ý: chuỗi `radr://5614542` xuất hiện trong nhiều binary arm64e — đây là nhiễu dữ liệu nhị phân trong vùng hằng số, **không** phải endpoint (xem Mục 10).

### 6.1 DuoFaceUI (6.549 chuỗi duy nhất)

DuoFaceUI: total unique strings=6549

## reverse-dns ids (38)
app.badge.fill
com.apple.AuthKitUIService
com.apple.CTNotifyUIService
com.apple.CarPlayApp
com.apple.CarPlaySettings
com.apple.CarPlayTemplateUIHost
com.apple.CarPlayWallpaper
com.apple.CheckerBoard
com.apple.CoreAuthUI
com.apple.DataActivation
com.apple.Diagnostics
com.apple.HomeUIService
com.apple.InCallService
com.apple.PassbookUIService
com.apple.PreBoard
com.apple.PurpleSoftware
com.apple.SIMSetupSupport.SIMSetupUIService
com.apple.ScreenTimeUnlock
com.apple.ScreenshotServicesService
com.apple.SharedWebCredentialsViewService
com.apple.SharingViewService
com.apple.StoreKitUIService
com.apple.TrustMe
com.apple.fieldtest
com.apple.maps
com.apple.music
com.apple.podcasts
com.apple.sidecar
com.apple.springboard
com.apple.tv
com.apple.webapp
com.duoface.http.client
com.duoface.license.sync
com.google.ios.youtube
com.google.maps
com.netflix.netflix
com.spotify.client
com.waze.iphone

## url/scheme (3)
http://
https://
radr://5614542

## paths (26)
/Library/Application Support/CarBridge/duoface-icon.png
/Library/Application Support/CarBridge/duoface-logo.png
/Library/Application Support/DuoFace/duoface-icon.png
/Library/Application Support/DuoFace/duoface-logo.png
/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation
/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics
/System/Library/Frameworks/CoreServices.framework/CoreServices
/System/Library/Frameworks/Foundation.framework/Foundation
/System/Library/Frameworks/IOKit.framework/Versions/A/IOKit
/System/Library/Frameworks/MobileCoreServices.framework/MobileCoreServices
/System/Library/Frameworks/QuartzCore.framework/QuartzCore
/System/Library/Frameworks/SafariServices.framework/SafariServices
/System/Library/Frameworks/Security.framework/Security
/System/Library/Frameworks/UIKit.framework/UIKit
/usr/lib/dyld
/usr/lib/libSystem.B.dylib
/usr/lib/libobjc.A.dylib
/var/jb/Library/Application Support/CarBridge/duoface-icon.png
/var/jb/Library/Application Support/CarBridge/duoface-logo.png
/var/jb/Library/Application Support/DuoFace/duoface-icon.png
/var/jb/Library/Application Support/DuoFace/duoface-logo.png
/var/jb/Library/Frameworks
/var/jb/usr/bin/killall
/var/jb/usr/lib
@loader_path/.jbroot/Library/Frameworks
@loader_path/.jbroot/usr/lib

## log formats (14)
[DuoFaceLicense] %@
[DuoFaceLicense] Automated sync attempt detected from another process %llu s ago (< 10s cooldown). Skipping duplicate trigger.
[DuoFaceLicense] Automated sync was already initiated %llu s ago (< 10s cooldown). Skipping duplicate trigger.
[DuoFaceLicense] Dispatching async license sync request to %@ for HW: %@ (source: %@)
[DuoFaceLicense] License refresh interval reached (interval=%llu s, last=%llu s, now=%llu s). Triggering background refresh...
[DuoFaceLicense] Network request failed: %@
[DuoFaceLicense] Offline license is valid (rem: %llu s). Next refresh in %llu s. Using cached license.
[DuoFaceLicense] Server returned non-200 status code: %ld (Error: %@)
[DuoFaceLicense] Warning: Ignoring invalid/negative expiration header: %@
[DuoFaceLicense] Warning: Ignoring invalid/negative expiration in JSON: %@
[DuoFace] Warning: Failed writing to log file: %@
[DuoFace_DEBUG] resolvedBackendBaseURL Tier 1 (File Override): %@
[DuoFace_DEBUG] resolvedBackendBaseURL Tier 2 (Plist Override): %@
[DuoFace_DEBUG] resolvedBackendBaseURL Tier 3 (Production Default): %@

### 6.2 DuoFaceDashboard (9.987 chuỗi duy nhất)

Dashboard: total unique strings=9987

## reverse-dns ids (48)
app.badge.fill
com.apple.AccountAuthenticationDialog
com.apple.CarPlay
com.apple.CarPlay.screenConnected
com.apple.CarPlay.screenDisconnected
com.apple.CarPlayApp
com.apple.CarPlayWallpaper
com.apple.CompassCalibrationViewService
com.apple.CoreAuthUI
com.apple.DiagnosticsService
com.apple.InCallService
com.apple.MailCompositionService
com.apple.Maps
com.apple.PassbookUIService
com.apple.ScreenshotServicesService
com.apple.Search
com.apple.SharingViewService
com.apple.Spotlight
com.apple.TrustMe
com.apple.audiobooks
com.apple.backboardd
com.apple.calendarnotificationservice
com.apple.carkit.sessionStatusChanged
com.apple.carplay
com.apple.dashboard
com.apple.maps
com.apple.mobilephone
com.apple.mobilesafari
com.apple.mobilesms
com.apple.music
com.apple.news
com.apple.podcasts
com.apple.purplebuddy
com.apple.shortcuts.runtime
com.apple.springboard
com.apple.springboard.displayChanged
com.apple.springboard.screenStateChanged
com.apple.tv
com.apple.weather
com.duoface.duofaceui
com.duoface.http.client
com.duoface.license.sync
com.google.Maps
com.google.ios.youtube
com.google.maps
com.netflix.netflix
com.spotify.client
com.waze.iphone

## url/scheme (9)
comgooglemaps://?daddr=%@&directionsmode=driving
http://
http://maps.apple.com/?daddr=%@&dirflg=d
https://
https://m.youtube.com/results?search_query=%@
https://www.google.com/speech-api/v2/recognize?client=chromium&lang=vi-VN&key=%@&maxresults=5&pFilter=0
radr://5614542
waze://?q=%@&navigate=yes
youtube://results?search_query=%@

## paths (43)
/Library/Application Support/CarBridge/AssistantAppIcon.png
/Library/Application Support/CarBridge/PortalAppIcon.png
/Library/Application Support/CarBridge/duoface-icon.png
/Library/Application Support/CarBridge/duoface-logo.png
/Library/Application Support/DuoFace/AssistantAppIcon.png
/Library/Application Support/DuoFace/PortalAppIcon.png
/Library/Application Support/DuoFace/duoface-icon.png
/Library/Application Support/DuoFace/duoface-logo.png
/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.plist
/Library/TCC/TCC.db
/System/Library/Frameworks/AVFAudio.framework/AVFAudio
/System/Library/Frameworks/AVFoundation.framework/AVFoundation
/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation
/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics
/System/Library/Frameworks/Foundation.framework/Foundation
/System/Library/Frameworks/IOKit.framework/IOKit
/System/Library/Frameworks/IOKit.framework/Versions/A/IOKit
/System/Library/Frameworks/QuartzCore.framework/QuartzCore
/System/Library/Frameworks/Security.framework/Security
/System/Library/Frameworks/Speech.framework/Speech
/System/Library/Frameworks/UIKit.framework/UIKit
/System/Library/PrivateFrameworks/AppSupport.framework/AppSupport
/System/Library/PrivateFrameworks/BackBoardServices.framework/BackBoardServices
/System/Library/PrivateFrameworks/GraphicsServices.framework/GraphicsServices
/usr/lib/libSystem.B.dylib
/usr/lib/libobjc.A.dylib
/usr/lib/libsqlite3.dylib
/var/jb/Library/Application Support/CarBridge/AssistantAppIcon.png
/var/jb/Library/Application Support/CarBridge/PortalAppIcon.png
/var/jb/Library/Application Support/CarBridge/duoface-icon.png
/var/jb/Library/Application Support/CarBridge/duoface-logo.png
/var/jb/Library/Application Support/DuoFace/AssistantAppIcon.png
/var/jb/Library/Application Support/DuoFace/PortalAppIcon.png
/var/jb/Library/Application Support/DuoFace/duoface-icon.png
/var/jb/Library/Application Support/DuoFace/duoface-logo.png
/var/jb/Library/Frameworks
/var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.plist
/var/jb/usr/lib
/var/jb/var/mobile/Library/TCC/TCC.db
/var/mobile/Library/TCC/TCC.db
/var/tmp/carbridge_autoresume_bid
@loader_path/.jbroot/Library/Frameworks
@loader_path/.jbroot/usr/lib

## log formats (231)
[DuoFaceApp] Activated via disk state file: size={%.1f, %.1f}, o=%ld, isSplit=%d
[DuoFaceApp] Error in recursive VC relayout: %@
[DuoFaceApp] Error laying out window: %@
[DuoFaceApp] Notification indicated not bridged for %@. Resetting to phone mode.
[DuoFaceApp] Received handleAppStateNotification: %@
[DuoFaceApp] Sending NOTIFY_APP_REQUEST for %@
[DuoFaceApp] State file indicates not bridged for %@. Resetting to phone mode.
[DuoFaceApp] State updated via notification: bridging=%d, size={%.1f, %.1f}, o=%ld
[DuoFaceApp] Waking app to active foreground state for CarPlay presentation: %@
[DuoFaceApp] checkStateFile: bid=%@, dict=%@
[DuoFaceCarPlay] Calculated dock screen frame df=%@ (sw=%.1f, sh=%.1f)
[DuoFaceCarPlay] Exception in updateCarPlayMetrics: %@
[DuoFaceCarPlay] Warning: Failed to write dock path: %@
[DuoFaceCarPlay] Warning: Failed to write inset path: %@
[DuoFaceCarPlay] Warning: Failed to write screen path: %@
[DuoFaceCarPlay] safeInsets=%@, dockInsets=%@
[DuoFaceCarPlay] updateCarPlayMetrics: Screen=%@, Insets=%@, Edge=%@
[DuoFaceDB] CARAppDockViewController _dockButtonPressed: bundleID=%@
[DuoFaceDB] CARApplication +_newApplicationLibrary: %@
[DuoFaceDB] CARApplication -_newApplicationLibrary: %@
[DuoFaceDB] CARIconManager iconTapped: iconView=%@, bid=%@, isBridged=%d
[DuoFaceDB] CARIconManager iconTapped:modifierFlags: iconView=%@, bid=%@, isBridged=%d
[DuoFaceDB] CARIconManager launchIcon: icon=%@, bid=%@, isBridged=%d
[DuoFaceDB] CARIconManager launchIcon:location:animated:completionHandler: bid=%@, isBridged=%d
[DuoFaceDB] CARIconManager launchIconForIconView: iconView=%@, bid=%@, isBridged=%d
[DuoFaceDB] CARIconManager launchIconForIconView:withActions: iconView=%@, bid=%@, isBridged=%d
[DuoFaceDB] CARIconModel addIcon exception: %@
[DuoFaceDB] CARIconModel check leafIconForIdentifier:%@ -> %@
[DuoFaceDB] CARIconModel loadAllIcons EXCEPTION: %@
[DuoFaceDB] CARIconView _handleTapGesture: state=%ld, bid=%@, isBridged=%d
[DuoFaceDB] CARIconView intercepted bridged app tap: %@
[DuoFaceDB] CARRootStatusBarViewController homeButtonUp: activated=%d
[DuoFaceDB] CBBundleIDForIconView FAILED: iconView=%@, icon=%@
[DuoFaceDB] CBUpdateApplicationLibrary executing on library: %@
[DuoFaceDB] CBUpdateApplicationLibrary registered info for %@
[DuoFaceDB] DBIconView _handleTapGesture: state=%ld, bid=%@, isBridged=%d
[DuoFaceDB] DBIconView intercepted bridged app tap: %@
[DuoFaceDB] DBRootStatusBarViewController homeButtonUp: activated=%d
[DuoFaceDB] Explicitly adding leaf icon %@ to CARIconModel
[DuoFaceDB] Explicitly adding leaf icon %@ to rootFolder
[DuoFaceDB] FBSApplicationLibrary allInstalledApplications injected special app: %@
[DuoFaceDB] Failed to save request plist: %@
[DuoFaceDB] LayoutSafety: targetFrame %@ intersects dockRect %@! Adjusting...
[DuoFaceDB] License inactive/expired for native CarPlay app %@ -> PASS-THROUGH to native launcher
[DuoFaceDB] License inactive/expired for non-native app %@ -> INTERCEPTING to present warning modal
[DuoFaceDB] Notifying library of %lu added applications
[DuoFaceDB] SBHIconManager iconTapped: iconView=%@, bid=%@, isBridged=%d
[DuoFaceDB] SBHIconManager iconTapped:modifierFlags: iconView=%@, bid=%@, isBridged=%d
[DuoFaceDB] SBHIconManager launchIconForIconView: iconView=%@, bid=%@, isBridged=%d
[DuoFaceDB] SBHIconManager launchIconForIconView:withActions: iconView=%@, bid=%@, isBridged=%d
[DuoFaceDB] SBIconView _handleTapGesture: state=%ld, bid=%@, isBridged=%d
[DuoFaceDB] SBIconView intercepted bridged app tap: %@
[DuoFaceDB] SBIconView touchesEnded intercepted bridged app: %@
[DuoFaceDB] SystemMonitor applied targetFrame=%@ (dockMinY=%.1f, lowestItemY=%.1f, highestItemY=%.1f)
[DuoFaceDB] Warning: Exception querying dataSource property: %@
[DuoFaceDB] Warning: Exception querying icon application bundleID: %@
[DuoFaceDB] Warning: Exception querying icon property %@: %@
[DuoFaceDB] Warning: Exception querying iconView property %@: %@
[DuoFaceDB] Warning: Failed to write req plist on disconnect (req=%d, tmp=%d)
[DuoFaceDB] Warning: Failed to write request plist (req=%d, tmp=%d)
[DuoFaceDB] [CONNECT_TRACE] DashBoard received screen connected notification: %@
[DuoFaceDB] [DISCONNECT_TRACE] DashBoard received screen disconnected notification: %@
[DuoFaceDB] _CARDashboardHomeViewController iconManager:launchIcon: bid=%@, isBridged=%d
[DuoFaceDB] _CARDashboardHomeViewController iconManager:launchIcon:location: bid=%@, isBridged=%d
[DuoFaceDB] _CARDashboardHomeViewController iconManager:launchIcon:location:animated: bid=%@, isBridged=%d
[DuoFaceDB] _CARDashboardHomeViewController iconManager:launchIconForIconView: iconView=%@, bid=%@, isBridged=%d
[DuoFaceDB] _CARDashboardHomeViewController iconManager:launchIconForIconView:withActions: iconView=%@, bid=%@, isBridged=%d
[DuoFaceDB] _CARDashboardRootViewController viewSafeAreaInsetsDidChange: %@
[DuoFaceDB] effectivePolicyForAppDeclaration: policy signal inactive for native app %@ -> 100%% %%orig pass-through
[DuoFaceDB] requestActivation called for bundleID=%@ (pending=%d)
[DuoFaceDB] requestDismiss called (current pending=%d)
[DuoFaceDB] setHomeButtonInApp exception: %@
[DuoFaceKB-Mode] kim cur=%@ active=%@
[DuoFaceKB-Mode] kimc=%@ cur=%@ active=%@
[DuoFaceKB-Tree] %@%@ frame=%@ bounds=%@ hidden=%d alpha=%.2f layer=%@ layerBounds=%@
[DuoFaceKB]   starLayer=%@ frame=%@ hidden=%d opacity=%.2f
[DuoFaceKB] Added prefix to setKeyboardName: from %@ to %@
[DuoFaceKB] Added prefix to setKeyboardName:appearance: from %@ to %@
[DuoFaceKB] Corrected (null) in setKeyboardName: from %@ to %@
[DuoFaceKB] Corrected (null) in setKeyboardName:appearance: from %@ to %@
[DuoFaceKB] Corrected nil setKeyboardName: to %@
[DuoFaceKB] Corrected nil setKeyboardName:appearance: to %@
[DuoFaceKB] Warning: Exception getting currentInputMode: %@
[DuoFaceKB] Warning: Exception getting keyboardInputModeWithIdentifier: %@
[DuoFaceKB] Warning: Exception in CBDumpViewHierarchy: %@
[DuoFaceKB] Warning: Exception in activeInstance inputMode setup: %@
[DuoFaceKB] Warning: Exception querying keyplane: %@
[DuoFaceKB] Warning: Exception recovering keyplane: %@
[DuoFaceKB] Warning: Exception setting idiom emulation on traits: %@
[DuoFaceKB] [UIInputWindowController viewDidAppear:%d] view=%@
[DuoFaceKB] [UIInputWindowController viewWillAppear:%d] view=%@
[DuoFaceKB] [UIKeyboardImpl forcing fallback inputMode identifier: %@]
[DuoFaceKB] [UIKeyboardImpl setDelegate:%@ force:%d]
[DuoFaceKB] [UIKeyboardImpl showKeyboard] called! inHWMode=%d, autoMin=%d
[DuoFaceKB] [UIKeyboardLayoutStar after showKeyboard] frame=%@ hidden=%d alpha=%.2f keyplane=%@ subviews=%lu sublayers=%lu
[DuoFaceKB] [UIKeyboardLayoutStar setKeyboardName:%@ appearance:%ld]
[DuoFaceKB] [UIKeyboardLayoutStar setKeyplaneName:%@]
[DuoFaceKB] [UIKeyboardLayoutStar showKeyboard forcing inputMode: %@]
[DuoFaceKB] [UIKeyboardLayoutStar showKeyboard] inputTraits=%@ screenTraits=%@
[DuoFaceKB] [UIRemoteKeyboardWindow setAlpha:%.2f]
[DuoFaceKB] [UIRemoteKeyboardWindow setHidden:%d] frame=%@
[DuoFaceKB] [UIResponder becomeFirstResponder] class=%@ ret=%d
[DuoFaceKB] [UIResponder resignFirstResponder] class=%@ ret=%d
[DuoFaceKB] [UITextEffectsWindow setAlpha:%.2f]
[DuoFaceKB] [UITextEffectsWindow setHidden:%d] frame=%@
[DuoFaceKB] activeImpl=%@ inHWMode=%d autoMin=%d inMode=%@ kpName=%@
[DuoFaceKB] layoutStar=%@ frame=%@ bounds=%@ hidden=%d alpha=%.2f subviews=%lu sublayers=%lu
[DuoFaceKB] setDelegate exception: %@
[DuoFaceKB] viewDidAppear inspection exception: %@
[DuoFaceLicense] %@
[DuoFaceLicense] Automated sync attempt detected from another process %llu s ago (< 10s cooldown). Skipping duplicate trigger.
[DuoFaceLicense] Automated sync was already initiated %llu s ago (< 10s cooldown). Skipping duplicate trigger.
[DuoFaceLicense] Dispatching async license sync request to %@ for HW: %@ (source: %@)
[DuoFaceLicense] License refresh interval reached (interval=%llu s, last=%llu s, now=%llu s). Triggering background refresh...
[DuoFaceLicense] Network request failed: %@
[DuoFaceLicense] Offline license is valid (rem: %llu s). Next refresh in %llu s. Using cached license.
[DuoFaceLicense] Server returned non-200 status code: %ld (Error: %@)
[DuoFaceLicense] Warning: Ignoring invalid/negative expiration header: %@
[DuoFaceLicense] Warning: Ignoring invalid/negative expiration in JSON: %@
[DuoFaceSB] >>> AUTO-LAUNCHING/RESUMING APP AFTER CARPLAY CONNECT: %@ <<<
[DuoFaceSB] >>> PRE-RENDER CHECK <<< CarPlay Screen: %@, UsableCanvas: %@, RenderCanvas: %@
[DuoFaceSB] CarPlay display already present at init, scheduling auto-resume for: %@
[DuoFaceSB] Close All (Fallback): Killing background PID %d for %@
[DuoFaceSB] Close All: Killing background PID %d for %@
[DuoFaceSB] Currently active app %@ was disabled -> deactivating
[DuoFaceSB] Exception in notifyStateUpdated file write: %@
[DuoFaceSB] Exception while terminating %@: %@
[DuoFaceSB] Killing process %d for %@
[DuoFaceSB] Live replacing slot %ld with %@
[DuoFaceSB] Live switching split preset to %ld, apps: %@
[DuoFaceSB] Metrics updated: %@
[DuoFaceSB] Posting NOTIFY_APP_STATE to %@: %@
[DuoFaceSB] Restart single app: Killing PID %d for %@
[DuoFaceSB] Restart: Killing PID %d for %@
[DuoFaceSB] Restarting slot %ld for app: %@
[DuoFaceSB] Session tracked bridged app: %@ (Total: %lu)
[DuoFaceSB] UI closeSingleAppTapped: %@
[DuoFaceSB] UI restartSingleAppTapped: %@
[DuoFaceSB] Warning: Exception in CBExtractBundleIDFromScene: %@
[DuoFaceSB] Warning: Exception in updateSettings:withTransitionContext: %@
[DuoFaceSB] Warning: Exception killing background process %@: %@
[DuoFaceSB] Warning: Exception reading auto-resume bid: %@
[DuoFaceSB] Warning: Exception setting scene association for %@: %@
[DuoFaceSB] Warning: Failed to write bridge state file(s) (state=%d, tmp=%d)
[DuoFaceSB] Warning: Failed to write clear bridge state file(s) (state=%d, tmp=%d)
[DuoFaceSB] Warning: Failed to write notifyStateUpdated file(s) (state=%d, tmp=%d)
[DuoFaceSB] [CONNECT_TRACE] CarPlay CADisplay available: %@
[DuoFaceSB] [CONNECT_TRACE] Detected autoResume/autoLaunch BundleID: %@, scheduling launch...
[DuoFaceSB] [CONNECT_TRACE] Ignoring rapid screen connect flap (%.2fs since last connect).
[DuoFaceSB] [CONNECT_TRACE] handleScreenDidConnect triggered. Object screen: %@
[DuoFaceSB] [DISCONNECT_TRACE]   - CADisplay[%lu]: %@ | name: %@ | uid: %@ | isMain: %d | screenType: %u
[DuoFaceSB] [DISCONNECT_TRACE]   - Screen[%lu]: %@ | bounds: %@ | scale: %.1f | isMain: %d
[DuoFaceSB] [DISCONNECT_TRACE] -> Sending shouldBridge:NO to child app: %@
[DuoFaceSB] [DISCONNECT_TRACE] -> Sending shouldBridge:NO to single app: %@
[DuoFaceSB] [DISCONNECT_TRACE] === Screen & Display State Dump (%@) ===
[DuoFaceSB] [DISCONNECT_TRACE] >>> MANDATORY 1-MIN WATCHDOG EXPIRED: Unconditionally terminating %lu CarPlay session app(s) (ZERO EXCEPTION) <<<
[DuoFaceSB] [DISCONNECT_TRACE] >>> MANDATORY 1-MIN WATCHDOG STARTED (token: %llu): %lu app(s) scheduled for forced termination in %d seconds <<<
[DuoFaceSB] [DISCONNECT_TRACE] Cancelling mandatory disconnect watchdog (CarPlay reconnected, newToken: %llu).
[DuoFaceSB] [DISCONNECT_TRACE] Current state -> activated: %d, bundleID: %@, currentApp: %@, sessionBridgedCount: %lu
[DuoFaceSB] [DISCONNECT_TRACE] Darwin screen/CarPlay notification fired: %@
[DuoFaceSB] [DISCONNECT_TRACE] DashBoard process exited (%@) -> Ensuring CarPlay disconnect cleanup in SpringBoard!
[DuoFaceSB] [DISCONNECT_TRACE] Deactivating SplitApp (DuoFace) with %lu appViews
[DuoFaceSB] [DISCONNECT_TRACE] Disconnect watchdog GCD block fired but token %llu is obsolete (current: %llu) -> Cancelled.
[DuoFaceSB] [DISCONNECT_TRACE] Exception while forcibly terminating %@: %@
[DuoFaceSB] [DISCONNECT_TRACE] Mandatory Watchdog: Forcibly terminating PID %d for %@ (Zero Exception)
[DuoFaceSB] [DISCONNECT_TRACE] NSNotificationCenter received: name=%@ | object=%@ | userInfo=%@
[DuoFaceSB] [DISCONNECT_TRACE] Preserved autoResumeBundleID before disconnect: %@
[DuoFaceSB] [DISCONNECT_TRACE] Query Results -> carPlayCADisplay: %@ | carPlayUIScreen: %@ | carPlayWindowScene: %@
[DuoFaceSB] [DISCONNECT_TRACE] Stopping and removing _currentApp (%@)...
[DuoFaceSB] [DISCONNECT_TRACE] Total CADisplay count: %lu
[DuoFaceSB] [DISCONNECT_TRACE] Total UIScreen count: %lu
[DuoFaceSB] [DISCONNECT_TRACE] deactivateCurrentApp START -> activated: %d, bundleID: %@, currentApp: %@
[DuoFaceSB] [DISCONNECT_TRACE] handleCarPlayConnectionChanged notification: %@
[DuoFaceSB] [DISCONNECT_TRACE] handleScreenDidDisconnect triggered. Object screen: %@ (notif=%@)
[DuoFaceSB] [LICENSE_KILL_TRACE] -> App %@ PID not active or already terminated.
[DuoFaceSB] [LICENSE_KILL_TRACE] -> Found active Split slot %ld app: %@
[DuoFaceSB] [LICENSE_KILL_TRACE] -> Found active single app: %@
[DuoFaceSB] [LICENSE_KILL_TRACE] -> Found running background bridged app: %@ (PID: %@)
[DuoFaceSB] [LICENSE_KILL_TRACE] -> FrontBoard resolved PID %d for %@
[DuoFaceSB] [LICENSE_KILL_TRACE] -> KILLING PID %d for %@ via SIGKILL (POSIX signal 9)...
[DuoFaceSB] [LICENSE_KILL_TRACE] -> SpringBoard resolved PID %d for %@
[DuoFaceSB] [LICENSE_KILL_TRACE] -> kill(%d, SIGKILL) returned result: %d
[DuoFaceSB] [LICENSE_KILL_TRACE] >>> IMMEDIATE KILL EXECUTION: Forcibly killing %lu application(s) <<<
[DuoFaceSB] [LICENSE_KILL_TRACE] Adding %lu session-tracked bridged apps: %@
[DuoFaceSB] [LICENSE_KILL_TRACE] Cleared %lu entries from _sessionBridgedBundleIDs.
[DuoFaceSB] [LICENSE_KILL_TRACE] Exception while forcibly terminating %@: %@
[DuoFaceSB] [LICENSE_KILL_TRACE] Scanning Split Screen (%lu slots) for active apps...
[DuoFaceSB] [LICENSE_KILL_TRACE] Skipping protected system/internal BID: %@
[DuoFaceSB] [LICENSE_KILL_TRACE] Step 3: Presenting license warning modal (type=%ld)...
[DuoFaceSB] [LICENSE_KILL_TRACE] Step 4: Immediately killing all %lu targeted CarPlay app processes...
[DuoFaceSB] [LICENSE_KILL_TRACE] Terminating app: %@ (sending shouldBridge:NO)...
[DuoFaceSB] [LICENSE_KILL_TRACE] Total apps targeted for immediate termination: %lu %@
[DuoFaceSB] [LICENSE_KILL_TRACE] handleSettingsChanged: License expired/invalid during settings sync (loaded=%d, status=%d, mask=0x%llx). Deactivating and presenting modal.
[DuoFaceSB] [LICENSE_KILL_TRACE] licenseWatchdogTimerFired: Runtime license expired or invalid during session (loaded=%d, status=%d, mask=0x%llx).
[DuoFaceSB] [LICENSE_KILL_TRACE] loadNewAppFromCurrentRequest: License validation failed (loaded=%d, status=%d, mask=0x%llx) for bid=%@.
[DuoFaceSB] [LICENSE_KILL_TRACE] reconfigureSplitMode: License invalid (loaded=%d, status=%d, mask=0x%llx). Aborting split configuration.
[DuoFaceSB] [LICENSE_KILL_TRACE] requestStateChange: App %@ active but license invalid (loaded=%d, status=%d, mask=0x%llx).
[DuoFaceSB] evictAppFromPhoneScreen exception: %@
[DuoFaceSB] performAutoResume: CarPlay CADisplay not ready, retrying #%ld in 1.0s...
[DuoFaceSB] performAutoResume: License is inactive/expired (loaded=%d, status=%d). Skipping auto-launch.
[DuoFaceSB] receivedAppRequestNotification for: %@
[DuoFaceSB] requestStateChange: App %@ already active and visible, re-showing window.
[DuoFaceSB] requestStateChange: App %@ marked active but window/display stale or detached (e.g. after CarPlay reconnect). Performing clean reload...
[DuoFaceSB] restartApplicationWithBundleID: %@
[DuoFaceSB] saveBridgeStateToDisk: %@
[DuoFaceSB] syncDashboardPolicySignalToDisk: isValid=%d, exp=%llu, ts=%llu
[DuoFaceSB] terminateApplicationWithBundleID: %@
[DuoFaceWindow] createWindows completed: _rootWindow=%@, rootVC=%@, screenBounds=%@, usableBounds=%@, config=%@
[DuoFaceWindow] resizeWindows completed: screenBounds=%@, usableBounds=%@
[DuoFaceWindow] show: _rootWindow=%@, frame=%@, hidden=%d, level=%.1f
[DuoFace] %@
[DuoFace] Acquired PreventUserIdleSystemSleep assertion result: %d, id: %u
[DuoFace] Assistant start exception: %@
[DuoFace] Assistant stop exception: %@
[DuoFace] Assistant toggle exception: %@
[DuoFace] Client App Modular Hooks initialized successfully for: %@
[DuoFace] Dynamically updated tweak filter plist with %lu bundles
[DuoFace] Initializing App hooks for target app: %@
[DuoFace] Initializing Client App Modular Hooks for: %@...
[DuoFace] Initializing DashBoard hooks in process: %@
[DuoFace] Released PreventUserIdleSystemSleep assertion id: %u
[DuoFace] SBAppViewController didUpdateSettingsWithDiff exception: %@
[DuoFace] Tweak constructor loaded in process: %@ (PID %d)
[DuoFace] Warning: Failed writing to log file: %@
[DuoFace] _applyUpdate error: %@
[DuoFace] carPlayCADisplay exception: %@
[DuoFace] updateSceneSettingsFrame: scene not yet ready: %@
[DuoFace] updateSettingsWithBlock error: %@
[DuoFace_DEBUG] resolvedBackendBaseURL Tier 1 (File Override): %@
[DuoFace_DEBUG] resolvedBackendBaseURL Tier 2 (Plist Override): %@
[DuoFace_DEBUG] resolvedBackendBaseURL Tier 3 (Production Default): %@

### 6.3 DuoFaceFullscreenBridge (544 chuỗi duy nhất)

FullscreenBridge: total unique strings=544

## reverse-dns ids (6)
com.apple.carplay
com.apple.carplayapp
com.apple.dashboard
com.duoface.fullscreen.command.v1
com.duoface.fullscreen.picker.v1
com.duoface.fullscreen.state.v1

## url/scheme (1)
radr://5614542

## paths (12)
/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation
/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics
/System/Library/Frameworks/Foundation.framework/Foundation
/System/Library/Frameworks/UIKit.framework/UIKit
/usr/lib/libSystem.B.dylib
/usr/lib/libc++.1.dylib
/usr/lib/libobjc.A.dylib
/var/jb/Library/Application Support/DuoFace/duoface-logo.png
/var/jb/Library/Frameworks
/var/jb/usr/lib
@loader_path/.jbroot/Library/Frameworks
@loader_path/.jbroot/usr/lib

## log formats (10)
[DuoFaceFullscreen] Zoom Out failed %@
[DuoFaceFullscreen] bootstrap pending picker=%d transport=%d
[DuoFaceFullscreen] candidate adapter started in %@
[DuoFaceFullscreen] candidate adapter unavailable in %@ after class-load retries
[DuoFaceFullscreen] host geometry applied %@
[DuoFaceFullscreen] host restored sameOwner=%d
[DuoFaceFullscreen] native picker zoom requested=%d
[DuoFaceFullscreen] picker sheet width invalid %.1f
[DuoFaceFullscreen] rollback %@
[DuoFaceFullscreen] rollback restored=%d %@

### 6.4 DuoFaceVisualHook (317 chuỗi duy nhất)

VisualHook: total unique strings=317

## reverse-dns ids (0)

## url/scheme (0)

## paths (10)
/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation
/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics
/System/Library/Frameworks/Foundation.framework/Foundation
/System/Library/Frameworks/QuartzCore.framework/QuartzCore
/System/Library/Frameworks/UIKit.framework/UIKit
/usr/lib/libSystem.B.dylib
/usr/lib/libobjc.A.dylib
/usr/lib/libsubstrate.dylib
/var/jb/Library/Application Support/DuoFace/
/var/jb/usr/lib/libsubstrate.dylib

## log formats (5)
[DuoFaceBorder] RED OFF native idle view=%p
[DuoFaceBorder] RED ON user activity view=%p focus=%d
[DuoFaceBorder] install %@ start=%p stop=%p focus=%p restore=%p
[DuoFaceBorder] signature mismatch start=%s stop=%s
[DuoFaceVisual12] splash %@ applied; original loading untouched

### 6.5 duoface_cboptimize_helper (149 chuỗi duy nhất)

Helper: total unique strings=149

## reverse-dns ids (0)

## url/scheme (1)
radr://5614542

## paths (12)
/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation
/System/Library/Frameworks/IOKit.framework/Versions/A/IOKit
/System/Library/Frameworks/Security.framework/Security
/usr/lib/dyld
/usr/lib/libSystem.B.dylib
/var/jb/Library/Frameworks
/var/jb/bin/sh
/var/jb/usr/bin/cboptimize
/var/jb/usr/bin/sh
/var/jb/usr/lib
@loader_path/.jbroot/Library/Frameworks
@loader_path/.jbroot/usr/lib

## log formats (0)

---

## 7. Cơ chế A→Z

### 7.1 Bản đồ thành phần × tiến trình

| Thành phần | Tiến trình nó sống trong | Vai trò |
|---|---|---|
| `DuoFaceDashboard.dylib` | SpringBoard, Dashboard, CarPlay/CarPlayApp, **và từng app được bridge** (YouTube, Maps, Waze, Netflix, Spotify, Safari, Chrome, Music, Notes, Phone, Preferences, BarcodeScanner, DuoFaceUI…) theo filter 24 bundle (Mục 3.2) | Lõi: quản lý phiên bridge phía SpringBoard, chặn icon phía Dashboard, thành phần trong-app, bàn phím, metrics màn xe, license |
| `DuoFaceFullscreenBridge.dylib` | SpringBoard, Dashboard, CarPlay, CarPlayApp (filter Bundles + Executables) | Nới khung host ra toàn màn hình, ẩn/hiện chrome, menu zoom picker |
| `DuoFaceVisualHook.dylib` | SpringBoard, Dashboard, CarPlay, CarPlayApp, DuoFaceUI | Viền đỏ quanh ô đang focus + layout pill/divider/splash (đúng hậu tố build `border-focus-red3`) |
| `DuoFaceUI.app` | Tiến trình app riêng | Cấu hình (apps được bridge, split, auto-launch…), subscription/license, optimizer |
| `duoface_cboptimize_helper` + `duoface-cboptimize` | Chạy theo lệnh (helper setuid root) | Lấy hardware hash; tắt/bật 12 daemon hệ thống, dọn log |

Trong Dashboard, các "vai" phân biệt bằng tiền tố chuỗi log: `[DuoFaceSB]` (SpringBoard), `[DuoFaceDB]` (Dashboard/Home), `[DuoFaceApp]` (trong app được bridge), `[DuoFaceKB]` (bàn phím), `[DuoFaceCarPlay]` (metrics màn xe), `[DuoFaceWindow]` (cửa sổ gốc), `[DuoFaceLicense]` (dùng chung với app UI).

### 7.2 Điểm nạp → khởi tạo

1. MobileSubstrate/ElleKit đọc filter plist cạnh mỗi dylib; tiến trình nào có bundle id khớp thì dylib được nạp vào lúc tiến trình khởi động *(plist)*.
2. Không binary nào có class `+load` (danh sách `__objc_nlclslist` rỗng ở cả 5 binary) — khởi tạo đi qua constructor C:
   - Dashboard: 2 constructor (0x6258 + 0x2a803c ở arm64; 0x62f0 + 0x2aeff0 ở arm64e).
   - FullscreenBridge: 1 init function tại offset 0x4000 (`__init_offsets`).
   - VisualHook: `_DFInit` (0x4000) → đăng ký `_DFImageAdded` qua `_dyld_register_func_for_add_image` *(symbol)* — chờ image đích nạp xong mới cài (`_DFInstall`, `_DFInstallBorderRunner`), có cờ chống cài trùng `_DFInstall.triedLibrary`, `_DFBorderHooksInstalled`…

### 7.3 Kênh liên tiến trình (3 kênh chạy song song)

1. **File trạng thái trong `/var/tmp`** *(script + chuỗi)*: `/var/tmp/com.duoface.bridgestate.plist` (+ bản legacy `/var/tmp/com.tiz.carbridge.bridgestate.plist`) được postinst đặt 0666 để mọi tiến trình (kể cả app sandbox) đều ghi/đọc được. Dashboard phía SpringBoard ghi trạng thái (`saveBridgeStateToDisk: %@`, `notifyStateUpdated` — log có cả nhánh lỗi ghi file), phía app đọc lại (`checkStateFile: bid=%@, dict=%@`, `Activated via disk state file: size={%.1f, %.1f}, o=%ld, isSplit=%d`). Thêm file `/var/tmp/carbridge_autoresume_bid` chứa bundle id để tự khôi phục phiên.
2. **Darwin notify / CFNotificationCenter Darwin** *(symbol + chuỗi, Mục 5.3)*: sự kiện hệ thống (CarPlay connect/disconnect, screen state) + kênh riêng của tweak (`NOTIFY_APP_STATE`, `NOTIFY_APP_REQUEST` theo tên macro trong log) + 3 kênh fullscreen `com.duoface.fullscreen.command.v1` / `.state.v1` / `.picker.v1`.
3. **File yêu cầu (request plist)**: class `CBBridgeRequest` (Mục 4.2); phía app/Dashboard ghi yêu cầu kích hoạt (log: `Failed to write request plist`, `Failed to save request plist: %@`), phía SpringBoard nhận qua `receivedAppRequestNotification for: %@` và `requestActivation called for bundleID=%@ (pending=%d)`.

### 7.4 Luồng chính: đưa app thường lên màn hình xe

1. **Bơm icon vào CarPlay Home** *(chuỗi [DuoFaceDB])*: hook `FBSApplicationLibrary allInstalledApplications` và `CARIconModel` để các app trong danh sách `bridgedApps` xuất hiện trên lưới icon CarPlay dù không có entitlement CarPlay gốc (`injected special app: %@`, `Explicitly adding leaf icon %@ to CARIconModel`, `…to rootFolder`).
2. **Chặn cú chạm icon** *(chuỗi [DuoFaceDB])*: các hook icon ở Mục 5.2 kiểm tra `isBridged`; nếu là app được bridge thì chặn đường launcher gốc (`intercepted bridged app tap: %@`) và phát yêu cầu kích hoạt qua kênh ở Mục 7.3 thay vì mở app trên điện thoại.
3. **SpringBoard dựng sân khấu** *(metadata + chuỗi [DuoFaceSB]/[DuoFaceWindow]/[DuoFaceCarPlay])*:
   - `CBBridgeManager` (73 method) + `CBBridgeManagerDashboard` (33 method) điều phối phiên; `CBWindow` (28+9 method) tạo cửa sổ gốc trên display xe (`createWindows completed: _rootWindow=%@, rootVC=%@, screenBounds=%@, usableBounds=%@`).
   - Metrics màn xe được tính và ghi ra file đường dẫn dock/inset/screen (`updateCarPlayMetrics: Screen=%@, Insets=%@, Edge=%@`, `Failed to write dock path/inset path/screen path`).
   - Scene của app đích được host vào ô: một ô toàn màn (`CBBridgedUIApp`/`CBBridgedPortalApp`) hoặc chia ô (`CBBridgedSplitApp` 49 method, `CBSplitContainerView`, `CBSlotPlaceholderView`, thanh chia kéo được `CBDividerView` 27 method + `CBDividerButtonInfo`, pill chuyển ô `CBSlotPillView` 36 method/`CBMultitaskingPillView`, lớp phủ đa nhiệm chọn app `CBMultitaskingOverlayView` 66 method, `CBTouchCloneView` — view nhân bản cảm ứng).
   - Vòng đời phiên: connect → tự chạy/khôi phục app đã chọn (`AUTO-LAUNCHING/RESUMING APP AFTER CARPLAY CONNECT`, chống "flap" kết nối nhanh); disconnect → gửi `shouldBridge:NO` cho các app, hủy watchdog nếu reconnect, hết 60 giây thì terminate bắt buộc toàn bộ app của phiên (`MANDATORY 1-MIN WATCHDOG … ZERO EXCEPTION`); có đường tắt tiến trình cho "Close All"/"Restart" từng app (`kill(%d, SIGKILL)`).
4. **Phía trong app được bridge** *(chuỗi [DuoFaceApp])*: cùng dylib (nạp theo filter) nhận trạng thái, tự đưa mình về foreground phục vụ trình diễn (`Waking app to active foreground state for CarPlay presentation: %@`), tự relayout theo kích thước ô được cấp, và tự trả về "phone mode" khi nhận tin không còn bridged.
5. **Bàn phím** *(chuỗi [DuoFaceKB], Mục 5.2)*: sửa tên bàn phím/keyplane và input mode để bàn phím của app được host hiện đúng trong ngữ cảnh CarPlay (thêm tiền tố vào keyboard name, chữa nil/(null), ép input mode dự phòng, theo dõi `UIKeyboardLayoutStar`/`UIRemoteKeyboardWindow`/`UITextEffectsWindow`).
6. **Trợ lý giọng nói & điều hướng** *(metadata + chuỗi)*: `CBAssistantManager` (68 method); Dashboard khai báo tuân thủ `SFSpeechRecognizerDelegate` và `AVSpeechSynthesizerDelegate` (danh sách protocol đã parse); chuỗi URL nhận dạng giọng nói Google `https://www.google.com/speech-api/v2/recognize?client=chromium&lang=vi-VN&key=%@&maxresults=5&pFilter=0` song song Speech.framework (link yếu); deep link mở điều hướng `comgooglemaps://?daddr=%@&directionsmode=driving`, `waze://?q=%@&navigate=yes`, `http://maps.apple.com/?daddr=%@&dirflg=d`, tìm kiếm `youtube://results?search_query=%@` / `https://m.youtube.com/results?search_query=%@`. Dashboard còn đọc cơ sở dữ liệu TCC qua libsqlite3 với các đường dẫn `/var/mobile/Library/TCC/TCC.db`, `/Library/TCC/TCC.db`, `/var/jb/var/mobile/Library/TCC/TCC.db` *(chuỗi + thư viện liên kết)* — mục đích cụ thể của việc đọc TCC không ghi trong chuỗi (Mục 10).

### 7.5 Fullscreen và viền focus

- **FullscreenBridge**: `DFFullscreenTransport` (36 method) vận chuyển lệnh/trạng thái qua 3 kênh Darwin ở Mục 5.3; `DFHostSnapshot` (23 method) chụp trạng thái hình học host; `_DFInstallHostGeometryHooks` nới host (`host geometry applied %@`), `_DFDashboardSetChromeHidden`/`_DFDashboardRestoreChrome` ẩn/khôi phục chrome, `_DFInstallPickerZoomMenuHooks` thêm menu zoom cho picker. Cơ chế an toàn: thử nạp adapter theo lần thử chờ class (`candidate adapter started/unavailable in %@ after class-load retries`), không được thì rollback (`rollback restored=%d %@`) và khôi phục host (`host restored sameOwner=%d`).
- **VisualHook**: duy trì tập view viền đã biết (`_DFKnownBorderViewsFor`, associated objects), bật viền đỏ khi người dùng thao tác (`RED ON user activity … focus=%d`), tắt khi về native idle (`RED OFF native idle`), và áp layout cho pill/divider/splash. Các ô callback `_DFNative*` (Mục 4.4) là nơi phía Dashboard đăng ký hành vi start/stop/focus/restore vào — khớp chuỗi `[DuoFaceBorder] install %@ start=%p stop=%p focus=%p restore=%p`.

### 7.6 "System Optimizer" và helper root

- **Script `/var/jb/usr/bin/duoface-cboptimize`** (đã đọc toàn văn 3.364 bytes): tham số `status|optimize|restore|clean-logs` (mặc định `status`).
  - `optimize`: dùng launchctl `disable` + `kill SIGKILL` với **12 daemon**: `com.apple.ReportCrash`, `com.apple.ReportCrash.SimulateCrash`, `com.apple.AggregateDictionary.addaily`, `com.apple.symptomsd-diag`, `com.apple.healthd`, `com.apple.healthrecordsd`, `com.apple.OTATaskingAgent`, `com.apple.softwareupdated`, `com.apple.triald`, `com.apple.biomesyncd`, `com.apple.routined`, `com.apple.duetexpertd`; xóa toàn bộ `/var/mobile/Library/Logs/CrashReporter/*` và `/Library/Logs/CrashReporter/*`; truncate 4 file log `/var/mobile/duoface.log`, `duoface_live.log`, `carbridge.log`, `carbridge_live.log`.
  - `restore`: `enable` lại đúng 12 daemon đó. `clean-logs`: chỉ phần dọn log. `status`: in `uptime`, `vm_stat`, `launchctl print-disabled system`.
  - Preferences mặc định có `systemOptimizerEnabled = true` *(script postinst)*.
- **Helper setuid root**: in hardware hash với `--hw-hash`/`-hwhash` *(chuỗi)*, đọc thuộc tính qua IOKit registry + `sysctlbyname` *(symbol)*, và chứa đường thực thi `/var/jb/usr/bin/cboptimize` qua `/var/jb/bin/sh` với `posix_spawn` *(chuỗi + symbol)*. Đường gọi tổng thể được bảo trợ thêm bởi sudoers drop-in `ALL ALL=(ALL) NOPASSWD: ALL` *(file)*.
- `prerm` không khôi phục gì khi gỡ gói (Mục 1.3.3) — daemon đã `disable` sẽ giữ nguyên trạng thái đó sau khi gỡ, theo đúng nội dung script.

### 7.7 License / lease / subscription

- **Dùng chung code**: `CBLicenseSyncManager` (24 instance + 6 class method) và `CBHttpClient` (`postJSON:toURL:timeout:customHeaders:completion:`, `getJSONFromURL:timeout:customHeaders:completion:`, `+sharedClient`) xuất hiện **giống hệt nhau** trong cả DuoFaceUI và DuoFaceDashboard (đã đối chiếu bảng method) — license được kiểm tra cả trong app cấu hình lẫn trong tiến trình xe.
- **Định danh máy**: hardware hash (Mục 7.6) đi kèm yêu cầu đồng bộ: `Dispatching async license sync request to %@ for HW: %@ (source: %@)`; app UI có riêng cell hiển thị `CBSubscriptionHardwareIDCell`.
- **Địa chỉ backend**: hàm `resolvedBackendBaseURL` phân giải 3 tầng *(chuỗi [DuoFace_DEBUG])*: Tier 1 — File Override, Tier 2 — Plist Override, Tier 3 — Production Default. Host tĩnh duy nhất xuất hiện dạng rõ là `duoface.com`; User-Agent `DuoFace-Client/1.0.3` *(chuỗi)*. URL đầy đủ không nằm dạng một literal (Mục 10).
- **Chu kỳ đồng bộ** *(chuỗi [DuoFaceLicense])*: chống trùng lặp liên tiến trình bằng cooldown 10 giây (`Automated sync attempt detected from another process %llu s ago (< 10s cooldown)`); đến hạn refresh thì đồng bộ nền; mất mạng thì dùng lease cache (`Offline license is valid (rem: %llu s). Next refresh in %llu s. Using cached license.`); hạn dùng đọc từ HTTP header hoặc JSON (có cảnh báo khi giá trị âm/không hợp lệ); HTTP khác 200 → ghi lỗi.
- **Trạng thái bền**: file `com.duonavi.sync.plist` (Mục 8.3) với `status`, `lastSyncTimestamp`, `lastAttemptTimestamp`, `leaseSeconds`, `expiresAt`, `actualExpireTimestamp`.
- **Khi license không hợp lệ** *(chuỗi [DuoFaceDB]/[DuoFaceSB])*:
  - App CarPlay native: cho qua launcher gốc (`License inactive/expired for native CarPlay app %@ -> PASS-THROUGH to native launcher`; `effectivePolicyForAppDeclaration: policy signal inactive for native app %@ -> 100% %orig pass-through`).
  - App không native: chặn và hiện modal cảnh báo (`INTERCEPTING to present warning modal`; `CBLicenseWarningModalView` phía Dashboard, `CBLicenseExpiredModalViewController` phía app).
  - App đang chạy trong phiên: chuỗi `[LICENSE_KILL_TRACE]` — deactivate, hiện modal, rồi **kill SIGKILL mọi app đã bridge trong phiên** (bỏ qua các bundle id hệ thống/nội bộ được bảo vệ), kèm watchdog license định kỳ trong phiên (`licenseWatchdogTimerFired`, `handleSettingsChanged: License expired/invalid during settings sync…`). Dashboard còn ghi "policy signal" ra đĩa để các tiến trình khác cùng biết (`syncDashboardPolicySignalToDisk: isValid=%d, exp=%llu, ts=%llu`).
- **Mua/gia hạn trong app**: `CBSubscriptionViewController` (71 method), `CBSubscriptionOrderCoordinator` (36 method, các delegate protocol `CBSubscriptionOrderCoordinatorDelegate`, `CBSubscriptionCheckoutCellDelegate`, `CBSubscriptionPendingOrderCellDelegate`, `CBSubscriptionGiftcodeInputCellDelegate`, `CBSubscriptionGiftcodeRedeemCellDelegate`, `CBSubscriptionHardwareIDCellDelegate`), các cell Checkout / PlanCard / VIPCard / VIPStatus / Status / PendingOrder / GiftcodeInput / GiftcodeRedeem / HardwareID, và `SFSafariViewControllerDelegate` (mở trang web trong Safari View Controller). Có cơ chế giftcode (nhập + redeem) và đơn chờ (pending order).

---

## 8. Tài nguyên và cấu hình kèm gói

### 8.1 `DuoFaceUI.app/Info.plist` (2.303 bytes)

| Key | Giá trị |
|---|---|
| CFBundleIdentifier | `com.duoface.duofaceui` |
| CFBundleName / CFBundleDisplayName | `DuoFace` / `DuoFace` |
| CFBundleExecutable | `DuoFaceUI` |
| CFBundleVersion / CFBundleShortVersionString | `1.0.0` / `1.0.0` |
| CFBundlePackageType / CFBundleSignature | `APPL` / `????` |
| CFBundleSupportedPlatforms | `[iPhoneOS]` |
| LSRequiresIPhoneOS | `true` |
| UIDeviceFamily | `[1, 2]` (iPhone + iPad) |
| UIRequiredDeviceCapabilities | `[arm64]` |
| UISupportedInterfaceOrientations | Portrait, LandscapeLeft, LandscapeRight |
| CFBundleIconFile / CFBundleIconFiles | `AppIcon60x60`; bộ `AppIcon29x29…AppIcon76x76` (+ biến thể `~ipad`) |

**Các key KHÔNG có** (đã kiểm tra toàn bộ file): không `CFBundleURLTypes` (app không đăng ký URL scheme nào), không `UIBackgroundModes`, không key xin quyền `NS…UsageDescription` nào, không `UIAppFonts`, không `NSExtension`.

### 8.2 Preferences mặc định do postinst ghi (`/var/mobile/Library/Preferences/com.duoface.plist`)

| Key | Giá trị mặc định |
|---|---|
| `bridgedApps` | `[com.google.Maps, com.apple.Maps, com.google.ios.youtube, com.apple.Music, com.apple.podcasts, com.apple.tv, com.ss.iphone.ugc.Ame, com.ss.iphone.ugc.tiktok.lite, vn.com.vng.zingalo]` |
| `userAppsDefaultInitialized` | `true` |
| `splitScreenEnabled` | `true` |
| `autoLaunchOnConnect` | `true` |
| `autoLaunchBundleID` | `com.apple.BarcodeScanner` |
| `systemOptimizerEnabled` | `true` |

Domain preferences chính là `com.duoface`; domain legacy được migrate là `com.tiz.carbridge` *(script)*. Lớp settings trong Dashboard là `CBDashboardSettings` (56+5 method, bảng ở Mục 4.2) và phía app là `CBGeneralSettingsViewController` (30 method) + `CBAppManager`/`CBAppsManagerViewController`/`CBAppPickerViewController` quản lý danh sách app.

### 8.3 `com.duonavi.sync.plist` — trạng thái license đóng gói sẵn trong deb

File này được cài thẳng vào `/var/mobile/Library/Preferences/com.duonavi.sync.plist` (531 bytes) — tức máy nào cài gói cũng nhận cùng một bản trạng thái này:

| Key | Giá trị thô | Diễn giải |
|---|---|---|
| `status` | `SUCCESS` | |
| `lastSyncTimestamp` | 1791604360 | 10/10/2026 10:52:40 (+07) |
| `lastAttemptTimestamp` | 1791700039 | 11/10/2026 13:27:19 (+07) |
| `leaseSeconds` | 157766400 | 1.826 ngày ≈ 5 năm |
| `expiresAt` | 1949370760 | 10/10/2031 10:52:40 (+07) |
| `actualExpireTimestamp` | 1949370760 | trùng `expiresAt` |

Kiểm tra nhất quán nội bộ: `expiresAt − lastSyncTimestamp = 157766400 = leaseSeconds` — khớp tuyệt đối.

### 8.4 Ảnh và `asset-manifest.json`

Thư mục `/var/jb/Library/Application Support/DuoFace/` chứa: `duoface-logo.png` (960×240), `duoface-logo-vert.png` (640×640), `duoface-icon.png` (256×256), `VisualAssets/duoface-swap.png` (120×120), `VisualAssets/duoface-fullscreen.png` (88×88), `VisualAssets/duoface-picker.png` (256×70) — kích thước theo `asset-manifest.json` và **SHA256 của cả 6 file khớp với mục `outputs` trong manifest** (đã đối chiếu từng file với bảng ở Mục 2). Manifest ghi nguồn là `DuoFace_5_images_REVIEW_before_upload.zip` kèm SHA256 của 5 ảnh gốc và thông số crop panel logo (horizontal/vertical).

Đường đọc ảnh lúc chạy *(chuỗi)*: VisualHook dùng thư mục `/var/jb/Library/Application Support/DuoFace/`; FullscreenBridge trỏ thẳng `…/DuoFace/duoface-logo.png`. Dashboard còn chứa chuỗi đường dẫn biến thể rootful (không tiền tố `/var/jb`) và biến thể thư mục `CarBridge` cho `AssistantAppIcon.png`, `PortalAppIcon.png`, `duoface-icon.png`, `duoface-logo.png` — hai file `AssistantAppIcon.png`/`PortalAppIcon.png` **không có trong gói này** (chỉ có chuỗi tham chiếu).

### 8.5 Sudoers drop-in

`/var/jb/etc/sudoers.d/duoface` (28 bytes), toàn văn: `ALL ALL=(ALL) NOPASSWD: ALL`. Postinst đặt file này (và file `carbridge` nếu tồn tại) về owner root, quyền 0440 *(script)*.

---

## 9. Phụ lục — dump Mach-O đầy đủ từng binary (cả hai slice)

Nội dung dưới đây là đầu ra nguyên văn của parser tĩnh: header, toàn bộ load commands, segments/sections, chữ ký số (superblob + CodeDirectory ident), entitlements (nếu có), bảng symbol định nghĩa/chưa định nghĩa, exports trie, danh sách constructor, và metadata Objective-C (class/ivar/property/method kèm type encoding). Superclass hiển thị dạng `: None` trong dump thô là do superclass nằm ngoài binary — bản đã khôi phục nằm ở Mục 4.

### 9.1 DuoFaceUI

```
# Mach-O parse: root/var/jb/Applications/DuoFaceUI.app/DuoFaceUI
file size: 2456784  slices: 2

===== SLICE 0: arm64 sub=all (raw subtype 0x0) filetype=EXECUTE flags=0xa00085 off=16384 size=1214224 =====
ncmds=33
load commands: LC_SEGMENT_64, LC_SEGMENT_64, LC_SEGMENT_64, LC_SEGMENT_64, LC_SEGMENT_64, LC_DYLD_INFO_ONLY, LC_SYMTAB, LC_DYSYMTAB, LC_LOAD_DYLINKER, LC_UUID, LC_BUILD_VERSION, LC_SOURCE_VERSION, LC_MAIN, LC_ENCRYPTION_INFO_64, LC_LOAD_DYLIB, LC_LOAD_DYLIB, LC_LOAD_DYLIB, LC_LOAD_DYLIB, LC_LOAD_DYLIB, LC_LOAD_DYLIB, LC_LOAD_DYLIB, LC_LOAD_DYLIB, LC_LOAD_DYLIB, LC_LOAD_DYLIB, LC_LOAD_DYLIB, LC_LOAD_DYLIB, LC_RPATH(REQ), LC_RPATH(REQ), LC_RPATH(REQ), LC_RPATH(REQ), LC_FUNCTION_STARTS, LC_DATA_IN_CODE, LC_CODE_SIGNATURE
id_dylib: None
uuid: 9d789c67bf823c8f812717d1ae50e08e
build_version: ('iOS', '15.0.0', '16.5.0')  min_version: None  source_version: 0.0.0
encryption: (16384, 933888, 0)  main: (29332, 0)  rpaths: ['/var/jb/Library/Frameworks', '/var/jb/usr/lib', '@loader_path/.jbroot/Library/Frameworks', '@loader_path/.jbroot/usr/lib']
codesig: (1204432, 9792) chained_fixups=False dyld_info=True
linked libraries:
  [LC_LOAD_DYLIB] /usr/lib/libobjc.A.dylib cur=228.0.0 compat=1.0.0
  [LC_LOAD_DYLIB] /System/Library/Frameworks/Foundation.framework/Foundation cur=1971.0.0 compat=300.0.0
  [LC_LOAD_DYLIB] /System/Library/Frameworks/CoreFoundation.framework/CoreFoundation cur=1971.0.0 compat=150.0.0
  [LC_LOAD_DYLIB] /System/Library/Frameworks/UIKit.framework/UIKit cur=6441.1.101 compat=1.0.0
  [LC_LOAD_DYLIB] /System/Library/Frameworks/CoreGraphics.framework/CoreGraphics cur=1690.5.4 compat=64.0.0
  [LC_LOAD_DYLIB] /System/Library/Frameworks/QuartzCore.framework/QuartzCore cur=1.11.0 compat=1.2.0
  [LC_LOAD_DYLIB] /System/Library/Frameworks/Security.framework/Security cur=60420.102.1 compat=1.0.0
  [LC_LOAD_DYLIB] /System/Library/Frameworks/IOKit.framework/Versions/A/IOKit cur=275.0.0 compat=1.0.0
  [LC_LOAD_DYLIB] /System/Library/Frameworks/SafariServices.framework/SafariServices cur=1.0.0 compat=1.0.0
  [LC_LOAD_DYLIB] /System/Library/Frameworks/MobileCoreServices.framework/MobileCoreServices cur=1228.0.0 compat=1.0.0
  [LC_LOAD_DYLIB] /usr/lib/libSystem.B.dylib cur=1319.100.3 compat=1.0.0
  [LC_LOAD_DYLIB] /System/Library/Frameworks/CoreServices.framework/CoreServices cur=1228.0.0 compat=1.0.0
segments/sections:
  __TEXT,__text addr=0x100007294 size=636060 off=29332 flags=0x80000400
  __TEXT,__stubs addr=0x1000a2730 size=1128 off=665392 flags=0x80000408
  __TEXT,__stub_helper addr=0x1000a2b98 size=1152 off=666520 flags=0x80000400
  __TEXT,__objc_methlist addr=0x1000a3018 size=6584 off=667672 flags=0x0
  __TEXT,__objc_methname addr=0x1000a49d0 size=27786 off=674256 flags=0x2
  __TEXT,__const addr=0x1000ab660 size=5726 off=702048 flags=0x0
  __TEXT,__gcc_except_tab addr=0x1000accc0 size=876 off=707776 flags=0x0
  __TEXT,__cstring addr=0x1000ad02c size=54076 off=708652 flags=0x2
  __TEXT,__objc_classname addr=0x1000ba368 size=1129 off=762728 flags=0x2
  __TEXT,__objc_methtype addr=0x1000ba7d1 size=6693 off=763857 flags=0x2
  __TEXT,__ustring addr=0x1000bc1f6 size=177864 off=770550 flags=0x0
  __TEXT,__unwind_info addr=0x1000e78c0 size=1852 off=948416 flags=0x0
  __DATA_CONST,__got addr=0x1000e8000 size=312 off=950272 flags=0x6
  __DATA_CONST,__const addr=0x1000e8138 size=4144 off=950584 flags=0x0
