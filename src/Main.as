package
{
	import com.adobe.images.JPGEncoder;
	import com.adobe.images.PNGEncoder;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.net.FileReference;
	import flash.utils.ByteArray;
	import iqcat.ui.QuickButton;
	
	/**
	 * drawing mask
	 * 
	 * Usage:
	 * click "save" button: 取得人物去背圖
	 * click "save as map" button: 取得人物 mask 圖
	 * click "undo" button: undo drawing mask
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
		
		private var drawingMask:DrawingMask;
		
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
			
			var before_bmp:Bitmap = new ImageBeforeClass();
			var after_bmp:Bitmap = new ImageAfterClass();
			drawingMask = new DrawingMask(before_bmp.bitmapData, after_bmp.bitmapData);
			addChild(drawingMask);
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
				bytes = PNGEncoder.encode(drawingMask.getMaskedImage());
				//bytes = PNGEncoder.encode(drawingMask.getMasker());
				var file:FileReference = new FileReference();
				//file.addEventListener(Event.COMPLETE, function():void { trace("save complete"); } );
				file.save(bytes, "pic.png");
			}
			
			// displacement map
			if (e.target.name == "save as map")
			{
				bytes = PNGEncoder.encode(drawingMask.getDisplacementMap());
				
				var mapfile:FileReference = new FileReference ();
				//file.addEventListener(Event.COMPLETE, function():void { trace("save complete"); } );
				mapfile.save (bytes, "map.png");
			}
			
			// undo
			if (e.target.name == "undo") {
				drawingMask.undo()
			}
		}
		
	}

}