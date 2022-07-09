// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//levelEditor.LevelEditor

package levelEditor
{
    import background.class_10;
    import background.Background;
    import background.ObjectBackground;
    import background.BlockBackground;
    import background.DrawableBackground;
    import background.LineBackground;
    import com.jiggmin.data.Data;
    import flash.display.Sprite;
    import flash.display.StageQuality;
    import flash.events.Event;
    import flash.geom.Point;
    import flash.net.URLVariables;
    import page.GamePage;

    public class LevelEditor extends GamePage 
    {

        public static var segSize:Number = 30;
        public static var editor:LevelEditor;

        private var drawingPop:DrawingPopup; // var_221
        public var var_364:Sprite;
        public var menu:LevelEditorMenu;
        public var var_225:Background;
        public var cur:ObjectBackground; // currently selected layer
        public var var_220:DrawableBackground;
        public var bg1:ObjectBackground;
        public var bg2:ObjectBackground;
        public var bg3:ObjectBackground;
        public var bg4:ObjectBackground;
        public var bg5:ObjectBackground;
        public var draw1:DrawableBackground;
        public var draw2:DrawableBackground;
        public var draw3:DrawableBackground;
        public var draw4:DrawableBackground;
        public var draw5:DrawableBackground;
        public var bg:class_10;
        public var blockBG:BlockBackground;
        public var blockGrid:LineBackground; // var_171
        public var live:Number = 0;
        public var minRank:String = "0"; // minLevel
        public var pass:String = null;
        public var hasPass:int = 0;
        public var toNewest:Boolean = true;
        private var variables:URLVariables;
        private var isMod:Boolean = false;
        private var reportsMode:Boolean = false;

        public function LevelEditor(vars:URLVariables, mod:Boolean = false, report:Boolean = false)
        {
            this.variables = vars;
            this.isMod = mod;
            this.reportsMode = report;
        }

        override public function initialize()
        {
            super.initialize();
            LevelEditor.editor = this;
            Main.stage.quality = StageQuality.HIGH;
            this.var_364 = new Sprite();
            this.var_364.mouseEnabled = false;
            this.var_364.mouseChildren = false;
            this.menu = new LevelEditorMenu();
            this.menu.init();
            this.attachBackgrounds();
            addChild(this.menu);
            this.menu.setReportsMode(this.reportsMode);
            addChild(this.var_364);
            if (this.variables != null) {
                this.setVariables(this.variables);
                this.variables = null;
            }
            addEventListener(Event.ENTER_FRAME, this.keyScroll);
        }

        override protected function keyScroll(e:Event)
        {
            super.keyScroll(e);
            var _local_2:Number = 275 * (1 / scaleX);
            var _local_3:Number = 200 * (1 / scaleY);
            posX = Data.numLimit(posX, -var_239 + _local_2, -_local_2);
            posY = Data.numLimit(posY, -var_362 + _local_3, -_local_3);
            this.setPos(posX, posY);
        }

        override protected function attachBackgrounds()
        {
            this.bg1 = new ObjectBackground(this);
            this.bg2 = new ObjectBackground(this);
            this.bg3 = new ObjectBackground(this);
            this.bg4 = new ObjectBackground(this);
            this.bg5 = new ObjectBackground(this);
            this.draw1 = new DrawableBackground(this);
            this.draw2 = new DrawableBackground(this);
            this.draw3 = new DrawableBackground(this);
            this.draw4 = new DrawableBackground(this);
            this.draw5 = new DrawableBackground(this);
            this.bg = new class_10(this);
            this.blockGrid = new LineBackground(this);
            this.blockBG = new BlockBackground(this);
            this.bg1.setScale(1);
            this.draw1.setScale(1);
            this.bg2.setScale(0.5);
            this.draw2.setScale(0.5);
            this.bg3.setScale(0.25);
            this.draw3.setScale(0.25);
            this.bg4.setScale(1);
            this.draw4.setScale(1);
            this.bg5.setScale(2);
            this.draw5.setScale(2);
            var_14.addChild(this.bg);
            var_14.addChild(this.draw3);
            var_14.addChild(this.bg3);
            var_14.addChild(this.draw2);
            var_14.addChild(this.bg2);
            var_14.addChild(this.draw1);
            var_14.addChild(this.bg1);
            var_14.addChild(this.blockGrid);
            var_14.addChild(this.blockBG);
            var_14.addChild(this.bg4);
            var_14.addChild(this.draw4);
            var_14.addChild(this.bg5);
            var_14.addChild(this.draw5);
            this.cur = this.blockBG;
            this.var_220 = this.draw1;
            this.var_225 = this.cur;
            this.blockGrid.mouseEnabled = false;
            this.blockGrid.mouseChildren = false;
            this.setStartPos();
            this.setZoom(zoom);
            this.setColor(12303325);
            this.focusOn(this.blockBG);
            this.menu.reset();
        }

        override protected function removeBackgrounds()
        {
            this.bg1.remove();
            this.bg2.remove();
            this.bg3.remove();
            this.bg4.remove();
            this.bg5.remove();
            this.draw1.remove();
            this.draw2.remove();
            this.draw3.remove();
            this.draw4.remove();
            this.draw5.remove();
            this.bg.remove();
            this.blockBG.remove();
            this.blockGrid.remove();
            this.bg1 = null;
            this.bg2 = null;
            this.bg3 = null;
            this.bg4 = null;
            this.bg5 = null;
            this.draw1 = null;
            this.draw2 = null;
            this.draw3 = null;
            this.draw4 = null;
            this.draw5 = null;
        }

        override public function setPos(x:Number, y:Number)
        {
            this.blockBG.setPos(x, y);
            this.bg1.setPos(x, y);
            this.bg2.setPos(x, y);
            this.bg3.setPos(x, y);
            this.bg4.setPos(x, y);
            this.bg5.setPos(x, y);
            this.draw1.setPos(x, y);
            this.draw2.setPos(x, y);
            this.draw3.setPos(x, y);
            this.draw4.setPos(x, y);
            this.draw5.setPos(x, y);
            this.blockGrid.setPos(x, y);
        }

        override public function setColor(val:Number = 0)
        {
            this.bg1.setColor(val);
            this.bg2.setColor(val);
            this.bg3.setColor(val);
            this.bg4.setColor(val);
            this.bg5.setColor(val);
            this.draw1.setColor(val);
            this.draw2.setColor(val);
            this.draw3.setColor(val);
            this.draw4.setColor(val);
            this.draw5.setColor(val);
            this.bg.setColor(val);
            super.setColor(val);
        }

        // _loc2 = arr
        override public function setSaveString(s:String)
        {
            var arr:Array = s.split("`");
            this.setColor(Number(arr[0]));
            this.menu.bg.cp_btn.updateColor();
            this.blockBG.setSaveString(arr[1]);
            this.bg1.setSaveString(arr[2]);
            this.bg2.setSaveString(arr[3]);
            this.bg3.setSaveString(arr[4]);
            this.bg4.setSaveString(arr[9]);
            this.bg5.setSaveString(arr[10]);
            this.draw1.setSaveString(arr[5]);
            this.draw2.setSaveString(arr[6]);
            this.draw3.setSaveString(arr[7]);
            this.draw4.setSaveString(arr[11]);
            this.draw5.setSaveString(arr[12]);
            this.bg.setSaveString(arr[8]);
            this.focusOn(this.var_225);
            this.setStartPos();
        }

        override public function startDrawing(_arg_1:Background)
        {
            super.startDrawing(_arg_1);
            if (this.drawingPop == null) {
                this.drawingPop = new DrawingPopup();
            }
        }

        override public function finishDrawing(_arg_1:Background)
        {
            super.finishDrawing(_arg_1);
            if (var_133.length <= 0 && this.drawingPop != null) {
                this.drawingPop.startFadeOut();
                this.drawingPop = null;
            }
        }

        // _loc1 = a
        public function getSaveString():String
        {
            var a:Array = new Array("m4", color.toString(16), this.blockBG.getSaveString(), this.bg1.getSaveString(), this.bg2.getSaveString(), this.bg3.getSaveString(), this.draw1.getSaveString(), this.draw2.getSaveString(), this.draw3.getSaveString(), this.bg.getSaveString(), this.bg4.getSaveString(), this.bg5.getSaveString(), this.draw4.getSaveString(), this.draw5.getSaveString());
            return a.join("`");
        }

        // _loc1 = point
        private function setStartPos()
        {
            var point:Point = this.blockBG.getStartPos();
            posX = -point.x - 100;
            posY = -point.y - 50;
        }

        public function focusOn(_arg_1:Background)
        {
            this.blockBG.method_22();
            this.bg1.method_22();
            this.bg2.method_22();
            this.bg3.method_22();
            this.bg4.method_22();
            this.bg5.method_22();
            this.draw1.method_22();
            this.draw2.method_22();
            this.draw3.method_22();
            this.draw4.method_22();
            this.draw5.method_22();
            _arg_1.focusOn();
            this.var_225 = _arg_1;
            this.menu.changeUndoRedoState();
            this.blockGrid.visible = _arg_1 == this.blockBG;
            if (_arg_1 == this.bg1 || _arg_1 == this.draw1) {
                this.bg1.alpha = this.draw1.alpha = 1;
            }
            if (_arg_1 == this.bg2 || _arg_1 == this.draw2) {
                this.bg2.alpha = this.draw2.alpha = 1;
            }
            if (_arg_1 == this.bg3 || _arg_1 == this.draw3) {
                this.bg3.alpha = this.draw3.alpha = 1;
            }
            if (_arg_1 == this.bg4 || _arg_1 == this.draw4) {
                this.bg4.alpha = this.draw4.alpha = 1;
            }
            if (_arg_1 == this.bg5 || _arg_1 == this.draw5) {
                this.bg5.alpha = this.draw5.alpha = 1;
            }
        }

        public function focusNone()
        {
            this.blockBG.focusNone();
            this.bg1.focusNone();
            this.bg2.focusNone();
            this.bg3.focusNone();
            this.bg4.focusNone();
            this.bg5.focusNone();
            this.draw1.focusNone();
            this.draw2.focusNone();
            this.draw3.focusNone();
            this.draw4.focusNone();
            this.draw5.focusNone();
        }

        override public function setSong(s:String)
        {
            super.setSong(s);
            this.menu.settings.musicButton.setSong(s);
        }

        override public function setGravity(g:String)
        {
            if (g == null || g == "") {
                g = "1";
            }
            super.setGravity(g);
            this.menu.settings.gravityButton.setValue(this.gravity);
        }

        override public function setMaxTime(t:String)
        {
            if (t == null || t == "") {
                t = "120";
            }
            super.setMaxTime(t);
            this.menu.settings.timeButton.setValue(this.maxTime);
        }

        // method_142 = setMinRank
        public function setMinRank(r:String)
        {
            r = r == null || r == '' ? '0' : r;
            this.minRank = r;
            this.menu.settings.minRankButton.setValue(r);
        }

        override public function setCowboyChance(sfcm:String)
        {
            sfcm = sfcm == null || sfcm == '' ? '5' : sfcm;
            super.setCowboyChance(sfcm);
            this.menu.settings.sfcmButton.setValue(this.cowboyChance);
        }

        // method_121 = setPass
        public function setPass(p:String)
        {
            p = p == null ? '' : p;
            this.hasPass = int(p != "");
            this.pass = p;
            this.menu.settings.passButton.setValue(p);
        }

        override public function setGameMode(gMode:String)
        {
            gMode = gMode === 'eggs' ? 'egg' : gMode;
            this.menu.settings.modeButton.setValue(gMode);
            super.setGameMode(gMode);
        }

        override public function setVariables(vars:URLVariables)
        {
            this.live = vars.live;
            this.setMinRank(vars.min_level);
            this.setPass(int(vars.has_pass) == 1 ? '******' : '');
            super.setVariables(vars);
            this.menu.reset();
        }

        public function method_344():URLVariables
        {
            var vars:URLVariables = new URLVariables();
            vars.title = title;
            vars.note = note;
            vars.data = this.getSaveString();
            vars.credits = getCredits();
            vars.live = this.live;
            vars.min_level = this.minRank;
            vars.song = song;
            vars.gravity = gravity;
            vars.max_time = maxTime;
            vars.items = allowedItems.join("`");
            vars.badHats = badHats.join(',');
            vars.hasPass = this.hasPass;
            vars.gameMode = gameMode === 'eggs' ? 'egg' : gameMode;
            vars.cowboyChance = cowboyChance;
            vars.passHash = this.pass != null && this.pass.replace(/\*/g, "").length > 0 ? Data.hash(this.pass + Env.LEVEL_PASS_SALT) : '';
            return vars;
        }

        override public function setZoom(z:Number)
        {
            super.setZoom(z);
            this.blockGrid.setZoom(z);
        }

        override protected function finishGlide()
        {
            Main.stage.quality = StageQuality.HIGH;
            super.finishGlide();
        }

        override protected function glideToScale(e:Event)
        {
            super.glideToScale(e);
            this.menu.scaleX = this.menu.scaleY = this.bg.scaleX = this.bg.scaleY = (1 / scale);
        }

        public function canViewLevelReports() : Boolean
        {
            return this.isMod;
        }

        public function inReportsMode() : Boolean
        {
            return this.reportsMode;
        }

        public function setReportsMode(on:Boolean = false)
        {
            this.reportsMode = on;
        }

        public function clear()
        {
            this.removeBackgrounds();
            this.attachBackgrounds();
            this.setMinRank("0");
            this.setPass("");
            this.setSong("");
            this.setGravity("1");
            this.setMaxTime("120");
            setItems("all");
            setBadHats('');
            this.setGameMode("race");
            this.setCowboyChance("5");
            title = "";
            note = "";
            this.live = 0;
            this.hasPass = 0;
            this.bg.scaleX = this.bg.scaleY = (1 / scale);
        }

        override public function remove()
        {
            removeEventListener(Event.ENTER_FRAME, this.keyScroll);
            if (this.drawingPop != null) {
                this.drawingPop.remove();
            }
            this.menu.remove();
            super.remove();
            LevelEditor.editor = null;
        }


    }
}//package levelEditor

