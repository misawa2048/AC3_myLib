/////////////////////////
// ObjWork.as
// t.misawa 2010
/////////////////////////
package tmlib
{
	import flash.display.Sprite;
	import flash.geom.Point;

	public class ObjWork extends Work
	{
		static public const	WORK_RNO0_INIT:uint		= 0;
		static public const	WORK_RNO0_MOVE:uint		= 1;
		static public const	WORK_RNO0_DIE:uint		= 2;
		static public const	WORK_RNO0_ERASE:uint	= 3;
		
		public	var	pos:Point;
		public	var	oldPos:Point;
		public	var	speed:Point;
		public	var	accel:Point;
		public	var	centerOfs:Point;
		public	var	basePos:Point;		// 初期位置 
		public	var	rotRad:Number;
		public var	rno:Array;
		public	var	prio:uint;		// 表示優先 
		public	var	color:uint;
		public	var	timer:int;
		public	var	counter:int;
		public	var container:Sprite;

		public function ObjWork(_id:int=0){
			clear();
		}

		public override function clear():void {
			super.clear();
			pos			= new Point();
			oldPos	= new Point();
			speed		= new Point();
			accel		= new Point();
			centerOfs	= new Point();
			basePos		= new Point();
			container	= new Sprite();
			rno				= new Array(0,0,0,0);
		}

		//-----------------------------------------------------------------------------
		//! setRno
		//-----------------------------------------------------------------------------
		public function setRno(_r0:uint=0, _r1:uint=0, _r2:uint=0, _r3:uint=0):void {	rno[0]=_r0;	rno[1]=_r1;	rno[2]=_r2;	rno[3]=_r3; }
		//-----------------------------------------------------------------------------
		//! preMove
		//-----------------------------------------------------------------------------
		public function preMove():void{
		}
		
		//-----------------------------------------------------------------------------
		//! move
		//-----------------------------------------------------------------------------
		public function move():void{
		}
		
		//-----------------------------------------------------------------------------
		//! postMove
		//-----------------------------------------------------------------------------
		public function postMove():void{
		}

		//-----------------------------------------------------------------------------
		// 加速度をセット
		//-----------------------------------------------------------------------------
		public function setAccel(_accX:Number, _accY:Number) {
			accel.x = _accX;
			accel.y = _accY;
		}
		//-----------------------------------------------------------------------------
		// 速度をセット
		//-----------------------------------------------------------------------------
		public function setSpeed(_spdX:Number, _spdY:Number) {
			speed.x = _spdX;
			speed.y = _spdY;
		}
		//-----------------------------------------------------------------------------
		// 速度を加える(accelを使用)
		//-----------------------------------------------------------------------------
		public function addSpeed(_minX:Number=Number.MIN_VALUE, _minY:Number=Number.MIN_VALUE, _maxX:Number=Number.MAX_VALUE, _maxY:Number=Number.MAX_VALUE ):Point{
			var old:Point = new Point(speed.x, speed.y);
			speed.x += accel.x;
			if (speed.x < _minX) {
				speed.x = _minX;
			}else if (speed.x > _maxX) {
				speed.x = _maxX;
			}
			speed.y += accel.y;
			if (speed.y < _minY) {
				speed.y = _minY;
			}else if (speed.y > _maxY) {
				speed.y = _maxY;
			}
			return(old);
		}
	}
}
