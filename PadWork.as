/////////////////////////
// PadWork.as
// t.misawa 2010
/////////////////////////
package tmlib
{
	import flash.display.DisplayObject;
	import flash.display.InteractiveObject;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;
	import flash.geom.Point;

	//----------------------------------------------------------------
	public class PadWork
	{
		static public const	PAD_REP_STT_TIME:int	= 20;
		static public const	PAD_REP_CONT_TIME:int	= 2;

		static public const	PAD_KEY_MOUSE_L:uint	= (1<<0);
		static public const	PAD_KEY_MOUSE_R:uint	= (1<<1);	// 未使用
		static public const	PAD_KEY_WHEEL_U:uint	= (1<<2);
		static public const	PAD_KEY_WHEEL_D:uint	= (1<<3);
		static public const	PAD_KEY_UP:uint		= (1<<4);
		static public const	PAD_KEY_DOWN:uint	= (1<<5);
		static public const	PAD_KEY_LEFT:uint	= (1<<6);
		static public const	PAD_KEY_RIGHT:uint	= (1<<7);
		static public const	PAD_KEY_TRIG_A:uint	= (1<<8);
		static public const	PAD_KEY_TRIG_B:uint	= (1<<9);
		static public const	PAD_KEY_TRIG_C:uint	= (1<<10);
		static public const	PAD_KEY_TRIG_D:uint	= (1<<11);
		static public const	PAD_KEY_START:uint	= (1<<12);
		static public const	PAD_KEY_SELECT:uint	= (1<<13);
		static public const	PAD_KEY_PAUSE:uint	= (1<<14);
		static public const	PAD_KEY_DEBUG:uint	= (1<<15);

		static public const	KEYDEF_LEFT:uint		= (Keyboard.LEFT);		//	カーソルキー左
		static public const	KEYDEF_RIGHT:uint	= (Keyboard.RIGHT);		//	カーソルキー右
		static public const	KEYDEF_UP:uint		= (Keyboard.UP);		//	カーソルキー上
		static public const	KEYDEF_DOWN:uint		= (Keyboard.DOWN);		//	カーソルキー下
		static public const	KEYDEF_TRIG_A:uint	= (Keyboard.SPACE);		//	スペースキー
		static public const	KEYDEF_TRIG_B:uint	= (Keyboard.SHIFT);		//	シフトキー
		static public const	KEYDEF_TRIG_C:uint	= (Keyboard.CONTROL);	//	コントロールキー
		static public const	KEYDEF_TRIG_D:uint	= (Keyboard.NUMPAD_0);	//	テンキーの０
		static public const	KEYDEF_START:uint	= (Keyboard.ENTER);		//	エンターキー
		static public const	KEYDEF_SELECT:uint	= (Keyboard.BACKSPACE);	//	バックスペースキー
		static public const	KEYDEF_PAUSE:uint	= (Keyboard.ESCAPE);	//	エスケープキー
		static public const	KEYDEF_DEBUG:uint	= (Keyboard.F12);		//	F12キー
		
		static public const	DEF_REC_BUFF_SIZE:int = 4096;
		static public const	REC_MODE_STOP:String = "stop";
		static public const	REC_MODE_REC:String  = "rec";
		static public const	REC_MODE_PLAY:String = "play";
		static public const	REC_TYPE_NORMAL:String = "rec_type_normal"; // いっぱいになったらそれ以上記録しない
		static public const	REC_TYPE_SHIFT:String = "rec_type_shift";   // いっぱいになったらシフトして記録
		
		static public const	PAD_WORK_DRAG_LINE:String = "_padWorkDragLineObj";
		
		public	var	mousePos:Point;
		public	var	dragSttPos:Point;	// ドラッグ開始位置
		public	var	key:uint;
		public	var	trg:uint;	// 押した瞬間
		public	var	rel:uint;	// 離した瞬間
		public	var	rep:uint;
		public	var	repTimer:Array;
		public	var	isRep:Array;
		private var	repSttTime:int;
		private var	repCntTime:int;
		private	var	app:InteractiveObject; /*Apprication*/
		private	var	padDev:PadWork = null;
		private var recBuff:Array;
		private var recBuffSize:int;
		private var recMode:String;
		private var playFrame:int;
		private var dragLineColor:uint;	//argb
		private var dragLineDispTarget:Sprite
		private var dragLine:Sprite;
		private var useTargetFocus:Boolean;
		private var recType:String;
		

		//----------------------------------------------------------------
		public	function PadWork(_recBuffSize = DEF_REC_BUFF_SIZE,_isParent:Boolean = true) {
			if (_isParent) {
				padDev = new PadWork(_recBuffSize,false);
				recBuff = new Array();
				recBuffSize = _recBuffSize;
				playFrame = -1;
			}
			recMode = REC_MODE_STOP;
			mousePos	= new Point(0,0);
			dragSttPos = new Point(0,0);
			key			= 0;
			trg			= 0;
			rep			= 0;
			rel			= 0;
			repTimer	= new Array(32);
			isRep		= new Array(32);
			for(var ii:int = 0;ii<32;++ii){
				repTimer[ii]	= new int(0);
				isRep[ii]		= new Boolean(false);
			}
			dragLineDispTarget = null;
			dragLine = new Sprite();
			dragLine.name = PAD_WORK_DRAG_LINE;
			repSttTime = PAD_REP_STT_TIME;
			repCntTime = PAD_REP_CONT_TIME;
			recType = REC_TYPE_NORMAL;
			useTargetFocus = false;
		}
		//----------------------------------------------------------------
		public	function setRepeatTime(_stt:int=PAD_REP_STT_TIME, _rep:int=PAD_REP_CONT_TIME):void {
			repSttTime = _stt;
			repCntTime = _rep;
		}
		//----------------------------------------------------------------
		public	function start(_app:InteractiveObject/*Apprication*/):void {
			if(padDev!=null){
				app = _app;
				padDev.setEventListener(_app);
			}
		}
		//----------------------------------------------------------------
		public	function flush():void{
			key		= 0;
			trg		= 0;
			rep		= 0;
			rel		= 0;
		}

		// 不要な情報は消す 
		public	function reset():void {
			flush();
//			this.key &= (~PAD_KEY_WHEEL_U);
//			this.key &= (~PAD_KEY_WHEEL_D);
//			this.key &= (~PAD_KEY_DEBUG);
		}

		public	function update():void {
			var nowKey:uint = (this.padDev != null ? this.padDev.key : 0 );
			if (recMode == REC_MODE_PLAY) {
				playFrame++;
				if (recBuff.length > playFrame) {
					nowKey = recBuff[playFrame];
				}else {
					recMode = REC_MODE_STOP;
					playFrame = -1;
				}
			}

			// キーデータ更新
			this.trg		= nowKey & ~this.key;	//この時点ではthis.keyはold値
			this.rel		= ~nowKey & this.key;
			this.key		= nowKey;
			if(padDev!=null){	// 再生専用PadはMouseなし
				this.mousePos.x = app.mouseX;
				this.mousePos.y = app.mouseY;
				if ((nowKey & PAD_KEY_MOUSE_L)==0) {
					this.dragSttPos.x = app.mouseX;
					this.dragSttPos.y = app.mouseY;
				}
			}
			// リピート情報の更新 
			rep	= trg;
			for(var ii:int =0; ii<32; ++ii){
				if( this.key & (1<<ii) ){
					var repTime:int;
					if(isRep[ii]==false){
						repTime = repSttTime;
					}else{
						repTime = repCntTime;
					}
					repTimer[ii]++;
					if(repTimer[ii] >= repTime){
						if(isRep[ii]==false){
							isRep[ii] = true;
						}
						repTimer[ii]=0;
						rep |= (1<<ii);
					}
				}else{
					isRep[ii] = false;
					repTimer[ii]=0;
				}
			}
			
			// キーデータの記録
			if(recMode == REC_MODE_REC){
				if (recBuff.length >= recBuffSize) {
					if(recType == REC_TYPE_SHIFT){
						recBuff.shift();		//最後のを捨てる
						recBuff.push(nowKey);	//先頭に追加
					}
				}else {
					recBuff.push(nowKey);	//先頭に追加
				}
			}
			// ドラッグライン表示
			dragLineDisp();
		}

		//----------------------------------------------------------------
		// ドラッグ表示ON/OFF
		//----------------------------------------------------------------
		public	function setDragLineDisp(_dispTarget:Sprite=null, _color:uint = 0xccbbccff, _useTargetFocus:Boolean=false):void {
			dragLineColor = _color;
			if(dragLineDispTarget != null){
				var lineObj:DisplayObject = _dispTarget.getChildByName(PAD_WORK_DRAG_LINE);
				if ( lineObj != null) {
					_dispTarget.removeChild(lineObj);
				}
				dragLineDispTarget = null;
			}
			if (_dispTarget != null) {
				dragLineDispTarget = _dispTarget;
				_dispTarget.addChild(dragLine);
			}
		}
		//----------------------------------------------------------------
		// ドラッグ表示ON/OFF
		//----------------------------------------------------------------
		private	function dragLineDisp():void {
			if (dragLineDispTarget != null) {
				var col:uint = (dragLineColor & 0xffffff);
				var alpha :Number = (uint)((dragLineColor >> 24)&0xff) / 255;
				dragLine.graphics.clear();
				dragLine.graphics.lineStyle(5, col, alpha);
				dragLine.graphics.moveTo(dragSttPos.x, dragSttPos.y);
				dragLine.graphics.lineTo(mousePos.x, mousePos.y);
			}
		}
		//----------------------------------------------------------------
		// キーデータ記録再生関連
		//----------------------------------------------------------------
		// 次回updateより記録
		public function startRec() {
			recMode = REC_MODE_REC;
			recBuff = new Array();
			playFrame = -1;
		}
		public function stopRec(_recType:String = REC_TYPE_NORMAL) {
			recMode = REC_MODE_STOP;
			recType = _recType;
			playFrame = -1;
		}
		// 次回updateより再生
		public function startPlay() {
			recMode = REC_MODE_PLAY;
			playFrame = -1;
		}
		public function stopPlay() {
			recMode = REC_MODE_STOP;
			playFrame = -1;
		}
		public function getRecDataNum():int {
			return(recBuff.length);
		}
		public function getRecBuffSize():int {
			return(recBuffSize);
		}
		public function getRecMode():String {
			return(recMode);
		}
		//----------------------------------------------------------------
		public function copyRecBuff():Array {
			return(recBuff.slice());	// Recデータのコピーを作成して返す
		}
		//----------------------------------------------------------------
		public function getRecBuff():Array {
			return(recBuff);	// Recデータの参照
		}
		//----------------------------------------------------------------
		public function setRecBuff(_recBuff:Array) {
			recBuff = _recBuff.slice();	// Recデータにデータを入れる
		}
		//----------------------------------------------------------------
		// 圧縮キーデータを生成
		//----------------------------------------------------------------
		public function copyCompressedRecBuff():Array {
			var cmpBuff:Array = null;	// {key:,count:}
			if (recBuff.length > 0) {
				var oldKey:uint = recBuff[0];
				var nowKey:uint;
				var cnt:uint = 0;
				cmpBuff = new Array();
				for (var ii = 0; ii < recBuff.length; ++ii) {
					nowKey = recBuff[ii];
					if (oldKey != nowKey) {
						cnt = 0;
						oldKey = nowKey;
					}
					cnt++;
					if (cnt == 1) {
						cmpBuff.push( { key:nowKey, count:cnt } );
					}else {
						cmpBuff[cmpBuff.length-1].count = cnt;
					}
				}
			}
			return(cmpBuff);	// 圧縮されたRecデータのコピーを作成して返す
		}
		//----------------------------------------------------------------
		// 圧縮キーデータをセット:返り値は展開後のサイズ(length)
		//----------------------------------------------------------------
		public function setCompressedRecBuff(_compressedRecBuff:Array):uint {
			recBuff = new Array();
			for (var ii = 0; ii < _compressedRecBuff.length; ++ii) {
				var key:int = _compressedRecBuff[ii].key;
				var cnt:int = _compressedRecBuff[ii].count;
				for (var jj = 0; jj < cnt; ++jj) {
					recBuff.push(key);
				}
			}
			return(recBuff.length);
		}
		//----------------------------------------------------------------


		//----------------------------------------------------------------
		private function setEventListener(app:InteractiveObject/*Apprication*/):void {
//			app.addEventListener(MouseEvent.MOUSE_MOVE,	mouseMoveHandler);
	 		app.addEventListener(MouseEvent.MOUSE_DOWN,	mouseKeyHandler);
	 		app.addEventListener(MouseEvent.MOUSE_UP,		mouseKeyHandler);
	 		app.addEventListener(MouseEvent.ROLL_OUT,		mouseKeyHandler);
	 		app.addEventListener(MouseEvent.ROLL_OVER,		mouseKeyHandler);
			app.addEventListener(MouseEvent.MOUSE_WHEEL,	mouseKeyHandler);
			app.stage.addEventListener(KeyboardEvent.KEY_DOWN,	keybordHandler);
			app.stage.addEventListener(KeyboardEvent.KEY_UP,	keybordHandler);
		}

		public function mouseMoveHandler(event:MouseEvent):void {	}
		public function mouseKeyHandler(event:MouseEvent):void {
			if(event.buttonDown){
				if (useTargetFocus) {
					event.target.stage.focus = event.target;
				}
				key |= PAD_KEY_MOUSE_L;
			}else{
				key &= ~PAD_KEY_MOUSE_L;
			}
			if(event.delta>0){
				key |= PAD_KEY_WHEEL_U;
			}else if(event.delta<0){
				key |= PAD_KEY_WHEEL_D;
			}
		}

		public function keybordHandler(event:KeyboardEvent):void {
			var inp:uint = 0;
			switch(event.keyCode){
				case KEYDEF_LEFT:		inp = PAD_KEY_LEFT;		break;
				case KEYDEF_RIGHT:		inp = PAD_KEY_RIGHT;	break;
				case KEYDEF_UP:			inp = PAD_KEY_UP;		break;
				case KEYDEF_DOWN:		inp = PAD_KEY_DOWN;		break;
				case KEYDEF_TRIG_A:		inp = PAD_KEY_TRIG_A;	break;
				case KEYDEF_TRIG_B:		inp = PAD_KEY_TRIG_B;	break;
				case KEYDEF_TRIG_C:		inp = PAD_KEY_TRIG_C;	break;
				case KEYDEF_TRIG_D:		inp = PAD_KEY_TRIG_D;	break;
				case KEYDEF_START:		inp = PAD_KEY_START;	break;
				case KEYDEF_SELECT:		inp = PAD_KEY_SELECT;	break;
				case KEYDEF_PAUSE:		inp = PAD_KEY_PAUSE;	break;
				case KEYDEF_DEBUG:		inp = PAD_KEY_DEBUG;	break;
			}
			if(event.type=="keyDown"){
				this.key |= inp;
			}else{
				this.key &= ~inp;
			}
		}
	}
}