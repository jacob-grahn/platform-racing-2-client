// Main

package 
{
    import blocks.Blocks;
    import dialogs.MessagePopup;
    import com.jiggmin.data.Time;
    import com.jiggmin.data.PR2Socket;
    import com.jiggmin.data.CommandHandler;
    import com.jiggmin.data.GpNotification;
    import com.jiggmin.data.SavedAccounts;
    import com.jiggmin.data.SWFStats;
    import flash.display.Loader;
    import flash.display.LoaderInfo;
    import flash.display.Sprite;
    import flash.display.Stage;
    import flash.events.Event;
    import flash.events.UncaughtErrorEvent;
    import flash.external.ExternalInterface;
    import flash.net.URLRequest;
    import flash.net.URLVariables;
    import flash.system.Capabilities;
    import flash.system.Security;
    import flash.ui.ContextMenu;
    import flash.utils.setTimeout;
    import menu.CheckServers;
    import menu.CommAuth;
    import menu.IntroPage;
    import sounds.NoodleTown;
    import page.PageHolder;
    import ui.MuteButton;
    import ui.CustomCursor;

    public class Main extends Sprite
    {

        private static var initialized:Boolean = false;
        private var _debugDot:flash.display.Shape;
        public static var debugLog:String = "";
        public static function log(s:String):void { debugLog += s + "\n"; }
        private static const clientWidth:int = 550;
        public static const clientHeight:int = 400;
        public static const accountChange:String = "accountChange";
        public static const beta:Boolean = false; // DISABLE IN PRODUCTION
        public static const testing:Boolean = false; // DISABLE IN PRODUCTION
        public static const build:String = '29-oct-2023-v168_2_1';
        public static const version:String = '168.2.1';
        public static const baseURL:String = "https://pr2hub.com"; // "https://pr2hub.dev";
        public static const levelsURL:String = "https://pr2hub.com/levels"; //"https://pr2hub.dev/levels";
        public static var stage:Stage;
        public static var instance:Main;
        public static var token:String = "";
        public static var loggedInAs:String = "";
        public static var userName:String = "";
        public static var userPass:String = "";
        public static var remember:Boolean = false;
        public static var group:int = 0;
        public static var isSpecialUser:Boolean = false;
        public static var isTempMod:Boolean = false;
        public static var isTrialMod:Boolean = false;
        public static var isPrizer:Boolean = false;
        public static var hasEmail:Boolean = false;
        public static var awardKongNextLogin:Boolean = false;
        public static var userId:int = 0;
        public static var guild:int = 0;
        public static var guildOwner:int = 0;
        public static var guildName:String = "";
        public static var emblem:String = "";
        public static var favoriteLevels:Array = new Array();
        public static var lastAuthTime:Time = new Time();
        public static var server:Object;
        public static var commandHandler:CommandHandler = new CommandHandler();
        public static var socket:PR2Socket;
        public static var noodleTown:NoodleTown = new NoodleTown();
        public static var pageHolder:PageHolder;
        public static var muteButton:MuteButton = new MuteButton();
        public static var filledSlotCourseID:int;
        public static var filledSlotCourseVersion:int;
        public static var stats:SWFStats;
        public static var bitmapArray:Array = new Array();
        public static var bitmapTileCount:int = 0;
        public static var blockArray:Array = new Array();
        public static var siteMode:String = "kongregate";
        public static var domain:String;
        private static var url:String;
        private static var protocol:String;

        public var kongAPI:*;
        public var betaLoader:Boolean;

        public function Main()
        {
            hideContextMenu();
            if (stage) {
                this.init();
            } else {
                addEventListener(Event.ADDED_TO_STAGE, this.init);
            }
        }

        private function init(e:Event = null)
        {
            removeEventListener(Event.ADDED_TO_STAGE, this.init);
            loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, this.onUncaughtError);
            Main.betaLoader = LoaderInfo(root.loaderInfo).parameters.hasOwnProperty('betaLoader') ? Boolean(int(LoaderInfo(root.loaderInfo).parameters.betaLoader)) : false;
            if (Main.testing || (
                    parent != stage
                    && !Main.initialized
                    && ( // browser
                        (Capabilities.playerType == "ActiveX" || Capabilities.playerType == "PlugIn") && Security.sandboxType == Security.REMOTE
                    ) || ( // local
                        Capabilities.playerType == 'StandAlone' && Security.sandboxType == Security.LOCAL_TRUSTED
                    )
                ) && (
                    ( // beta loader (debugger) used to access beta client
                        Main.betaLoader && Main.beta
                    ) || ( // regular loader (no debugger) used to access regular client
                        !Main.betaLoader && !Main.beta
                    )
                )
            ) {
                Main.initialized = true;
                Main.stage = stage;
                Main.instance = this;
                Blocks.init();
                Parts.makeParts();
                Keys.initialize(stage);
                CustomCursor.stageRef = stage;
                CheckServers.activate();
                SavedAccounts.init();
                GpNotification.init(stage);
                CommAuth.init();
                stats = new SWFStats();
                this.determineSite();
                stage.frameRate = 27;
                Security.loadPolicyFile(baseURL + "/crossdomain.xml");
                Security.allowDomain("kongregate.com");
                muteButton.x = 504;
                muteButton.y = 380;
                muteButton.doToggle(Main.testing); // mutes by default if testing mode is enabled
                pageHolder = new PageHolder(new IntroPage());
                addChild(pageHolder);
                addChild(new Doughnut());
                addChild(muteButton);
                _debugDot = new flash.display.Shape();
                _debugDot.graphics.beginFill(0x00FF00);
                _debugDot.graphics.drawCircle(0, 0, 6);
                _debugDot.x = 590; _debugDot.y = 10;
                addChild(_debugDot);
            }
        }

        private function onUncaughtError(e:UncaughtErrorEvent):void
        {
            var msg:String = "(unknown error)";
            try {
                e.preventDefault();
                var err:Error = e.error as Error;
                if (err) {
                    msg = err.name + " #" + err.errorID + ": " + err.message;
                    var st:String = err.getStackTrace();
                    if (st) msg += "\n" + st;
                } else if (e.error != null) {
                    msg = String(e.error);
                }
            } catch (ex:Error) {
                msg = "handler threw: " + ex.message;
            }
            if (debugLog.length > 0) msg += "\n\nDebug log:\n" + debugLog;
            msg = msg.split("&").join("&amp;").split("<").join("&lt;").split(">").join("&gt;");
            new MessagePopup(msg);
        }

        private function hideContextMenu()
        {
            var my_menu:ContextMenu = new ContextMenu();
            my_menu.hideBuiltInItems();
            contextMenu = my_menu;
        }

        private function determineSite()
        {
            var site:String = "local";
            url = stage.loaderInfo.url;
            protocol = url.substr(0, url.indexOf(":"));
            if (protocol == "http" || protocol == "https") {
                var afterProtocol:Number = url.indexOf("//");
                site = url.substr(afterProtocol + 2, url.indexOf("/", afterProtocol + 2) - afterProtocol - 2);
                site = site.toLowerCase();
                if (site.indexOf("www.") != -1) {
                    site = site.substr(site.indexOf("www.") + 4, site.length);
                }
            }
            Main.domain = site;
            if (Main.domain.indexOf("bubblebox.com") != -1 || Main.domain.indexOf("2games.com") != -1) {
                Main.siteMode = "bubbleBox";
            } else if (Main.domain.indexOf("armorgames.com") != -1) {
				Main.siteMode = "armorGames";
			} else if (Main.domain.indexOf("sparkworkz.com") != -1 || Main.domain.indexOf("inxile-entertainment.com") != -1) {
				Main.siteMode = "inXile";
            } else {
                Main.siteMode = "kongregate";
			}
        }

        // CURRENTLY UNUSED
        private function getKongApiOnTesting()
        {
            if (Main.siteMode == "kongregate" && Main.domain == "local" && Main.kongAPI == null && stage == parent) {
                var params:Object = LoaderInfo(root.loaderInfo).parameters;
                var kongPath:String = params.kongregate_api_path || "http://www.kongregate.com/flash/API_AS3_Local.swf";
                Security.allowDomain(kongPath);
                var request:URLRequest = new URLRequest(kongPath);
                var loader:Loader = new Loader();
                loader.contentLoaderInfo.addEventListener(Event.COMPLETE, this.receiveKongAPI);
                loader.load(request);
                this.addChild(loader);
            }
        }

        public static function clearUserData()
        {
            Main.loggedInAs = "";
            Main.group = 0;
            Main.userId = 0;
            Main.hasEmail = false;
            Main.hasAnt = false;
            Main.token = "";
            Main.remember = false;
            Main.guild = 0;
            Main.guildOwner = 0;
            Main.guildName = "";
            Main.emblem = "";
        }

        // CURRENTLY UNUSED
        private function receiveKongAPI(e:Event)
        {
            var recv:* = e.target.content;
            Main.instance.kongAPI = recv;
            Main.instance.kongAPI.services.connect();
            Security.allowDomain(Main.instance.kongAPI.loaderInfo.url);
        }

        public static function traceExt(s:*)
        {
            trace(s);
            if (ExternalInterface.available == true && beta == true) {
                ExternalInterface.call('console.log', 'Flash traceExt: ' + s);
            }
        }


    }
}
