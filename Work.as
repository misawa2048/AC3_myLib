/////////////////////////
// Work.as
// t.misawa 2010 Elix.Inc.
/////////////////////////
package tmlib
{
	public class Work
	{
		static private var uid:uint=0;
		private	var serialNo:uint;	// ワーク固有の通し番号(書き換え不可)
		private	var beFlag:Boolean;
		private	var preDie:Boolean;
		private	var isMove:Boolean;
		private	var isDisp:Boolean;
		public	var name:String;		// 名前(書き換え可)
		public	var type:int;		// 0:テクスチャ 1:コントロール 2:ベクタ
		public	var id:int;			// 0: PL 1:EM 2:SHELL
		public	var kind:int;
		
		public function Work(){
			serialNo	= uid;
			name		= "work" + uid.toString();
			clear();
			uid++;
		}
		public function clear():void{
			beFlag		= false;
			preDie		= false;
			isMove		= false;
			isDisp		= false;
			type		= 0;
			id			= 0;
			kind		= 0;
		}
	}
}