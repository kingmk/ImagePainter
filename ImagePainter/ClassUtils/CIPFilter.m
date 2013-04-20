//
//  CIPFilter.m
//  ImagePainter
//
//  Created by yuxinjin on 12-11-10.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

#import "CIPFilter.h"

static CIContext *cicontext;
static NSArray *filterSupports;

@implementation CIPFilter

+ (CIContext*) createContext {
    EAGLContext *eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (eaglContext == nil) {
        eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
    }
    NSMutableDictionary * options = [[NSMutableDictionary alloc] init];
    [options setObject:[NSNull null] forKey:kCIContextWorkingColorSpace];
    CIContext *context = [CIContext contextWithEAGLContext:eaglContext options:options];
    return context;
}

+ (CGImageRef) renderInContext:(CIImage*)ciImage inSize:(CGSize)size {
    if (!cicontext) {
        cicontext = [self createContext];
    }
    CGRect rect = {CGPointZero, size};
    return [cicontext createCGImage:ciImage fromRect:rect];
}

+ (BOOL) supportFilter:(NSString*)filterName {
    if (!filterSupports) {
        filterSupports = [CIFilter filterNamesInCategory:kCICategoryStillImage];
    }
    return [filterSupports containsObject:filterName];
}


+ (void) queryFilterInfo {
    NSArray *filterNames = [CIFilter filterNamesInCategory:kCICategoryStillImage];
    NSLog(@"%@", filterNames);
}

+ (NSDictionary*) queryFilterInfo:(NSString *)filterName {
    CIFilter *filter = [CIFilter filterWithName:filterName];
    NSDictionary *attr = [filter attributes];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithCapacity:5];
    [attr enumerateKeysAndObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id key, id obj, BOOL *stop) {
        if ([(NSString* )key hasPrefix:@"input"] && ![(NSString* )key isEqualToString:@"inputImage"]) {
            [params setObject:obj forKey:key];
        }
    }];
    NSLog(@"%@", params);
    return params;
}

+ (CGImageRef) applyFilter:(NSString *)filterName onImage:(CGImageRef)cgImage with:(NSDictionary *)params {
    if (!cicontext) {
        cicontext = [self createContext];
    }
    
    CIFilter *filter = [CIFilter filterWithName:filterName];
    if (cgImage) {
        CIImage *image = [CIImage imageWithCGImage:cgImage];
        [filter setValue:image forKey:@"inputImage"];
    }
    if (params) {
        [params enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [filter setValue:obj forKey:key];
        }];
    }
    CIImage *result = [filter valueForKey:@"outputImage"];
    CGRect rect = CGRectMake(0, 0, CGImageGetWidth(cgImage), CGImageGetHeight(cgImage));
    
    CGImageRef cgImageResult = [cicontext createCGImage:result fromRect:rect];
    return cgImageResult;
}

+ (CGImageRef) generateRandomWhiteSpecksIn:(CGSize) size {
    NSUInteger w = size.width;
    NSUInteger h = size.height;
    NSUInteger bitsPerComponent = 8;
    NSUInteger bytesPerRow = w*4;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char *data = malloc(w*h*4);
    memset(data, 0, w*h*4);
    CGContextRef context = CGBitmapContextCreate(data, w, h, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast);

    int step = size.width/30;
    int idx;
    int x=[CIPUtilities randomInt:step];
    while (x<w) {
        int y0 = [CIPUtilities randomInt:(h*4/5)];
        int y1;
        if ([CIPUtilities randomInt:3]>=2) {
            y1 = y0+2;
        } else {
            y1 = y0+MIN([CIPUtilities randomInt:(h-y0-3)]+3, h/10);
        }
        
        CGFloat gray = 0.0+[CIPUtilities randomFloat:0.5];
        CGFloat alpha = 0.1+[CIPUtilities randomFloat:0.4];
        idx = y0*bytesPerRow+x*4;
        
        CGFloat tmpStep = 2+[CIPUtilities randomFloat:MAX(step-2, 0)];
        CGFloat width = 1+[CIPUtilities randomFloat:tmpStep*0.2];
        const CGFloat colorComps[4] = {gray, gray, gray, alpha};
        CGContextSetLineWidth(context, width);
        CGContextSetLineCap(context, kCGLineCapRound);
        CGContextSetStrokeColor(context, colorComps);
        CGContextMoveToPoint(context, x, y0);
        CGContextAddLineToPoint(context, x, y1);
        
        CGContextStrokePath(context);
        x += tmpStep;
    }

    CGColorSpaceRelease(colorSpace);
    CGImageRef resultImage = CGBitmapContextCreateImage(context);
    free(CGBitmapContextGetData(context));
    CGContextRelease(context);

    return resultImage;
}

+ (CGImageRef) generateCheckerBoardWithSize:(CGSize)size gridWidth:(CGFloat)width withColor:(UIColor *)color{
    if (!cicontext) {
        cicontext = [self createContext];
    }
    CGPoint center = CGPointMake(size.width/2, size.height/2);
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:[[CIVector alloc] initWithCGPoint:center], @"inputCenter", [[CIColor alloc] initWithColor:[UIColor whiteColor]], @"inputColor0", [[CIColor alloc] initWithColor:color], @"inputColor1", [NSNumber numberWithFloat:width], @"inputWidth", nil];
    CIFilter *filter = [CIFilter filterWithName:@"CICheckerboardGenerator"];
    [params enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [filter setValue:obj forKey:key];
    }];
    CIImage *result = [filter valueForKey:@"outputImage"];
    CGImageRef cgImageResult = [cicontext createCGImage:result fromRect:CGRectMake(0, 0, size.width, size.height)];
    return cgImageResult;
}

#pragma mark -
#pragma mark Filters Function

+ (UIImage*) filterEnhance:(UIImage*)image {
    CIImage *ciImage = [CIImage imageWithCGImage:image.CGImage];
    NSArray *filters = [ciImage autoAdjustmentFilters];
    for (CIFilter *filter in filters) {
        [filter setValue:ciImage forKey:kCIInputImageKey];
        ciImage = filter.outputImage;
    }
    
    CIFilter *filter = [CIFilter filterWithName:@"CIVignette"];
    [filter setValue:ciImage forKey:@"inputImage"];
    [filter setValue:[NSNumber numberWithFloat:1.2] forKey:@"inputRadius"];
    [filter setValue:[NSNumber numberWithFloat:0.4] forKey:@"inputIntensity"];
    ciImage = [filter outputImage];
    
    CGImageRef rltCGImage = [self renderInContext:ciImage inSize:image.size];
    UIImage *rltImage = [UIImage imageWithCGImage:rltCGImage];
    CGImageRelease(rltCGImage);
    return rltImage;
}

+ (UIImage*) filterInstant:(UIImage*)image {
    GPUImagePicture *gpuImage = [[GPUImagePicture alloc] initWithImage:image];
    GPUImageSepiaFilter *sepiaFilter = [[GPUImageSepiaFilter alloc] init];
    sepiaFilter.intensity = 0.4;
    [gpuImage addTarget:sepiaFilter];
    
    GPUImageVignetteFilter *vignetteFilter = [[GPUImageVignetteFilter alloc] init];
    vignetteFilter.vignetteStart = 0.2;
    vignetteFilter.vignetteEnd = 0.9;
    vignetteFilter.vignetteColor = (GPUVector3) {0.2f, 0.2f, 0.2f};
    [sepiaFilter addTarget:vignetteFilter];
    
    [gpuImage processImage];
    UIImage *rltImage = [vignetteFilter imageFromCurrentlyProcessedOutput];
    
    return [CIPImageProcess drawImage:rltImage onOpaqueAreaIn:image scale:image.scale];
}

+ (UIImage*) filterExpose:(UIImage*)image {
    GPUImagePicture *gpuImage = [[GPUImagePicture alloc] initWithImage:image];
    GPUImageExposureFilter *exposeFilter = [[GPUImageExposureFilter alloc] init];
    exposeFilter.exposure = 1.0;
    [gpuImage addTarget:exposeFilter];
    
    GPUImageVignetteFilter *vignetteFilter = [[GPUImageVignetteFilter alloc] init];
    vignetteFilter.vignetteStart = 0.2;
    vignetteFilter.vignetteEnd = 0.9;
    vignetteFilter.vignetteColor = (GPUVector3) {0.7f, 0.7f, 0.7f};
    [exposeFilter addTarget:vignetteFilter];
    
    [gpuImage processImage];
    UIImage *rltImage = [vignetteFilter imageFromCurrentlyProcessedOutput];
    
    return [CIPImageProcess drawImage:rltImage onOpaqueAreaIn:image scale:image.scale];
}

+ (UIImage*) filterVibrance:(UIImage*)image {
    GPUImagePicture *gpuImage = [[GPUImagePicture alloc] initWithImage:image];
    GPUImageSaturationFilter *satFilter = [[GPUImageSaturationFilter alloc] init];
    satFilter.saturation = 2.0;
    [gpuImage addTarget:satFilter];
    
    [gpuImage processImage];
    UIImage *rltImage = [satFilter imageFromCurrentlyProcessedOutput];
    return [UIImage imageWithCGImage:rltImage.CGImage scale:image.scale orientation:UIImageOrientationUp];
}

+ (UIImage*) filterComic:(UIImage*)image {
    GPUImagePicture *gpuImage = [[GPUImagePicture alloc] initWithImage:image];
    GPUImageToonFilter *toonFilter = [[GPUImageToonFilter alloc] init];
    toonFilter.threshold = 0.7;
    toonFilter.quantizationLevels = 10.0;
    [gpuImage addTarget:toonFilter];
    [gpuImage processImage];
    
    UIImage *rltImage = [toonFilter imageFromCurrentlyProcessedOutput];
    return [UIImage imageWithCGImage:rltImage.CGImage scale:image.scale orientation:UIImageOrientationUp];
}

+ (UIImage*) filterOcean:(UIImage*)image {
    GPUImagePicture *gpuImage = [[GPUImagePicture alloc] initWithImage:image];
    GPUImageAmatorkaFilter *amatorkaFilter = [[GPUImageAmatorkaFilter alloc] init];
    [gpuImage addTarget:amatorkaFilter];
    [gpuImage processImage];
    
    UIImage *rltImage = [amatorkaFilter imageFromCurrentlyProcessedOutput];
    return [UIImage imageWithCGImage:rltImage.CGImage scale:image.scale orientation:UIImageOrientationUp];
}

+ (UIImage*) filterLake:(UIImage*)image {
    GPUImagePicture *gpuImage = [[GPUImagePicture alloc] initWithImage:image];
    GPUImageMissEtikateFilter *amatorkaFilter = [[GPUImageMissEtikateFilter alloc] init];
    [gpuImage addTarget:amatorkaFilter];
    [gpuImage processImage];
    
    UIImage *rltImage = [amatorkaFilter imageFromCurrentlyProcessedOutput];
    return [UIImage imageWithCGImage:rltImage.CGImage scale:image.scale orientation:UIImageOrientationUp];
}

+ (UIImage*) filterEmboss:(UIImage*)image {
    GPUImagePicture *gpuImage = [[GPUImagePicture alloc] initWithImage:image];
    GPUImageEmbossFilter *embossFilter = [[GPUImageEmbossFilter alloc] init];
    [gpuImage addTarget:embossFilter];
    [gpuImage processImage];
    
    UIImage *rltImage = [embossFilter imageFromCurrentlyProcessedOutput];
    return [UIImage imageWithCGImage:rltImage.CGImage scale:image.scale orientation:UIImageOrientationUp];
}


+ (UIImage*)filterOilPaint:(UIImage*) image {
    GPUImagePicture *gpuImage = [[GPUImagePicture alloc] initWithImage:image];
    GPUImageKuwaharaFilter *oilPaintFilter = [[GPUImageKuwaharaFilter alloc] init];
    [gpuImage addTarget:oilPaintFilter];
    [gpuImage processImage];
    
    UIImage *rltImage = [oilPaintFilter imageFromCurrentlyProcessedOutput];
    
    return [CIPImageProcess drawImage:rltImage onOpaqueAreaIn:image scale:image.scale];
}

+ (UIImage*) filterGrayish:(UIImage *)image {
    GPUImagePicture *gpuImage = [[GPUImagePicture alloc] initWithImage:image];
    GPUImageGrayscaleFilter *grayFilter = [[GPUImageGrayscaleFilter alloc] init];
    [gpuImage addTarget:grayFilter];
    
    [gpuImage processImage];    
    UIImage *rltImage = [grayFilter imageFromCurrentlyProcessedOutput];
    return [UIImage imageWithCGImage:rltImage.CGImage scale:image.scale orientation:UIImageOrientationUp];
}

+ (UIImage*) filterOldFilm:(UIImage *)image {
    CGImageRef specks = [self generateRandomWhiteSpecksIn:CGSizeApplyAffineTransform(image.size, CGAffineTransformMakeScale(image.scale, image.scale))];
    GPUImagePicture *speckImage = [[GPUImagePicture alloc] initWithCGImage:specks];
    GPUImageOverlayBlendFilter *blendFilter = [[GPUImageOverlayBlendFilter alloc] init];
    [speckImage addTarget:blendFilter];
    [speckImage processImage];
    
    GPUImagePicture *gpuImage = [[GPUImagePicture alloc] initWithImage:image];
    GPUImageSepiaFilter *sepiaFilter = [[GPUImageSepiaFilter alloc] init];
    [gpuImage addTarget:sepiaFilter];
    [sepiaFilter addTarget:blendFilter];
    
    [gpuImage processImage];
    UIImage *rltImage = [blendFilter imageFromCurrentlyProcessedOutput];
    
    CGImageRelease(specks);
    return [CIPImageProcess drawImage:rltImage onOpaqueAreaIn:image scale:image.scale];
}

+ (UIImage*)test:(UIImage*) image {
    GPUImagePicture *gpuImage = [[GPUImagePicture alloc] initWithImage:image];
    GPUImageKuwaharaFilter *oilPaintFilter = [[GPUImageKuwaharaFilter alloc] init];
    [gpuImage addTarget:oilPaintFilter];
    [gpuImage processImage];
    
    UIImage *rltImage = [oilPaintFilter imageFromCurrentlyProcessedOutput];
    return [UIImage imageWithCGImage:rltImage.CGImage scale:image.scale orientation:UIImageOrientationUp];
}

+ (UIImage*)test2:(UIImage*) image {
    //image = [UIImage imageNamed:@"sample_original.png"];
    UIImage *tmpImage;

    tmpImage = [self filterOilPaint:image];
    [[CIPFileUtilities defaultFileUtils] saveImage:tmpImage withCompletionBloc:^(NSError *error) {
    }];
    NSLog(@"2 finished");
    
    return nil;
}

@end
