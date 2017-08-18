//
//  ViewController.m
//  LocationMap
//
//  Created by 牛 on 2017/8/18.
//  Copyright © 2017年 牛. All rights reserved.
//

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@interface ViewController ()<CLLocationManagerDelegate>

//通过CLLocaltionManager获取用户的地理位置
@property(nonatomic)CLLocationManager *locationManager;

//地图
@property(nonatomic)MKMapView *mapView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self getUserLocation];
    //[self stopLocation];
    
    //添加系统地图
    [self addSystemMap];
    [self addLongPressGestrue];
    
    [self addMoveMapButton];
    //[self testGeocoder];
}

- (void)addMoveMapButton
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0, 0, 80, 40);
    button.backgroundColor = [UIColor blackColor];
    [button setTitle:@"移动" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(moveMap) forControlEvents:UIControlEventTouchUpInside];
    [self.mapView addSubview:button];
}

- (void)moveMap
{
    //移动map一般是移动map的中心点
    CLLocationCoordinate2D coordinate = self.mapView.centerCoordinate;
    coordinate.latitude += 0.005;
    [self.mapView setCenterCoordinate:coordinate animated:YES];
}

- (void)testGeocoder
{
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake(34.772885,113.675880);
    
    CLLocation *location = [[CLLocation alloc]initWithLatitude:center.latitude longitude:center.longitude];
    //反向地理编码，根据坐标值来得到实际的位置信息
    CLGeocoder *geocode = [[CLGeocoder alloc]init];
    [geocode reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        
        CLPlacemark *placeMark = [placemarks lastObject];
        NSLog(@"%@,%@",placeMark.country,placeMark.name);
        NSLog(@"%@",placeMark.thoroughfare);
        NSLog(@"%@",placeMark.subThoroughfare);
        NSLog(@"%@",placeMark.locality);
        NSLog(@"%@",placeMark.subLocality);
        NSLog(@"%@",placeMark.administrativeArea);
    }];
}

- (void)addLongPressGestrue
{
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(handleLongPress:)];
    [self.mapView addGestureRecognizer:longPressGesture];
}

- (void)handleLongPress:(UILongPressGestureRecognizer*)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan) {
        CGPoint point = [gesture locationInView:self.mapView];
        CLLocationCoordinate2D coordinate = [self.mapView convertPoint:point toCoordinateFromView:self.mapView];
        NSLog(@"%f,%f",coordinate.latitude,coordinate.longitude);
    }
}

- (void)addSystemMap
{
    self.mapView = [[MKMapView alloc]initWithFrame:self.view.bounds];
    //显示用户的位置，系统使用蓝色圆圈标注用户的位置
    //self.mapView.showsUserLocation = YES;
    //self.mapView.mapType = MKMapTypeSatellite;
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake(34.774329,113.669838);
    
    //设置显示的区域,span地图的缩放级别，一般0.0几，设置的值越小，显示的区域范围越小，也就是越精确
    MKCoordinateSpan span = MKCoordinateSpanMake(0.01, 0.01);
    MKCoordinateRegion region = MKCoordinateRegionMake(center, span);
    
    //regionThatFits,由于地图有自己的现实的经度和纬度的比例，我们输入的范围的比例有可能跟地图的显示比例不一致，系统地图会自动帮我们调整，一可以调用下面的方法进行调整地图显示的区域
    MKCoordinateRegion adjuestRegion = [self.mapView regionThatFits:region];
    
    //setRegion 设置地图的现实范围
    [self.mapView setRegion:adjuestRegion];
    
    [self.view addSubview:self.mapView];
    
    //设置地图的中心点位置
    self.mapView.centerCoordinate = center;
}

- (void)stopLocation
{
    //停止跟新位置信息
    [self.locationManager stopUpdatingLocation];
}
- (void)getUserLocation
{
    //注意在IOS8之后，定位信息需要在plist中加入字段 NSLocationAlwaysUsageDescription
    
    //1:首先判断是否有定位功能
    if ([CLLocationManager locationServicesEnabled]) {
        self.locationManager = [[CLLocationManager alloc]init];
        //2:获取用户的许可
        //获取当前用户ios版本号
        float version = [[UIDevice currentDevice].systemVersion floatValue];
        if(version >= 8.0){
            [self.locationManager requestAlwaysAuthorization];
        }
        //3:设置定位的精度
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        //设置位置更新的过滤器，当设备移动到指定的距离后，才会再次给你坐标
        self.locationManager.distanceFilter = kCLLocationAccuracyBest;
        //4:设置代理，这样位置信息就会通知代理方法给我们
        self.locationManager.delegate = self;
        //5:开始启动定位
        [self.locationManager startUpdatingLocation];
    }
}

#pragma mark -
#pragma mark CLLocaitonManagerDelegate

//定位成功，会把最新的位置信息存放到数组中
- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations
{
    //获取最后一次更新的位置
    CLLocation *location = [locations lastObject];
    //location.coordinate.latitude  纬度坐标
    //location.coordinate.longitude 经度坐标
    //NSLog(@"%f,%f",location.coordinate.latitude,location.coordinate.longitude);
    //注意系统会缓存以前程序的定位事件，当我们开始定位时首先发送给我们的可能是以前的缓存定位事件，所以需要通过时间戳过滤掉
    NSDate *locationTime = location.timestamp;
    NSTimeInterval timeInterval = [locationTime timeIntervalSinceNow];
    if (fabs(timeInterval) < 15) {
        //该事件可用,打印位置信息
        NSLog(@"%f,%f",location.coordinate.latitude,location.coordinate.longitude);
    }
}

//定位信息失败，调用的回调函数
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    NSLog(@"定位失败,原因%@",error);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
