//************************************************************************************
// tmMcOperate.as t.misawa 2010
//************************************************************************************
package tmlib {
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.IOErrorEvent;
	import flash.geom.Point;
	import flash.net.URLRequest;
	
	public class tmMcOperate	{
		//-----------------------------------------------------------------------		
		//-----------------------------------------------------------------------		
//		public function tmMcOperate() {}
			static public const NAME_PRE_REMOVE:String = "_NAME_PRE_REMOVE";  // リムーブチェックタグ用の名前

		//-----------------------------------------------------------------------		
		//-----------------------------------------------------------------------		
		// ---------------------------------------------------------
		// コンテナ上のオブジェクトを外す
		// _setType:名前のついたオブジェクトをはずす　null すべてはずす _isRemove:falseなら外さない(リストのみ返す)
		// 返値:外したもののリスト
		// ---------------------------------------------------------
		static public function removeSelChild(_containerObj:DisplayObjectContainer, _layerNameStr:String=null, _isRemove:Boolean=true):Array {
			var ii:int;
			var retArr:Array = new Array();
			if (_containerObj != null) {
				var child:DisplayObject;
				for (ii = (_containerObj.numChildren-1); ii >=0 ; --ii) {
					if (_layerNameStr == null) {
						child = _containerObj.getChildAt(0);
					}else {
						child = _containerObj.getChildByName(_layerNameStr);
					}
					if (child != null) {
						retArr.push(child);
						if(_isRemove==true){
							_containerObj.removeChild(child);//　上に載っているOBJがあればはずしておく
						}
					}
				}
			}
			return(retArr);
		}
		// ---------------------------------------------------------
		// バインド済みのBitmapDataをセット(リンケージプロパティでＣｌａｓｓをセット)
		// ---------------------------------------------------------
		static public function setBitmap(_containerObj:DisplayObjectContainer, _bmpData:BitmapData, _layerNameStr:String, _setType:int=0):void {
			removeSelChild(_containerObj,(_setType==0?null:_layerNameStr));	//　上に載っているOBJがあればはずしておく
			_containerObj.addChild(new Bitmap(_bmpData));
		}
		
		// ---------------------------------------------------------
		// バインド済みのMovieClipをセット(リンケージプロパティでＣｌａｓｓをセット)
		// _setType:0 すべて消して載せる 1: 上乗せ
		// ---------------------------------------------------------
		static public function setLinkedMc(_containerObj:DisplayObjectContainer, _mcData:MovieClip, _frame:int=1, _layerNameStr:String=null, _setType:int=0):void {
			if (_containerObj!=null) {
				removeSelChild(_containerObj,(_setType==0?null:_layerNameStr));	//　上に載っているOBJがあればはずしておく
				if (_mcData != null) {
					if (_layerNameStr != null) {
						_mcData.name = _layerNameStr;
					}
					_mcData.gotoAndStop(_frame);				
					_containerObj.addChild(_mcData);
				}
			}
		}
		
		// ---------------------------------------------------------
		//LoadMovie同等処理（実際には上乗せ処理）
		// ---------------------------------------------------------
		static public function loadMovieAc3(_containerObj:DisplayObjectContainer, _urlStr:String, _ofs:Point=null, _frame:int=1, _layerNameStr:String=null, _setType:int = 0, _func:Function = null,_errFunc:Function = null):Array {
			// まずはじめに載っているものをはずしておく(_urlStr==nullの場合は外して終了、それ以外ならエラー時に戻せるようにする)
			var _keepArr:Array = null;
			if (_urlStr!=null) {
				if ((_setType==0)&&(_containerObj!=null)) {
					_keepArr = removeSelChild(_containerObj, (_setType == 0?null:_layerNameStr), true);	//　上に載っているOBJを外す準備(false)
				}
				var loader:Loader = new Loader();
				var urlReq:URLRequest = new URLRequest(_urlStr);
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loadMovieAc3CompleteHandler);
				loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, loadMovieAc3IoErrorHandler);
				if(_ofs!=null){
					loader.x = _ofs.x;
					loader.y = _ofs.y;
				}
				if (_layerNameStr != null) {
					loader.name = _layerNameStr;
				}
				loader.load(urlReq);
				if (_containerObj!=null) {
					_containerObj.addChild(loader);//読み込みが終わったら表示される
				}
			}else {
				loadMovieAc3CompleteHandler(null);
			}
			return(_keepArr);

		// ---------------------------------------------------------
			function loadMovieAc3CompleteHandler(event:Event):void {
				if(event!=null){	// urlStr==nullで来た場合はevent==null
					var rootMc:Sprite = loader.content as Sprite;
					if((rootMc!=null)&&(rootMc.numChildren>0)){
						var childMc:MovieClip = rootMc.getChildAt(0) as MovieClip;
						if(childMc!=null){
							childMc.gotoAndStop(_frame);				
						}
					}
				}
				if (_func != null) {
					_func(event);
				}
			}
		// ---------------------------------------------------------
			function loadMovieAc3IoErrorHandler(event:IOErrorEvent):void {
				trace("load Error:"+event.currentTarget.loaderURL);
				if (_containerObj!=null) {
					_containerObj.removeChild(loader);//loaderをはずす
				}
				if (_errFunc != null) {
					_errFunc(event);
				}
			}
		}
	}
}