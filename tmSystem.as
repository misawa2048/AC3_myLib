//************************************************************************************
//************************************************************************************
package tmlib {
	import flash.display.MovieClip;
	import flash.events.Event
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	public class tmSystem extends MovieClip {
		public var	timer:int;
		public var	rno:Array;
		public function tmSetOnEnterFrameFunc(_func:Function = null):void { onEnterFrameFunc = _func; };
		
		private var	systemTimer:uint;
		private var onEnterFrameFunc:Function = null;

		//============================================================
		//============================================================
		public function tmSystem() {
			trace("start");
			initSys();
		}
		//============================================================
		//============================================================
		public function tmStart() {
			this.addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
		//============================================================
		//============================================================
		public function tmUpdate() {
			systemTimer++;
		}
		//============================================================
		//============================================================
		public function tmDraw() {
		}
		//============================================================
		//! setRno
		//============================================================
		public function setRno(_r0:uint=0, _r1:uint=0, _r2:uint=0, _r3:uint=0):void {	rno[0]=_r0;	rno[1]=_r1;	rno[2]=_r2;	rno[3]=_r3; }
		//------------------------------------------------------------
		//------------------------------------------------------------
		private function initSys() {
			systemTimer = 0;
			timer = 0;
			rno	= new Array(0,0,0,0);
		}
		//------------------------------------------------------------
		//------------------------------------------------------------
		private function onEnterFrame(event:Event) {
			if (onEnterFrameFunc != null) {
				onEnterFrameFunc(event);
			}
		}
	}
}
//************************************************************************************
