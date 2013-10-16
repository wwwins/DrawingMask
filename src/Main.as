package
{
	import com.adobe.images.JPGEncoder;
	import com.adobe.images.PNGEncoder;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.BlurFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.FileReference;
	import flash.utils.ByteArray;
	import flash.utils.getTimer;
	import iqcat.ui.QuickButton;
	import iqcat.utility.ScreenCapture;
	
	/**
	 * drawing mask
	 * 
	 * Usage:
	 * click "save" button: 取得人物去背圖
	 * click "save as map" button: 取得人物 mask 圖
	 * 
	 * @author flashisobar
	 */
	public class Main extends Sprite
	{
		[Embed(source="../assets/Before.jpg")]
		private var ImageBeforeClass:Class;
		[Embed(source="../assets/After.jpg")]
		private var ImageAfterClass:Class;
		//[Embed(source="../assets/bg.jpg")]
		//private var ImageBgClass:Class;
		
		static private const IMAGE_W:Number = 500;
		static private const IMAGE_H:Number = 550;
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
		
		public function Main():void
		{
			if (stage)
				init();
			else
				addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			// entry point
			
			// set layout
			layout();
			
			_before_pic = new ImageBeforeClass();
			_after_pic = new ImageAfterClass();

			
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

			_stage.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void
				{
					isClicked = true;
					lastx = mouseX;
					lasty = mouseY;
					_drawShape.graphics.lineStyle(LINE_THICKNESS, LINE_COLOR, LINE_ALPHA);
					_drawShape.graphics.moveTo(lastx, lasty);
					//_drawBitmapData.lock();
				});

			_stage.addEventListener(MouseEvent.MOUSE_MOVE, function(e:MouseEvent):void
				{
					if (isClicked)
					{
						_drawShape.graphics.lineTo(mouseX, mouseY);
						updateMask();
					}
					lastx = mouseX;
					lasty = mouseY;
				});
			
			_stage.addEventListener(MouseEvent.MOUSE_UP, function(e:MouseEvent):void
				{
					if (isClicked) {
							stopDraw();
							//_drawBitmapData.unlock();
					}
					isClicked = false;
				});
		
			// set undo manager
			undoStack = new Vector.<BitmapData>();
		}
		
		private function stopDraw():void 
		{
			trace("stopDraw");
			undoStack.push(_maskBitmapData.clone());
			if (undoStack.length > numUndoLevels + 1) {
				undoStack.splice(0,1);
			}
		}

		private function undo():void {
			if (undoStack.length > 1) {
				trace("undo");
				_maskBitmapData.copyPixels(undoStack[undoStack.length - 2], _maskBitmapData.rect, new Point(0, 0));
				_drawBitmapData.copyPixels(_maskBitmapData, new Rectangle(0, 0, IMAGE_W, IMAGE_H), new Point(0, 0));
				undoStack.splice(undoStack.length - 1, 1);
			}
			_drawShape.graphics.clear();
		}
		
		private function layout():void 
		{
			var save:QuickButton = new QuickButton("save");
			save.name = "save";
			save.y = stage.stageHeight - 30;
			save.addEventListener(MouseEvent.CLICK, myClick);
			addChild(save);
			
			var save_map:QuickButton = new QuickButton("save as map");
			save_map.name = "save as map";
			save_map.x = save.width + 10;
			save_map.y = stage.stageHeight - 30;
			save_map.addEventListener(MouseEvent.CLICK, myClick);
			addChild(save_map);
			var undo:QuickButton = new QuickButton("undo");
			undo.name = "undo";
			undo.x = save_map.x + save_map.width + 10;
			undo.y = stage.stageHeight - 30;
			undo.addEventListener(MouseEvent.CLICK, myClick);
			addChild(undo);
		}
		
		// save to local file
		private function myClick(e:MouseEvent):void
		{
			var bytes:ByteArray;
			
			// 去背圖
			if (e.target.name == "save")
			{
				bytes = PNGEncoder.encode(ScreenCapture.capture(_container, true, new Rectangle(0, 0, IMAGE_W, IMAGE_H)));
				var file:FileReference = new FileReference();
				//file.addEventListener(Event.COMPLETE, function():void { trace("save complete"); } );
				file.save(bytes, "pic.png");
			}
			
			// displacement map
			if (e.target.name == "save as map")
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
						if (image.getPixel(h, v) != 0x0) {
							image_map.setPixel(h, v, MAGIC_COLOR);
						}
					}
				}
				trace(getTimer() - startTime);
				
				var blur:BlurFilter = new BlurFilter(10,10,2);
				image_map.applyFilter(image_map, new Rectangle(0, 0, IMAGE_W, IMAGE_H), new Point(0, 0), blur);
				bytes = PNGEncoder.encode(image_map);
				
				var mapfile:FileReference = new FileReference ();
				//file.addEventListener(Event.COMPLETE, function():void { trace("save complete"); } );
				mapfile.save (bytes, "map.png");
			}
			// undo
			if (e.target.name == "undo") {
				undo();
			}
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
	
	}

}
