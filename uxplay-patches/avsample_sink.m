// avsample_sink.m — custom macOS video sink (Plan B).
//
// Bypasses GStreamer's buggy applemedia sinks (avsamplebufferlayersink UAF on
// caps-change, osxvideosink teardown deadlock): we pull decoded NV12 frames from
// an `appsink` (video_renderer.c) and feed them to OUR OWN
// AVSampleBufferDisplayLayer, hosted in the app's NSView. Because we own the
// layer and the enqueue path, there is no framework UAF and no main-thread
// teardown deadlock, and the layer scales cleanly on resize/rotation.
//
// Compiled as Objective-C (ARC) into the `renderers` lib; exposed to the C TU
// video_renderer.c via the small C ABI below.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#import <AVFoundation/AVFoundation.h>
#import <AppKit/AppKit.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>
#ifdef AIR_SERVER_HAVE_SYPHON
#import <CoreImage/CoreImage.h>
#import <Syphon/SyphonSubclassing.h>
#endif

// --- C ABI (called from video_renderer.c) -------------------------------------
void *avlayer_sink_create(void *nsview_ptr);
void  avlayer_sink_enqueue_nv12(void *sink, const unsigned char *y, unsigned long y_stride,
                                const unsigned char *uv, unsigned long uv_stride,
                                int width, int height);
void  avlayer_sink_destroy(void *sink);

#ifdef AIR_SERVER_HAVE_SYPHON
// SyphonServerBase exposes an IOSurface-backed BGRA frame to local clients.
// Core Image converts the existing NV12 CVPixelBuffer directly into that
// surface on the GPU, so the AirPlay frame never makes another CPU round-trip.
@interface AirServerSyphonServer : SyphonServerBase
@property(nonatomic, strong) CIContext *airServerContext;
@property(nonatomic, assign) CGColorSpaceRef airServerColorSpace;
- (void)publishPixelBuffer:(CVPixelBufferRef)pixelBuffer;
@end

@implementation AirServerSyphonServer
- (instancetype)initWithName:(NSString *)name {
    self = [super initWithName:name options:nil];
    if (self) {
        _airServerContext = [CIContext contextWithOptions:@{
            kCIContextUseSoftwareRenderer : @NO
        }];
        _airServerColorSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
    }
    return self;
}

- (void)dealloc {
    if (_airServerColorSpace) CGColorSpaceRelease(_airServerColorSpace);
}

- (void)publishPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    if (!pixelBuffer || !self.hasClients) return;
    const size_t width = CVPixelBufferGetWidth(pixelBuffer);
    const size_t height = CVPixelBufferGetHeight(pixelBuffer);
    IOSurfaceRef surface = [self newSurfaceForWidth:width height:height options:nil];
    if (!surface) return;

    CIImage *image = [CIImage imageWithCVPixelBuffer:pixelBuffer];
    [self.airServerContext render:image
                       toIOSurface:surface
                            bounds:CGRectMake(0, 0, width, height)
                        colorSpace:self.airServerColorSpace];
    [self publish];
    CFRelease(surface);
}
@end

// UxPlay prepares one appsink for H.264 and another for H.265. Both must feed
// the same publisher: creating one server per sink would show two indistinguish-
// able sources in Resolume before either codec has even received a frame.
static AirServerSyphonServer *airServerSharedSyphonServer = nil;
static NSUInteger airServerSharedSyphonReferences = 0;

static void *airserver_syphon_acquire(void) {
    @synchronized([AirServerSyphonServer class]) {
        if (!airServerSharedSyphonServer) {
            airServerSharedSyphonServer =
                [[AirServerSyphonServer alloc] initWithName:@"Air Server — iPhone"];
            if (airServerSharedSyphonServer) {
                fprintf(stderr, "[syphon] publishing as Air Server — iPhone\n");
            } else {
                fprintf(stderr, "[syphon] failed to create server\n");
                return NULL;
            }
        }
        airServerSharedSyphonReferences++;
        return (__bridge_retained void *)airServerSharedSyphonServer;
    }
}

static void airserver_syphon_release(void *server_ref) {
    if (!server_ref) return;
    AirServerSyphonServer *server =
        (__bridge_transfer AirServerSyphonServer *)server_ref;
    @synchronized([AirServerSyphonServer class]) {
        if (airServerSharedSyphonReferences > 0) {
            airServerSharedSyphonReferences--;
        }
        if (airServerSharedSyphonReferences == 0 &&
            airServerSharedSyphonServer == server) {
            [airServerSharedSyphonServer stop];
            airServerSharedSyphonServer = nil;
        }
    }
}
#endif

typedef struct AVLayerSink {
    // CFBridgingRetain'd AVSampleBufferDisplayLayer. _Atomic because create()
    // publishes it from the main queue while the GStreamer streaming thread is
    // already calling enqueue().
    _Atomic(void *) layer;
    // Reused across frames of the same dimensions. The previous path allocated
    // a fresh IOSurface-backed pixel buffer and format description for every
    // frame, adding avoidable work to the latency-critical streaming thread.
    CVPixelBufferPoolRef pool;
    CMVideoFormatDescriptionRef format;
    int width;
    int height;
#ifdef AIR_SERVER_HAVE_SYPHON
    // CFBridgingRetain'd AirServerSyphonServer, present only when enabled in
    // Settings for this engine run.
    void *syphon_server;
#endif
} AVLayerSink;

static bool avlayer_sink_prepare_pool(AVLayerSink *s, int width, int height) {
    if (s->pool && s->format && s->width == width && s->height == height) {
        return true;
    }

    if (s->format) {
        CFRelease(s->format);
        s->format = NULL;
    }
    if (s->pool) {
        CVPixelBufferPoolRelease(s->pool);
        s->pool = NULL;
    }
    s->width = 0;
    s->height = 0;

    @autoreleasepool {
        NSDictionary *poolAttrs = @{
            (id)kCVPixelBufferPoolMinimumBufferCountKey : @3
        };
        NSDictionary *pixelAttrs = @{
            (id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange),
            (id)kCVPixelBufferWidthKey : @(width),
            (id)kCVPixelBufferHeightKey : @(height),
            (id)kCVPixelBufferMetalCompatibilityKey : @YES,
            (id)kCVPixelBufferIOSurfacePropertiesKey : @{}
        };
        if (CVPixelBufferPoolCreate(kCFAllocatorDefault,
                                    (__bridge CFDictionaryRef)poolAttrs,
                                    (__bridge CFDictionaryRef)pixelAttrs,
                                    &s->pool) != kCVReturnSuccess || !s->pool) {
            return false;
        }
    }

    CVPixelBufferRef prototype = NULL;
    if (CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, s->pool, &prototype) != kCVReturnSuccess || !prototype) {
        CVPixelBufferPoolRelease(s->pool);
        s->pool = NULL;
        return false;
    }
    OSStatus status = CMVideoFormatDescriptionCreateForImageBuffer(
        kCFAllocatorDefault, prototype, &s->format);
    CVPixelBufferRelease(prototype);
    if (status != noErr || !s->format) {
        CVPixelBufferPoolRelease(s->pool);
        s->pool = NULL;
        return false;
    }

    s->width = width;
    s->height = height;
    return true;
}

/// Create the display layer and host it in `nsview` (AppKit work on the main thread).
///
/// MUST NOT dispatch_sync to the main queue — same hazard as destroy() below: this
/// runs on the engine worker, and a host that quits mid-connect blocks its main
/// thread inside airplay_core_stop() joining that worker, so a sync hop would
/// deadlock with no window and no tray. So: inline if already on main, else
/// fire-and-forget. The caller only needs the AVLayerSink handle (it is appsink
/// callback userdata); enqueue() drops the first frames until `layer` is published,
/// which is a few ms at stream start and invisible.
void *avlayer_sink_create(void *nsview_ptr) {
    if (!nsview_ptr) return NULL;
    AVLayerSink *s = (AVLayerSink *)calloc(1, sizeof(AVLayerSink));
    if (!s) return NULL;
#ifdef AIR_SERVER_HAVE_SYPHON
    const char *syphon_enabled = getenv("AIR_SERVER_SYPHON_OUTPUT");
    if (syphon_enabled && strcmp(syphon_enabled, "1") == 0) {
        s->syphon_server = airserver_syphon_acquire();
    }
#endif
    NSView *view = (__bridge NSView *)nsview_ptr;
    void (^build)(void) = ^{
        AVSampleBufferDisplayLayer *layer = [[AVSampleBufferDisplayLayer alloc] init];
        layer.videoGravity = AVLayerVideoGravityResizeAspect; // honest aspect, letterbox
        view.wantsLayer = YES;
        CALayer *backing = view.layer;
        backing.backgroundColor = CGColorGetConstantColor(kCGColorBlack);
        layer.frame = view.bounds;
        layer.backgroundColor = CGColorGetConstantColor(kCGColorBlack);
        // kCALayerWidthSizable | kCALayerHeightSizable -> follows the view on resize
        layer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
        [backing addSublayer:layer];
        s->layer = (void *)CFBridgingRetain(layer);
    };
    if ([NSThread isMainThread]) {
        build();
    } else {
        dispatch_async(dispatch_get_main_queue(), build);
    }
    return s;
}

/// Wrap an NV12 frame in a CVPixelBuffer + CMSampleBuffer and enqueue it. Safe to
/// call from the GStreamer streaming thread (AVSampleBufferDisplayLayer enqueue is
/// thread-safe). Frames are tagged display-immediately (lowest latency).
void avlayer_sink_enqueue_nv12(void *sink_, const unsigned char *y, unsigned long y_stride,
                               const unsigned char *uv, unsigned long uv_stride,
                               int width, int height) {
    AVLayerSink *s = (AVLayerSink *)sink_;
    if (!s || !s->layer || !y || !uv || width <= 0 || height <= 0) return;
    AVSampleBufferDisplayLayer *layer = (__bridge AVSampleBufferDisplayLayer *)s->layer;

    // If the layer failed (e.g. went to background), flush so it accepts frames again.
    if (layer.status == AVQueuedSampleBufferRenderingStatusFailed) {
        [layer flush];
    }

    bool dimensions_changed = s->width != width || s->height != height;
    if (!avlayer_sink_prepare_pool(s, width, height)) return;
    if (dimensions_changed) [layer flush];

    CVPixelBufferRef pb = NULL;
    CVReturn rc = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, s->pool, &pb);
    if (rc != kCVReturnSuccess || !pb) return;

    if (CVPixelBufferLockBaseAddress(pb, 0) != kCVReturnSuccess) {
        CVPixelBufferRelease(pb); // never unlock a lock that did not succeed
        return;
    }
    unsigned char *dy = (unsigned char *)CVPixelBufferGetBaseAddressOfPlane(pb, 0);
    unsigned long dys = CVPixelBufferGetBytesPerRowOfPlane(pb, 0);
    for (int row = 0; row < height; row++) {
        memcpy(dy + (unsigned long)row * dys, y + (unsigned long)row * y_stride, (size_t)width);
    }
    unsigned char *duv = (unsigned char *)CVPixelBufferGetBaseAddressOfPlane(pb, 1);
    unsigned long duvs = CVPixelBufferGetBytesPerRowOfPlane(pb, 1);
    for (int row = 0; row < height / 2; row++) {
        memcpy(duv + (unsigned long)row * duvs, uv + (unsigned long)row * uv_stride, (size_t)width);
    }
    CVPixelBufferUnlockBaseAddress(pb, 0);

    CMSampleTimingInfo timing = { kCMTimeInvalid, kCMTimeInvalid, kCMTimeInvalid };
    CMSampleBufferRef sb = NULL;
    OSStatus st = CMSampleBufferCreateReadyWithImageBuffer(kCFAllocatorDefault, pb, s->format, &timing, &sb);
    if (st == noErr && sb) {
        CFArrayRef atts = CMSampleBufferGetSampleAttachmentsArray(sb, true);
        if (atts && CFArrayGetCount(atts) > 0) {
            CFMutableDictionaryRef d = (CFMutableDictionaryRef)CFArrayGetValueAtIndex(atts, 0);
            CFDictionarySetValue(d, kCMSampleAttachmentKey_DisplayImmediately, kCFBooleanTrue);
        }
        // AVSampleBufferDisplayLayer may queue faster than the display can
        // consume. Flush that stale queue under pressure, then show the newest
        // frame instead of allowing delay to grow over time.
        if (!layer.readyForMoreMediaData) [layer flush];
        [layer enqueueSampleBuffer:sb];
        CFRelease(sb);
    }
#ifdef AIR_SERVER_HAVE_SYPHON
    if (s->syphon_server) {
        AirServerSyphonServer *server =
            (__bridge AirServerSyphonServer *)s->syphon_server;
        [server publishPixelBuffer:pb];
    }
#endif
    CVPixelBufferRelease(pb);
}

/// Detach + release the layer (AppKit work must run on the main thread).
///
/// MUST NOT dispatch_sync to the main queue: teardown runs on the engine worker
/// while the main thread is blocked inside airplay_core_stop() joining that very
/// worker (X-button restart) — a sync hop would deadlock. So we run inline if we
/// are already on main, else fire-and-forget via dispatch_async. The block only
/// captures `s`, whose ownership passes to the block (single CFBridgingRelease
/// transfers the layer exactly once).
///   * On restart the async cleanup drains FIFO before the next create() bind (the
///     serial main queue + distinct CALayer instances keep the layer tree correct).
///   * On app quit the process exit()s before the main queue drains again, so the
///     block is simply abandoned — harmless, teardown at exit is moot.
///
/// Reading `s->layer` and freeing `s` happen INSIDE the block, not before it:
/// create() may still have its own block queued ahead of ours, so the layer only
/// exists once that has run, and an earlier free() would let it write freed memory.
/// The serial main queue gives us that ordering because create() and destroy() are
/// always called from the same thread (the engine worker, or main in standalone
/// uxplay) — the pairing that video_renderer.c enforces.
void avlayer_sink_destroy(void *sink_) {
    AVLayerSink *s = (AVLayerSink *)sink_;
    if (!s) return;
    void (^cleanup)(void) = ^{
        void *layer_ref = s->layer;
        s->layer = NULL;
        if (layer_ref) {
            AVSampleBufferDisplayLayer *layer = (AVSampleBufferDisplayLayer *)CFBridgingRelease(layer_ref);
            [layer flush];
            [layer removeFromSuperlayer];
        }
        if (s->format) CFRelease(s->format);
        if (s->pool) CVPixelBufferPoolRelease(s->pool);
#ifdef AIR_SERVER_HAVE_SYPHON
        if (s->syphon_server) {
            void *server_ref = s->syphon_server;
            s->syphon_server = NULL;
            airserver_syphon_release(server_ref);
        }
#endif
        free(s);
    };
    if ([NSThread isMainThread]) {
        cleanup();
    } else {
        dispatch_async(dispatch_get_main_queue(), cleanup);
    }
}
