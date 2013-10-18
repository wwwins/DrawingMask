package  
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

    static private const IMAGE_W:Number = 500;
    static private const IMAGE_H:Number = 500;
    static private const LINE_THICKNESS:Number = 30;
    static private const LINE_COLOR:Number = 0xFFFFFF;
    static private const LINE_ALPHA:Number = 1.0;
    static private const MAGIC_COLOR:Number = 0x686868;

    private var enableMasking:Boolean = true;
    private var isClicked:Boolean = false;
    private var lastx:Number = 0;
    private var lasty:Number = 0;

    private var undoStack:Vector.<BitmapData>;
    private var numUndoLevels:uint = 10;

    private var _stage:Sprite;
    private var _container:Sprite;
    private var _drawShape:Shape;
    private var _drawBitmap:Bitmap;
    private var _drawBitmapData:BitmapData;
    private var _maskBitmapData:BitmapData;
    private var _maskBitmap:Bitmap;
    // 處理前的圖
    private var _before_pic:Bitmap;
    // 處理後的圖
    private var _after_pic:Bitmap;

    public function DrawingMask(__beforeBitmapdata:BitmapData, __afterBitmapdata:BitmapData) 
    {
      init(__beforeBitmapdata, __afterBitmapdata);
    }

    private function init(_before_bmd:BitmapData, _after_bmd:BitmapData):void 
    {
      _before_pic = new Bitmap(_before_bmd);
      _after_pic = new Bitmap(_after_bmd);

      _maskBitmapData = new BitmapData(IMAGE_W, IMAGE_H, true, 0x0);
      _maskBitmap = new Bitmap(_maskBitmapData);
      var blur:BlurFilter = new BlurFilter();
      _maskBitmap.filters = [blur];
      _maskBitmap.cacheAsBitmap = true;
      _after_pic.cacheAsBitmap = true;
      _after_pic.mask = _maskBitmap;

      _drawShape = new Shape();
      _drawShape.graphics.lineStyle(LINE_THICKNESS, LINE_COLOR, LINE_ALPHA);
      _drawBitmapData = new BitmapData(IMAGE_W, IMAGE_H, true, 0x0);
      _drawBitmap = new Bitmap(_drawBitmapData, "auto", true);
      _drawBitmap.alpha = 0.4;

      _container = new Sprite();
      // add background image
      //_container.addChild(new ImageBgClass);
      _container.addChild(_after_pic);
      _container.addChild(_maskBitmap);
      _container.x = IMAGE_W + 10;
      addChild(_container);

      _stage = new Sprite();
      addChild(_stage);
      _stage.addChild(_before_pic);
      _stage.addChild(_drawBitmap);
      //_stage.addChild(_drawShape);

      _stage.addEventListener(MouseEvent.MOUSE_DOWN, handleDown);
      _stage.addEventListener(MouseEvent.MOUSE_MOVE, handleMove);
      _stage.addEventListener(MouseEvent.MOUSE_UP, handleUp);

      // set undo manager
      undoStack = new Vector.<BitmapData>();

    }

    private function handleUp(e:MouseEvent):void 
    {
      if (isClicked) {
        stopDraw();
        //_drawBitmapData.unlock();
      }
      isClicked = false;
    }

    private function handleMove(e:MouseEvent):void 
    {
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
        _drawBitmapData.copyPixels(_maskBitmapData, new Rectangle(0,0,IMAGE_W,IMAGE_H),new Point(0,0));
      }
    }

    private function stopDraw():void 
    {
      trace("stopDraw");
      undoStack.push(_maskBitmapData.clone());
      if (undoStack.length > numUndoLevels + 1) {
        undoStack.splice(0,1);
      }
    }

    public function undo():void {
      if (undoStack.length > 1) {
        trace("undo");
        _maskBitmapData.copyPixels(undoStack[undoStack.length - 2], _maskBitmapData.rect, new Point(0, 0));
        _drawBitmapData.copyPixels(_maskBitmapData, new Rectangle(0,0,IMAGE_W,IMAGE_H),new Point(0,0));
        undoStack.splice(undoStack.length - 1, 1);
      }
      _drawShape.graphics.clear();
    }

    /**
     * get mask object
     * @return
     */
    public function getMasker():BitmapData {
      return _drawBitmapData;
    }

    /**
     * get masked display image
     * @return
     */
    public function getMaskedImage():BitmapData {

      var image:BitmapData = new BitmapData(IMAGE_W, IMAGE_H, true, 0x00FFFFFF);
      image.draw(_container);
      return image;
    }

    /**
     * get mask displacement map
     * @return
     */
    public function getDisplacementMap():BitmapData {
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
          if (image.getPixel(h, v) != 0x0) {
            image_map.setPixel(h, v, MAGIC_COLOR);
          }
        }
      }
      trace(getTimer() - startTime);

      var blur:BlurFilter = new BlurFilter(10,10,2);
      image_map.applyFilter(image_map, new Rectangle(0, 0, IMAGE_W, IMAGE_H), new Point(0, 0), blur);
      return image_map;
    }

    public function destroy():void {

      _container.removeChild(_after_pic);
      _container.removeChild(_maskBitmap);
      removeChild(_container);

      _stage.removeChild(_before_pic);
      _stage.removeChild(_drawBitmap);
      removeChild(_stage);

      _stage.removeEventListener(MouseEvent.MOUSE_DOWN, handleDown);
      _stage.removeEventListener(MouseEvent.MOUSE_MOVE, handleMove);
      _stage.removeEventListener(MouseEvent.MOUSE_UP, handleUp);

      undoStack.length = 0;

      _drawBitmapData.dispose();
      _maskBitmapData.dispose();
      _drawBitmapData = null;
      _maskBitmapData = null;

    }
  }

}
