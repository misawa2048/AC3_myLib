/////////////////////////
// BgWork.as
// t.misawa 2010
/////////////////////////
package tmlib
{
	import flash.display.Sprite;
	import flash.geom.Point;

	public class BgWork extends Work
	{
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

		public function BgWork(_id:int=0){
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
			rno				= new Array(0,0,0,0);
			container	= new Sprite();
		}

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

	}
}
