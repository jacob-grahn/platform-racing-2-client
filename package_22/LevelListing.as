// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//package_22.LevelListing = package_22.class_247

package package_22
{
    import com.adobe.crypto.MD5;
    import data.class_33;
    import data.Memory;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.net.URLVariables;
    import flash.net.URLRequest;
    import flash.utils.clearTimeout;
    import flash.utils.setTimeout;
    import page.Page;
    import ui.PageNavigation;
    import data.CommandHandler;
    import flash.utils.ByteArray;

    public class LevelListing extends Page
    {

        public static var levelListing:LevelListing; // var_667

        public var class_10:Sprite = new Sprite();
        protected var loadingGraphic:LoadingGraphic = new LoadingGraphic();
        protected var pageNavigation:PageNavigation;
        protected var var_280:uint;
        private var levelArray:Array = new Array(); // var_303
        public var levels:Object = new Object(); // var_393
        protected var pageNum:int = 1; // var_195
        protected var mode:String = "best";
        protected var superLoader:SuperLoader;
        private var cm:CommandHandler = CommandHandler.commandHandler;

        public function LevelListing()
        {
            this.pageNavigation = new PageNavigation(this, "vertical", 1, 9, 283);
            this.superLoader = new SuperLoader(true, SuperLoader.j);
            super();
            addChild(this.class_10);
            this.loadingGraphic.x = 164;
            this.loadingGraphic.y = 150;
            addChild(this.loadingGraphic);
            this.pageNavigation.x = 328;
            this.pageNavigation.y = 26;
            addChild(this.pageNavigation);
            this.superLoader.addEventListener(Event.COMPLETE, this.loadHandler);
            this.superLoader.addEventListener(SuperLoader.e, this.errorHandler);
            Main.socket.write("set_right_room`none");
            LevelListing.levelListing = this;
            this.cm.defineCommand('addPageHighlight', this.addPageHighlight);
            this.cm.defineCommand('removePageHighlight', this.removePageHighlight);
        }

        // _loc1 = existingPageNum
        override public function initialize()
        {
            var existingPageNum:int = Memory.memory["coursePageNum" + this.mode];
            if (existingPageNum != 0) {
                this.pageNavigation.setPageNum(existingPageNum);
            }
        }

        // _loc2 = levelInRow
        // _loc3 = levelOnPage
        // _loc5 = spriteHeight
        // _loc8 = levelItem
        // _loc9 = i
        // deleted _loc4,6,7 - hardcoded unchanging integers at levelItem.x/y modifiers
        protected function showCourses(levels:Array)
        {
            if (class_33.getNumber("userRank") < 0) {
                this.var_280 = setTimeout(this.showCourses, 250, levels);
            } else {
                if (this.pageNavigation.parent == this.class_10) {
                    this.class_10.removeChild(this.pageNavigation);
                }
                var levelInRow:int = 0;
                var levelOnPage:int = 0;
                var spriteHeight:Number = this.class_10.height;
                if (spriteHeight != 0) {
                    spriteHeight = spriteHeight + 20;
                }
                for (var i:int = 0; i < levels.length; i++) {
                    var level:Object = levels[i];
                    if ((spriteHeight + (levelOnPage * 112)) > 224) {
                        break; // prevent "phantom" rows below the intended final row of levels on a page
                    }
                    var levelItem:LevelItem = new LevelItem(level.level_id, level.version, level.title, level.rating, level.play_count, level.min_level, level.note, level.user_name, level.user_group, level.pass, level.type, level.time);
                    levelItem.x = 2 + (levelInRow * 109);
                    levelItem.y = spriteHeight + (levelOnPage * 112);
                    this.levelArray.push(levelItem);
                    this.levels["c" + levelItem.courseID] = levelItem;
                    this.class_10.addChild(levelItem);
                    levelInRow++;
                    if (levelInRow >= 3) {
                        levelOnPage++;
                        levelInRow = 0;
                    }
                }
                Main.socket.write("set_right_room`" + this.mode);
                this.loadingGraphic.visible = false;
            }
        }

        // _loc2 = ret
        // _loc3 = dataNoHash
        // _loc4 = gameHash
        // _loc5 = vars
        protected function loadHandler(e:Event)
        {
            var ret:String = e.target.data;
            if (ret != "") {
                var obj:Object = JSON.parse(ret);
                if (obj.hash != null) {
                    var levelsStr:String = ret.substr(10, ret.length - 53); // janky way to preserve utf-8 char codes from php for hash validation
                    var gameHash:String = MD5.hash(levelsStr + Env.LEVEL_LIST_SALT);
                    if (obj.hash == gameHash) {
                        this.showCourses(obj.levels);
                    }
                }
            }
            this.loadingGraphic.visible = false;
        }

        protected function errorHandler(e:Event)
        {
            this.loadingGraphic.visible = false;
        }

        protected function requestCourses()
        {
            this.superLoader.load(new URLRequest(Main.levelsURL.substr(0, -7) + "/files/lists/" + this.mode + "/" + this.pageNum));
            this.loadingGraphic.visible = true;
        }

        public function getPageNum()
        {
            return this.pageNum;
        }

        public function setPageNum(n:int)
        {
            this.pageNum = n;
            Memory.memory["coursePageNum" + this.mode] = this.pageNum;
            this.removeLevels();
            this.requestCourses();
        }

        public function addPageHighlight(a:Array)
        {
            if (this.mode !== 'search') {
                this.pageNavigation.addPageHighlight(a[0]);
            }
        }

        public function removePageHighlight(a:Array)
        {
            if (this.mode !== 'search') {
                this.pageNavigation.removePageHighlight(a[0]);
            }
        }

        public function refreshHighlights()
        {
            Main.socket.write('refresh_highlights`');
        }

        // _loc1 = levelItem
        // _loc2 = i
        // method_260 = removeLevels
        protected function removeLevels()
        {
            var levelItem:LevelItem;
            var i:int = 0;
            while (i < this.levelArray.length) {
                levelItem = this.levelArray[i];
                levelItem.remove();
                i++;
            }
            this.levelArray = new Array();
            this.levels = new Object();
        }

        override public function remove()
        {
            this.superLoader.removeEventListener(Event.COMPLETE, this.loadHandler);
            this.superLoader.remove();
            this.pageNavigation.remove();
            this.removeLevels();
            this.loadingGraphic = null;
            clearTimeout(this.var_280);
            super.remove();
        }


    }
}
