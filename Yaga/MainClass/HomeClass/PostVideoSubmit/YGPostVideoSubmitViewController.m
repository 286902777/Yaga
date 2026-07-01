//
//  YGPostVideoSubmitViewController.m
//  Yaga
//

#import "YGPostVideoSubmitViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <PhotosUI/PhotosUI.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import "YGHUDHelper.h"
#import "YGVideoPostStore.h"

extern NSString * const YGVideoPostDidPublishNotification;

@interface YGPostVideoSubmitViewController () <UITextViewDelegate, PHPickerViewControllerDelegate>

@property (nonatomic, strong) UIButton *postButton;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UILabel *placeholderLabel;
@property (nonatomic, strong) UILabel *addVideoLabel;
@property (nonatomic, strong) UIControl *videoContainerView;
@property (nonatomic, strong) UIImageView *videoPreviewImageView;
@property (nonatomic, strong) UIImageView *addImageView;
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, copy, nullable) NSURL *selectedVideoURL;

@end

@implementation YGPostVideoSubmitViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = UIColor.whiteColor;
    [self setupSubviews];
}

- (void)setupSubviews {
    self.postButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.postButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.postButton.backgroundColor = [self colorWithHexString:@"#B829FF"];
    self.postButton.layer.cornerRadius = 20.0;
    self.postButton.clipsToBounds = YES;
    [self.postButton setTitle:@"Post" forState:UIControlStateNormal];
    [self.postButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.postButton.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightBold];
    [self.postButton addTarget:self action:@selector(postButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.postButton.widthAnchor constraintEqualToConstant:68.0].active = YES;
    [self.postButton.heightAnchor constraintEqualToConstant:40.0].active = YES;
    [self yg_setRightView:self.postButton];

    self.textView = [[UITextView alloc] init];
    self.textView.translatesAutoresizingMaskIntoConstraints = NO;
    self.textView.backgroundColor = UIColor.clearColor;
    self.textView.textColor = UIColor.blackColor;
    self.textView.font = [UIFont systemFontOfSize:15.0];
    self.textView.textContainerInset = UIEdgeInsetsZero;
    self.textView.textContainer.lineFragmentPadding = 0.0;
    self.textView.delegate = self;
    [self.view addSubview:self.textView];

    self.placeholderLabel = [[UILabel alloc] init];
    self.placeholderLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.placeholderLabel.text = @"Say something";
    self.placeholderLabel.textColor = [self colorWithHexString:@"#808080"];
    self.placeholderLabel.font = [UIFont systemFontOfSize:14.0];
    [self.textView addSubview:self.placeholderLabel];

    self.addVideoLabel = [[UILabel alloc] init];
    self.addVideoLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.addVideoLabel.text = @"Add video";
    self.addVideoLabel.textColor = UIColor.blackColor;
    self.addVideoLabel.font = [UIFont boldSystemFontOfSize:18.0];
    [self.view addSubview:self.addVideoLabel];

    self.videoContainerView = [[UIControl alloc] init];
    self.videoContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.videoContainerView.backgroundColor = UIColor.whiteColor;
    self.videoContainerView.layer.cornerRadius = 14.0;
    self.videoContainerView.clipsToBounds = YES;
    [self.videoContainerView addTarget:self action:@selector(videoContainerTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.videoContainerView];

    self.videoPreviewImageView = [[UIImageView alloc] init];
    self.videoPreviewImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.videoPreviewImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.videoPreviewImageView.clipsToBounds = YES;
    self.videoPreviewImageView.hidden = YES;
    [self.videoContainerView addSubview:self.videoPreviewImageView];

    self.addImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"placeaddimage"]];
    self.addImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.addImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.videoContainerView addSubview:self.addImageView];

    self.deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.deleteButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.deleteButton.hidden = YES;
    [self.deleteButton setImage:[UIImage imageNamed:@"postimage"] forState:UIControlStateNormal];
    [self.deleteButton addTarget:self action:@selector(deleteButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.videoContainerView addSubview:self.deleteButton];

    [NSLayoutConstraint activateConstraints:@[
        [self.textView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:28.0],
        [self.textView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:15.0],
        [self.textView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-15.0],
        [self.textView.heightAnchor constraintEqualToConstant:86.0],

        [self.placeholderLabel.topAnchor constraintEqualToAnchor:self.textView.topAnchor],
        [self.placeholderLabel.leadingAnchor constraintEqualToAnchor:self.textView.leadingAnchor],
        [self.placeholderLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.textView.trailingAnchor],

        [self.addVideoLabel.topAnchor constraintEqualToAnchor:self.textView.bottomAnchor constant:58.0],
        [self.addVideoLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:23.0],
        [self.addVideoLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor constant:-23.0],

        [self.videoContainerView.topAnchor constraintEqualToAnchor:self.addVideoLabel.bottomAnchor constant:26.0],
        [self.videoContainerView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:23.0],
        [self.videoContainerView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-23.0],
        [self.videoContainerView.heightAnchor constraintEqualToAnchor:self.videoContainerView.widthAnchor multiplier:240.0 / 335.0],

        [self.videoPreviewImageView.topAnchor constraintEqualToAnchor:self.videoContainerView.topAnchor],
        [self.videoPreviewImageView.leadingAnchor constraintEqualToAnchor:self.videoContainerView.leadingAnchor],
        [self.videoPreviewImageView.trailingAnchor constraintEqualToAnchor:self.videoContainerView.trailingAnchor],
        [self.videoPreviewImageView.bottomAnchor constraintEqualToAnchor:self.videoContainerView.bottomAnchor],

        [self.addImageView.centerXAnchor constraintEqualToAnchor:self.videoContainerView.centerXAnchor],
        [self.addImageView.centerYAnchor constraintEqualToAnchor:self.videoContainerView.centerYAnchor],
        [self.addImageView.widthAnchor constraintEqualToConstant:52.0],
        [self.addImageView.heightAnchor constraintEqualToConstant:52.0],

        [self.deleteButton.topAnchor constraintEqualToAnchor:self.videoContainerView.topAnchor constant:8.0],
        [self.deleteButton.trailingAnchor constraintEqualToAnchor:self.videoContainerView.trailingAnchor constant:-8.0],
        [self.deleteButton.widthAnchor constraintEqualToConstant:28.0],
        [self.deleteButton.heightAnchor constraintEqualToConstant:28.0]
    ]];
}

- (void)videoContainerTapped {
    [self presentVideoPicker];
}

- (void)presentVideoPicker {
    PHPickerConfiguration *configuration = [[PHPickerConfiguration alloc] init];
    configuration.filter = [PHPickerFilter videosFilter];
    configuration.selectionLimit = 1;

    PHPickerViewController *picker = [[PHPickerViewController alloc] initWithConfiguration:configuration];
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results {
    [picker dismissViewControllerAnimated:YES completion:nil];
    PHPickerResult *result = results.firstObject;
    if (result == nil) {
        return;
    }

    NSString *movieTypeIdentifier = UTTypeMovie.identifier;
    if (![result.itemProvider hasItemConformingToTypeIdentifier:movieTypeIdentifier]) {
        return;
    }

    [result.itemProvider loadFileRepresentationForTypeIdentifier:movieTypeIdentifier completionHandler:^(NSURL * _Nullable url, NSError * _Nullable error) {
        if (url == nil) {
            return;
        }

        NSURL *copiedURL = [self copiedVideoURLFromURL:url];
        UIImage *thumbnailImage = copiedURL != nil ? [self thumbnailImageForVideoURL:copiedURL] : nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            self.selectedVideoURL = copiedURL;
            self.videoPreviewImageView.image = thumbnailImage;
            self.videoPreviewImageView.hidden = (thumbnailImage == nil);
            self.addImageView.hidden = (thumbnailImage != nil);
            self.deleteButton.hidden = (thumbnailImage == nil);
        });
    }];
}

- (NSURL *)copiedVideoURLFromURL:(NSURL *)url {
    NSString *extension = url.pathExtension.length > 0 ? url.pathExtension : @"mov";
    NSString *fileName = [NSString stringWithFormat:@"yaga_post_video_%@.%@", NSUUID.UUID.UUIDString, extension];
    NSURL *destinationURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:fileName]];
    [[NSFileManager defaultManager] removeItemAtURL:destinationURL error:nil];
    NSError *copyError = nil;
    BOOL success = [[NSFileManager defaultManager] copyItemAtURL:url toURL:destinationURL error:&copyError];
    return success ? destinationURL : nil;
}

- (UIImage *)thumbnailImageForVideoURL:(NSURL *)videoURL {
    AVAsset *asset = [AVAsset assetWithURL:videoURL];
    AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    imageGenerator.appliesPreferredTrackTransform = YES;
    imageGenerator.maximumSize = CGSizeMake(670.0, 480.0);

    NSError *error = nil;
    CGImageRef imageRef = [imageGenerator copyCGImageAtTime:CMTimeMakeWithSeconds(0.1, 600)
                                                 actualTime:NULL
                                                      error:&error];
    if (imageRef == NULL) {
        return nil;
    }

    UIImage *image = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    return image;
}

- (void)deleteButtonTapped {
    self.selectedVideoURL = nil;
    self.videoPreviewImageView.image = nil;
    self.videoPreviewImageView.hidden = YES;
    self.addImageView.hidden = NO;
    self.deleteButton.hidden = YES;
}

- (void)postButtonTapped {
    [self.view endEditing:YES];
    NSString *content = [self.textView.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (content.length == 0) {
        [YGHUDHelper showText:@"Please enter content." inView:self.view];
        return;
    }
    if (self.selectedVideoURL == nil) {
        [YGHUDHelper showText:@"Please add video." inView:self.view];
        return;
    }

    self.postButton.enabled = NO;
    [YGHUDHelper showLoadingAddedTo:self.view text:@"Posting..."];
    NSTimeInterval delay = [self randomPostingDelay];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSDictionary *post = [[YGVideoPostStore sharedStore] addLocalVideoPostWithText:content videoURL:self.selectedVideoURL];
        self.postButton.enabled = YES;
        [YGHUDHelper hideLoadingForView:self.view];
        if (post == nil) {
            [YGHUDHelper showText:@"Post failed." inView:self.view];
            return;
        }

        [YGHUDHelper showText:@"Post successful." inView:self.view];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:YGVideoPostDidPublishNotification object:nil];
            [self.navigationController popViewControllerAnimated:YES];
        });
    });
}

- (NSTimeInterval)randomPostingDelay {
    return 1.0 + (NSTimeInterval)arc4random_uniform(2001) / 1000.0;
}

- (void)textViewDidChange:(UITextView *)textView {
    self.placeholderLabel.hidden = textView.text.length > 0;
}

- (UIColor *)colorWithHexString:(NSString *)hexString {
    NSString *cleanString = [[hexString stringByReplacingOccurrencesOfString:@"#" withString:@""] uppercaseString];
    unsigned int value = 0;
    [[NSScanner scannerWithString:cleanString] scanHexInt:&value];
    return [UIColor colorWithRed:((value >> 16) & 0xFF) / 255.0
                           green:((value >> 8) & 0xFF) / 255.0
                            blue:(value & 0xFF) / 255.0
                           alpha:1.0];
}

@end
