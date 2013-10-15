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

		private var enableMasking:Boolean = true;
		private var isClicked:Boolean = false;
		private var lastx:Number = 0;
		private var lasty:Number = 0;
		
		private var _container:Sprite;
		private var _drawShape:Shape;
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
			
			// set drawing 
			_before_pic = new ImageBeforeClass();
			_after_pic = new ImageAfterClass();
			_drawShape = new Shape();
			
			_drawShape.graphics.lineStyle(30, 0xFFFFFF, 0.40);
			
			_maskBitmapData = new BitmapData(IMAGE_W, IMAGE_H, true, 0x0);
			_maskBitmap = new Bitmap(_maskBitmapData);
			var blur:BlurFilter = new BlurFilter();
			_maskBitmap.filters = [blur];
			_maskBitmap.cacheAsBitmap = true;
			_after_pic.cacheAsBitmap = true;
			_after_pic.mask = _maskBitmap;
			
			_container = new Sprite();
			// add background image
			//_container.addChild(new ImageBgClass);
			_container.addChild(_after_pic);
			_container.addChild(_maskBitmap);
			_container.x = IMAGE_W + 10;
			addChild(_container);
			
			addChild(_before_pic);
			addChild(_drawShape);
			
			stage.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void
				{
					isClicked = true;
					lastx = mouseX;
					lasty = mouseY;
					_drawShape.graphics.moveTo(lastx, lasty);
				});
			
			stage.addEventListener(MouseEvent.MOUSE_MOVE, function(e:MouseEvent):void
				{
					if (isClicked)
					{
						_drawShape.graphics.lineTo(mouseX, mouseY);
						updateMask();
					}
					lastx = mouseX;
					lasty = mouseY;
				});
			
			stage.addEventListener(MouseEvent.MOUSE_UP, function(e:MouseEvent):void
				{
					isClicked = false;
				});
		
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
				image.draw(_drawShape);
				var image_map:BitmapData = new BitmapData(IMAGE_W, IMAGE_H, true, 0xFF000000);
				
				var startTime:Number = getTimer();
				var h:int = 0;
				var v:int = 0;
				for (h = 0; h < IMAGE_W; h++)
				{
					for (v = 0; v < IMAGE_H; v++)
					{
						if (image.getPixel(h, v) != 0x0) {
							image_map.setPixel(h, v, 0x686868);
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
		}
		
		private function updateMask():void
		{
			if (enableMasking)
			{
				// do something
				_maskBitmapData.draw(_drawShape);
			}
		}
	
	}

}
