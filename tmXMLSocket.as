// ----------------------------------------------------------------------------------------
// tmXMLSocket         t.misawa 2010
// ----------------------------------------------------------------------------------------
// new tmXMLSocket(_userName[,_useBuff][,_heartbeatSec]); でソケット作成
// tmXMLSocket.connect(_host, _port); で接続
// バッファリングあり(_useBuff=true)なら　tmXMLSocket.flush();　を呼ぶ必要がある
// ----------------------------------------------------------------------------------------
// 送信:[data](<???>~</???>形式の任意のxmlデータ)
// 受信:<_tmd><_uid>[uid]</_uid><_udata>[data]</_udata></_tmd>'\0'
// 予約タグ:<_tmd><_uid><_ubody><_udata><_con/><_discon/><_text><_user><_ulist/><_stt/>
//        <policy-file-request/>
// 接続時：<_con/>をブロードキャスト、返ってきた<_user>からユーザーリストを作成
// 入れ子の枠(<aa b="c"><dd e="f">ggg</dd></aa>のaa)は解析されない。末端のタグ(dd)のみが解析対象
// ----------------------------------------------------------------------------------------
package tmlib
{
	import flash.events.*;
	import flash.net.XMLSocket;
	import flash.utils.Timer;
	import flash.utils.escapeMultiByte;
	import flash.utils.unescapeMultiByte;
	import flash.system.Security;

	public class tmXMLSocket extends XMLSocket
	{
		static private const DEF_TIMEOUT_DELAY:int = 3000;
		static private const DEF_HEARTBEAT_SEC:int = 30;
		
		private var gUserListArray:Array = new Array();	// uid:uniqueID, uname:userName, udata:userData
		private var cmdBuf:Array = new Array((new Array()), (new Array()));	// ダブルバッファ
		private var gCmdBufPage:int = 0;
		private var gCmdBuf:Array = cmdBuf[gCmdBufPage];
		private var gUseBuffer:Boolean = true;					// イベントハンドラ内で実行/cmdFlushで実行
		private var gUserName:String = null;
		private var gUserIdStr:String = null;
		private var gConnectHandlerFunc:Function = null;
		private var gSimpleXmlGetHandlerFunc:Function = null;
		private var gIoErrorHandlerFunc:Function = null;
		private var gConnectTimeoutHandlerFunc:Function = null;
		private	var gHeartbeatSendCount:int = 0;	// 無送信チェック用
		private	var gHeartbeatIntSec:int = DEF_HEARTBEAT_SEC;	// ハートビート間隔
		private var gHeartbeatTimer:Timer = null;
		private var gTimeOutTimer:Timer = null;
		private var debugStr:String = null;
		private var dispatcher:IEventDispatcher = null;

		// --------------------------------------------------------------------------------
		// _userName:自分の名前
		// _useBuffFlag:falseならハンドラ内で即時実行(trueならcmdFlush()時に実行)
		// _heartbeatSec:ハートビート（長時間のむ通信で切断されないよう定期的にダミー通信を行う）のセット(単位は秒)
		// --------------------------------------------------------------------------------
		public function tmXMLSocket(_userName:String,_useBuff:Boolean=true, _heartbeatSec:uint=DEF_HEARTBEAT_SEC){
//			super(_host, _port);
			super(null, 0);

			gUseBuffer = _useBuff;
			gUserName = _userName;
			gHeartbeatIntSec = _heartbeatSec;
			dispatcher = this;
			configureListeners();
		}

		// --------------------------------------------------------------------------------
		// 自分のユーザーIDを返す
		// --------------------------------------------------------------------------------
		public function getMyUid():String {	return this.gUserIdStr;	 }
		// --------------------------------------------------------------------------------
		// ユーザー名前を返す  自分または 引数に<uid>でリスト上から該当ユーザーを探す
		// 自分のIDは_sttの後でないと受け取ることは出来ない(nullが返る)
		// _userListArrayを指定すると外部のユーザーリストから検索可能(ログアウト時等、既にリストにいないユーザー検索用)
		// --------------------------------------------------------------------------------
		public function getUserName(_uidStr:String=null, _userListArray:Array=null):String {
			var retStr:String = null;
			if (_userListArray == null) {
				_userListArray = gUserListArray;
			}
			if((_uidStr==this.gUserIdStr)||(_uidStr==null)){
				retStr = this.gUserName;
			}else{
				for each (var dt:Object in _userListArray) {
					if (dt["uid"] == _uidStr) {	// 発見
						retStr = dt["uname"];
						break;
					}
				}
			}
			return(retStr);
		}
	
		// --------------------------------------------------------------------------------
		// ユーザーリストを返す
		// uid:uniqueID, uname:userName, udata:ユーザーが自由に扱えるデータ
		// --------------------------------------------------------------------------------
		public function getUserList():Array {	return(gUserListArray);	}

		// --------------------------------------------------------------------------------
		// データを送信
		//	_sendUidStr :
		//		"TM_SEND_TYPE_NOBODY";  // 送らない
		//		"TM_SEND_TYPE_MYSELF";  // 自分のみに送信
		//		"TM_SEND_TYPE_OTHERS";  // 自分以外に送信
		//		"TM_SEND_TYPE_ALL";     // 全員に送信(自分含む) 
 		// --------------------------------------------------------------------------------
		public function sendData(_sendStr:String, _sendUidStr:String=null):Boolean {
			var ret:Boolean = false;
			var tagStr:String;
			if(this.connected){
				try {
					var tmpXml:XML = new XML("<_tmp>"+_sendStr+"</_tmp>");
				}catch (err:Error) {	// XMLデータでなかったときは<text>タグを付けてエスケープ
					_sendStr = "<_text>" + escapeMultiByte(_sendStr)+"</_text>";   
				}
					
				// タグを追加 <_udata [toId="address"] >
				if (_sendUidStr == null) {
					tagStr = '<_udata>';
				}else{
					tagStr = '<_udata toId="' + _sendUidStr +'">';
				}
				_sendStr = tagStr + _sendStr + '</_udata>';
				this.send(_sendStr);	// 送る際に自動的に\0が追加される
				gHeartbeatSendCount++;	// 送信したら無送信時間ブレーク
	//			this.cmdFlush();
				ret = true;
			}
			return(ret); 
		}

		// --------------------------------------------------------------------------------
		// バッファにあるコマンドを全て処理
		// --------------------------------------------------------------------------------
		public function cmdFlush():int {
			var inData:*;
			var cnt:int = 0;
			var tmpCmdBuf:Array = gCmdBuf;
			gCmdBufPage = ((gCmdBufPage == 0)?1:0);	// ダブルバッファの切り替え
			gCmdBuf = cmdBuf[gCmdBufPage];
			
			tmpCmdBuf.reverse();	// fifo
			while (tmpCmdBuf.length) {
				inData = tmpCmdBuf.pop();
				dataHandlerFunc(inData);
				cnt++;
			}
			return(cnt);
		}

		// --------------------------------------------------------------------------------
		// バッファコマンドをPush(gUseBuffer==falseなら即時実行)
		// --------------------------------------------------------------------------------
		private function cmdPush(_data:*):int {
			gCmdBuf.push(_data);
			if (gUseBuffer==false) { // バッファリングしないなら即時実行
				cmdFlush();
			}
			return(gCmdBuf.length);
		}

		// --------------------------------------------------------------------------------
		// 受け取ったデータを処理
		// --------------------------------------------------------------------------------
		private function dataHandlerFunc(_data:*):void {
			var xml:XML;
			var dataStr:String = _data.toString();
			try {
				xml = new XML(dataStr);
				this.analyzeXml(xml);
			}catch (err:Error) {	// XMLデータでなかったときはスルー
			}
		}

		// --------------------------------------------------------------------------------
		// 受け取ったXMLを処理
		// --------------------------------------------------------------------------------
		private function analyzeXml(_xml:XML, _gUidStr:String=null, _recursionCnt:int=0):void {
			var xmlList:XMLList = new XMLList(_xml.children());
			var cmdStr:String;
			var dataStr:String;
			
			if(_recursionCnt==0)	debugStr="";
			_recursionCnt++;	// 再帰チェック用カウント
			
			for each(var xml:XML in xmlList) {
				cmdStr = xml.name();
				debugStr += "{";
				if(xml.hasComplexContent()){ //	!xml.hasSimpleContent()
					debugStr += cmdStr + "++:";
					// 入れ子の枠の属性(<aa b="c"><dd e="f">ggg</dd></aa>のaa.bにあたる部分)を反映させるにはここで処理する必要がある
					analyzeXml(xml,_gUidStr,_recursionCnt);
				}else {
					var dataTextStr:String = xml.toString();	// xml.text()[0];	// <xx/>の場合undefinedに
					var attrList:XMLList = xml.@*;	// すべての属性を返す
					switch(cmdStr) {
						default :
						case null     : break;
//						case "_end"   :	break;
						case "_stt"   : 
							this.gUserIdStr = _gUidStr;
							break;
						case "_con"   : addUser(_gUidStr, dataTextStr);
														this.sendData("<_user>"+gUserName+"</_user>" , _gUidStr );	break;	// ユーザー名を返す
						case "_discon": removeUser(_gUidStr);	break;
						case "_uid"   : if(_recursionCnt==1){ _gUidStr = dataTextStr; }	break; // 最初に出てきたもののみOKとする
						case "_ulist" : this.sendData("<_user>"+gUserName+"</_user>" , _gUidStr );	break;	// ユーザー名を返す
						case "_user"  : addUser(_gUidStr, dataTextStr);	break;
						case "_text"  : dataTextStr = unescapeMultiByte(dataTextStr);	break;	// textをアンエスケープ
					}
					if(gSimpleXmlGetHandlerFunc!=null){
						gSimpleXmlGetHandlerFunc(cmdStr, dataTextStr, attrList, _gUidStr);
					}
					debugStr += cmdStr + ":" + dataTextStr;
				}
				debugStr += "}";
			}
		}

		// --------------------------------------------------------------------------------
		// リストにユーザーを追加
		// --------------------------------------------------------------------------------
		private function addUser(_uidStr:String, _unameStr:String):void {
			for each (var dt:Object in gUserListArray) {
				if (dt["uid"] == _uidStr) return;	// 既に登録されていたら終了
			}
			gUserListArray.push( { uid:_uidStr, uname:_unameStr, udata:null } );
		}

		// --------------------------------------------------------------------------------
		// リストからユーザーを削除
		// --------------------------------------------------------------------------------
		private function removeUser(_uidStr:String):void {
			var cnt:int = 0;
			for each (var dt:Object in gUserListArray) {
				if (dt["uid"] == _uidStr) {	// 既に登録されていたら削除
					gUserListArray.splice(cnt, 1);
					return;
				}
				cnt++;
			}
		}

		// --------------------------------------------------------------------------------
		// 接続時に実行される関数をセット _func(event:Event)
		// --------------------------------------------------------------------------------
		public function setConnectHandlerFunc(_func:Function):void {
			gConnectHandlerFunc = _func;
		}

		// --------------------------------------------------------------------------------
		// XML解析時タグが来るたびに実行される関数をセット
		// _func(_cmdStr:String, _dataStr:String, _attrList:XMLList, _uidStr:String )
		// _cmdStr:コマンド  _dataStr:データ   <_cmdStr>_dataStr</_cmdStr>
		// _gUidStr データを送ってきた相手のuid
		// --------------------------------------------------------------------------------
		public function setXmlGetHandlerFunc(_func:Function):void {
			gSimpleXmlGetHandlerFunc = _func;
		}

		// --------------------------------------------------------------------------------
		// ネットワークエラー時に時に実行される関数をセット _func(event:IOErrorEvent)
		// --------------------------------------------------------------------------------
		public function setIoErrorHandlerFunc(_func:Function):void {
			gIoErrorHandlerFunc = _func;
		}
		
		// --------------------------------------------------------------------------------
		// 接続タイムアウト時に時に実行される関数をセット _func(event:TimerEvent)
		// --------------------------------------------------------------------------------
		public function setConnectTimeoutHandlerFunc(_func:Function):void {
			gConnectTimeoutHandlerFunc = _func;
		}

		// --------------------------------------------------------------------------------
		// イベントリスナー群
		// --------------------------------------------------------------------------------
		private function configureListeners():void {
			dispatcher.addEventListener(Event.CLOSE, closeHandler);
			dispatcher.addEventListener(Event.CONNECT, connectHandler);
			dispatcher.addEventListener(DataEvent.DATA, dataHandler);
			dispatcher.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			dispatcher.addEventListener(ProgressEvent.PROGRESS, progressHandler);
			dispatcher.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
//			dispatcher.addEventListener(TimerEvent.TIMER_COMPLETE, connectTimeoutHandler);
//			dispatcher.addEventListener(Event.ACTIVATE, activateHandler);
		}
		// --------------------------------------------------------------------------------
		private function closeHandler(event:Event):void {
//			trace("closeHandler: " + event);
		}
		// --------------------------------------------------------------------------------
		private function connectHandler(event:Event):void {
			gTimeOutTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, connectTimeoutHandler);
			this.sendData("<_con>" + gUserName + "</_con>","TM_SEND_TYPE_ALL");	// 接続通知(自分も含む)
			this.sendData("<_stt/>","TM_SEND_TYPE_MYSELF");	// 自分のuidが何かを特定するためにも必要
			
			// ハートビート（長時間のむ通信で切断されないよう定期的にダミー通信を行う）のセット(単位は秒)
			if(gHeartbeatIntSec != 0){
				gHeartbeatTimer	= new Timer(gHeartbeatIntSec*1000);
				gHeartbeatTimer.addEventListener(TimerEvent.TIMER, onHeartbeatTimer);
				gHeartbeatSendCount=0;
				gHeartbeatTimer.start();
			}

			if (gConnectHandlerFunc != null)	gConnectHandlerFunc(event);
//			trace("connectHandler: " + event);
		}
		// --------------------------------------------------------------------------------
		private function connectTimeoutHandler(event:TimerEvent):void {
			gTimeOutTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, connectTimeoutHandler);
			if (gConnectTimeoutHandlerFunc != null)	gConnectTimeoutHandlerFunc(event);
			trace("connectTimeoutHandler: " + event);
		}
		// --------------------------------------------------------------------------------
		private function dataHandler(event:DataEvent):void {
			gHeartbeatSendCount++;	// 受信したら無送信時間ブレーク
			cmdPush(event.data);
//			trace("dataHandler: " + event);
		}
		// --------------------------------------------------------------------------------
		private function ioErrorHandler(event:IOErrorEvent):void {
			if (gIoErrorHandlerFunc != null)	gIoErrorHandlerFunc(event);
//			trace("ioErrorHandler: " + event);
		}
		// --------------------------------------------------------------------------------
		private function progressHandler(event:ProgressEvent):void {
//			trace("progressHandler loaded:" + event);
		}
		// --------------------------------------------------------------------------------
		private function securityErrorHandler(event:SecurityErrorEvent):void {
//			trace("securityErrorHandler: " + event);
		}
		// --------------------------------------------------------------------------------
		private function activateHandler(event:Event):void {
//			trace("activateHandler: " + event);
		}
		// --------------------------------------------------------------------------------
		private function onHeartbeatTimer(event:TimerEvent):void {
			gHeartbeatTimer.stop();
			if(gHeartbeatSendCount==0){	// ハートビート期間中に一度も送受信していなかったら送信 
				if(this.connected){
					this.sendData("<_user>"+gUserName+"</_user>","TM_SEND_TYPE_NOBODY");
				}
			}
			gHeartbeatSendCount=0;
			gHeartbeatTimer.start();
		}
		
		// --------------------------------------------------------------------------------
		// 接続:トラップできるようオーバーライドしておきます
		// --------------------------------------------------------------------------------
		public override function connect(_host:String, _port:int):void {
			// ネットに接続するための設定
			Security.allowDomain("xmlsocket://"+_host+":"+_port); // ローカルにつないでも良い
			Security.loadPolicyFile("xmlsocket://"+_host+":"+_port);

			super.connect(_host, _port);

			// 接続タイムアウトの設定
			gTimeOutTimer = new Timer(DEF_TIMEOUT_DELAY, 1);
			gTimeOutTimer.addEventListener(TimerEvent.TIMER_COMPLETE, connectTimeoutHandler);
			gTimeOutTimer.start();
		}
	}
}
// ----------------------------------------------------------------------------------------
// ----------------------------------------------------------------------------------------
