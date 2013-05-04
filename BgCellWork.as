package tmlib
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.display.Sprite;
	import flash.geom.Rectangle;
	
	public class BgCellWork
	{
//		private	var	vramWkId:int;	// 使用するBITMAPの VramWork[n] の n
		private	var	color:int;
		private	var	bmp:Bitmap;
		private	var	bmp2:Bitmap;	// 重ね合わせ用
//		public	var	bmaData:BitmapData;
//		public	var	bmaData2:BitmapData;	// 重ね合わせ用
		public	var spr:Sprite;

		public function BgCellWork(_bmp:Bitmap, _bmp2:Bitmap = null){
			color = 0x7f808080;
			bmp = _bmp;
			bmp2 = _bmp2;
			spr = new Sprite();
			if (bmp != null) {
				spr.addChild(bmp);
			}
			if (bmp2 != null) {
				spr.addChild(bmp2);
			}
		}
	}
}