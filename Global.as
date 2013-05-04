/////////////////////////
// Gloabl.as
// t.misawa 2010
/////////////////////////
package tmlib
{
	import flash.display.MovieClip;
	import flash.display.Sprite;
	public class Global
	{
		static public const	GL_CONST_NUM_0=0;
		static public const	GL_CONST_NUM_1=1;
		static public const	GL_CONST_NUM_2=2;

		static public const	DEBUG_USE:Boolean	= true;		//debugあり/なし 
		static public const	DEBUG_DISP:Boolean	= true;	//debug表示あり/なし 

		static public const	SYS_WINDOW_W:int	= 240;	//
		static public const	SYS_WINDOW_H:int	= 240;	//
		static public const	MAP_CELL_W_NUM:int	= 15;	//
		static public const	MAP_CELL_H_NUM:int	= 9;	//

		static public const	GRP_PRIO_NUM:int	= 8;
		static public const	GRP_DEF_OBJ_SIZE:int	= 32;
		static public const	GRP_DEF_BGCELL_SIZE:int	= 16;
		static public const	GRP_DEF_BGCELL_W_NUM:int = 136;	// 2176/16 今回はマップサイズ //(Math.ceil(SYS_WINDOW_W / GRP_DEF_BGCELL_SIZE) + 1);
		static public const	GRP_DEF_BGCELL_H_NUM:int = 136	// 今回はマップサイズ //(Math.ceil(SYS_WINDOW_H / GRP_DEF_BGCELL_SIZE) + 1);

		static public const	OBJ_WORK_NUM:int	= 512;
		static public const	BG_WORK_NUM:int		= 256;

		static public const	RNO0_INIT:int		= 0;
		static public const	RNO0_MOVE:int		= 1;

		static public const	BG_ID_GAME:int	= 0;
		static public const	BG_ID_FRONT:int	= 1;
		static public const	BG_ID_MAP:int		= 2;

		static public const	OBJ_ID_PL:int		= 0;
		static public const	OBJ_ID_EM:int		= 1;
		static public const	OBJ_ID_SH:int		= 2;
		static public const	OBJ_ID_ST:int		= 3;	// メッセージなど
		static public const	OBJ_ID_UI:int		= 4;	// ボタンなど
		
		//----------------------------------------------------
//		include "globalExt.as"
		static public const	VRAM_ID_FIELD=0;
		//----------------------------------------------------
		public var systemTime:int;
		//----------------------------------------------------
		public var	padWk:PadWork;
		public var	objWk:Array;
		public var	bgWk:Array;
		public var	dispList:Array;
		
		public	function Global() {
			var ii:int;
			padWk	= new PadWork();

			objWk	= new Array(OBJ_WORK_NUM);
			for( ii = 0; ii<OBJ_WORK_NUM;++ii){
				objWk[ii] = null;
			}
			bgWk	= new Array(BG_WORK_NUM);
			for( ii = 0; ii<BG_WORK_NUM;++ii){
				bgWk[ii] = null;
			}
			
			dispList	= new Array(GRP_PRIO_NUM);
			for( ii = 0; ii<GRP_PRIO_NUM; ++ii){
				dispList[ii]	= new Sprite();
			}

			systemTime	= 0;

			// 追加global変数分
//			globalExt();
		}

		//-----------------------------------------------------------------------------
		// 各種情報の更新 :PAUSE中ならfalseが返る
		// メインクラスだとデバッグができないようなのでここに入れます。
		//-----------------------------------------------------------------------------
		public	function update( app:MovieClip ):Boolean{
	
			this.padWk.update();	// 
			return(true);
		}

		// ---------------------------------------------------------
		// OBJ初期化
		// ---------------------------------------------------------
		public function objInit():Boolean{
			var	ret:Boolean = true;
			for( var ii:int = 0; ii<OBJ_WORK_NUM;++ii){
				if(objWk[ii]){
					delete(objWk[ii]);
					objWk[ii] = null;
				}
			}
			return(ret);
		}
		
		// ---------------------------------------------------------
		// BG初期化
		// ---------------------------------------------------------
		public function bgInit():Boolean{
			var	ret:Boolean = true;
			for( var ii:int = 0; ii < BG_WORK_NUM;++ii){
				if(bgWk[ii]){
					delete(bgWk[ii]);
					bgWk[ii] = null;
				}
			}
			return(ret);
		}
	}
}