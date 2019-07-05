//
//  NaviSearchRoutes.m
//  QMapKitDemo
//
//  Created by Tencent on 2018/8/7.
//  Copyright © 2018年 tencent. All rights reserved.
//

#import "NaviSearchRoutes.h"

@implementation NaviSearchRoutes

#pragma mark - QMapViewDelegate

- (QOverlayView *)mapView:(QMapView *)mapView viewForOverlay:(id<QOverlay>)overlay
{
    if ([overlay isKindOfClass:[QPolyline class]])
    {
        QTexturePolylineView *polylineRender = [[QTexturePolylineView alloc] initWithPolyline:overlay];
        polylineRender.lineWidth    = 6;
        polylineRender.symbolGap    = 15;
        polylineRender.drawType     = QTextureLineDrawType_ColorLine;
        polylineRender.drawSymbol   = YES;
        polylineRender.strokeColor  = UIColor.blueColor;
        
        return polylineRender;
    }
    
    return nil;
}

- (QAnnotationView *)mapView:(QMapView *)mapView viewForAnnotation:(id<QAnnotation>)annotation
{
    if ([annotation isMemberOfClass:[QPointAnnotation class]])
    {
        QAnnotationView *annotationView = [[QAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:nil];
        
        annotationView.image = [UIImage imageNamed:@"QMapKit.bundle/start_point_in_map"];
        
        return annotationView;
    }
    
    return nil;
}

#pragma mark - Overlay

- (void)drawRouteLinesForNaviResult:(TWNWalkRouteSearchResult *)result
{
    NSArray<QPolyline *> *routeLines = [self routeLinesForNaviResult:result];
    [self.walkNaviView.naviMapView addOverlays:routeLines];
}

- (NSArray<QPolyline *> *)routeLinesForNaviResult:(TWNWalkRouteSearchResult *)result
{
    NSMutableArray *routeLines = [NSMutableArray array];
    
    TWNWalkRouteSearchPlan *plan = [result.routes firstObject];
    for (TWNWalkRouteSearchLine *line in plan.renderArray)
    {
        if (![line isKindOfClass:[TWNWalkRouteSearchElevatorLine class]])
        {
            int from = line.fromIndex;
            int count = line.toIndex - from + 1;
            
            CLLocationCoordinate2D *coordinateArray = (CLLocationCoordinate2D *)malloc(sizeof(CLLocationCoordinate2D) * count);
            
            for (int i = 0; i < count; i++)
            {
                coordinateArray[i] = plan.pointsArray[i + from].coordinate;
            }
            
            QPolyline *polyline = [QPolyline polylineWithCoordinates:coordinateArray count:count];
            
            if ([line isKindOfClass:[TWNWalkRouteSearchIndoorLine class]])
            {
                TWNWalkRouteSearchIndoorLine *indoorLine = (TWNWalkRouteSearchIndoorLine *)line;
                
                QIndoorInfo *indoorInfo = [[QIndoorInfo alloc] initWithBuildUid:indoorLine.buildingID levelName:indoorLine.floorName];
                polyline.indoorInfo = indoorInfo;
            }
            
            [routeLines addObject:polyline];
            
            free(coordinateArray);
        }
    }
    
    return [[NSArray<QPolyline *> alloc] initWithArray:routeLines];
}

#pragma mark - Annotation

- (void)addAnnotationWithPoint:(TWNWalkRouteSearchNaviPoi *)point
{
    QPointAnnotation *annotation = [[QPointAnnotation alloc] init];
    annotation.coordinate = point.coordinate;
    
    if (point.buildingID.length > 0 && point.floorName.length > 0)
    {
        QIndoorInfo *indoorInfo = [[QIndoorInfo alloc] initWithBuildUid:point.buildingID levelName:point.floorName];
        annotation.indoorInfo = indoorInfo;
    }
    
    [self.walkNaviView.naviMapView addAnnotation:annotation];
}

#pragma mark - Route Search

- (void)startRouteSearch
{
    TWNWalkRouteSearchNaviPoi *startPoint = [[TWNWalkRouteSearchNaviPoi alloc] init];
    startPoint.coordinate = CLLocationCoordinate2DMake(39.979602, 116.313972);
    startPoint.floorName = @"F3";
    startPoint.buildingID = @"11000023805";
    [self addAnnotationWithPoint:startPoint];
    
    TWNWalkRouteSearchNaviPoi *destinationPoint = [[TWNWalkRouteSearchNaviPoi alloc] init];
    destinationPoint.coordinate = CLLocationCoordinate2DMake(39.958553, 116.288640);
    destinationPoint.floorName = @"F3";
    destinationPoint.buildingID = @"1100005175";
    [self addAnnotationWithPoint:destinationPoint];
    
    TWNWalkRouteSearchRequest *searchRequest = [[TWNWalkRouteSearchRequest alloc] init];
    
    searchRequest.startPoint = startPoint;
    searchRequest.destinationPoint = destinationPoint;
    
    __weak __typeof(self) weakSelf = self;
    [self.walkNaviManager searchNavigationRoutesWithRequest:searchRequest completion:^(TWNWalkRouteSearchResult * _Nullable result, NSError * _Nullable error)
     {
         if (error != nil)
         {
             return;
         }
         
         // 绘制步行规划路线
         [weakSelf drawRouteLinesForNaviResult:result];
     }];
}

#pragma mark - Setup

- (void)setupMapView
{
    self.walkNaviView.naviMapView.centerCoordinate = CLLocationCoordinate2DMake(39.979602, 116.313972);
}

#pragma mark - Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupMapView];
    [self startRouteSearch];
}

@end
