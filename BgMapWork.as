package tmlib
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	import tmlib.Global;

//----------------------------------------------------------------------------------------
//MAP用データフォーマット(uint x 2)
// MLB|hhhhdddd|--------|--------|--------| |xxxxxxxx|yyyyyyyy|xxxxxxxx|yyyyyyyy|
//      |   |                                  |                 +VRAM上の画像位置(8pixelを1)
//      |   |                                  +VRAM上の画像位置:草等の重ね合わせ用:未使用時は0
//      |   +MDH_DIR_（0：なし 1:上 2:右上 3:右 ... 7:左 8:左上)
//      +コリジョンフラグ 
//----------------------------------------------------------------------------------------
//マスクID＞０のとき：重ね合わせ画像位置から左にID*8ピクセルずつ　上、右上、右、...左、左上
//
	public class BgMapWork extends BgWork
	{
		static public var MDH_DIR_NONE:uint = uint(0x00000000);
		static public var MDH_DIR_U:uint    = uint(0x00010000);
		static public var MDH_DIR_UR:uint   = uint(0x00020000);
		static public var MDH_DIR_R:uint    = uint(0x00030000);
		static public var MDH_DIR_DR:uint   = uint(0x00040000);
		static public var MDH_DIR_D:uint    = uint(0x00050000);
		static public var MDH_DIR_DL:uint   = uint(0x00060000);
		static public var MDH_DIR_L:uint    = uint(0x00070000);
		static public var MDH_DIR_UL:uint   = uint(0x00080000);
		static public var MDH_MASK_COLL:uint = uint(0xf0000000);

		static public var MDL_MASK_UV:uint =     uint(0x0000ffff);
		static public var MDL_MASK_EXT_UV:uint = uint(0xffff0000);

		public var fieldCanvas:Sprite;
public	var	mapTop:Point;
public	var mapTopOld:Point;

		private	var	vramWkId:int;
		private	var	mapArray:Array;	// MAP配列
		private	var	mapCellArray:Array;	// 表示領域用配列
		private	var	mapWNum:int;
		private	var	mapHNum:int;
		
		private	var	cellWNum:int;
		private	var	cellHNum:int;
		private	var	cellWidth:int;
		private	var	cellHeight:int;
		

		//-----------------------------------------------------------------------------
		//! _id:work id  _cellWNum,_cellHNum:セルの数   cW,cH:セルのサイズ
		//-----------------------------------------------------------------------------
//		public function BgMapWork(_id:int=0,_cellWNum:int=Global.GRP_DEF_BGCELL_W_NUM, _cellHNum:int=Global.GRP_DEF_BGCELL_H_NUM, cW:int=Global.GRP_DEF_BGCELL_SIZE, cH:int=Global.GRP_DEF_BGCELL_SIZE )
		public function BgMapWork(_id:int=0,_cellWNum:int=Global.GRP_DEF_BGCELL_W_NUM, _cellHNum:int=Global.GRP_DEF_BGCELL_H_NUM, _cW:int=Global.GRP_DEF_BGCELL_SIZE, _cH:int=Global.GRP_DEF_BGCELL_SIZE )
		{
			var ix:int,iy:int;

			super(_id);
			this.vramWkId = 0;
			this.mapArray = null;	// setTexture後に設定される
			this.mapWNum = 0;
			this.mapHNum = 0;
			this.mapTop = new Point();
			this.mapTopOld = new Point();

			this.cellWNum = _cellWNum;
			this.cellHNum = _cellHNum;
			this.cellWidth =	_cW;
			this.cellHeight=	_cH;

			this.fieldCanvas = new Sprite();
			
//------------------------------------
// for debug
//------------------------------------
var tmpSpr:Sprite = new Sprite();
tmpSpr.graphics.clear();
tmpSpr.graphics.lineStyle(1,0x004400);
tmpSpr.graphics.drawRect(0,0,Global.SYS_WINDOW_W,Global.SYS_WINDOW_H);
this.fieldCanvas.addChild(tmpSpr);
//------------------------------------
			
		}

		//-----------------------------------------------------------------------------
		//! mapTextureをセット 
		//! vId:テクスチャID _mapArray:マップデータ
		//-----------------------------------------------------------------------------
		public function setMapTexture( srcBmpData:BitmapData, _vId:int, _mapArray:Array ):Boolean{
			var ix:int,iy:int;
			var bgCellW:BgCellWork;
			var tmpMat:Matrix = new Matrix();
			var texU:int
			var texV:int

			this.mapArray = _mapArray;	// setTexture後に設定される
			this.mapWNum =	_mapArray.length;
			this.mapHNum =	_mapArray[0].length;
			this.mapTop.x = 0;
			this.mapTop.y = 0;

			this.vramWkId = _vId;

//			var srcBmp:Bitmap = SysMain.gw.vramWk[ this.vramWkId ].getBmp();
//			var srcBmpData:BitmapData = srcBmp.bitmapData;

var cW:int = this.mapWNum;	// this.cellHNum;
var cH:int = this.mapHNum; // this.cellHNum;
			
			this.mapCellArray = new Array(cW);
			for (ix = 0; ix < cW; ++ix) {
				this.mapCellArray[ix] = new Array(cH);
				for(iy=0; iy<cH; ++iy){
					var cellW:int = Global.GRP_DEF_BGCELL_SIZE;
					var cellH:int = Global.GRP_DEF_BGCELL_SIZE;

					var tmpCellData:uint = _mapArray[ix][iy];
					texU = ((tmpCellData >> 8) & 0xff) * cellW;
					texV = ((tmpCellData >> 0) & 0xff) * cellH;
					var cellBmpData:BitmapData = new BitmapData(cellW, cellH,true,0);
					cellBmpData.copyPixels(srcBmpData, new Rectangle(texU, texV, cellW, cellH), new Point(0, 0),null,null,true);
					var cellBmp:Bitmap = new Bitmap(cellBmpData);
					var cellBmp2:Bitmap = null;
					if (tmpCellData & MDL_MASK_EXT_UV) {	// 重ね合わせあり
						texU = ((tmpCellData >> 24) & 0xff) * cellW;
						texV = ((tmpCellData >> 16) & 0xff) * cellH;
						var cellBmpData2:BitmapData = new BitmapData(cellW, cellH,true,0);
						cellBmpData2.copyPixels(srcBmpData, new Rectangle(texU, texV, cellW, cellH), new Point(0, 0),null,null,true);
						cellBmp2 = new Bitmap(cellBmpData2);
					}
					bgCellW = new BgCellWork(cellBmp,cellBmp2);
					this.mapCellArray[ix][iy] = bgCellW;

					bgCellW.spr.x = ix * cellW;
					bgCellW.spr.y = iy * cellH;
					bgCellW.spr.width = cellW*1.01;
					bgCellW.spr.height = cellH*1.01;
						
					this.fieldCanvas.addChild(bgCellW.spr);
				}
//				bgCellW.spr.width=this.cellWidth+0.25;
//				bgCellW.spr.height=this.cellHeight+0.25;
			}

			return(true);
		}

		
		//-----------------------------------------------------------------------------
		//! move
		//-----------------------------------------------------------------------------
		override public function preMove():void {
			this.mapTopOld.x = this.mapTop.x;
			this.mapTopOld.y = this.mapTop.y;
		}
		
// セルひとつづつ計算するのではなく、mapTopXYから一意に決まるようにする（小数点移動で隙間ができるのを防ぐ）
		override public function move():void{
			var ix:int,iy:int;
/*
//------------------今だけ仮--------
this.mapTop.x = Obj00Pl(SysMain.gw.player).plMapPos.x;
this.mapTop.y = Obj00Pl(SysMain.gw.player).plMapPos.y;
var mvSpeed:Point = new Point(this.mapTop.x-this.mapTopOld.x,this.mapTop.y-this.mapTopOld.y);
//------------------今だけ仮--------


			for(iy=0;iy<this.cellHNum;++iy){
				for(ix=0;ix<this.cellWNum;++ix){
					var isChanged:Boolean = false;
					var bgCellW:BgCellWork = this.mapCellArray[iy*this.cellWNum+ix];
					bgCellW.spr.x+=mvSpeed.x;
					if(bgCellW.spr.x > this.cellWidth*(this.cellWNum-1)){
						bgCellW.spr.x -= this.cellWidth*(this.cellWNum);
						bgCellW.mapX = (bgCellW.mapX-this.cellWNum+this.mapWNum*100)%this.mapWNum;
						isChanged = true;
					}else if(bgCellW.spr.x < -this.cellWidth){
						bgCellW.spr.x += this.cellWidth*(this.cellWNum);
						bgCellW.mapX = (bgCellW.mapX+this.cellWNum)%this.mapWNum;
						isChanged = true;
					}
					bgCellW.spr.y+=mvSpeed.y;
					if(bgCellW.spr.y > this.cellHeight*(this.cellHNum-1)){
						bgCellW.spr.y -= this.cellHeight*(this.cellHNum);
						bgCellW.mapY = (bgCellW.mapY-this.cellHNum+this.mapHNum*100)%this.mapHNum;
						isChanged = true;
					}else if(bgCellW.spr.y < -this.cellHeight){
						bgCellW.spr.y += this.cellHeight*(this.cellHNum);
						bgCellW.mapY = (bgCellW.mapY+this.cellHNum)%this.mapHNum;
						isChanged = true;
					}

					if(isChanged){	// 表示するCELLが変わった
						var texU:int;
						var texV:int;
						var texU2:int=0;
						var texV2:int=0;
						var tmpCellData:int;
						
						if(this.mapArray!=null){
							tmpCellData = this.mapArray[bgCellW.mapY][bgCellW.mapX];
							texU = ((tmpCellData>>8)&0xff)*Global.GRP_DEF_BGCELL_SIZE;
							texV = ((tmpCellData>>0)&0xff)*Global.GRP_DEF_BGCELL_SIZE;
							if((tmpCellData>>16)&0x00ffff){	// 重ね合わせありなら
								texU2 = ((tmpCellData>>24)&0xff)*Global.GRP_DEF_BGCELL_SIZE;
								texV2 = ((tmpCellData>>16)&0xff)*Global.GRP_DEF_BGCELL_SIZE;
							}
						}else{
							texU = bgCellW.mapX*Global.GRP_DEF_BGCELL_SIZE;
							texV = bgCellW.mapY*Global.GRP_DEF_BGCELL_SIZE;
						}
						var rect:Rectangle	= new Rectangle(texU,texV,this.cellWidth,this.cellHeight);
						var pt:Point		= new Point(0,0);
						var srcBmp:Bitmap = SysMain.gw.vramWk[ this.vramWkId ].getBmp();
						bgCellW.bmaData.copyPixels(srcBmp.bitmapData,rect,pt);

						if(texU2|texV2){	// 重ね合わせありなら
							var rect2:Rectangle	= new Rectangle(texU2,texV2,this.cellWidth,this.cellHeight);
							bgCellW.bmaData.copyPixels(srcBmp.bitmapData,rect2,pt,null,null,true);
						}
						
					}	//isChanged
				}
			}
*/
		}
		
		override public function postMove():void{
		}
	}
}