/////////////////////////
// SubMath.as
// t.misawa 2009
/////////////////////////
package tmlib
{
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.utils.ByteArray;

	public class tmSub
	{
		//-----------------------------------------------------------------------------
		//! 自分から見たターゲット方向(world)を回転ベクトルrad(-PI~PI)で返す 
		//-----------------------------------------------------------------------------
		public static function getTargetAngle(myPos:Point, tgtPos:Point):Number
		{
			var outAngle:Number;
			outAngle = Math.atan2( (tgtPos.x - myPos.x), -(tgtPos.y - myPos.y) );
			return( outAngle );
		}

		//-----------------------------------------------------------------------------
		//! 自分から見たターゲット方向(local)を回転ベクトルrad(-PI~PI)で返す 
		//-----------------------------------------------------------------------------
		public static function getTargetAngleLocal(myPos:Point, tgtPos:Point, myRad:Number):Number
		{
			var outAngle:Number;
			outAngle = Math.atan2( (tgtPos.x - myPos.x), -(tgtPos.y - myPos.y) );
			outAngle = myRad - outAngle;
			if(outAngle > Math.PI) {	outAngle -= (Math.PI*2.0) }
			if(outAngle < -Math.PI){	outAngle += (Math.PI*2.0) }
			return( outAngle );
		}

		//-----------------------------------------------------------------------------
		//! ターゲット方向へ ホーミング(返り値はホーミング後の向き)
		//-----------------------------------------------------------------------------
		public static function homingRad(myPos:Point, tgtPos:Point, myRad:Number, maxRad:Number):Number
		{
			var ret:Number;
			maxRad = Math.abs(maxRad);
			ret = getTargetAngleLocal(myPos, tgtPos, myRad);
			if(ret > maxRad)		{	ret = maxRad;	}
			else if(ret < -maxRad)	{	ret = -maxRad;	}
			return(ret);
		}
		//-----------------------------------------------------------------------------
		//! 線分の交差チェック   交差したらtrue
		//-----------------------------------------------------------------------------
		public static function crossCheck(p1:Point, p2:Point, p3:Point, p4:Point):Boolean
		{
			if(((p1.x-p2.x)*(p3.y-p1.y)+(p1.y-p2.y)*(p1.x-p3.x))*((p1.x-p2.x)*(p4.y-p1.y)+(p1.y-p2.y)*(p1.x-p4.x))<0){
			if(((p3.x-p4.x)*(p1.y-p3.y)+(p3.y-p4.y)*(p3.x-p1.x))*((p3.x-p4.x)*(p2.y-p3.y)+(p3.y-p4.y)*(p3.x-p2.x))<0){
					return(true);
				}
			}
			return(false);
		}

		//-----------------------------------------------------------------------------
		// 配列のコピー
		//-----------------------------------------------------------------------------
		public static function clone(source:Object):* 
		{ 
				var myBA:ByteArray = new ByteArray(); 
				myBA.writeObject(source); 
				myBA.position = 0; 
				return(myBA.readObject()); 
		}

		//-----------------------------------------------------------------------------
		//! 2次元配列の転置
		//-----------------------------------------------------------------------------
		public static function transpose2DArray(_yxArr):Array
		{
			var xyArr:Array;
			var aW = _yxArr[0].length;
			var aH = _yxArr.length;
			xyArr = new Array(aW);
			for (var ii:int = 0; ii < aW; ++ii) {
				xyArr[ii] = new Array(aH);
				for (var jj:int = 0; jj < aH; ++jj) {
					xyArr[ii][jj] = _yxArr[jj][ii];
				}
			}
			return(xyArr);
		}
		
		//-----------------------------------------------------------------------------
		// 変化のあるときのみモーションをセット : _immediate == true なら通常のgotoAndPlay()と同じ
		//-----------------------------------------------------------------------------
		public static function gotoAndPlayContinue(_obj:MovieClip, _nextMotStr:String, _immediate:Boolean = false):void {
			if (( _obj.currentLabel != _nextMotStr )||(_immediate==true)) {// 変化したら
					_obj.gotoAndPlay(_nextMotStr);
			}
		}
		
		//-----------------------------------------------------------------------------
		// 文字列を適当な数字に変換(0<n<_mod)
		//-----------------------------------------------------------------------------
		public static function parceIntfromStr(_inStr:String, _mod:uint):uint {
			var ret:uint = 0;
			if(_inStr!=null){
				var len = _inStr.length;
				while (len--) {
					ret += _inStr.substr(len, 1).charCodeAt(0);
				}
				ret %= _mod;
			}
			return(ret);
		}
	}
}
