//
//  YGPersonMessageViewController.m
//  Yaga
//

#import "YGPersonMessageViewController.h"
#import "YGHUDHelper.h"
#import "YGUserStore.h"
#import "YGImagePostStore.h"
#import "YGVideoPostStore.h"

@interface YGPersonMessageViewController () <UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPickerViewDataSource, UIPickerViewDelegate>

@property (nonatomic, strong) UIButton *avatarButton;
@property (nonatomic, strong) UITextField *nameField;
@property (nonatomic, strong) UIButton *birthdayButton;
@property (nonatomic, strong) UIButton *locationButton;
@property (nonatomic, strong) UIButton *maleButton;
@property (nonatomic, strong) UIButton *femaleButton;
@property (nonatomic, copy) NSString *selectedBirthday;
@property (nonatomic, copy) NSString *selectedLocation;
@property (nonatomic, copy) NSString *selectedGender;
@property (nonatomic, copy) NSString *selectedAvatarName;
@property (nonatomic, copy) NSString *selectedAvatarDataBase64;
@property (nonatomic, strong) UIDatePicker *birthdayPicker;
@property (nonatomic, strong) UIPickerView *locationPickerView;
@property (nonatomic, strong) UIView *pickerOverlayView;
@property (nonatomic, strong) UIView *pickerContainerView;
@property (nonatomic, strong) NSArray<NSString *> *locations;

@end

@implementation YGPersonMessageViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        _locations = [self buildCountryList];
        [self loadCurrentUserProfile];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"";
    self.navigationItem.title = @"";
    self.view.backgroundColor = UIColor.whiteColor;
    [self setupSubviews];
    [self applyCurrentUserProfile];
}

- (void)setupSubviews {
    self.avatarButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.avatarButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.avatarButton.backgroundColor = UIColor.whiteColor;
    self.avatarButton.layer.cornerRadius = 50.0;
    self.avatarButton.clipsToBounds = YES;
    [self.avatarButton setImage:[UIImage imageNamed:@"headplace"] forState:UIControlStateNormal];
    self.avatarButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.avatarButton addTarget:self action:@selector(avatarButtonTapped) forControlEvents:UIControlEventTouchUpInside];

    UILabel *nameLabel = [self fieldTitleLabelWithText:@"Name"];
    UILabel *birthdayLabel = [self fieldTitleLabelWithText:@"Birthday"];
    UILabel *locationLabel = [self fieldTitleLabelWithText:@"Location"];
    UILabel *genderLabel = [self fieldTitleLabelWithText:@"Gender"];

    self.nameField = [self textFieldWithPlaceholder:@"Name"];
    self.birthdayButton = [self dropdownButtonWithTitle:@"Select birthday" action:@selector(birthdayButtonTapped)];
    self.locationButton = [self dropdownButtonWithTitle:@"Select country" action:@selector(locationButtonTapped)];
    self.maleButton = [self genderButtonWithTitle:@"Male" action:@selector(maleButtonTapped)];
    self.femaleButton = [self genderButtonWithTitle:@"Female" action:@selector(femaleButtonTapped)];

    UIButton *saveButton = [self primaryButtonWithTitle:@"Save" action:@selector(saveButtonTapped)];

    [self.view addSubview:self.avatarButton];
    [self.view addSubview:nameLabel];
    [self.view addSubview:self.nameField];
    [self.view addSubview:birthdayLabel];
    [self.view addSubview:self.birthdayButton];
    [self.view addSubview:locationLabel];
    [self.view addSubview:self.locationButton];
    [self.view addSubview:genderLabel];
    [self.view addSubview:self.maleButton];
    [self.view addSubview:self.femaleButton];
    [self.view addSubview:saveButton];

    [NSLayoutConstraint activateConstraints:@[
        [self.avatarButton.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:10.0],
        [self.avatarButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.avatarButton.widthAnchor constraintEqualToConstant:100.0],
        [self.avatarButton.heightAnchor constraintEqualToConstant:100.0],

        [nameLabel.topAnchor constraintEqualToAnchor:self.avatarButton.bottomAnchor constant:36.0],
        [nameLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:32.0],
        [nameLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-32.0],

        [self.nameField.topAnchor constraintEqualToAnchor:nameLabel.bottomAnchor constant:12.0],
        [self.nameField.leadingAnchor constraintEqualToAnchor:nameLabel.leadingAnchor],
        [self.nameField.trailingAnchor constraintEqualToAnchor:nameLabel.trailingAnchor],
        [self.nameField.heightAnchor constraintEqualToConstant:44.0],

        [birthdayLabel.topAnchor constraintEqualToAnchor:self.nameField.bottomAnchor constant:24.0],
        [birthdayLabel.leadingAnchor constraintEqualToAnchor:self.nameField.leadingAnchor],
        [birthdayLabel.trailingAnchor constraintEqualToAnchor:self.nameField.trailingAnchor],

        [self.birthdayButton.topAnchor constraintEqualToAnchor:birthdayLabel.bottomAnchor constant:12.0],
        [self.birthdayButton.leadingAnchor constraintEqualToAnchor:self.nameField.leadingAnchor],
        [self.birthdayButton.trailingAnchor constraintEqualToAnchor:self.nameField.trailingAnchor],
        [self.birthdayButton.heightAnchor constraintEqualToConstant:44.0],

        [locationLabel.topAnchor constraintEqualToAnchor:self.birthdayButton.bottomAnchor constant:24.0],
        [locationLabel.leadingAnchor constraintEqualToAnchor:self.birthdayButton.leadingAnchor],
        [locationLabel.trailingAnchor constraintEqualToAnchor:self.birthdayButton.trailingAnchor],

        [self.locationButton.topAnchor constraintEqualToAnchor:locationLabel.bottomAnchor constant:12.0],
        [self.locationButton.leadingAnchor constraintEqualToAnchor:self.birthdayButton.leadingAnchor],
        [self.locationButton.trailingAnchor constraintEqualToAnchor:self.birthdayButton.trailingAnchor],
        [self.locationButton.heightAnchor constraintEqualToConstant:44.0],

        [genderLabel.topAnchor constraintEqualToAnchor:self.locationButton.bottomAnchor constant:24.0],
        [genderLabel.leadingAnchor constraintEqualToAnchor:self.locationButton.leadingAnchor],
        [genderLabel.trailingAnchor constraintEqualToAnchor:self.locationButton.trailingAnchor],

        [self.maleButton.topAnchor constraintEqualToAnchor:genderLabel.bottomAnchor constant:12.0],
        [self.maleButton.leadingAnchor constraintEqualToAnchor:self.locationButton.leadingAnchor],
        [self.maleButton.heightAnchor constraintEqualToConstant:44.0],

        [self.femaleButton.topAnchor constraintEqualToAnchor:self.maleButton.topAnchor],
        [self.femaleButton.leadingAnchor constraintEqualToAnchor:self.maleButton.trailingAnchor constant:12.0],
        [self.femaleButton.trailingAnchor constraintEqualToAnchor:self.locationButton.trailingAnchor],
        [self.femaleButton.widthAnchor constraintEqualToAnchor:self.maleButton.widthAnchor],
        [self.femaleButton.heightAnchor constraintEqualToConstant:44.0],
        [self.maleButton.trailingAnchor constraintEqualToAnchor:self.femaleButton.leadingAnchor constant:-12.0],

        [saveButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:32.0],
        [saveButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-32.0],
        [saveButton.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-40.0],
        [saveButton.heightAnchor constraintEqualToConstant:56.0],
    ]];
}

- (void)loadCurrentUserProfile {
    NSDictionary *currentUser = [[YGUserStore sharedStore] currentUser];
    _selectedAvatarName = [currentUser[@"avatarName"] length] > 0 ? currentUser[@"avatarName"] : @"headplace";
    _selectedAvatarDataBase64 = [currentUser[@"avatarDataBase64"] isKindOfClass:NSString.class] ? currentUser[@"avatarDataBase64"] : @"";
    _selectedBirthday = [currentUser[@"birthday"] isKindOfClass:NSString.class] ? currentUser[@"birthday"] : @"";
    _selectedLocation = [currentUser[@"location"] isKindOfClass:NSString.class] ? currentUser[@"location"] : @"";
    _selectedGender = [currentUser[@"gender"] isKindOfClass:NSString.class] ? currentUser[@"gender"] : @"";
}

- (void)applyCurrentUserProfile {
    NSDictionary *currentUser = [[YGUserStore sharedStore] currentUser];
    self.nameField.text = [currentUser[@"nickname"] isKindOfClass:NSString.class] ? currentUser[@"nickname"] : @"";

    UIImage *avatarImage = [self currentAvatarImage];
    if (avatarImage != nil) {
        [self.avatarButton setImage:avatarImage forState:UIControlStateNormal];
    }

    if (self.selectedBirthday.length > 0) {
        [self.birthdayButton setTitle:self.selectedBirthday forState:UIControlStateNormal];
        [self.birthdayButton setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    }

    if (self.selectedLocation.length > 0) {
        [self.locationButton setTitle:self.selectedLocation forState:UIControlStateNormal];
        [self.locationButton setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    }

    [self updateGenderButtons];
}

- (UILabel *)fieldTitleLabelWithText:(NSString *)text {
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = text;
    label.textColor = UIColor.blackColor;
    label.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightMedium];
    return label;
}

- (UITextField *)textFieldWithPlaceholder:(NSString *)placeholder {
    UITextField *textField = [[UITextField alloc] init];
    textField.translatesAutoresizingMaskIntoConstraints = NO;
    textField.placeholder = placeholder;
    textField.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.92];
    textField.textColor = UIColor.blackColor;
    textField.font = [UIFont systemFontOfSize:16.0];
    textField.layer.cornerRadius = 22.0;
    textField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 16.0, 44.0)];
    textField.leftViewMode = UITextFieldViewModeAlways;
    textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    textField.autocorrectionType = UITextAutocorrectionTypeNo;
    textField.delegate = self;
    [textField.heightAnchor constraintEqualToConstant:44.0].active = YES;
    return textField;
}

- (UIButton *)dropdownButtonWithTitle:(NSString *)title action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.92];
    button.layer.cornerRadius = 22.0;
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor colorWithWhite:0.55 alpha:1.0] forState:UIControlStateNormal];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];

    UIImageView *arrowImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"lowarrow"]];
    arrowImageView.translatesAutoresizingMaskIntoConstraints = NO;
    arrowImageView.contentMode = UIViewContentModeScaleAspectFit;
    [button addSubview:arrowImageView];

    [NSLayoutConstraint activateConstraints:@[
        [arrowImageView.centerYAnchor constraintEqualToAnchor:button.centerYAnchor],
        [arrowImageView.trailingAnchor constraintEqualToAnchor:button.trailingAnchor constant:-16.0],
        [arrowImageView.widthAnchor constraintEqualToConstant:16.0],
        [arrowImageView.heightAnchor constraintEqualToConstant:16.0],
    ]];

    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    button.contentEdgeInsets = UIEdgeInsetsMake(0.0, 16.0, 0.0, 40.0);
    button.titleLabel.font = [UIFont systemFontOfSize:16.0];
    return button;
}

- (UIButton *)genderButtonWithTitle:(NSString *)title action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightMedium];
    button.backgroundColor = UIColor.whiteColor;
    button.layer.cornerRadius = 22.0;
    button.clipsToBounds = YES;
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (UIButton *)primaryButtonWithTitle:(NSString *)title action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightSemibold];
    button.backgroundColor = [UIColor colorWithRed:0.72 green:0.16 blue:1.0 alpha:1.0];
    button.layer.cornerRadius = 28.0;
    button.clipsToBounds = YES;
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)avatarButtonTapped {
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        [YGHUDHelper showText:@"Photo library is unavailable." inView:self.view];
        return;
    }

    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.allowsEditing = YES;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)birthdayButtonTapped {
    [self presentPickerOverlayWithTitle:@"Select birthday" contentView:[self birthdayPickerContentView] confirmAction:@selector(confirmBirthdaySelection)];
}

- (void)locationButtonTapped {
    [self presentPickerOverlayWithTitle:@"Select country" contentView:[self locationPickerContentView] confirmAction:@selector(confirmLocationSelection)];
}

- (void)maleButtonTapped {
    self.selectedGender = @"Male";
    [self updateGenderButtons];
}

- (void)femaleButtonTapped {
    self.selectedGender = @"Female";
    [self updateGenderButtons];
}

- (void)updateGenderButtons {
    BOOL maleSelected = [self.selectedGender isEqualToString:@"Male"];
    self.maleButton.backgroundColor = maleSelected ? [self colorWithHexString:@"#B829FF"] : UIColor.whiteColor;
    [self.maleButton setTitleColor:maleSelected ? UIColor.whiteColor : UIColor.blackColor forState:UIControlStateNormal];

    BOOL femaleSelected = [self.selectedGender isEqualToString:@"Female"];
    self.femaleButton.backgroundColor = femaleSelected ? [self colorWithHexString:@"#B829FF"] : UIColor.whiteColor;
    [self.femaleButton setTitleColor:femaleSelected ? UIColor.whiteColor : UIColor.blackColor forState:UIControlStateNormal];
}

- (void)saveButtonTapped {
    [self.view endEditing:YES];

    NSString *name = [[self.nameField.text ?: @"" stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] copy];
    if (name.length == 0) {
        [YGHUDHelper showText:@"Please enter your name." inView:self.view];
        return;
    }
    if (self.selectedBirthday.length == 0) {
        [YGHUDHelper showText:@"Please select your birthday." inView:self.view];
        return;
    }
    if (self.selectedLocation.length == 0) {
        [YGHUDHelper showText:@"Please select your country." inView:self.view];
        return;
    }
    if (self.selectedGender.length == 0) {
        [YGHUDHelper showText:@"Please select your gender." inView:self.view];
        return;
    }

    [YGHUDHelper showLoadingAddedTo:self.view text:@"Saving profile..."];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSString *errorMessage = nil;
        BOOL success = [[YGUserStore sharedStore] updateCurrentUserProfileWithNickname:name
                                                                              birthday:self.selectedBirthday
                                                                              location:self.selectedLocation
                                                                                gender:self.selectedGender
                                                                            avatarName:self.selectedAvatarName
                                                                      avatarDataBase64:self.selectedAvatarDataBase64
                                                                                 error:&errorMessage];
        [YGHUDHelper hideLoadingForView:self.view];
        if (!success) {
            [YGHUDHelper showText:errorMessage ?: @"Unable to save profile." inView:self.view];
            return;
        }
        [YGHUDHelper showText:@"Profile updated." inView:self.view];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.navigationController popViewControllerAnimated:YES];
        });
    });
}

- (UIColor *)colorWithHexString:(NSString *)hexString {
    NSString *value = [[hexString stringByReplacingOccurrencesOfString:@"#" withString:@""] uppercaseString];
    if (value.length != 6) {
        return UIColor.clearColor;
    }

    unsigned int red = 0;
    unsigned int green = 0;
    unsigned int blue = 0;
    [[NSScanner scannerWithString:[value substringWithRange:NSMakeRange(0, 2)]] scanHexInt:&red];
    [[NSScanner scannerWithString:[value substringWithRange:NSMakeRange(2, 2)]] scanHexInt:&green];
    [[NSScanner scannerWithString:[value substringWithRange:NSMakeRange(4, 2)]] scanHexInt:&blue];
    return [UIColor colorWithRed:red / 255.0 green:green / 255.0 blue:blue / 255.0 alpha:1.0];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    UIImage *image = info[UIImagePickerControllerEditedImage] ?: info[UIImagePickerControllerOriginalImage];
    if (image != nil) {
        [self.avatarButton setImage:image forState:UIControlStateNormal];
        self.selectedAvatarName = @"custom-avatar";
        NSData *imageData = UIImageJPEGRepresentation(image, 0.8);
        self.selectedAvatarDataBase64 = [imageData base64EncodedStringWithOptions:0] ?: @"";
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (NSArray<NSString *> *)buildCountryList {
    NSArray<NSString *> *countryCodes = [NSLocale ISOCountryCodes];
    NSLocale *locale = [NSLocale currentLocale];
    NSMutableArray<NSString *> *countries = [NSMutableArray arrayWithCapacity:countryCodes.count];
    for (NSString *countryCode in countryCodes) {
        NSString *countryName = [locale displayNameForKey:NSLocaleCountryCode value:countryCode];
        if (countryName.length > 0) {
            [countries addObject:countryName];
        }
    }
    return [countries sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}

- (UIView *)birthdayPickerContentView {
    UIView *contentView = [[UIView alloc] init];
    contentView.translatesAutoresizingMaskIntoConstraints = NO;

    self.birthdayPicker = [[UIDatePicker alloc] init];
    self.birthdayPicker.translatesAutoresizingMaskIntoConstraints = NO;
    self.birthdayPicker.datePickerMode = UIDatePickerModeDate;
    self.birthdayPicker.preferredDatePickerStyle = UIDatePickerStyleWheels;
    self.birthdayPicker.maximumDate = NSDate.date;
    self.birthdayPicker.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    if (self.selectedBirthday.length > 0) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd";
        NSDate *date = [formatter dateFromString:self.selectedBirthday];
        if (date != nil) {
            self.birthdayPicker.date = date;
        }
    }
    [contentView addSubview:self.birthdayPicker];

    [NSLayoutConstraint activateConstraints:@[
        [self.birthdayPicker.topAnchor constraintEqualToAnchor:contentView.topAnchor],
        [self.birthdayPicker.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor],
        [self.birthdayPicker.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor],
        [self.birthdayPicker.bottomAnchor constraintEqualToAnchor:contentView.bottomAnchor],
        [contentView.heightAnchor constraintEqualToConstant:216.0],
    ]];

    return contentView;
}

- (UIView *)locationPickerContentView {
    UIView *contentView = [[UIView alloc] init];
    contentView.translatesAutoresizingMaskIntoConstraints = NO;

    self.locationPickerView = [[UIPickerView alloc] init];
    self.locationPickerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.locationPickerView.dataSource = self;
    self.locationPickerView.delegate = self;
    if (self.selectedLocation.length > 0) {
        NSInteger selectedIndex = [self.locations indexOfObject:self.selectedLocation];
        if (selectedIndex != NSNotFound) {
            [self.locationPickerView selectRow:selectedIndex inComponent:0 animated:NO];
        }
    }
    [contentView addSubview:self.locationPickerView];

    [NSLayoutConstraint activateConstraints:@[
        [self.locationPickerView.topAnchor constraintEqualToAnchor:contentView.topAnchor],
        [self.locationPickerView.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor],
        [self.locationPickerView.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor],
        [self.locationPickerView.bottomAnchor constraintEqualToAnchor:contentView.bottomAnchor],
        [contentView.heightAnchor constraintEqualToConstant:216.0],
    ]];

    return contentView;
}

- (void)presentPickerOverlayWithTitle:(NSString *)title
                          contentView:(UIView *)contentView
                        confirmAction:(SEL)confirmAction {
    [self dismissPickerOverlay];

    self.pickerOverlayView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.pickerOverlayView.translatesAutoresizingMaskIntoConstraints = NO;
    self.pickerOverlayView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.22];
    [self.view addSubview:self.pickerOverlayView];

    UIButton *dismissButton = [UIButton buttonWithType:UIButtonTypeCustom];
    dismissButton.translatesAutoresizingMaskIntoConstraints = NO;
    [dismissButton addTarget:self action:@selector(dismissPickerOverlay) forControlEvents:UIControlEventTouchUpInside];
    [self.pickerOverlayView addSubview:dismissButton];

    self.pickerContainerView = [[UIView alloc] init];
    self.pickerContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.pickerContainerView.backgroundColor = UIColor.whiteColor;
    self.pickerContainerView.layer.cornerRadius = 24.0;
    self.pickerContainerView.clipsToBounds = YES;
    [self.pickerOverlayView addSubview:self.pickerContainerView];

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.text = title;
    titleLabel.textColor = UIColor.blackColor;
    titleLabel.font = [UIFont systemFontOfSize:17.0 weight:UIFontWeightSemibold];

    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    [cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [cancelButton setTitleColor:[self colorWithHexString:@"#808080"] forState:UIControlStateNormal];
    cancelButton.titleLabel.font = [UIFont systemFontOfSize:16.0];
    [cancelButton addTarget:self action:@selector(dismissPickerOverlay) forControlEvents:UIControlEventTouchUpInside];

    UIButton *confirmButton = [UIButton buttonWithType:UIButtonTypeSystem];
    confirmButton.translatesAutoresizingMaskIntoConstraints = NO;
    [confirmButton setTitle:@"Confirm" forState:UIControlStateNormal];
    [confirmButton setTitleColor:[self colorWithHexString:@"#B829FF"] forState:UIControlStateNormal];
    confirmButton.titleLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightSemibold];
    [confirmButton addTarget:self action:confirmAction forControlEvents:UIControlEventTouchUpInside];

    [self.pickerContainerView addSubview:titleLabel];
    [self.pickerContainerView addSubview:cancelButton];
    [self.pickerContainerView addSubview:confirmButton];
    [self.pickerContainerView addSubview:contentView];

    [NSLayoutConstraint activateConstraints:@[
        [self.pickerOverlayView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.pickerOverlayView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.pickerOverlayView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.pickerOverlayView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [dismissButton.topAnchor constraintEqualToAnchor:self.pickerOverlayView.topAnchor],
        [dismissButton.leadingAnchor constraintEqualToAnchor:self.pickerOverlayView.leadingAnchor],
        [dismissButton.trailingAnchor constraintEqualToAnchor:self.pickerOverlayView.trailingAnchor],
        [dismissButton.bottomAnchor constraintEqualToAnchor:self.pickerOverlayView.bottomAnchor],

        [self.pickerContainerView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.pickerContainerView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.pickerContainerView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [titleLabel.topAnchor constraintEqualToAnchor:self.pickerContainerView.topAnchor constant:18.0],
        [titleLabel.centerXAnchor constraintEqualToAnchor:self.pickerContainerView.centerXAnchor],

        [cancelButton.centerYAnchor constraintEqualToAnchor:titleLabel.centerYAnchor],
        [cancelButton.leadingAnchor constraintEqualToAnchor:self.pickerContainerView.leadingAnchor constant:20.0],

        [confirmButton.centerYAnchor constraintEqualToAnchor:titleLabel.centerYAnchor],
        [confirmButton.trailingAnchor constraintEqualToAnchor:self.pickerContainerView.trailingAnchor constant:-20.0],

        [contentView.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:16.0],
        [contentView.leadingAnchor constraintEqualToAnchor:self.pickerContainerView.leadingAnchor],
        [contentView.trailingAnchor constraintEqualToAnchor:self.pickerContainerView.trailingAnchor],
        [contentView.bottomAnchor constraintEqualToAnchor:self.pickerContainerView.safeAreaLayoutGuide.bottomAnchor constant:-12.0],
    ]];
}

- (void)confirmBirthdaySelection {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd";
    self.selectedBirthday = [formatter stringFromDate:self.birthdayPicker.date];
    [self.birthdayButton setTitle:self.selectedBirthday forState:UIControlStateNormal];
    [self.birthdayButton setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    [self dismissPickerOverlay];
}

- (void)confirmLocationSelection {
    NSInteger selectedRow = [self.locationPickerView selectedRowInComponent:0];
    if (selectedRow >= 0 && selectedRow < self.locations.count) {
        self.selectedLocation = self.locations[selectedRow];
        [self.locationButton setTitle:self.selectedLocation forState:UIControlStateNormal];
        [self.locationButton setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    }
    [self dismissPickerOverlay];
}

- (void)dismissPickerOverlay {
    [self.pickerOverlayView removeFromSuperview];
    self.pickerOverlayView = nil;
    self.pickerContainerView = nil;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.locations.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return self.locations[row];
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
    return 32.0;
}

- (UIImage *)currentAvatarImage {
    NSDictionary *currentUser = [[YGUserStore sharedStore] currentUser];
    NSString *avatarLocalPath = currentUser[@"avatarLocalPath"];
    if (avatarLocalPath.length > 0) {
        UIImage *image = [UIImage imageWithContentsOfFile:avatarLocalPath];
        if (image != nil) {
            return image;
        }
    }

    NSString *avatarBase64 = currentUser[@"avatarDataBase64"];
    if (avatarBase64.length > 0) {
        NSData *imageData = [[NSData alloc] initWithBase64EncodedString:avatarBase64 options:0];
        UIImage *image = [UIImage imageWithData:imageData];
        if (image != nil) {
            return image;
        }
    }

    NSString *avatarName = currentUser[@"avatarName"];
    NSString *avatarImageName = currentUser[@"avatarImageName"];
    if (avatarImageName.length > 0) {
        UIImage *image = [[YGImagePostStore sharedStore] imageInPostResourcesNamed:avatarImageName];
        if (image != nil) {
            return image;
        }
        image = [[YGVideoPostStore sharedStore] imageInVideoResourcesNamed:avatarImageName];
        if (image != nil) {
            return image;
        }
    }

    if (avatarName.length > 0) {
        UIImage *image = [UIImage imageNamed:avatarName];
        if (image != nil) {
            return image;
        }
    }

    return [UIImage imageNamed:@"headplace"];
}

@end
