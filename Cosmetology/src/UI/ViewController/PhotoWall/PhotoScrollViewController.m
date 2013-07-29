//
//  PhotoScrollViewController.m
//  homi
//   @：照片滑动预览
//  Created by mijie on 12-7-6.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "PhotoScrollViewController.h"
#import "AdPhotoInfo.h"
#import "SubProductInfo.h"
#import "PhotoBrowserDataSource.h"
#import "UIColor+Extra.h"
#import "MHImagePickerMutilSelector.h"
#import "CommonUtil.h"
#import "ResourceCache.h"
#import "AdPhotoManager.h"
#import "SubCatalogManager.h"
#import "PriceViewController.h"
#import "MessageListsViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "KTPhotoView.h"
#import "MainProductInfo.h"
#import "MainCatalogManager.h"
#import "UIAlertView+Blocks.h"

#define BTN_LIKE_TAG   1001
#define BTN_COMMENT_TAG 1002
#define BTN_REPORT_TAG  1003
#define BTN_DEL_TAG     1004
#define ALERT_VIEW_DEL_TAG 1005


static BOOL isProsecutingPhoto = NO;


@interface PhotoScrollViewController (){
    //视频
    MPMoviePlayerController *moviePlayer;
    NSURL *_videoURL;
    int _moviePlayState;
}

@end


@implementation PhotoScrollViewController

@synthesize delegate = _delegate;


- (id)initWithDataSource:(id <KTPhotoBrowserDataSource>)dataSource andStartWithPhotoAtIndex:(NSUInteger)index
{
    self = [super initWithDataSource:dataSource andStartWithPhotoAtIndex:index];
    if (self)
    {
        
    }
    return self;
}

- (void)dealloc
{

}


- (void)loadView
{
    [super loadView];

    //把navigatorController的delegate设置为自己,用于在显示本页面时候设置全屏
    // self.navigationController.delegate = self;

    NSMutableArray         *buttonArray = [NSMutableArray array];

    // 设置标题栏
    self.titleBar.frame = CGRectMake(0, 0, self.view.bounds.size.width, kPhotoBrowerTitleBarHight);
    [self.titleBar.btnBack addTarget:self action:@selector(back:) forControlEvents:UIControlEventTouchUpInside];

    // 设置底部工具栏
    self.toolbar.frame = CGRectMake(0, self.view.bounds.size.height - kPhotoBrowerToolBarHight, self.view.bounds.size.width, kPhotoBrowerToolBarHight);
    if (_bIsEdit)
    {
        UIButton *pickVedio = [UIButton buttonWithType:UIButtonTypeCustom];
        [pickVedio setTitle:@"添加视频" forState:UIControlStateNormal];
//        [pickVedio setImage:[UIImage imageNamed:@"btn_photo_brower_toolbar_del_nomal.png"] forState:UIControlStateNormal];
//        [pickVedio setImage:[UIImage imageNamed:@"btn_photo_brower_toolbar_del_highted.png"] forState:UIControlStateHighlighted];
        [pickVedio addTarget:self action:@selector(pickVedioBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        pickVedio.tag       = BTN_COMMENT_TAG;
        [buttonArray addObject:pickVedio];
        
        UIButton *addPhotoButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [addPhotoButton setTitle:@"添加照片" forState:UIControlStateNormal];
//        [addPhotoButton setImage:[UIImage imageNamed:@"btn_photo_brower_toolbar_del_nomal.png"] forState:UIControlStateNormal];
//        [addPhotoButton setImage:[UIImage imageNamed:@"btn_photo_brower_toolbar_del_highted.png"] forState:UIControlStateHighlighted];
        [addPhotoButton addTarget:self action:@selector(addBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        addPhotoButton.tag       = BTN_COMMENT_TAG;
        [buttonArray addObject:addPhotoButton];
        
        
        UIButton *deletePhotoButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [deletePhotoButton setTitle:@"删除广告" forState:UIControlStateNormal];
        //        [addPhotoButton setImage:[UIImage imageNamed:@"btn_photo_brower_toolbar_del_nomal.png"] forState:UIControlStateNormal];
        //        [addPhotoButton setImage:[UIImage imageNamed:@"btn_photo_brower_toolbar_del_highted.png"] forState:UIControlStateHighlighted];
        [deletePhotoButton addTarget:self action:@selector(deleteBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        deletePhotoButton.tag       = BTN_COMMENT_TAG;
        [buttonArray addObject:deletePhotoButton];
        
//        UIButton *videoButton = [UIButton buttonWithType:UIButtonTypeCustom];
//        [videoButton setImage:[UIImage imageNamed:@"btn_photo_brower_toolbar_del_nomal.png"] forState:UIControlStateNormal];
//        [videoButton setImage:[UIImage imageNamed:@"btn_photo_brower_toolbar_del_highted.png"] forState:UIControlStateHighlighted];
//        [videoButton addTarget:self action:@selector(videoBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
//        videoButton.tag       = BTN_COMMENT_TAG;
        //[buttonArray addObject:videoButton];
        
        //判断是不是超值体验的广告,是的话不能添加报价页面
        SubProductInfo *subProduct = [[SubCatalogManager instance] subProductInfoForProductID:_subProductID];
        MainProductInfo *expProduct = [[MainCatalogManager instance] experienceCatalog];
        if (subProduct.mainProductID != expProduct.productID) {
            UIButton *priceButton = [UIButton buttonWithType:UIButtonTypeCustom];
            //        [priceButton setImage:[UIImage imageNamed:@"btn_photo_brower_toolbar_del_nomal.png"] forState:UIControlStateNormal];
            //        [priceButton setImage:[UIImage imageNamed:@"btn_photo_brower_toolbar_del_highted.png"] forState:UIControlStateHighlighted];
            [priceButton setTitle:@"至尊价" forState:UIControlStateNormal];
            [priceButton addTarget:self action:@selector(priceBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
            priceButton.tag       = BTN_COMMENT_TAG;
            [buttonArray addObject:priceButton];
        }
        UIButton *messageListButton = [UIButton buttonWithType:UIButtonTypeCustom];
//        [messageListButton setImage:[UIImage imageNamed:@"btn_photo_brower_toolbar_del_nomal.png"] forState:UIControlStateNormal];
//        [messageListButton setImage:[UIImage imageNamed:@"btn_photo_brower_toolbar_del_highted.png"] forState:UIControlStateHighlighted];
        [messageListButton setTitle:@"留言板" forState:UIControlStateNormal];
        [messageListButton addTarget:self action:@selector(messageListBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        messageListButton.tag = BTN_DEL_TAG;
        [buttonArray addObject:messageListButton];
    }
    else
    {
        //判断是不是超值体验的广告,是的话不能添加报价页面
        SubProductInfo *subProduct = [[SubCatalogManager instance] subProductInfoForProductID:_subProductID];
        MainProductInfo *expProduct = [[MainCatalogManager instance] experienceCatalog];
        if (subProduct.mainProductID != expProduct.productID) {
            UIButton *priceButton = [UIButton buttonWithType:UIButtonTypeCustom];
            //        [priceButton setImage:[UIImage imageNamed:@"btn_photo_brower_toolbar_del_nomal.png"] forState:UIControlStateNormal];
            //        [priceButton setImage:[UIImage imageNamed:@"btn_photo_brower_toolbar_del_highted.png"] forState:UIControlStateHighlighted];
            [priceButton setTitle:@"报价" forState:UIControlStateNormal];
            [priceButton addTarget:self action:@selector(priceBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
            priceButton.tag       = BTN_COMMENT_TAG;
            [buttonArray addObject:priceButton];
        }

        
        UIButton *messageListButton = [UIButton buttonWithType:UIButtonTypeCustom];
//        [messageListButton setImage:[UIImage imageNamed:@"btn_photo_brower_toolbar_del_nomal.png"] forState:UIControlStateNormal];
//        [messageListButton setImage:[UIImage imageNamed:@"btn_photo_brower_toolbar_del_highted.png"] forState:UIControlStateHighlighted];
        [messageListButton setTitle:@"留言板" forState:UIControlStateNormal];
        [messageListButton addTarget:self action:@selector(messageListBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        messageListButton.tag = BTN_DEL_TAG;
        [buttonArray addObject:messageListButton];
    }

    self.toolbar.buttonArray = buttonArray;
    if (_bIsEdit) {
        self.isShowChromeAlways = YES;
    }
    [self showChrome];
    self.hidesBottomBarWhenPushed = NO;
}

- (void)viewDidLoad
{
    DDetailLog(@"viewDidLoad:%@", self);
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self];

}

-(void)showIncrementTipsView{

}



-(void)setBIsEdit:(BOOL)isEdit{
    _bIsEdit = isEdit;
    if (_bIsEdit) {
        self.isShowChromeAlways = YES;
        [self showChrome];
    }
}

- (void)back:(UIButton *)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)likePhotoBtnClick:(UIButton *)button
{
//    PhotoBrowserDataSource *dataSource = (PhotoBrowserDataSource *)dataSource_;
//    PhotoInfo              *photoInfo  = [[dataSource photoList] objectAtIndex:currentIndex_];
//    if (!photoInfo.isLike){
//        photoInfo.isLike = YES;
//        photoInfo.numOfLike += 1;
//        [self showIncrementTipsView];
//        [[ScreenWaitingView shareScreenWaitingView] updateMessage:@"喜欢该照片..."];
//        [[PhotoAlbumManager instance] likePhotoInfo:photoInfo];
//    }
}

-(void)pickVedioBtnClicked:(UIButton *)sender{
    
    if(![_popController isPopoverVisible])
    {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.contentSizeForViewInPopover = CGSizeMake(320, 480);
        picker.delegate = self;
        [picker setAllowsEditing:NO];
        picker.modalTransitionStyle          = UIModalTransitionStyleCoverVertical;
        picker.mediaTypes = [[NSArray alloc] initWithObjects:(NSString *)kUTTypeMovie, nil];
        if (!_popController)
        {
            _popController = [[UIPopoverController alloc] initWithContentViewController:picker];
        }else{
            [_popController setContentViewController:picker];
        }
        
        [_popController presentPopoverFromRect:[sender convertRect:sender.bounds toView:self.view]
                                        inView:self.view
                      permittedArrowDirections:UIPopoverArrowDirectionUp
                                      animated:YES];
    }
    else
    {
        [_popController dismissPopoverAnimated:YES];
    }
}

-(void)videoBtnClicked:(UIButton *)button{
    
//    SubProductInfo *subProductInfo = [[SubCatalogManager instance] subProductInfoForProductID:_subProductID];
//    _videoURL = [NSURL fileURLWithPath:subProductInfo.vedioURL isDirectory:NO];
//    NSLog(@"videoURL is %@",_videoURL);
//    if (_videoURL == nil) {
//        UIAlertView *errorMsg = [[UIAlertView alloc]initWithTitle:@"温馨提示" message:@"视频地址为空" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil];
//        [errorMsg show];
//        return;
//    }
//    
//    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(exitFullScreen:) name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
//    moviePlayer = [[MPMoviePlayerController alloc]initWithContentURL:_videoURL];
//    [moviePlayer prepareToPlay];
//    moviePlayer.shouldAutoplay = YES;
//    _moviePlayState = MPMoviePlaybackStateStopped;
//    [moviePlayer setControlStyle:MPMovieControlStyleFullscreen];
//    [moviePlayer.view setFrame:self.view.bounds];
//    [self.view addSubview:moviePlayer.view];

}

-(void)playVedio:(UIButton *)vedioBtn{
    KTPhotoView *photoView = (KTPhotoView *)vedioBtn.superview;
    AdPhotoInfo *photoInfo = [[(PhotoBrowserDataSource *)dataSource_ photoList] objectAtIndex:photoView.index];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(exitFullScreen:) name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
    NSURL *url = [NSURL fileURLWithPath:photoInfo.vedioFilePath isDirectory:NO];
    moviePlayer = [[MPMoviePlayerController alloc]initWithContentURL:url];
    [moviePlayer prepareToPlay];
    moviePlayer.shouldAutoplay = YES;
    _moviePlayState = MPMoviePlaybackStateStopped;
    [moviePlayer setControlStyle:MPMovieControlStyleFullscreen];
    [moviePlayer.view setFrame:self.view.bounds];
    [self.view addSubview:moviePlayer.view];
    
}

-(void)exitFullScreen:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
    
    NSNumber *reason = [[notification userInfo]objectForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey];
    if (moviePlayer == nil) {
        return;
    }
    
    switch ([reason integerValue]) {
        case MPMovieFinishReasonPlaybackEnded:
        {
            NSLog(@"%@,The movie has playback ended!",self);
            [moviePlayer stop];
            _moviePlayState = MPMoviePlaybackStateStopped;
            [moviePlayer.view removeFromSuperview];
            moviePlayer = nil;
            break;
        }
        case MPMovieFinishReasonPlaybackError:
        {
            NSLog(@"An error was encountered during playback");
            UIAlertView *errorMsg = [[UIAlertView alloc]initWithTitle:@"温馨提示" message:@"视频播放出错" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil];
            [errorMsg show];
            break;
        }
        case MPMovieFinishReasonUserExited:
        {
            [moviePlayer stop];
            _moviePlayState = MPMoviePlaybackStateStopped;
            [moviePlayer.view removeFromSuperview];
            moviePlayer = nil;
            NSLog(@"moviePlayerFinish is %@",moviePlayer);
            break;
        }
            
        default:
            break;
    }
    
}


- (void)commentPhotoBtnClick:(UIButton *)button
{

}

- (void)reportBtnClick:(UIButton *)sender
{

}

-(void)addBtnClicked:(UIButton *)sender{

    if(![_popController isPopoverVisible])
    {
        MHImagePickerMutilSelector *imagePickerMutilSelector = [MHImagePickerMutilSelector standardSelector];//自动释放
        imagePickerMutilSelector.delegate = self;//设置代理
        imagePickerMutilSelector.limit = NSIntegerMax;
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.contentSizeForViewInPopover = CGSizeMake(320, 480);
        picker.delegate = imagePickerMutilSelector;//将UIImagePicker的代理指向到imagePickerMutilSelector
        [picker setAllowsEditing:NO];
        picker.sourceType                    = UIImagePickerControllerSourceTypePhotoLibrary;
        picker.modalTransitionStyle          = UIModalTransitionStyleCoverVertical;
        picker.navigationController.delegate = imagePickerMutilSelector;//将UIImagePicker的导航代理指向到imagePickerMutilSelector

        imagePickerMutilSelector.imagePicker = picker;//使imagePickerMutilSelector得知其控制的UIImagePicker实例，为释放时需要。
        if (!_popController)
        {
            _popController = [[UIPopoverController alloc] initWithContentViewController:picker];
        }else{
            [_popController setContentViewController:picker];
        }

        [_popController presentPopoverFromRect:[sender convertRect:sender.bounds toView:self.view]
                                        inView:self.view
                      permittedArrowDirections:UIPopoverArrowDirectionUp
                                      animated:YES];
    }
    else
    {
        [_popController dismissPopoverAnimated:YES];
    }
}

-(void)deleteBtnClicked:(UIButton *)sender{
    RIButtonItem *confirmItem = [RIButtonItem item];
    confirmItem.label = @"确定";
    confirmItem.action = ^{
        //删除数据库的广告
        //获取广告实体,插入视频
        AdPhotoInfo *photoInfo = [[(PhotoBrowserDataSource *)dataSource_ photoList] objectAtIndex:currentIndex_];
        if (photoInfo) {
            [[ResourceCache instance] deleteResourceForPath:photoInfo.imageFilePath];
            [[ResourceCache instance] deleteResourceForPath:photoInfo.vedioFilePath];
            [[AdPhotoManager instance] deleteAdPhotoForId:photoInfo.photoId];
        }
        [self deleteCurrentPhoto];
    };
    RIButtonItem *cancelItem = [RIButtonItem item];
    cancelItem.label = @"取消";
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"是否要删除当前广告"
                                                        message:nil
                                               cancelButtonItem:cancelItem
                                               otherButtonItems:confirmItem, nil];
    [alertView show];
}

- (void)messageListBtnClicked:(UIButton *)sender
{
//    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"确定要删除该照片？" message:nil delegate:self cancelButtonTitle:@"确定" otherButtonTitles:@"取消", nil];
//    alertView.tag = ALERT_VIEW_DEL_TAG;
//    [alertView show];

    //TODO: 此处该成查看留言列表
    MessageListsViewController *messageListsViewController = [[MessageListsViewController alloc]initWithProductId:_subProductID];
    DDetailLog(@"%d",_subProductID);
    [self.navigationController pushViewController:messageListsViewController animated:YES];
    DDetailLog(@"留言列表按钮");
}

-(void)priceBtnClicked:(UIButton *)btn{
    PriceViewController *priceViewController = [[PriceViewController alloc] initWithSubProductID:_subProductID];
    DDetailLog(@"%d",_subProductID);
    [self.navigationController pushViewController:priceViewController animated:YES];
}


#pragma mark UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    [_popController dismissPopoverAnimated:YES];
    DDetailLog(@"info is %@",info);
    NSURL *vedioURL = [info objectForKey:UIImagePickerControllerMediaURL];
    NSData *vedioData = [NSData dataWithContentsOfURL:vedioURL];
    NSString *bgUuid = [CommonUtil uuid];
    NSString *vedioFilePath = [[ResourceCache instance] saveResourceData:vedioData
                                                                relatePath:[bgUuid stringByAppendingPathExtension:@"MP4"]
                                                              resourceType:kResourceCacheTypeVedio];
    
    if (vedioFilePath.length == 0) {
        ALERT_MSG(@"保存失败", nil, @"确定");
        return;
    }
    
    //获取广告实体,插入视频
    AdPhotoInfo *photoInfo = [[(PhotoBrowserDataSource *)dataSource_ photoList] objectAtIndex:currentIndex_];
    photoInfo.hadVedio = YES;
    photoInfo.vedioFilePath = vedioFilePath;
    [[AdPhotoManager instance] updateAdPhoto:photoInfo];
    
    //显示播放按钮
    KTPhotoView *photoView = [photoViews_ objectAtIndex:currentIndex_];
    if (photoView && [photoView isKindOfClass:[KTPhotoView class]]) {
        [photoView showOrHideVedioBtn:YES];
    }
    
//    SubProductInfo *subProductInfo = [[SubCatalogManager instance] subProductInfoForProductID:_subProductID];
//    subProductInfo.vedioURL = vedioFilePath;
//    DDetailLog(@"%@",subProductInfo.vedioURL);
//    SubCatalogManager *subCatalogManager = [SubCatalogManager instance];
//    [subCatalogManager updateSubCatalog:subProductInfo];

}


#pragma mark - MHImagePickerMutilSelectorDelegate

-(void)imagePickerMutilSelectorDidGetImages:(NSArray*)imageArr {
    for(UIImage *image in imageArr){
        //生成图片的uuid,保存到缓存
        NSString *bgUuid = [CommonUtil uuid];
        NSString *bgImageFilePath = [[ResourceCache instance] saveResourceData:UIImageJPEGRepresentation(image, 1)
                                                                    relatePath:bgUuid
                                                                  resourceType:kResourceCacheTypeAdImage];

        if (bgImageFilePath.length == 0) {
            ALERT_MSG(@"保存失败", nil, @"确定");
            return;
        }
        AdPhotoInfo *adPhotoInfo = [[AdPhotoInfo alloc] init];
        adPhotoInfo.imageFilePath = bgImageFilePath;
        adPhotoInfo.subProductId = _subProductID;
        int index = [[AdPhotoManager instance] indexForNewPhoto];
        adPhotoInfo.index = index;
        int photoId = [[AdPhotoManager instance] addAdPhoto:adPhotoInfo];
        if(photoId == NSNotFound){
            ALERT_MSG(@"保存失败", nil, @"确定");
            return;
        }else{
            adPhotoInfo.photoId = photoId;
            PhotoBrowserDataSource *dataSource = (PhotoBrowserDataSource *)dataSource_;
            [dataSource.photoList addObject:adPhotoInfo];
            [photoViews_ addObject:[NSNull null]];
        }
    }
    photoCount_ += imageArr.count;
    [self setScrollViewContentSize];
    [self setCurrentIndex:currentIndex_];
    [_popController dismissPopoverAnimated:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

-(NSUInteger)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskLandscape;
}

- (BOOL)shouldAutorotate
{
    return NO;
}

@end
