    - segmentedHeaderView  types=@16@0:8
    - setSegmentedHeaderView:  types=v24@0:8@16
    - modeSegmentedControl  types=@16@0:8
    - setModeSegmentedControl:  types=v24@0:8@16
    - currentMode  types=q16@0:8
    - setCurrentMode:  types=v24@0:8q16
    - plansData  types=@16@0:8
    - setPlansData:  types=v24@0:8@16
    - rawPlansData  types=@16@0:8
    - setRawPlansData:  types=v24@0:8@16
    - selectedTierIndex  types=q16@0:8
    - setSelectedTierIndex:  types=v24@0:8q16
    - isLoadingPlans  types=B16@0:8
    - setIsLoadingPlans:  types=v20@0:8B16
    - plansLoadFailed  types=B16@0:8
    - setPlansLoadFailed:  types=v20@0:8B16
    - orderCoordinator  types=@16@0:8
    - setOrderCoordinator:  types=v24@0:8@16
    - isCheckoutLoading  types=B16@0:8
    - setIsCheckoutLoading:  types=v20@0:8B16
    - giftCodeTextField  types=@16@0:8
    - setGiftCodeTextField:  types=v24@0:8@16
    - giftRedeemCell  types=@16@0:8
    - setGiftRedeemCell:  types=v24@0:8@16
    - isGiftRedeeming  types=B16@0:8
    - setIsGiftRedeeming:  types=v20@0:8B16
    - .cxx_destruct  types=v16@0:8

--- @interface CBLicenseExpiredModalViewController : None (instanceSize=88, ro_flags=0x184) ---
  ivars:
    _onActivateTapped : @? offset=8 size=8
    _onDismissTapped : @? offset=16 size=8
    _blurBackdrop : @"UIVisualEffectView" offset=24 size=8
    _dimmerOverlay : @"UIView" offset=32 size=8
    _cardView : @"UIView" offset=40 size=8
    _iconImageView : @"UIImageView" offset=48 size=8
    _titleLabel : @"UILabel" offset=56 size=8
    _messageLabel : @"UILabel" offset=64 size=8
    _activateButton : @"UIButton" offset=72 size=8
    _laterButton : @"UIButton" offset=80 size=8
  properties:
    blurBackdrop  attrs=T@"UIVisualEffectView",&,N,V_blurBackdrop
    dimmerOverlay  attrs=T@"UIView",&,N,V_dimmerOverlay
    cardView  attrs=T@"UIView",&,N,V_cardView
    iconImageView  attrs=T@"UIImageView",&,N,V_iconImageView
    titleLabel  attrs=T@"UILabel",&,N,V_titleLabel
    messageLabel  attrs=T@"UILabel",&,N,V_messageLabel
    activateButton  attrs=T@"UIButton",&,N,V_activateButton
    laterButton  attrs=T@"UIButton",&,N,V_laterButton
    onActivateTapped  attrs=T@?,C,N,V_onActivateTapped
    onDismissTapped  attrs=T@?,C,N,V_onDismissTapped
  instance methods (29):
    - viewDidLoad  types=v16@0:8
    - viewWillAppear:  types=v20@0:8B16
    - setupBackdrop  types=v16@0:8
    - setupCardView  types=v16@0:8
    - setupContent  types=v16@0:8
    - handleActivateTapped  types=v16@0:8
    - handleLaterTapped  types=v16@0:8
    - dismissWithCompletion:  types=v24@0:8@?16
    - onActivateTapped  types=@?16@0:8
    - setOnActivateTapped:  types=v24@0:8@?16
    - onDismissTapped  types=@?16@0:8
    - setOnDismissTapped:  types=v24@0:8@?16
    - blurBackdrop  types=@16@0:8
    - setBlurBackdrop:  types=v24@0:8@16
    - dimmerOverlay  types=@16@0:8
    - setDimmerOverlay:  types=v24@0:8@16
    - cardView  types=@16@0:8
    - setCardView:  types=v24@0:8@16
    - iconImageView  types=@16@0:8
    - setIconImageView:  types=v24@0:8@16
    - titleLabel  types=@16@0:8
    - setTitleLabel:  types=v24@0:8@16
    - messageLabel  types=@16@0:8
    - setMessageLabel:  types=v24@0:8@16
    - activateButton  types=@16@0:8
    - setActivateButton:  types=v24@0:8@16
    - laterButton  types=@16@0:8
    - setLaterButton:  types=v24@0:8@16
    - .cxx_destruct  types=v16@0:8
  class methods (1):
    + modalWithActivateHandler:dismissHandler:  types=@32@0:8@?16@?24

--- @interface CBSubscriptionCheckoutCell : None (instanceSize=32, ro_flags=0x184) ---
  ivars:
    _delegate : @"<CBSubscriptionCheckoutCellDelegate>" offset=8 size=8
    _checkoutButton : @"UIButton" offset=16 size=8
    _checkoutSpinner : @"UIActivityIndicatorView" offset=24 size=8
  properties:
    checkoutButton  attrs=T@"UIButton",&,N,V_checkoutButton
    checkoutSpinner  attrs=T@"UIActivityIndicatorView",&,N,V_checkoutSpinner
    delegate  attrs=T@"<CBSubscriptionCheckoutCellDelegate>",W,N,V_delegate
  instance methods (10):
    - initWithStyle:reuseIdentifier:  types=@32@0:8q16@24
    - configureWithTitle:loading:  types=v28@0:8@16B24
    - checkoutTapped  types=v16@0:8
    - delegate  types=@16@0:8
    - setDelegate:  types=v24@0:8@16
    - checkoutButton  types=@16@0:8
    - setCheckoutButton:  types=v24@0:8@16
    - checkoutSpinner  types=@16@0:8
    - setCheckoutSpinner:  types=v24@0:8@16
    - .cxx_destruct  types=v16@0:8

--- @interface CBSubscriptionVIPStatusCell : None (instanceSize=8, ro_flags=0x80) ---
  instance methods (2):
    - initWithStyle:reuseIdentifier:  types=@32@0:8q16@24
    - configureWithExpirationTimestamp:  types=v24@0:8Q16

--- @interface CBSubscriptionHardwareIDCell : None (instanceSize=32, ro_flags=0x184) ---
  ivars:
    _delegate : @"<CBSubscriptionHardwareIDCellDelegate>" offset=8 size=8
    _hwLabel : @"UILabel" offset=16 size=8
    _clipboardButton : @"UIButton" offset=24 size=8
  properties:
    hwLabel  attrs=T@"UILabel",&,N,V_hwLabel
    clipboardButton  attrs=T@"UIButton",&,N,V_clipboardButton
    delegate  attrs=T@"<CBSubscriptionHardwareIDCellDelegate>",W,N,V_delegate
  instance methods (10):
    - initWithStyle:reuseIdentifier:  types=@32@0:8q16@24
    - configureWithHardwareHash:  types=v24@0:8@16
    - copyTapped  types=v16@0:8
    - delegate  types=@16@0:8
    - setDelegate:  types=v24@0:8@16
    - hwLabel  types=@16@0:8
    - setHwLabel:  types=v24@0:8@16
    - clipboardButton  types=@16@0:8
    - setClipboardButton:  types=v24@0:8@16
    - .cxx_destruct  types=v16@0:8

--- @interface CBSubscriptionGiftcodeInputCell : None (instanceSize=32, ro_flags=0x184) ---
  ivars:
    _delegate : @"<CBSubscriptionGiftcodeInputCellDelegate>" offset=8 size=8
    _textField : @"UITextField" offset=16 size=8
    _pasteButton : @"UIButton" offset=24 size=8
  properties:
    textField  attrs=T@"UITextField",&,N,V_textField
    pasteButton  attrs=T@"UIButton",&,N,V_pasteButton
    delegate  attrs=T@"<CBSubscriptionGiftcodeInputCellDelegate>",W,N,V_delegate
  instance methods (9):
    - initWithStyle:reuseIdentifier:  types=@32@0:8q16@24
    - pasteTapped  types=v16@0:8
    - delegate  types=@16@0:8
    - setDelegate:  types=v24@0:8@16
    - textField  types=@16@0:8
    - setTextField:  types=v24@0:8@16
    - pasteButton  types=@16@0:8
    - setPasteButton:  types=v24@0:8@16
    - .cxx_destruct  types=v16@0:8

--- @interface CBSubscriptionGiftcodeRedeemCell : None (instanceSize=32, ro_flags=0x184) ---
  ivars:
    _delegate : @"<CBSubscriptionGiftcodeRedeemCellDelegate>" offset=8 size=8
    _redeemButton : @"UIButton" offset=16 size=8
    _spinner : @"UIActivityIndicatorView" offset=24 size=8
  properties:
    redeemButton  attrs=T@"UIButton",&,N,V_redeemButton
    spinner  attrs=T@"UIActivityIndicatorView",&,N,V_spinner
    delegate  attrs=T@"<CBSubscriptionGiftcodeRedeemCellDelegate>",W,N,V_delegate
  instance methods (10):
    - initWithStyle:reuseIdentifier:  types=@32@0:8q16@24
    - redeemTapped  types=v16@0:8
    - setLoading:  types=v20@0:8B16
    - delegate  types=@16@0:8
    - setDelegate:  types=v24@0:8@16
    - redeemButton  types=@16@0:8
    - setRedeemButton:  types=v24@0:8@16
    - spinner  types=@16@0:8
    - setSpinner:  types=v24@0:8@16
    - .cxx_destruct  types=v16@0:8

--- @interface CBSubscriptionPendingOrderCell : None (instanceSize=56, ro_flags=0x184) ---
  ivars:
    _delegate : @"<CBSubscriptionPendingOrderCellDelegate>" offset=8 size=8
    _titleLabel : @"UILabel" offset=16 size=8
    _descLabel : @"UILabel" offset=24 size=8
    _resumeBtn : @"UIButton" offset=32 size=8
    _checkStatusButton : @"UIButton" offset=40 size=8
    _cancelBtn : @"UIButton" offset=48 size=8
  properties:
    titleLabel  attrs=T@"UILabel",&,N,V_titleLabel
    descLabel  attrs=T@"UILabel",&,N,V_descLabel
    resumeBtn  attrs=T@"UIButton",&,N,V_resumeBtn
    checkStatusButton  attrs=T@"UIButton",&,N,V_checkStatusButton
    cancelBtn  attrs=T@"UIButton",&,N,V_cancelBtn
    delegate  attrs=T@"<CBSubscriptionPendingOrderCellDelegate>",W,N,V_delegate
  instance methods (18):
    - initWithStyle:reuseIdentifier:  types=@32@0:8q16@24
    - configureWithTitle:description:  types=v32@0:8@16@24
    - resumeTapped  types=v16@0:8
    - checkStatusTapped  types=v16@0:8
    - cancelTapped  types=v16@0:8
    - delegate  types=@16@0:8
    - setDelegate:  types=v24@0:8@16
    - titleLabel  types=@16@0:8
    - setTitleLabel:  types=v24@0:8@16
    - descLabel  types=@16@0:8
    - setDescLabel:  types=v24@0:8@16
    - resumeBtn  types=@16@0:8
    - setResumeBtn:  types=v24@0:8@16
    - checkStatusButton  types=@16@0:8
    - setCheckStatusButton:  types=v24@0:8@16
    - cancelBtn  types=@16@0:8
    - setCancelBtn:  types=v24@0:8@16
    - .cxx_destruct  types=v16@0:8

--- @interface CBSubscriptionPlanCardCell : None (instanceSize=48, ro_flags=0x184) ---
  ivars:
    _nameLabel : @"UILabel" offset=8 size=8
    _badgeLabel : @"UILabel" offset=16 size=8
    _descLabel : @"UILabel" offset=24 size=8
    _priceLabel : @"UILabel" offset=32 size=8
    _checkIcon : @"UIImageView" offset=40 size=8
  properties:
    nameLabel  attrs=T@"UILabel",&,N,V_nameLabel
    badgeLabel  attrs=T@"UILabel",&,N,V_badgeLabel
    descLabel  attrs=T@"UILabel",&,N,V_descLabel
    priceLabel  attrs=T@"UILabel",&,N,V_priceLabel
    checkIcon  attrs=T@"UIImageView",&,N,V_checkIcon
  instance methods (13):
    - initWithStyle:reuseIdentifier:  types=@32@0:8q16@24
    - configureWithPlan:selected:formattedPrice:  types=v36@0:8@16B24@28
    - nameLabel  types=@16@0:8
    - setNameLabel:  types=v24@0:8@16
    - badgeLabel  types=@16@0:8
    - setBadgeLabel:  types=v24@0:8@16
    - descLabel  types=@16@0:8
    - setDescLabel:  types=v24@0:8@16
    - priceLabel  types=@16@0:8
    - setPriceLabel:  types=v24@0:8@16
    - checkIcon  types=@16@0:8
    - setCheckIcon:  types=v24@0:8@16
    - .cxx_destruct  types=v16@0:8

--- @interface CBSubscriptionStatusCell : None (instanceSize=8, ro_flags=0x80) ---
  instance methods (2):
    - initWithStyle:reuseIdentifier:  types=@32@0:8q16@24
    - configureWithLoading:failed:  types=v24@0:8B16B20

--- @interface CBSubscriptionVIPCardCell : None (instanceSize=80, ro_flags=0x184) ---
  ivars:
    _badgeIcon : @"UIImageView" offset=8 size=8
    _titleLabel : @"UILabel" offset=16 size=8
    _statusPillLabel : @"UILabel" offset=24 size=8
    _durationKeyLabel : @"UILabel" offset=32 size=8
    _durationValueLabel : @"UILabel" offset=40 size=8
    _serverExpiryKeyLabel : @"UILabel" offset=48 size=8
    _serverExpiryValueLabel : @"UILabel" offset=56 size=8
    _licenseValidationKeyLabel : @"UILabel" offset=64 size=8
    _licenseValidationValueLabel : @"UILabel" offset=72 size=8
  properties:
    badgeIcon  attrs=T@"UIImageView",&,N,V_badgeIcon
    titleLabel  attrs=T@"UILabel",&,N,V_titleLabel
    statusPillLabel  attrs=T@"UILabel",&,N,V_statusPillLabel
    durationKeyLabel  attrs=T@"UILabel",&,N,V_durationKeyLabel
    durationValueLabel  attrs=T@"UILabel",&,N,V_durationValueLabel
    serverExpiryKeyLabel  attrs=T@"UILabel",&,N,V_serverExpiryKeyLabel
    serverExpiryValueLabel  attrs=T@"UILabel",&,N,V_serverExpiryValueLabel
    licenseValidationKeyLabel  attrs=T@"UILabel",&,N,V_licenseValidationKeyLabel
    licenseValidationValueLabel  attrs=T@"UILabel",&,N,V_licenseValidationValueLabel
  instance methods (24):
    - initWithStyle:reuseIdentifier:  types=@32@0:8q16@24
    - keyLabel  types=@16@0:8
    - valueLabel  types=@16@0:8
    - keyValuePairWithKeyLabel:valueLabel:  types=@32@0:8@16@24
    - configureWithExpirationTimestamp:tierName:  types=v32@0:8Q16@24
    - badgeIcon  types=@16@0:8
    - setBadgeIcon:  types=v24@0:8@16
    - titleLabel  types=@16@0:8
    - setTitleLabel:  types=v24@0:8@16
    - statusPillLabel  types=@16@0:8
    - setStatusPillLabel:  types=v24@0:8@16
    - durationKeyLabel  types=@16@0:8
    - setDurationKeyLabel:  types=v24@0:8@16
    - durationValueLabel  types=@16@0:8
    - setDurationValueLabel:  types=v24@0:8@16
    - serverExpiryKeyLabel  types=@16@0:8
    - setServerExpiryKeyLabel:  types=v24@0:8@16
    - serverExpiryValueLabel  types=@16@0:8
    - setServerExpiryValueLabel:  types=v24@0:8@16
    - licenseValidationKeyLabel  types=@16@0:8
    - setLicenseValidationKeyLabel:  types=v24@0:8@16
    - licenseValidationValueLabel  types=@16@0:8
    - setLicenseValidationValueLabel:  types=v24@0:8@16
    - .cxx_destruct  types=v16@0:8

--- @interface CBSubscriptionOrderCoordinator : None (instanceSize=80, ro_flags=0x184) ---
  ivars:
    _delegate : @"<CBSubscriptionOrderCoordinatorDelegate>" offset=8 size=8
    _activeOrderId : @"NSString" offset=16 size=8
    _activePaymentUrl : @"NSString" offset=24 size=8
    _activeTierName : @"NSString" offset=32 size=8
    _activeAmountCrypto : @"NSString" offset=40 size=8
    _activeCurrency : @"NSString" offset=48 size=8
    _activeNetwork : @"NSString" offset=56 size=8
    _pollTimer : @"NSTimer" offset=64 size=8
    _safariVC : @"SFSafariViewController" offset=72 size=8
  properties:
    pollTimer  attrs=T@"NSTimer",&,N,V_pollTimer
    safariVC  attrs=T@"SFSafariViewController",&,N,V_safariVC
    delegate  attrs=T@"<CBSubscriptionOrderCoordinatorDelegate>",W,N,V_delegate
    activeOrderId  attrs=T@"NSString",C,N,V_activeOrderId
    activePaymentUrl  attrs=T@"NSString",C,N,V_activePaymentUrl
    activeTierName  attrs=T@"NSString",C,N,V_activeTierName
    activeAmountCrypto  attrs=T@"NSString",C,N,V_activeAmountCrypto
    activeCurrency  attrs=T@"NSString",C,N,V_activeCurrency
    activeNetwork  attrs=T@"NSString",C,N,V_activeNetwork
    hash  attrs=TQ,R
    superclass  attrs=T#,R
    description  attrs=T@"NSString",R,C
    debugDescription  attrs=T@"NSString",R,C
  instance methods (36):
    - dealloc  types=v16@0:8
    - hasActivePendingOrder  types=B16@0:8
    - currentServerBaseURL  types=@16@0:8
    - fetchActivePendingOrderFromServer  types=v16@0:8
    - startCheckoutForTier:forceNew:  types=v28@0:8@16B24
    - resumePayment  types=v16@0:8
    - checkStatusManual  types=v16@0:8
    - cancelActiveOrderWithCompletion:  types=v24@0:8@?16
    - requestCancelPendingOrder  types=v16@0:8
    - openPaymentGatewayURL:  types=v24@0:8@16
    - safariViewControllerDidFinish:  types=v24@0:8@16
    - startPollingOrderStatus:  types=v24@0:8@16
    - stopPollingOrderStatus  types=v16@0:8
    - pollTimerFired  types=v16@0:8
    - checkOrderStatusOnce:  types=v24@0:8@16
    - handlePaymentCompletedSuccess  types=v16@0:8
    - showAlertWithTitle:message:  types=v32@0:8@16@24
    - delegate  types=@16@0:8
    - setDelegate:  types=v24@0:8@16
    - activeOrderId  types=@16@0:8
    - setActiveOrderId:  types=v24@0:8@16
    - activePaymentUrl  types=@16@0:8
    - setActivePaymentUrl:  types=v24@0:8@16
    - activeTierName  types=@16@0:8
    - setActiveTierName:  types=v24@0:8@16
    - activeAmountCrypto  types=@16@0:8
    - setActiveAmountCrypto:  types=v24@0:8@16
    - activeCurrency  types=@16@0:8
    - setActiveCurrency:  types=v24@0:8@16
    - activeNetwork  types=@16@0:8
    - setActiveNetwork:  types=v24@0:8@16
    - pollTimer  types=@16@0:8
    - setPollTimer:  types=v24@0:8@16
    - safariVC  types=@16@0:8
    - setSafariVC:  types=v24@0:8@16
    - .cxx_destruct  types=v16@0:8

--- @interface CBLocalization : None (instanceSize=48, ro_flags=0x184) ---
  ivars:
    _activeLanguageCode : @"NSString" offset=8 size=8
    _cachedStringTables : @"NSMutableDictionary" offset=16 size=8
    _activeLanguageTable : @"NSDictionary" offset=24 size=8
    _viTable : @"NSDictionary" offset=32 size=8
    _enTable : @"NSDictionary" offset=40 size=8
  instance methods (6):
    - init  types=@16@0:8
    - reloadLanguage  types=v16@0:8
    - activeLanguageCode  types=@16@0:8
    - stringTableForLanguageCode:  types=@24@0:8@16
    - localizedStringForKey:  types=@24@0:8@16
    - .cxx_destruct  types=v16@0:8
  class methods (7):
    + sharedInstance  types=@16@0:8
    + speechVoiceLanguageCode  types=@16@0:8
    + supportedLanguages  types=@16@0:8
    + displayNameForLanguageCode:  types=@24@0:8@16
    + currentLanguageCode  types=@16@0:8
    + setCurrentLanguageCode:  types=v24@0:8@16
    + localizedStringForKey:  types=@24@0:8@16

--- @interface CBSplitSplashScreenView : None (instanceSize=112, ro_flags=0x184) ---
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

--- @interface CBHttpClient : None (instanceSize=16, ro_flags=0x184) ---
  ivars:
    _networkQueue : @"NSObject<OS_dispatch_queue>" offset=8 size=8
  properties:
    networkQueue  attrs=T@"NSObject<OS_dispatch_queue>",&,N,V_networkQueue
  instance methods (6):
    - init  types=@16@0:8
    - postJSON:toURL:timeout:customHeaders:completion:  types=v56@0:8@16@24d32@40@?48
    - getJSONFromURL:timeout:customHeaders:completion:  types=v48@0:8@16d24@32@?40
    - networkQueue  types=@16@0:8
    - setNetworkQueue:  types=v24@0:8@16
    - .cxx_destruct  types=v16@0:8
  class methods (1):
    + sharedClient  types=@16@0:8

--- @interface CBLicenseSyncManager : None (instanceSize=32, ro_flags=0x184) ---
  ivars:
    _isSyncing : B offset=8 size=1
    _syncQueue : @"NSObject<OS_dispatch_queue>" offset=16 size=8
    _lastAttemptTimestamp : Q offset=24 size=8
  properties:
    isSyncing  attrs=TB,N,V_isSyncing
    syncQueue  attrs=T@"NSObject<OS_dispatch_queue>",&,N,V_syncQueue
    lastAttemptTimestamp  attrs=TQ,N,V_lastAttemptTimestamp
  instance methods (24):
    - init  types=@16@0:8
    - deviceHardwareHashHex  types=@16@0:8
    - isLicenseCurrentlyValid  types=B16@0:8
    - remainingLicenseSeconds  types=Q16@0:8
    - isCarPlayScreenConnected  types=B16@0:8
    - checkAndSyncLicenseIfNeeded  types=v16@0:8
    - checkAndSyncLicenseIfNeededWithSource:  types=v24@0:8@16
    - forceSyncWithCompletion:  types=v24@0:8@?16
    - resolvedBackendBaseURL  types=@16@0:8
    - resolvedLicenseServerEndpoint  types=@16@0:8
    - performSyncWithForce:isManualUserAction:completion:  types=v32@0:8B16B20@?24
    - performSyncWithForce:isManualUserAction:source:completion:  types=v40@0:8B16B20@24@?32
    - installAndVerifyLicensePayload:errorMsg:  types=B32@0:8@16^@24
    - actualLicenseExpirationTimestamp  types=Q16@0:8
    - setActualLicenseExpirationTimestamp:  types=v24@0:8Q16
    - actualLicenseTierName  types=@16@0:8
    - setActualLicenseTierName:  types=v24@0:8@16
    - isSyncing  types=B16@0:8
    - setIsSyncing:  types=v20@0:8B16
    - syncQueue  types=@16@0:8
    - setSyncQueue:  types=v24@0:8@16
    - lastAttemptTimestamp  types=Q16@0:8
    - setLastAttemptTimestamp:  types=v24@0:8Q16
    - .cxx_destruct  types=v16@0:8
  class methods (6):
    + sharedInstance  types=@16@0:8
    + isCarPlayScreen:  types=B24@0:8@16
    + isCarPlayScreenConnectedExcludingScreen:  types=B24@0:8@16
    + isCarPlayScreenConnected  types=B16@0:8
    + formatBaseURLString:  types=@24@0:8@16
    + resolvedBackendBaseURL  types=@16@0:8
```

### 9.2 DuoFaceDashboard.dylib

```
# Mach-O parse: root/var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib
file size: 7540464  slices: 2

===== SLICE 0: arm64 sub=all (raw subtype 0x0) filetype=DYLIB flags=0x900085 off=16384 size=3741760 =====
ncmds=35
load commands: LC_SEGMENT_64, LC_SEGMENT_64, LC_SEGMENT_64, LC_SEGMENT_64, LC_ID_DYLIB, LC_DYLD_INFO_ONLY, LC_SYMTAB, LC_DYSYMTAB, LC_UUID, LC_BUILD_VERSION, LC_SOURCE_VERSION, LC_ENCRYPTION_INFO_64, LC_LOAD_DYLIB, LC_LOAD_DYLIB, LC_LOAD_DYLIB, LC_LOAD_DYLIB, LC_LOAD_DYLIB, LC_LOAD_DYLIB, LC_LOAD_DYLIB, LC_LOAD_DYLIB, LC_LOAD_DYLIB, LC_LOAD_DYLIB, LC_LOAD_DYLIB, LC_LOAD_DYLIB, LC_LOAD_WEAK_DYLIB, LC_LOAD_DYLIB, LC_LOAD_DYLIB, LC_LOAD_DYLIB, LC_RPATH(REQ), LC_RPATH(REQ), LC_RPATH(REQ), LC_RPATH(REQ), LC_FUNCTION_STARTS, LC_DATA_IN_CODE, LC_CODE_SIGNATURE
id_dylib: ('@rpath/DuoFaceDashboard.dylib', '0.0.0', '0.0.0')
uuid: e585ce1cacc63e74b017d760ffc77c02
build_version: ('iOS', '15.0.0', '16.5.0')  min_version: None  source_version: 0.0.0
encryption: (16384, 3407872, 0)  main: None  rpaths: ['/var/jb/Library/Frameworks', '/var/jb/usr/lib', '@loader_path/.jbroot/Library/Frameworks', '@loader_path/.jbroot/usr/lib']
codesig: (3712352, 29408) chained_fixups=False dyld_info=True
linked libraries:
  [LC_LOAD_DYLIB] /usr/lib/libobjc.A.dylib cur=228.0.0 compat=1.0.0
  [LC_LOAD_DYLIB] /System/Library/Frameworks/Foundation.framework/Foundation cur=1971.0.0 compat=300.0.0
  [LC_LOAD_DYLIB] /System/Library/Frameworks/CoreFoundation.framework/CoreFoundation cur=1971.0.0 compat=150.0.0
  [LC_LOAD_DYLIB] /System/Library/Frameworks/UIKit.framework/UIKit cur=6441.1.101 compat=1.0.0
  [LC_LOAD_DYLIB] /System/Library/Frameworks/CoreGraphics.framework/CoreGraphics cur=1690.5.4 compat=64.0.0
  [LC_LOAD_DYLIB] /System/Library/Frameworks/IOKit.framework/Versions/A/IOKit cur=275.0.0 compat=1.0.0
  [LC_LOAD_DYLIB] /System/Library/Frameworks/Security.framework/Security cur=60420.102.1 compat=1.0.0
  [LC_LOAD_DYLIB] /System/Library/Frameworks/AVFoundation.framework/AVFoundation cur=2.0.0 compat=1.0.0
  [LC_LOAD_DYLIB] /System/Library/Frameworks/QuartzCore.framework/QuartzCore cur=1.11.0 compat=1.2.0
  [LC_LOAD_DYLIB] /usr/lib/libsqlite3.dylib cur=346.0.0 compat=9.0.0
  [LC_LOAD_DYLIB] /System/Library/PrivateFrameworks/AppSupport.framework/AppSupport cur=29.0.0 compat=1.0.0
  [LC_LOAD_DYLIB] /System/Library/PrivateFrameworks/BackBoardServices.framework/BackBoardServices cur=1.0.0 compat=1.0.0
  [LC_LOAD_WEAK_DYLIB] /System/Library/Frameworks/Speech.framework/Speech cur=1.0.0 compat=1.0.0
  [LC_LOAD_DYLIB] /usr/lib/libSystem.B.dylib cur=1319.100.3 compat=1.0.0
  [LC_LOAD_DYLIB] /System/Library/Frameworks/AVFAudio.framework/AVFAudio cur=1.0.0 compat=1.0.0
  [LC_LOAD_DYLIB] @rpath/CydiaSubstrate.framework/CydiaSubstrate cur=0.0.0 compat=0.0.0
segments/sections:
  __TEXT,__text addr=0x6258 size=3040544 off=25176 flags=0x80000400
  __TEXT,__stubs addr=0x2ec778 size=1848 off=3065720 flags=0x80000408
  __TEXT,__stub_helper addr=0x2eceb0 size=1872 off=3067568 flags=0x80000400
  __TEXT,__objc_methlist addr=0x2ed600 size=9532 off=3069440 flags=0x0
  __TEXT,__gcc_except_tab addr=0x2efb3c size=12344 off=3078972 flags=0x0
  __TEXT,__objc_methname addr=0x2f2b74 size=34516 off=3091316 flags=0x2
  __TEXT,__cstring addr=0x2fb248 size=83459 off=3125832 flags=0x2
  __TEXT,__const addr=0x30f850 size=35577 off=3209296 flags=0x0
  __TEXT,__ustring addr=0x31834a size=171056 off=3244874 flags=0x0
  __TEXT,__objc_classname addr=0x341f7a size=931 off=3415930 flags=0x2
  __TEXT,__objc_methtype addr=0x34231d size=3025 off=3416861 flags=0x2
  __TEXT,__unwind_info addr=0x342ef0 size=4368 off=3419888 flags=0x0
  __DATA_CONST,__got addr=0x344000 size=480 off=3424256 flags=0x6
  __DATA_CONST,__mod_init_func addr=0x3441e0 size=16 off=3424736 flags=0x9
  __DATA_CONST,__const addr=0x3441f0 size=7544 off=3424752 flags=0x0
  __DATA_CONST,__cfstring addr=0x345f68 size=189152 off=3432296 flags=0x0
  __DATA_CONST,__objc_classlist addr=0x374248 size=288 off=3621448 flags=0x10000000
  __DATA_CONST,__objc_catlist addr=0x374368 size=0 off=3621736 flags=0x10000000
  __DATA_CONST,__objc_protolist addr=0x374368 size=40 off=3621736 flags=0x0
  __DATA_CONST,__objc_imageinfo addr=0x374390 size=8 off=3621776 flags=0x0
  __DATA,__la_symbol_ptr addr=0x378000 size=1232 off=3637248 flags=0x7
  __DATA,__objc_const addr=0x3784d0 size=18704 off=3638480 flags=0x0
  __DATA,__objc_selrefs addr=0x37cde0 size=10528 off=3657184 flags=0x10000005
  __DATA,__objc_classrefs addr=0x37f700 size=872 off=3667712 flags=0x10000000
  __DATA,__objc_superrefs addr=0x37fa68 size=248 off=3668584 flags=0x10000000
  __DATA,__objc_ivar addr=0x37fb60 size=860 off=3668832 flags=0x0
  __DATA,__objc_data addr=0x37fec0 size=2880 off=3669696 flags=0x0
  __DATA,__data addr=0x380a00 size=496 off=3672576 flags=0x0
  __DATA,__thread_vars addr=0x380bf0 size=576 off=3673072 flags=0x13
  __DATA,__thread_bss addr=0x380e30 size=480 off=0 flags=0x12
  __DATA,__bss addr=0x381010 size=5688 off=0 flags=0x1
  __DATA,__common addr=0x382650 size=672 off=0 flags=0x1
signature blobs: [(0, '0xfade0c02', 29217), ('CD ident', 'DuoFaceDashboard.dylib.d0920c2e.unsigned', 'ver=0x20400 flags=0x0'), (2, '0xfade0c01', 156)]
ENTITLEMENTS:
(none found)
symbols: defined=0 undefined=295 stab/other=1
exported (trie): 0
defined symbols:
undefined symbols:
  U _AVAudioSessionCategoryPlayAndRecord
  U _AVAudioSessionModeMeasurement
  U _CACurrentMediaTime
  U _CAFrameRateRangeMake
  U _CFDataGetBytePtr
  U _CFDataGetLength
  U _CFDataGetTypeID
  U _CFGetTypeID
  U _CFNotificationCenterAddObserver
  U _CFNotificationCenterGetDarwinNotifyCenter
  U _CFNotificationCenterPostNotification
  U _CFNumberGetTypeID
  U _CFNumberGetValue
  U _CFRelease
  U _CFStringCreateWithCString
  U _CFStringGetCString
  U _CFStringGetTypeID
  U _CGAffineTransformIdentity
  U _CGAffineTransformMakeScale
  U _CGColorSpaceCreateDeviceRGB
  U _CGColorSpaceRelease
  U _CGContextDrawLinearGradient
  U _CGContextDrawRadialGradient
  U _CGContextRestoreGState
  U _CGContextSaveGState
  U _CGGradientCreateWithColors
  U _CGGradientRelease
  U _CGPointZero
  U _CGRectContainsPoint
  U _CGRectEqualToRect
  U _CGRectGetMaxX
  U _CGRectGetMaxY
  U _CGRectGetMidX
  U _CGRectGetMidY
  U _CGRectGetMinX
  U _CGRectGetMinY
  U _CGRectInset
  U _CGRectIntersectsRect
  U _CGRectZero
  U _CGSizeFromString
  U _CGSizeZero
  U _IOHIDEventAppendEvent
  U _IOHIDEventCreateDigitizerEvent
  U _IOHIDEventCreateDigitizerFingerEvent
  U _IOHIDEventSetSenderID
  U _IOHIDEventSystemClientCreate
  U _IOHIDEventSystemClientDispatchEvent
  U _IOObjectRelease
  U _IORegistryEntryCreateCFProperty
  U _IOServiceGetMatchingService
  U _IOServiceMatching
  U _MSHookFunction
  U _MSHookMessageEx
  U _NSFilePosixPermissions
  U _NSFontAttributeName
  U _NSForegroundColorAttributeName
  U _NSKernAttributeName
  U _NSLocalizedDescriptionKey
  U _NSLog
  U _NSParagraphStyleAttributeName
  U _NSRunLoopCommonModes
  U _NSSelectorFromString
  U _NSSetUncaughtExceptionHandler
  U _NSStringFromCGRect
  U _NSStringFromCGSize
  U _NSStringFromClass
  U _NSStringFromUIEdgeInsets
  U _OBJC_CLASS_$_AVAudioEngine
  U _OBJC_CLASS_$_AVAudioSession
  U _OBJC_CLASS_$_AVSpeechSynthesisVoice
  U _OBJC_CLASS_$_AVSpeechSynthesizer
  U _OBJC_CLASS_$_AVSpeechUtterance
  U _OBJC_CLASS_$_CABasicAnimation
  U _OBJC_CLASS_$_CADisplay
  U _OBJC_CLASS_$_CADisplayLink
  U _OBJC_CLASS_$_CAGradientLayer
  U _OBJC_CLASS_$_CAMediaTimingFunction
  U _OBJC_CLASS_$_CAShapeLayer
  U _OBJC_CLASS_$_NSArray
  U _OBJC_CLASS_$_NSAttributedString
  U _OBJC_CLASS_$_NSBundle
  U _OBJC_CLASS_$_NSCache
  U _OBJC_CLASS_$_NSCharacterSet
  U _OBJC_CLASS_$_NSData
  U _OBJC_CLASS_$_NSDate
  U _OBJC_CLASS_$_NSDictionary
  U _OBJC_CLASS_$_NSDistributedNotificationCenter
  U _OBJC_CLASS_$_NSError
  U _OBJC_CLASS_$_NSFileHandle
  U _OBJC_CLASS_$_NSFileManager
  U _OBJC_CLASS_$_NSHTTPURLResponse
  U _OBJC_CLASS_$_NSHashTable
  U _OBJC_CLASS_$_NSJSONSerialization
  U _OBJC_CLASS_$_NSLocale
  U _OBJC_CLASS_$_NSMutableArray
  U _OBJC_CLASS_$_NSMutableAttributedString
  U _OBJC_CLASS_$_NSMutableData
  U _OBJC_CLASS_$_NSMutableDictionary
  U _OBJC_CLASS_$_NSMutableParagraphStyle
  U _OBJC_CLASS_$_NSMutableSet
  U _OBJC_CLASS_$_NSMutableString
  U _OBJC_CLASS_$_NSMutableURLRequest
  U _OBJC_CLASS_$_NSNotification
  U _OBJC_CLASS_$_NSNotificationCenter
  U _OBJC_CLASS_$_NSNumber
  U _OBJC_CLASS_$_NSObject
  U _OBJC_CLASS_$_NSOperationQueue
  U _OBJC_CLASS_$_NSProcessInfo
  U _OBJC_CLASS_$_NSRecursiveLock
  U _OBJC_CLASS_$_NSRunLoop
  U _OBJC_CLASS_$_NSSet
  U _OBJC_CLASS_$_NSString
  U _OBJC_CLASS_$_NSThread
  U _OBJC_CLASS_$_NSTimer
  U _OBJC_CLASS_$_NSURL
  U _OBJC_CLASS_$_NSURLSession
  U _OBJC_CLASS_$_NSURLSessionConfiguration
  U _OBJC_CLASS_$_NSUUID
  U _OBJC_CLASS_$_NSValue
  U _OBJC_CLASS_$_SFSpeechRecognizer
  U _OBJC_CLASS_$_UIApplication
  U _OBJC_CLASS_$_UIBezierPath
  U _OBJC_CLASS_$_UIBlurEffect
  U _OBJC_CLASS_$_UIButton
  U _OBJC_CLASS_$_UIColor
  U _OBJC_CLASS_$_UIDevice
  U _OBJC_CLASS_$_UIFont
  U _OBJC_CLASS_$_UIImage
  U _OBJC_CLASS_$_UIImageSymbolConfiguration
  U _OBJC_CLASS_$_UIImageView
  U _OBJC_CLASS_$_UILabel
  U _OBJC_CLASS_$_UILongPressGestureRecognizer
  U _OBJC_CLASS_$_UIPageControl
  U _OBJC_CLASS_$_UIPanGestureRecognizer
  U _OBJC_CLASS_$_UIScreen
  U _OBJC_CLASS_$_UIScrollView
  U _OBJC_CLASS_$_UITapGestureRecognizer
  U _OBJC_CLASS_$_UITextInputMode
  U _OBJC_CLASS_$_UIView
  U _OBJC_CLASS_$_UIViewController
  U _OBJC_CLASS_$_UIVisualEffectView
  U _OBJC_CLASS_$_UIWindow
  U _OBJC_CLASS_$_UIWindowScene
  U _OBJC_EHTYPE_$_NSException
  U _OBJC_METACLASS_$_NSObject
  U _OBJC_METACLASS_$_UIButton
  U _OBJC_METACLASS_$_UIScrollView
  U _OBJC_METACLASS_$_UIView
  U _SecItemAdd
  U _SecItemCopyMatching
  U _SecItemUpdate
  U _UIApplicationDidBecomeActiveNotification
  U _UIApplicationDidEnterBackgroundNotification
  U _UIApplicationWillEnterForegroundNotification
  U _UIApplicationWillResignActiveNotification
  U _UIDeviceBatteryLevelDidChangeNotification
  U _UIDeviceBatteryStateDidChangeNotification
  U _UIEdgeInsetsFromString
  U _UIEdgeInsetsZero
  U _UIFontWeightBlack
  U _UIFontWeightBold
  U _UIFontWeightMedium
  U _UIFontWeightRegular
  U _UIFontWeightSemibold
  U _UIGraphicsBeginImageContextWithOptions
  U _UIGraphicsEndImageContext
  U _UIGraphicsGetCurrentContext
  U _UIGraphicsGetImageFromCurrentImageContext
  U _UISceneDidActivateNotification
  U _UISceneWillEnterForegroundNotification
  U _UIScreenDidConnectNotification
  U _UIScreenDidDisconnectNotification
  U _UIScreenModeDidChangeNotification
  U _UIWindowLevelAlert
  U _UIWindowLevelNormal
  U __Block_object_assign
  U __Block_object_dispose
  U __NSConcreteGlobalBlock
  U __NSConcreteStackBlock
  U __UICreateScreenUIImage
  U __Unwind_Resume
  U ___CFConstantStringClassReference
  U ___NSArray0__
  U ___NSDictionary0__
  U ___memcpy_chk
  U ___objc_personality_v0
  U ___stack_chk_fail
  U ___stack_chk_guard
  U __dispatch_main_q
  U __objc_empty_cache
  U __tlv_bootstrap
  U _backtrace
  U _backtrace_symbols
  U _bzero
  U _chmod
  U _chown
  U _class_addMethod
  U _class_getInstanceMethod
  U _class_getInstanceVariable
  U _class_getName
  U _class_getSuperclass
  U _dispatch_after
  U _dispatch_async
  U _dispatch_once
  U _dispatch_queue_create
  U _dispatch_time
  U _dlopen
  U _dlsym
  U _fclose
  U _fopen
  U _fread
  U _free
  U _fwrite
  U _getpid
  U _host_statistics
  U _host_statistics64
  U _ivar_getOffset
  U _kCACornerCurveContinuous
  U _kCAMediaTimingFunctionEaseInEaseOut
  U _kCFAllocatorDefault
  U _kCFCoreFoundationVersionNumber
  U _kIOMasterPortDefault
  U _kSecAttrAccessible
  U _kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
  U _kSecAttrAccount
  U _kSecAttrService
  U _kSecClass
  U _kSecClassGenericPassword
  U _kSecMatchLimit
  U _kSecMatchLimitOne
  U _kSecReturnData
  U _kSecValueData
  U _kill
  U _mach_absolute_time
  U _mach_host_self
  U _mach_task_self_
  U _memcpy
  U _method_getTypeEncoding
  U _notify_post
  U _notify_register_dispatch
  U _objc_alloc
  U _objc_alloc_init
  U _objc_allocateClassPair
  U _objc_autorelease
  U _objc_autoreleasePoolPop
  U _objc_autoreleasePoolPush
  U _objc_autoreleaseReturnValue
  U _objc_begin_catch
  U _objc_copyWeak
  U _objc_destroyWeak
  U _objc_end_catch
  U _objc_enumerationMutation
  U _objc_getAssociatedObject
  U _objc_getClass
  U _objc_getProperty
  U _objc_initWeak
  U _objc_loadWeakRetained
  U _objc_msgSend
  U _objc_msgSendSuper
  U _objc_msgSendSuper2
  U _objc_registerClassPair
  U _objc_release
  U _objc_retain
  U _objc_retainAutorelease
  U _objc_retainAutoreleaseReturnValue
  U _objc_retainAutoreleasedReturnValue
  U _objc_retainBlock
  U _objc_setAssociatedObject
  U _objc_setProperty_nonatomic_copy
  U _objc_storeStrong
  U _objc_storeWeak
  U _objc_sync_enter
  U _objc_sync_exit
  U _objc_unsafeClaimAutoreleasedReturnValue
  U _object_getClass
  U _object_getIvar
  U _object_setIvar
  U _rename
  U _sel_registerName
  U _sigaction
  U _snprintf
  U _sqlite3_close
  U _sqlite3_exec
  U _sqlite3_free
  U _sqlite3_open
  U _stat
  U _strlen
  U _strsignal
  U _strstr
  U _sysctl
  U _sysctlbyname
  U _time
  U _vm_kernel_page_size
  U _vm_read_overwrite
  U dyld_stub_binder
mod_init_func count (__DATA_CONST): 2

OBJC imageinfo: (0, '0x40')
OBJC classes: 36  +load classes: []  categories: 0  protocols: ['NSObject', 'SFSpeechRecognizerDelegate', 'AVSpeechSynthesizerDelegate', 'UIScrollViewDelegate', 'UIGestureRecognizerDelegate']
OBJC classrefs resolved: ['CBDashboardSettings', 'CBLocalization', 'CBHttpClient', 'CBLicenseSyncManager', 'CBTouchCloneView', 'CBSlotPillHitButton', 'CBBridgeManager', 'CBOverlayScrollView', 'CBBridgedSplitApp', 'CBWindow', 'CBMultitaskingOverlayView', 'CBDockMetricItemView', 'CBSplitSplashScreenView', 'CBLicenseShieldIconView', 'CBBridgedPortalAppView', 'CBUIAppContainerView', 'CBBridgedUIAppView', 'CBSlotPillView', 'CBDividerButtonInfo', 'CBSplitContainerView', 'CBDividerView', 'CBSlotPlaceholderView', 'CBAssistantManager', 'CBBridgedAssistantView', 'CBBridgeRequest', 'CBLicenseWarningModalView', 'CBBridgedPortalApp', 'CBBridgedAssistantApp', 'CBBridgedUIApp', 'CBAppMetadataItem', 'CBDashboardShared', 'CBAppStateListener', 'CBBridgeManagerDashboard', 'CBDockSystemMonitorView']
OBJC metadata digest: 348c15b9fd2142b4d001abd2d3ab16af108f80d9f525afdcade469e7e4468f25

--- @interface CBLocalization : None (instanceSize=48, ro_flags=0x194) ---
  ivars:
    _activeLanguageCode : @"NSString" offset=8 size=8
    _cachedStringTables : @"NSMutableDictionary" offset=16 size=8
    _activeLanguageTable : @"NSDictionary" offset=24 size=8
    _viTable : @"NSDictionary" offset=32 size=8
    _enTable : @"NSDictionary" offset=40 size=8
  instance methods (6):
    - init  types=@16@0:8
    - reloadLanguage  types=v16@0:8
    - activeLanguageCode  types=@16@0:8
    - stringTableForLanguageCode:  types=@24@0:8@16
    - localizedStringForKey:  types=@24@0:8@16
    - .cxx_destruct  types=v16@0:8
  class methods (7):
    + sharedInstance  types=@16@0:8
    + speechVoiceLanguageCode  types=@16@0:8
    + supportedLanguages  types=@16@0:8
    + displayNameForLanguageCode:  types=@24@0:8@16
    + currentLanguageCode  types=@16@0:8
    + setCurrentLanguageCode:  types=v24@0:8@16
    + localizedStringForKey:  types=@24@0:8@16

--- @interface CBAssistantManager : None (instanceSize=152, ro_flags=0x194) ---
  ivars:
    _isListening : B offset=8 size=1
    _voiceFeedbackEnabled : B offset=9 size=1
    _preferredMapIndex : q offset=16 size=8
    _onStatusUpdate : @? offset=24 size=8
    _speechRecognizer : @"SFSpeechRecognizer" offset=32 size=8
    _recognitionRequest : @"SFSpeechAudioBufferRecognitionRequest" offset=40 size=8
    _recognitionTask : @"SFSpeechRecognitionTask" offset=48 size=8
    _audioEngine : @"AVAudioEngine" offset=56 size=8
    _speechSynthesizer : @"AVSpeechSynthesizer" offset=64 size=8
    _recordedPCMData : @"NSMutableData" offset=72 size=8
    _speakCompletion : @? offset=80 size=8
    _silenceTimer : @"NSTimer" offset=88 size=8
    _lastTranscribedText : @"NSString" offset=96 size=8
    _hudWindow : @"UIWindow" offset=104 size=8
    _hudCard : @"UIVisualEffectView" offset=112 size=8
    _micIconView : @"UIImageView" offset=120 size=8
    _statusLabel : @"UILabel" offset=128 size=8
    _transcriptLabel : @"UILabel" offset=136 size=8
    _pulseAnimation : @"CABasicAnimation" offset=144 size=8
  properties:
    speechRecognizer  attrs=T@"SFSpeechRecognizer",&,N,V_speechRecognizer
    recognitionRequest  attrs=T@"SFSpeechAudioBufferRecognitionRequest",&,N,V_recognitionRequest
    recognitionTask  attrs=T@"SFSpeechRecognitionTask",&,N,V_recognitionTask
    audioEngine  attrs=T@"AVAudioEngine",&,N,V_audioEngine
    speechSynthesizer  attrs=T@"AVSpeechSynthesizer",&,N,V_speechSynthesizer
    recordedPCMData  attrs=T@"NSMutableData",&,N,V_recordedPCMData
    isListening  attrs=TB,N,V_isListening
    speakCompletion  attrs=T@?,C,N,V_speakCompletion
    silenceTimer  attrs=T@"NSTimer",&,N,V_silenceTimer
    lastTranscribedText  attrs=T@"NSString",C,N,V_lastTranscribedText
    hudWindow  attrs=T@"UIWindow",&,N,V_hudWindow
    hudCard  attrs=T@"UIVisualEffectView",&,N,V_hudCard
    micIconView  attrs=T@"UIImageView",&,N,V_micIconView
    statusLabel  attrs=T@"UILabel",&,N,V_statusLabel
    transcriptLabel  attrs=T@"UILabel",&,N,V_transcriptLabel
    pulseAnimation  attrs=T@"CABasicAnimation",&,N,V_pulseAnimation
    preferredMapIndex  attrs=Tq,N,V_preferredMapIndex
    voiceFeedbackEnabled  attrs=TB,N,V_voiceFeedbackEnabled
    onStatusUpdate  attrs=T@?,C,N,V_onStatusUpdate
    hash  attrs=TQ,R
    superclass  attrs=T#,R
    description  attrs=T@"NSString",R,C
    debugDescription  attrs=T@"NSString",R,C
  instance methods (68):
    - init  types=@16@0:8
    - dealloc  types=v16@0:8
    - cb_onLanguageChanged:  types=v24@0:8@16
    - reloadPreferences  types=v16@0:8
    - setupSpeechSynthesizer  types=v16@0:8
    - setupSpeechRecognizer  types=v16@0:8
    - speak:completion:  types=v32@0:8@16@?24
    - stopSpeaking  types=v16@0:8
    - speechSynthesizer:didFinishSpeechUtterance:  types=v32@0:8@16@24
    - toggleListening  types=v16@0:8
    - startListening  types=v16@0:8
    - beginRecordingSession  types=v16@0:8
    - resetSilenceTimer  types=v16@0:8
    - listeningTimeout  types=v16@0:8
    - finishListeningAndProcess  types=v16@0:8
    - stopListening  types=v16@0:8
    - transcribeAudioData:completion:  types=v32@0:8@16@?24
    - processVoiceCommand:  types=v24@0:8@16
    - handleNavigationCommand:  types=v24@0:8@16
    - handleAppLaunchCommand:  types=v24@0:8@16
    - handleMusicCommand:  types=v24@0:8@16
    - triggerBridgeApp:  types=v24@0:8@16
    - dismissCarBridgeApp  types=v16@0:8
    - showHUD  types=v16@0:8
    - startMicPulseAnimation  types=v16@0:8
    - stopMicPulseAnimation  types=v16@0:8
    - updateHUDStatus:subtext:  types=v32@0:8@16@24
    - stopListeningAndDismiss  types=v16@0:8
    - dismissHUD  types=v16@0:8
    - isListening  types=B16@0:8
    - setIsListening:  types=v20@0:8B16
    - preferredMapIndex  types=q16@0:8
    - setPreferredMapIndex:  types=v24@0:8q16
    - voiceFeedbackEnabled  types=B16@0:8
    - setVoiceFeedbackEnabled:  types=v20@0:8B16
    - onStatusUpdate  types=@?16@0:8
    - setOnStatusUpdate:  types=v24@0:8@?16
    - speechRecognizer  types=@16@0:8
    - setSpeechRecognizer:  types=v24@0:8@16
    - recognitionRequest  types=@16@0:8
    - setRecognitionRequest:  types=v24@0:8@16
    - recognitionTask  types=@16@0:8
    - setRecognitionTask:  types=v24@0:8@16
    - audioEngine  types=@16@0:8
    - setAudioEngine:  types=v24@0:8@16
    - speechSynthesizer  types=@16@0:8
    - setSpeechSynthesizer:  types=v24@0:8@16
    - recordedPCMData  types=@16@0:8
    - setRecordedPCMData:  types=v24@0:8@16
    - speakCompletion  types=@?16@0:8
    - setSpeakCompletion:  types=v24@0:8@?16
    - silenceTimer  types=@16@0:8
    - setSilenceTimer:  types=v24@0:8@16
    - lastTranscribedText  types=@16@0:8
    - setLastTranscribedText:  types=v24@0:8@16
    - hudWindow  types=@16@0:8
    - setHudWindow:  types=v24@0:8@16
    - hudCard  types=@16@0:8
    - setHudCard:  types=v24@0:8@16
    - micIconView  types=@16@0:8
    - setMicIconView:  types=v24@0:8@16
    - statusLabel  types=@16@0:8
    - setStatusLabel:  types=v24@0:8@16
    - transcriptLabel  types=@16@0:8
    - setTranscriptLabel:  types=v24@0:8@16
    - pulseAnimation  types=@16@0:8
    - setPulseAnimation:  types=v24@0:8@16
    - .cxx_destruct  types=v16@0:8
  class methods (1):
    + sharedInstance  types=@16@0:8

--- @interface CBDashboardSettings : None (instanceSize=144, ro_flags=0x194) ---
  ivars:
    _portalAppEnabled : B offset=8 size=1
    _screenBlankEnabled : B offset=9 size=1
    _splitScreenEnabled : B offset=10 size=1
    _assistantEnabled : B offset=11 size=1
    _voiceFeedbackEnabled : B offset=12 size=1
    _hideIconLabels : B offset=13 size=1
    _dockSystemMonitorEnabled : B offset=14 size=1
    _dockSystemMonitorShowAll : B offset=15 size=1
    _autoLaunchOnConnect : B offset=16 size=1
    _agreedToEULA : B offset=17 size=1
    _bridgedApps : @"NSArray" offset=24 size=8
    _appSettings : @"NSDictionary" offset=32 size=8
    _preferredMapIndex : q offset=40 size=8
    _splitLeftBundleID : @"NSString" offset=48 size=8
    _splitRightBundleID : @"NSString" offset=56 size=8
    _splitPreset : q offset=64 size=8
    _splitMode : q offset=72 size=8
    _splitApp1 : @"NSString" offset=80 size=8
    _splitApp2 : @"NSString" offset=88 size=8
    _splitApp3 : @"NSString" offset=96 size=8
    _splitApp4 : @"NSString" offset=104 size=8
    _splitRatio : d offset=112 size=8
    _gridCols : q offset=120 size=8
    _gridRows : q offset=128 size=8
    _autoLaunchBundleID : @"NSString" offset=136 size=8
  properties:
    bridgedApps  attrs=T@"NSArray",&,N,V_bridgedApps
    appSettings  attrs=T@"NSDictionary",&,N,V_appSettings
    portalAppEnabled  attrs=TB,N,V_portalAppEnabled
    screenBlankEnabled  attrs=TB,N,V_screenBlankEnabled
    splitScreenEnabled  attrs=TB,N,V_splitScreenEnabled
    assistantEnabled  attrs=TB,N,V_assistantEnabled
    preferredMapIndex  attrs=Tq,N,V_preferredMapIndex
    voiceFeedbackEnabled  attrs=TB,N,V_voiceFeedbackEnabled
    splitLeftBundleID  attrs=T@"NSString",C,N,V_splitLeftBundleID
    splitRightBundleID  attrs=T@"NSString",C,N,V_splitRightBundleID
    splitPreset  attrs=Tq,N,V_splitPreset
    splitMode  attrs=Tq,N,V_splitMode
    splitApp1  attrs=T@"NSString",C,N,V_splitApp1
    splitApp2  attrs=T@"NSString",C,N,V_splitApp2
    splitApp3  attrs=T@"NSString",C,N,V_splitApp3
    splitApp4  attrs=T@"NSString",C,N,V_splitApp4
    splitRatio  attrs=Td,N,V_splitRatio
    gridCols  attrs=Tq,N,V_gridCols
    gridRows  attrs=Tq,N,V_gridRows
    hideIconLabels  attrs=TB,N,V_hideIconLabels
    dockSystemMonitorEnabled  attrs=TB,N,V_dockSystemMonitorEnabled
    dockSystemMonitorShowAll  attrs=TB,N,V_dockSystemMonitorShowAll
    autoLaunchOnConnect  attrs=TB,N,V_autoLaunchOnConnect
    autoLaunchBundleID  attrs=T@"NSString",C,N,V_autoLaunchBundleID
    agreedToEULA  attrs=TB,N,V_agreedToEULA
  instance methods (56):
    - init  types=@16@0:8
    - scaleForBundleID:  types=d24@0:8@16
    - setScale:forBundleID:  types=v32@0:8d16@24
    - setDockSystemMonitorEnabled:  types=v20@0:8B16
    - setDockSystemMonitorShowAll:  types=v20@0:8B16
    - reload  types=v16@0:8
    - reloadAppPrefs  types=v16@0:8
    - bridgedApps  types=@16@0:8
    - setBridgedApps:  types=v24@0:8@16
    - appSettings  types=@16@0:8
    - setAppSettings:  types=v24@0:8@16
    - portalAppEnabled  types=B16@0:8
    - setPortalAppEnabled:  types=v20@0:8B16
    - screenBlankEnabled  types=B16@0:8
    - setScreenBlankEnabled:  types=v20@0:8B16
    - splitScreenEnabled  types=B16@0:8
    - setSplitScreenEnabled:  types=v20@0:8B16
    - assistantEnabled  types=B16@0:8
    - setAssistantEnabled:  types=v20@0:8B16
    - preferredMapIndex  types=q16@0:8
    - setPreferredMapIndex:  types=v24@0:8q16
    - voiceFeedbackEnabled  types=B16@0:8
    - setVoiceFeedbackEnabled:  types=v20@0:8B16
    - splitLeftBundleID  types=@16@0:8
    - setSplitLeftBundleID:  types=v24@0:8@16
    - splitRightBundleID  types=@16@0:8
    - setSplitRightBundleID:  types=v24@0:8@16
    - splitPreset  types=q16@0:8
    - setSplitPreset:  types=v24@0:8q16
    - splitMode  types=q16@0:8
    - setSplitMode:  types=v24@0:8q16
    - splitApp1  types=@16@0:8
    - setSplitApp1:  types=v24@0:8@16
    - splitApp2  types=@16@0:8
    - setSplitApp2:  types=v24@0:8@16
    - splitApp3  types=@16@0:8
    - setSplitApp3:  types=v24@0:8@16
    - splitApp4  types=@16@0:8
    - setSplitApp4:  types=v24@0:8@16
    - splitRatio  types=d16@0:8
    - setSplitRatio:  types=v24@0:8d16
    - gridCols  types=q16@0:8
    - setGridCols:  types=v24@0:8q16
    - gridRows  types=q16@0:8
    - setGridRows:  types=v24@0:8q16
    - hideIconLabels  types=B16@0:8
    - setHideIconLabels:  types=v20@0:8B16
    - dockSystemMonitorEnabled  types=B16@0:8
    - dockSystemMonitorShowAll  types=B16@0:8
    - autoLaunchOnConnect  types=B16@0:8
    - setAutoLaunchOnConnect:  types=v20@0:8B16
    - autoLaunchBundleID  types=@16@0:8
    - setAutoLaunchBundleID:  types=v24@0:8@16
    - agreedToEULA  types=B16@0:8
    - setAgreedToEULA:  types=v20@0:8B16
    - .cxx_destruct  types=v16@0:8
  class methods (5):
    + sharedInstance  types=@16@0:8
    + assistantIconImage  types=@16@0:8
    + portalAppIconImage  types=@16@0:8
    + splitScreenIconImage  types=@16@0:8
    + portalAppIdentifier  types=@16@0:8

--- @interface CBHttpClient : None (instanceSize=16, ro_flags=0x194) ---
  ivars:
    _networkQueue : @"NSObject<OS_dispatch_queue>" offset=8 size=8
  properties:
    networkQueue  attrs=T@"NSObject<OS_dispatch_queue>",&,N,V_networkQueue
  instance methods (6):
    - init  types=@16@0:8
    - postJSON:toURL:timeout:customHeaders:completion:  types=v56@0:8@16@24d32@40@?48
    - getJSONFromURL:timeout:customHeaders:completion:  types=v48@0:8@16d24@32@?40
    - networkQueue  types=@16@0:8
    - setNetworkQueue:  types=v24@0:8@16
    - .cxx_destruct  types=v16@0:8
  class methods (1):
    + sharedClient  types=@16@0:8

--- @interface CBLicenseSyncManager : None (instanceSize=32, ro_flags=0x194) ---
  ivars:
    _isSyncing : B offset=8 size=1
    _syncQueue : @"NSObject<OS_dispatch_queue>" offset=16 size=8
    _lastAttemptTimestamp : Q offset=24 size=8
  properties:
    isSyncing  attrs=TB,N,V_isSyncing
    syncQueue  attrs=T@"NSObject<OS_dispatch_queue>",&,N,V_syncQueue
    lastAttemptTimestamp  attrs=TQ,N,V_lastAttemptTimestamp
  instance methods (24):
    - init  types=@16@0:8
    - deviceHardwareHashHex  types=@16@0:8
    - isLicenseCurrentlyValid  types=B16@0:8
    - remainingLicenseSeconds  types=Q16@0:8
    - isCarPlayScreenConnected  types=B16@0:8
    - checkAndSyncLicenseIfNeeded  types=v16@0:8
    - checkAndSyncLicenseIfNeededWithSource:  types=v24@0:8@16
    - forceSyncWithCompletion:  types=v24@0:8@?16
    - resolvedBackendBaseURL  types=@16@0:8
    - resolvedLicenseServerEndpoint  types=@16@0:8
    - performSyncWithForce:isManualUserAction:completion:  types=v32@0:8B16B20@?24
    - performSyncWithForce:isManualUserAction:source:completion:  types=v40@0:8B16B20@24@?32
    - installAndVerifyLicensePayload:errorMsg:  types=B32@0:8@16^@24
    - actualLicenseExpirationTimestamp  types=Q16@0:8
    - setActualLicenseExpirationTimestamp:  types=v24@0:8Q16
    - actualLicenseTierName  types=@16@0:8
    - setActualLicenseTierName:  types=v24@0:8@16
    - isSyncing  types=B16@0:8
    - setIsSyncing:  types=v20@0:8B16
    - syncQueue  types=@16@0:8
    - setSyncQueue:  types=v24@0:8@16
    - lastAttemptTimestamp  types=Q16@0:8
    - setLastAttemptTimestamp:  types=v24@0:8Q16
    - .cxx_destruct  types=v16@0:8
  class methods (6):
    + sharedInstance  types=@16@0:8
    + isCarPlayScreen:  types=B24@0:8@16
    + isCarPlayScreenConnectedExcludingScreen:  types=B24@0:8@16
    + isCarPlayScreenConnected  types=B16@0:8
    + formatBaseURLString:  types=@24@0:8@16
    + resolvedBackendBaseURL  types=@16@0:8

--- @interface CBTouchCloneView : None (instanceSize=8, ro_flags=0x90) ---
  instance methods (5):
    - sendTouchEventAtPoint:isDown:  types=v36@0:8{CGPoint=dd}16B32
    - touchesBegan:withEvent:  types=v32@0:8@16@24
    - touchesMoved:withEvent:  types=v32@0:8@16@24
    - touchesEnded:withEvent:  types=v32@0:8@16@24
    - touchesCancelled:withEvent:  types=v32@0:8@16@24

--- @interface CBBridgedPortalAppView : None (instanceSize=32, ro_flags=0x194) ---
  ivars:
    _imageView : @"UIImageView" offset=8 size=8
    _touchCloneView : @"CBTouchCloneView" offset=16 size=8
    _displayLink : @"CADisplayLink" offset=24 size=8
  properties:
    imageView  attrs=T@"UIImageView",&,N,V_imageView
    touchCloneView  attrs=T@"CBTouchCloneView",&,N,V_touchCloneView
    displayLink  attrs=T@"CADisplayLink",&,N,V_displayLink
  instance methods (12):
    - initWithFrame:  types=@48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16
    - start  types=v16@0:8
    - stop  types=v16@0:8
    - captureFrame:  types=v24@0:8@16
    - dealloc  types=v16@0:8
    - imageView  types=@16@0:8
    - setImageView:  types=v24@0:8@16
    - touchCloneView  types=@16@0:8
    - setTouchCloneView:  types=v24@0:8@16
    - displayLink  types=@16@0:8
    - setDisplayLink:  types=v24@0:8@16
    - .cxx_destruct  types=v16@0:8

--- @interface CBMultitaskingPillView : None (instanceSize=40, ro_flags=0x194) ---
  ivars:
    _onPillTapped : @? offset=8 size=8
    _blurView : @"UIVisualEffectView" offset=16 size=8
    _iconView : @"UIImageView" offset=24 size=8
    _titleLabel : @"UILabel" offset=32 size=8
  properties:
    onPillTapped  attrs=T@?,C,N,V_onPillTapped
    blurView  attrs=T@"UIVisualEffectView",&,N,V_blurView
    iconView  attrs=T@"UIImageView",&,N,V_iconView
    titleLabel  attrs=T@"UILabel",&,N,V_titleLabel
  instance methods (12):
    - initWithFrame:  types=@48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16
    - pillTapped  types=v16@0:8
    - pillPanned:  types=v24@0:8@16
    - onPillTapped  types=@?16@0:8
    - setOnPillTapped:  types=v24@0:8@?16
    - blurView  types=@16@0:8
    - setBlurView:  types=v24@0:8@16
    - iconView  types=@16@0:8
    - setIconView:  types=v24@0:8@16
    - titleLabel  types=@16@0:8
    - setTitleLabel:  types=v24@0:8@16
    - .cxx_destruct  types=v16@0:8

--- @interface CBSlotPillHitButton : None (instanceSize=40, ro_flags=0x90) ---
  ivars:
    _hitInsets : {UIEdgeInsets="top"d"left"d"bottom"d"right"d} offset=8 size=32
  properties:
    hitInsets  attrs=T{UIEdgeInsets=dddd},N,V_hitInsets
  instance methods (3):
    - pointInside:withEvent:  types=B40@0:8{CGPoint=dd}16@32
    - hitInsets  types={UIEdgeInsets=dddd}16@0:8
    - setHitInsets:  types=v48@0:8{UIEdgeInsets=dddd}16

--- @interface CBSlotPillView : None (instanceSize=96, ro_flags=0x194) ---
  ivars:
    _dotViews : @"NSMutableArray" offset=8 size=8
    _isFocusedMode : B offset=16 size=1
    _showsExpandButton : B offset=17 size=1
    _isCompactMode : B offset=18 size=1
    _onPillTapped : @? offset=24 size=8
    _onPillLongPressed : @? offset=32 size=8
    _onExpandTapped : @? offset=40 size=8
    _onRestoreTapped : @? offset=48 size=8
    _slotIndex : q offset=56 size=8
    _dotsButton : @"UIButton" offset=64 size=8
    _expandButton : @"UIButton" offset=72 size=8
    _restoreButton : @"UIButton" offset=80 size=8
    _separatorView : @"UIView" offset=88 size=8
  properties:
    onPillTapped  attrs=T@?,C,N,V_onPillTapped
    onPillLongPressed  attrs=T@?,C,N,V_onPillLongPressed
    onExpandTapped  attrs=T@?,C,N,V_onExpandTapped
    onRestoreTapped  attrs=T@?,C,N,V_onRestoreTapped
    slotIndex  attrs=Tq,N,V_slotIndex
    isFocusedMode  attrs=TB,N,V_isFocusedMode
    showsExpandButton  attrs=TB,N,V_showsExpandButton
    isCompactMode  attrs=TB,N,V_isCompactMode
    dotsButton  attrs=T@"UIButton",&,N,V_dotsButton
    expandButton  attrs=T@"UIButton",&,N,V_expandButton
    restoreButton  attrs=T@"UIButton",&,N,V_restoreButton
    separatorView  attrs=T@"UIView",&,N,V_separatorView
  instance methods (36):
    - initWithSlotIndex:  types=@24@0:8q16
    - layoutSubviews  types=v16@0:8
    - updateBoundsSize  types=v16@0:8
    - setShowsExpandButton:  types=v20@0:8B16
    - setFocusedMode:  types=v20@0:8B16
    - setCompactMode:  types=v20@0:8B16
    - pointInside:withEvent:  types=B40@0:8{CGPoint=dd}16@32
    - handleLongPress:  types=v24@0:8@16
    - dotsTapped:  types=v24@0:8@16
    - expandTapped:  types=v24@0:8@16
    - restoreTapped:  types=v24@0:8@16
    - bounceButton:  types=v24@0:8@16
    - onPillTapped  types=@?16@0:8
    - setOnPillTapped:  types=v24@0:8@?16
    - onPillLongPressed  types=@?16@0:8
    - setOnPillLongPressed:  types=v24@0:8@?16
    - onExpandTapped  types=@?16@0:8
    - setOnExpandTapped:  types=v24@0:8@?16
    - onRestoreTapped  types=@?16@0:8
    - setOnRestoreTapped:  types=v24@0:8@?16
    - slotIndex  types=q16@0:8
    - setSlotIndex:  types=v24@0:8q16
    - isFocusedMode  types=B16@0:8
    - setIsFocusedMode:  types=v20@0:8B16
    - showsExpandButton  types=B16@0:8
    - isCompactMode  types=B16@0:8
    - setIsCompactMode:  types=v20@0:8B16
    - dotsButton  types=@16@0:8
    - setDotsButton:  types=v24@0:8@16
    - expandButton  types=@16@0:8
    - setExpandButton:  types=v24@0:8@16
    - restoreButton  types=@16@0:8
    - setRestoreButton:  types=v24@0:8@16
    - separatorView  types=@16@0:8
    - setSeparatorView:  types=v24@0:8@16
    - .cxx_destruct  types=v16@0:8

--- @interface CBOverlayScrollView : None (instanceSize=8, ro_flags=0x90) ---
  instance methods (4):
    - initWithFrame:  types=@48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16
    - touchesShouldCancelInContentView:  types=B24@0:8@16
    - addSubview:  types=v24@0:8@16
    - layoutSubviews  types=v16@0:8

--- @interface CBMultitaskingOverlayView : None (instanceSize=160, ro_flags=0x194) ---
  ivars:
    _onCloseRequested : @? offset=8 size=8
    _onMultiSplitSelected : @? offset=16 size=8
    _dimBackground : @"UIView" offset=24 size=8
    _cardShadowContainer : @"UIView" offset=32 size=8
    _sheetCard : @"UIVisualEffectView" offset=40 size=8
    _allApps : @"NSArray" offset=48 size=8
    _appPickerScrollView : @"UIScrollView" offset=56 size=8
    _appPickerPageControl : @"UIPageControl" offset=64 size=8
    _slotBIDs : @"NSMutableArray" offset=72 size=8
    _currentPreset : q offset=80 size=8
    _currentRatio : d offset=88 size=8
    _targetSlotIndex : q offset=96 size=8
    _overlayMode : q offset=104 size=8
    _headerIcon : @"UIImageView" offset=112 size=8
    _titleLabel : @"UILabel" offset=120 size=8
    _appSegmentBtn : @"UIButton" offset=128 size=8
    _layoutSegmentBtn : @"UIButton" offset=136 size=8
    _recentSegmentBtn : @"UIButton" offset=144 size=8
    _runningApps : @"NSArray" offset=152 size=8
  properties:
    onCloseRequested  attrs=T@?,C,N,V_onCloseRequested
    onMultiSplitSelected  attrs=T@?,C,N,V_onMultiSplitSelected
    dimBackground  attrs=T@"UIView",&,N,V_dimBackground
    cardShadowContainer  attrs=T@"UIView",&,N,V_cardShadowContainer
    sheetCard  attrs=T@"UIVisualEffectView",&,N,V_sheetCard
    allApps  attrs=T@"NSArray",&,N,V_allApps
    appPickerScrollView  attrs=T@"UIScrollView",&,N,V_appPickerScrollView
    appPickerPageControl  attrs=T@"UIPageControl",&,N,V_appPickerPageControl
    slotBIDs  attrs=T@"NSMutableArray",&,N,V_slotBIDs
    currentPreset  attrs=Tq,N,V_currentPreset
    currentRatio  attrs=Td,N,V_currentRatio
    targetSlotIndex  attrs=Tq,N,V_targetSlotIndex
    overlayMode  attrs=Tq,N,V_overlayMode
    headerIcon  attrs=T@"UIImageView",&,N,V_headerIcon
    titleLabel  attrs=T@"UILabel",&,N,V_titleLabel
    appSegmentBtn  attrs=T@"UIButton",&,N,V_appSegmentBtn
    layoutSegmentBtn  attrs=T@"UIButton",&,N,V_layoutSegmentBtn
    recentSegmentBtn  attrs=T@"UIButton",&,N,V_recentSegmentBtn
    runningApps  attrs=T@"NSArray",&,N,V_runningApps
    hash  attrs=TQ,R
    superclass  attrs=T#,R
    description  attrs=T@"NSString",R,C
    debugDescription  attrs=T@"NSString",R,C
  instance methods (66):
    - initWithFrame:  types=@48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16
    - dealloc  types=v16@0:8
    - cb_onLanguageChanged:  types=v24@0:8@16
    - loadInstalledApps  types=v16@0:8
    - layoutSubviews  types=v16@0:8
    - setupCardContent  types=v16@0:8
    - setupAppPickerCardsInCardW:cardH:contentY:  types=v40@0:8d16d24d32
    - scrollViewDidScroll:  types=v24@0:8@16
    - pageControlChanged:  types=v24@0:8@16
    - setupPresetCardsInCardW:cardH:contentY:  types=v40@0:8d16d24d32
    - setupRecentAppsCardsInCardW:cardH:contentY:  types=v40@0:8d16d24d32
    - addMoreAppsTapped:  types=v24@0:8@16
    - dismissCustomAlert:  types=v24@0:8@16
    - restartSingleAppTapped:  types=v24@0:8@16
    - closeSingleAppTapped:  types=v24@0:8@16
    - closeAllBridgedAppsTapped:  types=v24@0:8@16
    - switchToAppPickerMode  types=v16@0:8
    - switchToLayoutChooserMode  types=v16@0:8
    - switchToRecentMode  types=v16@0:8
    - toggleMode  types=v16@0:8
    - saveSlotIndex:bid:toSettings:prefs:  types=v48@0:8q16@24@32@40
    - appSelected:  types=v24@0:8@16
    - presetSelected:  types=v24@0:8@16
    - showAppPickerForSlot:parentView:  types=v32@0:8q16@24
    - showLayoutChooserInParentView:  types=v24@0:8@16
    - showRecentAppsInParentView:  types=v24@0:8@16
    - dismissOverlay  types=v16@0:8
    - onCloseRequested  types=@?16@0:8
    - setOnCloseRequested:  types=v24@0:8@?16
    - onMultiSplitSelected  types=@?16@0:8
    - setOnMultiSplitSelected:  types=v24@0:8@?16
    - dimBackground  types=@16@0:8
    - setDimBackground:  types=v24@0:8@16
    - cardShadowContainer  types=@16@0:8
    - setCardShadowContainer:  types=v24@0:8@16
    - sheetCard  types=@16@0:8
    - setSheetCard:  types=v24@0:8@16
    - allApps  types=@16@0:8
    - setAllApps:  types=v24@0:8@16
    - appPickerScrollView  types=@16@0:8
    - setAppPickerScrollView:  types=v24@0:8@16
    - appPickerPageControl  types=@16@0:8
    - setAppPickerPageControl:  types=v24@0:8@16
    - slotBIDs  types=@16@0:8
    - setSlotBIDs:  types=v24@0:8@16
    - currentPreset  types=q16@0:8
    - setCurrentPreset:  types=v24@0:8q16
    - currentRatio  types=d16@0:8
    - setCurrentRatio:  types=v24@0:8d16
    - targetSlotIndex  types=q16@0:8
    - setTargetSlotIndex:  types=v24@0:8q16
    - overlayMode  types=q16@0:8
    - setOverlayMode:  types=v24@0:8q16
    - headerIcon  types=@16@0:8
    - setHeaderIcon:  types=v24@0:8@16
    - titleLabel  types=@16@0:8
    - setTitleLabel:  types=v24@0:8@16
    - appSegmentBtn  types=@16@0:8
    - setAppSegmentBtn:  types=v24@0:8@16
    - layoutSegmentBtn  types=@16@0:8
    - setLayoutSegmentBtn:  types=v24@0:8@16
    - recentSegmentBtn  types=@16@0:8
    - setRecentSegmentBtn:  types=v24@0:8@16
    - runningApps  types=@16@0:8
    - setRunningApps:  types=v24@0:8@16
    - .cxx_destruct  types=v16@0:8

--- @interface CBBridgedUIAppView : None (instanceSize=48, ro_flags=0x194) ---
  ivars:
    _hosting : B offset=8 size=1
    _invalidated : B offset=9 size=1
    _audioOnlyBackgroundMode : B offset=10 size=1
    _bundleIdentifier : @"NSString" offset=16 size=8
    _appViewController : @"SBAppViewController" offset=24 size=8
    _wrapperView : @"UIView" offset=32 size=8
    _appScale : d offset=40 size=8
  properties:
    bundleIdentifier  attrs=T@"NSString",C,N,V_bundleIdentifier
    appViewController  attrs=T@"SBAppViewController",&,N,V_appViewController
    wrapperView  attrs=T@"UIView",&,N,V_wrapperView
    appScale  attrs=Td,N,V_appScale
    hosting  attrs=TB,N,V_hosting
    invalidated  attrs=TB,N,V_invalidated
    audioOnlyBackgroundMode  attrs=TB,N,V_audioOnlyBackgroundMode
  instance methods (29):
    - initWithBundleIdentifier:  types=@24@0:8@16
    - initWithBundleIdentifier:scale:  types=@32@0:8@16d24
    - setAppScale:  types=v24@0:8d16
    - setAudioOnlyBackgroundMode:  types=v20@0:8B16
    - layoutSubviews  types=v16@0:8
    - hitTest:withEvent:  types=@40@0:8{CGPoint=dd}16@32
    - touchesBegan:withEvent:  types=v32@0:8@16@24
    - calculateNativeSizeForSlotRect:  types={CGSize=dd}48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16
    - updateLayout  types=v16@0:8
    - updateSceneSettingsFrame  types=v16@0:8
    - updateSceneFrame  types=v16@0:8
    - refreshSceneLayout  types=v16@0:8
    - startInParentViewController:  types=v24@0:8@16
    - start  types=v16@0:8
    - dismiss  types=v16@0:8
    - dealloc  types=v16@0:8
    - bundleIdentifier  types=@16@0:8
    - setBundleIdentifier:  types=v24@0:8@16
    - appViewController  types=@16@0:8
    - setAppViewController:  types=v24@0:8@16
    - wrapperView  types=@16@0:8
    - setWrapperView:  types=v24@0:8@16
    - appScale  types=d16@0:8
    - hosting  types=B16@0:8
    - setHosting:  types=v20@0:8B16
    - invalidated  types=B16@0:8
    - setInvalidated:  types=v20@0:8B16
    - audioOnlyBackgroundMode  types=B16@0:8
    - .cxx_destruct  types=v16@0:8

--- @interface CBWindow : None (instanceSize=104, ro_flags=0x194) ---
  ivars:
    _boundDisplay : @"CADisplay" offset=8 size=8
    _boundDisplayConfig : @"FBSDisplayConfiguration" offset=16 size=8
    _isVisible : B offset=24 size=1
    _rootWindow : @"UIWindow" offset=32 size=8
    _rootViewController : @"UIViewController" offset=40 size=8
    _contentView : @"UIVisualEffectView" offset=48 size=8
    _multitaskingPill : @"CBMultitaskingPillView" offset=56 size=8
    _multitaskingOverlay : @"CBMultitaskingOverlayView" offset=64 size=8
    _appFrame : {CGRect="origin"{CGPoint="x"d"y"d}"size"{CGSize="width"d"height"d}} offset=72 size=32
  properties:
    appFrame  attrs=T{CGRect={CGPoint=dd}{CGSize=dd}},N,V_appFrame
    rootWindow  attrs=T@"UIWindow",&,N,V_rootWindow
    rootViewController  attrs=T@"UIViewController",&,N,V_rootViewController
    contentView  attrs=T@"UIVisualEffectView",&,N,V_contentView
    multitaskingPill  attrs=T@"CBMultitaskingPillView",&,N,V_multitaskingPill
    multitaskingOverlay  attrs=T@"CBMultitaskingOverlayView",&,N,V_multitaskingOverlay
    isVisible  attrs=TB,N,V_isVisible
  instance methods (28):
    - initWithAppFrame:  types=@48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16
    - getCarPlayDisplay  types=@16@0:8
    - createWindows  types=v16@0:8
    - multitaskingOverlay  types=@16@0:8
    - resizeWindows  types=v16@0:8
    - show  types=v16@0:8
    - hide:  types=v24@0:8@?16
    - isDisplayValid  types=B16@0:8
    - destroyWindows  types=v16@0:8
    - dismiss  types=v16@0:8
    - dealloc  types=v16@0:8
    - showAppPickerForSlot:  types=v24@0:8q16
    - showLayoutChooser  types=v16@0:8
    - showRecentApps  types=v16@0:8
    - appFrame  types={CGRect={CGPoint=dd}{CGSize=dd}}16@0:8
    - setAppFrame:  types=v48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16
    - rootWindow  types=@16@0:8
    - setRootWindow:  types=v24@0:8@16
    - rootViewController  types=@16@0:8
    - setRootViewController:  types=v24@0:8@16
    - contentView  types=@16@0:8
    - setContentView:  types=v24@0:8@16
    - multitaskingPill  types=@16@0:8
    - setMultitaskingPill:  types=v24@0:8@16
    - setMultitaskingOverlay:  types=v24@0:8@16
    - isVisible  types=B16@0:8
    - setIsVisible:  types=v20@0:8B16
    - .cxx_destruct  types=v16@0:8
  class methods (9):
    + activeCarPlayWindow  types=@16@0:8
    + resetCachedBounds  types=v16@0:8
    + carPlayWindowScene  types=@16@0:8
    + carPlayUIScreen  types=@16@0:8
    + carPlayCADisplay  types=@16@0:8
    + carPlayScreenScale  types=d16@0:8
    + carPlayScreenBounds  types={CGRect={CGPoint=dd}{CGSize=dd}}16@0:8
    + carPlayContentInsets  types={UIEdgeInsets=dddd}16@0:8
    + carPlayUsableBounds  types={CGRect={CGPoint=dd}{CGSize=dd}}16@0:8

--- @interface CBDockMetricItemView : None (instanceSize=32, ro_flags=0x194) ---
  ivars:
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

--- @interface CBDockSystemMonitorView : None (instanceSize=66, ro_flags=0x194) ---
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

--- @interface CBSplitSplashScreenView : None (instanceSize=112, ro_flags=0x194) ---
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

--- @interface CBLicenseShieldIconView : None (instanceSize=8, ro_flags=0x90) ---
  instance methods (2):
    - initWithFrame:  types=@48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16
    - drawRect:  types=v48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16

--- @interface CBLicenseWarningModalView : None (instanceSize=96, ro_flags=0x194) ---
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

--- @interface CBBridgedApp : None (instanceSize=32, ro_flags=0x194) ---
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

--- @interface CBUIAppContainerView : None (instanceSize=16, ro_flags=0x194) ---
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

--- @interface CBDividerButtonInfo : None (instanceSize=40, ro_flags=0x194) ---
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

--- @interface CBDividerView : None (instanceSize=48, ro_flags=0x194) ---
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

--- @interface CBSplitContainerView : None (instanceSize=16, ro_flags=0x194) ---
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

--- @interface CBSlotPlaceholderView : None (instanceSize=48, ro_flags=0x194) ---
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

--- @interface CBBridgedAssistantView : None (instanceSize=40, ro_flags=0x194) ---
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

--- @interface CBBridgeRequest : None (instanceSize=24, ro_flags=0x194) ---
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

--- @interface CBDashboardShared : None (instanceSize=8, ro_flags=0x90) ---
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

--- @interface CBBridgeManager : None (instanceSize=144, ro_flags=0x194) ---
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

--- @interface CBAppMetadataItem : None (instanceSize=32, ro_flags=0x194) ---
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

--- @interface CBBridgeManagerDashboard : None (instanceSize=24, ro_flags=0x194) ---
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

--- @interface CBAppStateListener : None (instanceSize=8, ro_flags=0x90) ---
  instance methods (5):
    - init  types=@16@0:8
    - checkStateFile  types=v16@0:8
    - sendStateRequest  types=v16@0:8
    - handleAppDidBecomeActive:  types=v24@0:8@16
    - handleAppStateNotification:  types=v24@0:8@16
  class methods (1):
    + sharedInstance  types=@16@0:8

===== SLICE 1: arm64 sub=arm64e (raw subtype 0x2) filetype=DYLIB flags=0x900085 off=3768320 size=3772144 =====
ncmds=36
load commands: LC_SEGMENT_64, LC_SEGMENT_64, LC_SEGMENT_64, LC_SEGMENT_64, LC_ID_DYLIB, LC_DYLD_CHAINED_FIXUPS, LC_DYLD_EXPORTS_TRIE, LC_SYMTAB, LC_DYSYMTAB, LC_UUID, LC_BUILD_VERSION, LC_SOURCE_VERSION, LC_ENCRYPTION_INFO_64, LC_LOAD_DYLIB, LC_LOAD_DYLIB, LC_LOAD_DYLIB, LC_LOAD_DYLIB, LC_LOAD_DYLIB, LC_LOAD_DYLIB, LC_LOAD_DYLIB, LC_LOAD_DYLIB, LC_LOAD_DYLIB, LC_LOAD_DYLIB, LC_LOAD_DYLIB, LC_LOAD_DYLIB, LC_LOAD_WEAK_DYLIB, LC_LOAD_DYLIB, LC_LOAD_DYLIB, LC_LOAD_DYLIB, LC_RPATH(REQ), LC_RPATH(REQ), LC_RPATH(REQ), LC_RPATH(REQ), LC_FUNCTION_STARTS, LC_DATA_IN_CODE, LC_CODE_SIGNATURE
id_dylib: ('@rpath/DuoFaceDashboard.dylib', '0.0.0', '0.0.0')
uuid: 1f83d1586c9f37898eb7dbb394b89f9c
build_version: ('iOS', '15.0.0', '16.5.0')  min_version: None  source_version: 0.0.0
encryption: (16384, 3440640, 0)  main: None  rpaths: ['/var/jb/Library/Frameworks', '/var/jb/usr/lib', '@loader_path/.jbroot/Library/Frameworks', '@loader_path/.jbroot/usr/lib']
codesig: (3742512, 29632) chained_fixups=True dyld_info=False
linked libraries:
  [LC_LOAD_DYLIB] /usr/lib/libobjc.A.dylib cur=228.0.0 compat=1.0.0
  [LC_LOAD_DYLIB] /System/Library/Frameworks/Foundation.framework/Foundation cur=1971.0.0 compat=300.0.0
  [LC_LOAD_DYLIB] /System/Library/Frameworks/CoreFoundation.framework/CoreFoundation cur=1971.0.0 compat=150.0.0
  [LC_LOAD_DYLIB] /System/Library/Frameworks/UIKit.framework/UIKit cur=6441.1.101 compat=1.0.0
  [LC_LOAD_DYLIB] /System/Library/Frameworks/CoreGraphics.framework/CoreGraphics cur=1690.5.4 compat=64.0.0
  [LC_LOAD_DYLIB] /System/Library/Frameworks/IOKit.framework/Versions/A/IOKit cur=275.0.0 compat=1.0.0
  [LC_LOAD_DYLIB] /System/Library/Frameworks/Security.framework/Security cur=60420.102.1 compat=1.0.0
  [LC_LOAD_DYLIB] /System/Library/Frameworks/AVFoundation.framework/AVFoundation cur=2.0.0 compat=1.0.0
  [LC_LOAD_DYLIB] /System/Library/Frameworks/QuartzCore.framework/QuartzCore cur=1.11.0 compat=1.2.0
  [LC_LOAD_DYLIB] /usr/lib/libsqlite3.dylib cur=346.0.0 compat=9.0.0
  [LC_LOAD_DYLIB] /System/Library/PrivateFrameworks/AppSupport.framework/AppSupport cur=29.0.0 compat=1.0.0
  [LC_LOAD_DYLIB] /System/Library/PrivateFrameworks/BackBoardServices.framework/BackBoardServices cur=1.0.0 compat=1.0.0
  [LC_LOAD_WEAK_DYLIB] /System/Library/Frameworks/Speech.framework/Speech cur=1.0.0 compat=1.0.0
  [LC_LOAD_DYLIB] /usr/lib/libSystem.B.dylib cur=1319.100.3 compat=1.0.0
  [LC_LOAD_DYLIB] /System/Library/Frameworks/AVFAudio.framework/AVFAudio cur=1.0.0 compat=1.0.0
  [LC_LOAD_DYLIB] @rpath/CydiaSubstrate.framework/CydiaSubstrate cur=0.0.0 compat=0.0.0
segments/sections:
  __TEXT,__text addr=0x62f0 size=3074176 off=25328 flags=0x80000400
  __TEXT,__auth_stubs addr=0x2f4b70 size=2464 off=3099504 flags=0x80000408
  __TEXT,__init_offsets addr=0x2f5510 size=8 off=3101968 flags=0x16
  __TEXT,__objc_methlist addr=0x2f5518 size=9532 off=3101976 flags=0x0
  __TEXT,__gcc_except_tab addr=0x2f7a54 size=12356 off=3111508 flags=0x0
  __TEXT,__objc_methname addr=0x2faa98 size=34516 off=3123864 flags=0x2
  __TEXT,__cstring addr=0x30316c size=83459 off=3158380 flags=0x2
  __TEXT,__const addr=0x317770 size=35785 off=3241840 flags=0x0
  __TEXT,__ustring addr=0x32033a size=171056 off=3277626 flags=0x0
  __TEXT,__objc_classname addr=0x349f6a size=931 off=3448682 flags=0x2
  __TEXT,__objc_methtype addr=0x34a30d size=3025 off=3449613 flags=0x2
