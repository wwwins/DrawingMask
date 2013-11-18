package mask
{
  import flash.display.Bitmap;
  import flash.display.BitmapData;
  import flash.display.Shape;
  import flash.display.Sprite;
  import flash.events.MouseEvent;
  import flash.filters.BlurFilter;
  import flash.geom.Point;
  import flash.geom.Rectangle;
  import flash.utils.getTimer;

  /**
   * ...
   * @author flashisobar
   */
  public class DrawingMask extends Sprite
  {

    public var IMAGE_W:Number = 600;
    public var IMAGE_H:Number = 600;
    public var LINE_THICKNESS:Number = 30;
    public var LINE_COLOR:Number = 0xFFFFFF;
    public var LINE_ALPHA:Number = 1.0;
    public var MAGIC_COLOR:Number = 0x686868;
    public var PREVIEW_X:Number = IMAGE_W + 50;
    public var PREVIEW_Y:Number = 0;

    private var enableMasking:Boolean = true;
    private var isClicked:Boolean = false;
    private var lastx:Number = 0;
    private var lasty:Number = 0;

    private var undoStack:Vector.<BitmapData>;
    private var numUndoLevels:uint = 10;

    private var _main_stage:Sprite;
    private var _preview_container:Sprite;
    private var _drawShape:Shape;
    private var _drawBitmap:Bitmap;
    private var _drawBitmapData:BitmapData;
    private var _maskBitmapData:BitmapData;
    private var _maskBitmap:Bitmap;
    // 處理前的圖
    private var _before_pic:Bitmap;
    // 處理後的圖
    private var _after_pic:Bitmap;

    private var _pause:Boolean;
    private var _enableBlur:Boolean;
    private var _enableMask:Boolean;

    public function DrawingMask(__W:Number = 600, __H:Number = 600, __preview_x:Number = 600, __preview_y:Number = 0, __enableMask:Boolean = true, __enableBlur:Boolean = false)
    {
      IMAGE_W = __W;
      IMAGE_H = __H;
      PREVIEW_X = __preview_x;
      PREVIEW_Y = __preview_y;

      _enableMask = __enableMask;
      _enableBlur = __enableBlur;
    }

    public function init(_before_bmd:BitmapData, _after_bmd:BitmapData):void
    {
      _before_pic = new Bitmap(_before_bmd);
      _before_pic.smoothing = true;
      _after_pic = new Bitmap(_after_bmd);
      _after_pic.smoothing = true;

      _maskBitmapData = new BitmapData(IMAGE_W, IMAGE_H, true, 0x0);
      _maskBitmap = new Bitmap(_maskBitmapData);
      if (_enableBlur)
      {
        var blur:BlurFilter = new BlurFilter();
        _maskBitmap.filters = [blur];
      }
      _maskBitmap.cacheAsBitmap = true;
      _after_pic.cacheAsBitmap = true;
      _after_pic.mask = _maskBitmap;

      _drawShape = new Shape();
      _drawShape.graphics.lineStyle(LINE_THICKNESS, LINE_COLOR, LINE_ALPHA);
      _drawBitmapData = new BitmapData(IMAGE_W, IMAGE_H, true, 0x0);
      _drawBitmap = new Bitmap(_drawBitmapData, "auto", true);
      _drawBitmap.alpha = 0.4;

      _preview_container = new Sprite();
      // add background image
      //_preview_container.addChild(new ImageBgClass);
      _preview_container.addChild(_after_pic);
      _preview_container.addChild(_maskBitmap);
      _preview_container.x = PREVIEW_X;
      _preview_container.y = PREVIEW_Y;
      addChild(_preview_container);

      _main_stage = new Sprite();
      if (_enableMask)
      {
        var mask_mc:Shape = new Shape();
        mask_mc.graphics.clear();
        mask_mc.graphics.beginFill(0xFFFF00, 1);
        mask_mc.graphics.drawRect(0, 0, IMAGE_W, IMAGE_H);
        _main_stage.addChild(mask_mc);
        _before_pic.mask = mask_mc;
      }
      addChild(_main_stage);
      _main_stage.addChild(_before_pic);
      _main_stage.addChild(_drawBitmap);
      //_main_stage.addChild(_drawShape);

      _main_stage.addEventListener(MouseEvent.MOUSE_DOWN, handleDown);
      _main_stage.addEventListener(MouseEvent.MOUSE_MOVE, handleMove);
      _main_stage.addEventListener(MouseEvent.MOUSE_UP, handleUp);

      // set undo manager
      undoStack = new Vector.<BitmapData>();

    }

    private function handleUp(e:MouseEvent):void
    {
      if (_pause)
        return;

      if (isClicked)
      {
        stopDraw();
        //_drawBitmapData.unlock();
      }
      isClicked = false;
    }

    private function handleMove(e:MouseEvent):void
    {
      if (_pause)
        return;

      if (isClicked)
      {
        _drawShape.graphics.lineTo(mouseX, mouseY);
        updateMask();
      }
      lastx = mouseX;
      lasty = mouseY;
    }

    private function handleDown(e:MouseEvent):void
    {
      if (_pause)
        return;

      isClicked = true;
      lastx = mouseX;
      lasty = mouseY;
      _drawShape.graphics.lineStyle(LINE_THICKNESS, LINE_COLOR, LINE_ALPHA);
      _drawShape.graphics.moveTo(lastx, lasty);
      //_drawBitmapData.lock();
    }

    private function updateMask():void
    {
      if (enableMasking)
      {
        // do something
        _maskBitmapData.draw(_drawShape);
        _drawBitmapData.copyPixels(_maskBitmapData, new Rectangle(0, 0, IMAGE_W, IMAGE_H), new Point(0, 0));
      }
    }

    private function stopDraw():void
    {
      trace("stopDraw");
      undoStack.push(_maskBitmapData.clone());
      if (undoStack.length > numUndoLevels + 1)
      {
        undoStack.splice(0, 1);
      }
    }

    public function undo():void
    {
      if (undoStack.length > 1)
      {
        trace("undo");
        _maskBitmapData.copyPixels(undoStack[undoStack.length - 2], _maskBitmapData.rect, new Point(0, 0));
        _drawBitmapData.copyPixels(_maskBitmapData, new Rectangle(0, 0, IMAGE_W, IMAGE_H), new Point(0, 0));
        undoStack.splice(undoStack.length - 1, 1);
      }
      _drawShape.graphics.clear();
    }

    /**
     * get mask object
     * @return
     */
    public function getMasker():BitmapData
    {
      return _drawBitmapData;
    }

    /**
     * get masked display image
     * @return
     */
    public function getMaskedImage():BitmapData
    {

      var image:BitmapData = new BitmapData(IMAGE_W, IMAGE_H, true, 0x00FFFFFF);
      image.draw(_preview_container);
      return image;
    }

    /**
     * get mask displacement map
     * @return
     */
    public function getDisplacementMap():BitmapData
    {
      var image:BitmapData = new BitmapData(IMAGE_W, IMAGE_H, true, 0xFF000000);
      image.draw(_drawBitmap);

      var image_map:BitmapData = new BitmapData(IMAGE_W, IMAGE_H, true, 0xFF000000);

      var startTime:Number = getTimer();
      var h:int = 0;
      var v:int = 0;
      for (h = 0; h < IMAGE_W; h++)
      {
        for (v = 0; v < IMAGE_H; v++)
        {
          if (image.getPixel(h, v) != 0x0)
          {
            image_map.setPixel(h, v, MAGIC_COLOR);
          }
        }
      }
      trace(getTimer() - startTime);

      var blur:BlurFilter = new BlurFilter(10, 10, 2);
      image_map.applyFilter(image_map, new Rectangle(0, 0, IMAGE_W, IMAGE_H), new Point(0, 0), blur);
      return image_map;
    }

    public function destroy():void
    {

      _preview_container.removeChild(_after_pic);
      _preview_container.removeChild(_maskBitmap);
      removeChild(_preview_container);

      _main_stage.removeChild(_before_pic);
      _main_stage.removeChild(_drawBitmap);
      removeChild(_main_stage);

      _main_stage.removeEventListener(MouseEvent.MOUSE_DOWN, handleDown);
      _main_stage.removeEventListener(MouseEvent.MOUSE_MOVE, handleMove);
      _main_stage.removeEventListener(MouseEvent.MOUSE_UP, handleUp);

      undoStack.length = 0;

      _drawBitmapData.dispose();
      _maskBitmapData.dispose();
      _drawBitmapData = null;
      _maskBitmapData = null;

    }

    public function get pause():Boolean
    {
      return _pause;
    }

    public function set pause(value:Boolean):void
    {
      _pause = value;
    }

    public function get before_pic():Bitmap
    {
      return _before_pic;
    }

    public function set before_pic(value:Bitmap):void
    {
      _before_pic = value;
    }

    public function get after_pic():Bitmap
    {
      return _after_pic;
    }

    public function set after_pic(value:Bitmap):void
    {
      _after_pic = value;
    }

    public function get main_stage():Sprite
    {
      return _main_stage;
    }

    public function set main_stage(value:Sprite):void
    {
      _main_stage = value;
    }

    public function get preview_container():Sprite
    {
      return _preview_container;
    }

    public function set preview_container(value:Sprite):void
    {
      _preview_container = value;
    }

  }

}
