//************************************************************************************
// tmBmpAnim.as t.misawa 2010
//************************************************************************************
package tmlib {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	public class tmBmpAnim  extends Bitmap {
		static public const ANM_FLIP_H:String = "h";	// 上下反転
		static public const ANM_FLIP_V:String = "v";	// 左右反転
		static public const ANM_FLIP_VH:String = "vh";	// 上下左右反転
		static private const ANM_DEF_TICK_TIME:int = 1;	// アニメーション速度（デフォルト)
		static private const ANM_BLUR_TICK_TIME:int = 2;	// ブラー時間（デフォルト)
		static private const ANM_FLIP_NOTHING:String = "flip_nothing";	// 反転なし
		private var vram:BitmapData = null;
		private var bmpData:BitmapData;
		private var blurSrcBmpData:BitmapData;
		private var cWidth:int;
		private var cHeight:int;
		private var defTickTime:int; 
		private var blurTickTime:int; 
		private var animArr:Array = null;
		private var setAnimLabel:String = "";	// 最後にセットしたラベル
		private var animLabel:String = "";	// 最後に通過したラベル
		private var animPtr:int;
		private var animTimer:int = 0;
		private var useAnmSmoothing:Boolean = false;
		private var blurDataArr:Array;	// {bmpdata:, timer:, timeMax:}
//	private var	smoothing;　// 継承につき不要
	//-----------------------------------------------------------------------		
		public function getLastSetAnimLabel():String {	return setAnimLabel; }  // 最後にセットしたラベル
		public function getLastMoveAnimLabel():String {	return animLabel; }     // 最後に通過したラベル
	//-----------------------------------------------------------------------
	// シンプルな固定矩形領域アニメ u*_widthが実際のテクスチャ座標
	// _animArr[]{[label:], cU:, cV:, [flip:ANM_FLIP_],[tick:], [goto:]}
	// texU = cU*cWidth  tickTime = tick * defTickTime
	// label,goto:String
	//-----------------------------------------------------------------------		
		public function tmBmpAnim(_width:int, _height:int, _vramData:BitmapData = null, _pixcelSnapping:String = "auto", _smoothing:Boolean = false) {
			vram = _vramData;
			cWidth = _width;
			cHeight = _height;
			bmpData = new BitmapData(cWidth, cHeight, true, 0x000000);
			blurSrcBmpData = new BitmapData(cWidth, cHeight, true, 0x000000);
			blurDataArr = new Array();
			super(bmpData, _pixcelSnapping, _smoothing);
		}
		
	//-----------------------------------------------------------------------
		public function startAnim() {
			if(!this.hasEventListener(Event.ENTER_FRAME)){
				addEventListener(Event.ENTER_FRAME, onEnterFrameFunc);
			}
		}
	//-----------------------------------------------------------------------
		public function stopAnim() {
			if(this.hasEventListener(Event.ENTER_FRAME)){
				removeEventListener(Event.ENTER_FRAME, onEnterFrameFunc);
			}
		}
	//-----------------------------------------------------------------------
	// アニメーションのセット:セットできたらtrue
	// _defTickTime:デフォルトアニメーションフレーム数
	// _anmSmoothing:ブラーあり（高負荷）:ブラースピードは_defTickTimeに依存
	//-----------------------------------------------------------------------		
		public function setAnim(_animArr:Array = null, _startLabel:String = null, _defTickTime:int = ANM_DEF_TICK_TIME, _anmSmoothing:Boolean = false,_blurTickTime:int = ANM_BLUR_TICK_TIME):Boolean {
			var ret:Boolean = false;
			useAnmSmoothing = _anmSmoothing;
			if((animArr != _animArr)||(setAnimLabel != _startLabel)){	// 同じなら再セットしない
				var sttPoint:int = labelToPtr(_animArr,_startLabel);
				if (sttPoint < 0) {
					sttPoint = 0;
				}
				setAnimLabel = _startLabel;
				animArr = _animArr;
				animPtr = sttPoint;
				if (animPtr < 0) animPtr = 0;
				defTickTime = _defTickTime;
				blurTickTime = _blurTickTime;
				animTimer = 0;
				updateAnim(true);
				ret = true;
			}
			startAnim();
			return(ret);
		}
		
	//-----------------------------------------------------------------------
	// アニメーションのアップデート:返値はポインタの場所(int)
	//-----------------------------------------------------------------------		
		private function updateAnim(_is1st:Boolean = false):int {
			bmpData.lock();
			if (animArr != null) {
				if((animPtr>=0)&&(animPtr < animArr.length)){
					var anmObj:Object = animArr[animPtr];	// 現在表示している場所
					if (anmObj != null) {
						animTimer++;
						var tickTime:int;
						if (anmObj.tick == undefined) {
							tickTime = defTickTime;
						}else {
							tickTime = defTickTime * anmObj.tick;
						}
						if ((_is1st)||(animTimer > tickTime)) {
							if (_is1st == false){ 
								animTimer = 0;
								if(anmObj.goto == undefined){
									animPtr++;
								}else{
									var labelPtr:int = labelToPtr(animArr,anmObj.goto);
									if(labelPtr>=0){
										animPtr = labelPtr;
									}
								}
							}
							anmObj = animArr[animPtr];	// 次に表示する場所
							if (anmObj != null) {
								if (anmObj.label != undefined) {
									animLabel = anmObj.label;
								}
								if (useAnmSmoothing) {
									blurDataArr.push( { bmpdata:bmpData.clone(), timer:blurTickTime, timeMax:blurTickTime } );
									copyPixelsVH(blurSrcBmpData, vram, anmObj);
								}
								copyPixelsVH(bmpData, vram, anmObj);
							}
						}
					}
				}
			}
			if (useAnmSmoothing) {
				updateBlurAnim();
			}
			bmpData.unlock();
			return(animPtr);
		}
		
		//-----------------------------------------------------------------------
		// ブラーアニメーションを追加:返値は現在動いているブラー数
		//-----------------------------------------------------------------------		
		private function updateBlurAnim():int {
			var cnt:int = 0;
			var ii:int;
			var data:Object;
			var srcRect:Rectangle = new Rectangle(0, 0, blurSrcBmpData.width, blurSrcBmpData.height);
			var srcPos:Point = new Point();
			bmpData.copyPixels(blurSrcBmpData, srcRect, srcPos);
			for ( ii = 0; ii < blurDataArr.length; ++ii) {
				data = blurDataArr[ii];
				data.timer--;
				if (data.timer <= 0) {	//このブラーは終了 
					blurDataArr.splice(ii, 1);
				}else {
					var rate:Number = (data.timer / data.timeMax);
					var col = 0xffff + (Math.floor(rate * 255) << 24);
					var alphaBmpData:BitmapData = new BitmapData(data.bmpdata.width, data.bmpdata.height, true, col);
					bmpData.copyPixels(data.bmpdata, srcRect, srcPos,alphaBmpData,srcPos,true);
					cnt++;
				}
			}
			return(cnt);
		}
		
		//-----------------------------------------------------------------------
		// 指定したlabel表記のある配列番号を返す（なければ-1）
		//-----------------------------------------------------------------------		
		private function labelToPtr(_animArr:Array, _label:String):int {
			var retPtr:int = -1;
			if ((_animArr != null)&&(_label!=null)) {
				for (var ii = 0; ii < _animArr.length; ++ii) {
					var anmObj:Object = _animArr[ii];	// 現在表示している場所
					if (anmObj != null) {
						if (anmObj.label != undefined) {
							if (anmObj.label == _label) {
								retPtr = ii;
								break;
							}
						}
					}
				}
			}
			return(retPtr);
		}
		//-----------------------------------------------------------------------		
		//-----------------------------------------------------------------------		
		private function copyPixelsVH(_dest:BitmapData, _src:BitmapData, _anmObj:Object) {

			var srcRect:Rectangle = new Rectangle( _anmObj.cU * cWidth, _anmObj.cV * cHeight, cWidth, cHeight);
			if (_anmObj.flip != undefined) {
var mat:Matrix = new Matrix();
				switch(_anmObj.flip) {
				default:
				case ANM_FLIP_VH:
					mat.translate( -srcRect.x-cWidth, -srcRect.y-cHeight);
					mat.scale( -1, -1);
					break;
				case ANM_FLIP_V:
					mat.translate( -srcRect.x-cWidth, -srcRect.y);
					mat.scale( -1, 1);
					break;
				case ANM_FLIP_H:
					mat.translate( -srcRect.x, -srcRect.y-cHeight);
					mat.scale( 1, -1);
					break;
				}
				_dest.fillRect(new Rectangle(0, 0, cWidth, cHeight), 0);
				_dest.draw(_src, mat);
			}else{
				_dest.copyPixels(_src , srcRect, new Point());
			}
		}
		//-----------------------------------------------------------------------		
		//-----------------------------------------------------------------------		
		private function onEnterFrameFunc(event:Event) {
			updateAnim();
		}
	}
}
