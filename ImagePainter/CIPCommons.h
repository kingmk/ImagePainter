//
//  Constants.h
//  ImagePainter
//
//  Created by yuxinjin on 12-9-20.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

#ifndef ImagePainter_Constants_h
#define ImagePainter_Constants_h

// note: do not change any value defined here which is used somewhere to calculate trickly
typedef enum {
    ProcNoImg = 0,
    ProcView = 100,
    ProcPaint = 110,
//    ProcShape = 120,
    ProcText = 130,
    ProcCrop = 140,
    ProcEraser = 150,
    ProcCollage = 160,
    ProcFilter = 200,
    ProcSetting = 300
} ImageProcState;

typedef enum {
    ProcSubView = 101,
    ProcSubViewSelect = 102,
    ProcSubViewWand = 103,
    
    ProcSubPaintPencil =111,
    ProcSubPaintBrush = 112,
    ProcSubPaintRubber = 113,
    
    ProcSubShapeLine = 121,
    ProcSubShapeRect = 122,
    ProcSubShapeCircle = 123,
    ProcSubShapeEclipse = 124,
    
    ProcSubTextSelect = 131,
    ProcSubTextTyping = 132,
    
    ProcSubSetPaint = 301,
    ProcSubSetShape = 302,
    ProcSubSetText = 303
} ProcSubType;

typedef enum {
    ShapeLine = 0,
    ShapeRect = 1,
    ShapeEclipse = 2
} ShapeType;

typedef enum {
    TagNavUndo = 280,
    TagNavRedo = 281,
    TagNavGallery = 282,
    TagNavPhoto = 283,
    TagNavInfo = 284,
    TagNavDelete = 285,
    TagNavDeleteS = 286,
    
    TagGalleryThumb = 290,
    TagGalleryDateLabel = 291,
    TagGalleryCanvasIdx = 292,
    TagGalleryDeleteMark = 293,
    TagGalleryDeleteSel = 294,
    
    TagPaletteSizeSlider = 300,
    TagPaletteAlphaSlider = 301,
    TagPaletteHueSlider = 302,
    TagStyleScrollSelect = 310,
    TagStyleScrollTagOff = 320,
    
    TagColorHSFocus = 330,
    
    TagScreenMask = 350,
    TagOperMenuMask = 351,
    TagCollagePanel = 352,
    
    TagThumbAdd = 360,
    TagThumbDel = 361,
    
    TagSelectCrop = 380,
    TagSelectClear = 381,
    TagSelectCopy = 382,
    TagSelectCut = 383,
    
    TagFilterDisplayIcon = 410,
    TagFilterDisplayLabel = 411,
    
    TagFilterOriginal = 420,
    TagFilterEnhance = 421,
    TagFilterInstant = 422,
    TagFilterExpose = 423,
    TagFilterVibrance = 424,
    TagFilterComic = 430,
    TagFilterOcean = 431,
    TagFilterLake = 432,
    TagFilterEmboss = 433,
    TagFilterOilPaint = 434,
    TagFilterOldFilm = 440,
    TagFilterGrayish = 450,

    TagTextView = 600,  // text view for inputting on the canvas

    TagGalleryAction = 800,
    TagPhotoAction = 801,
    
    TagLayerScaleAlert = 1000,
    TagLayerRotateAlert = 1001,
    TagLayerDeleteAlert = 1002,
    TagLayerMergeAlert = 1003,
    
    TagFilterApplyAlert = 2000
} TagInView;

typedef enum {
    GesturePan = 0,
    GesturePinch = 1,
    GestureRotate = 2,
    GesturePress = 3
} GestureType;

typedef enum {
    SUCCESS = 0,
    ErrorMergeBack = 1
} ResultCode;

typedef enum {
    PaintLayer = 0,
    PhotoLayer = 1,
    TextLayer = 2
} LayerType;

typedef enum {
    CropNA = -1,
    CropLT = 0,
    CropCT = 1,
    CropRT = 2,
    CropLC = 3,
    CropCC = 4,
    CropRC = 5,
    CropLB = 6,
    CropCB = 7,
    CropRB = 8
} CropMoveType;

typedef enum {
    TextControlNone = -1,
    TextControlNoAdded = 0,
    TextControlAdded = 10,
    TextControlUnchanged = 20,
    TextControlRemoved = 30,
    TextControlChanged = 40
} TextControlStatus;


#endif
