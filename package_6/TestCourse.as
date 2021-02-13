// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_6.TestCourse = package_6.class_171

package package_6
{
    import com.jiggmin.data.Settings;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.geom.Point;
    import flash.net.URLVariables;
    import levelEditor.HatPicker;
    import levelEditor.LevelEditor;
    import package_8.LocalCharacter;
    import package_9.TeleportPop;
    import sounds.SoundEffects;
    import ui.StatsSelect;

    public class TestCourse extends Course 
    {

        private var m:TestCourseGraphic = new TestCourseGraphic();
        private var variables:URLVariables;
        private var isMod:Boolean = false;
        private var reportsMode:Boolean = false;
        private var statsSelect:StatsSelect; // var_158
        private var hatPicker:HatPicker; // var_130

        public function TestCourse(v:URLVariables, mod:Boolean = false, report:Boolean = false)
        {
            this.variables = v;
            this.isMod = mod;
            this.reportsMode = report;
        }

        override public function initialize()
        {
            super.initialize();
            setVariables(this.variables);
            this.m.back_bt.addEventListener(MouseEvent.CLICK, this.clickBack);
            this.m.restart_bt.addEventListener(MouseEvent.CLICK, this.clickRestart);
            holder.addChild(this.m);
            musicSelection.x = -130;
            var_9 = new LocalCharacter(0, this, blockBackground, miniMap.getDot(), itemDisplay, this.variables.gravity);
            var_9.setColors(0xFFFFFF, -1, 0xFFFFFF, -1, 0xFFFFFF, -1, 0xFFFFFF, -1);
            var_9.testMode = true;
            playerArray.push(var_9);
            var savedStats:Object = Settings.getValue(Settings.LE_TEST_STATS, Settings.DEFAULT_LE_TEST_STATS);
            this.statsSelect = new StatsSelect(300, savedStats.speed, savedStats.accel, savedStats.jump, var_9);
            this.statsSelect.x = -265;
            this.statsSelect.y = 90;
            this.statsSelect.scaleX = this.statsSelect.scaleY = 0.66;
            holder.addChild(this.statsSelect);
            this.hatPicker = new HatPicker(var_9);
            this.hatPicker.x = -260;
            this.hatPicker.y = 65;
            this.hatPicker.scaleX = this.hatPicker.scaleY = 0.7;
            holder.addChild(this.hatPicker);
            var _local_1:Point = var_197[0];
            var_9.setPos(_local_1.x, _local_1.y);
            posX = -_local_1.x;
            posY = -_local_1.y;
            setPos(posX, posY);
            frontBackground.addChild(var_9);
            addEventListener(Event.ENTER_FRAME, this.go);
            var_14.addEventListener(MouseEvent.CLICK, this.method_430, false, 0, true);
            if (gameMode == Modes.egg) {
                setEggSeed([Math.floor(Math.random() * 9999).toString()]);
                addEggs([10]);
            }
        }

        override public function collectEgg(_arg_1:int)
        {
            addEggs([1]);
        }

        private function go(_arg_1:Event)
        {
            Main.stage.focus = Main.stage;
        }

        override protected function endIntro()
        {
            super.endIntro();
            beginRace(new Array());
        }

        // method_354 = clickBack
        private function clickBack(e:MouseEvent)
        {
            Main.pageHolder.changePage(new LevelEditor(this.variables, this.isMod, this.reportsMode));
        }

        // method_371 = clickRestart
        private function clickRestart(e:MouseEvent)
        {
            this.method_370();
        }

        override public function finish(finishId:int=-1, finishX:int=0, finishY:int=0)
        {
            if (this.gameMode != Modes.obj) {
                this.method_370();
            } else {
                miniMap.removeFinish(finishX, finishY);
            }
            SoundEffects.playSound(new VictorySound(), 1 * (Settings.soundLevel / 100));
        }

        // teleport fn
        private function method_430(e:MouseEvent)
        {
            var _local_2:Point = var_14.globalToLocal(new Point(e.stageX, e.stageY));
            var _local_3:int = -frontBackground.x + _local_2.x;
            var _local_4:int = -frontBackground.y + _local_2.y;
            new TeleportPop(var_9.x, var_9.y);
            var_9.setPos(_local_3, _local_4);
            new TeleportPop(var_9.x, var_9.y);
        }

        private function method_370()
        {
            Main.stage.focus = Main.stage;
            blockBackground.rotation = bg1.rotation = bg2.rotation = bg3.rotation = 0;
            timer.setTime(Number(maxTime));
            var_201.clear();
            blockBackground.clear();
            miniMap.clear();
            blockBackground.draw();
            blockBackground.method_578();
            var _local_1:Point = var_197[0];
            var_9.setPos(_local_1.x, _local_1.y);
            var_9.setLife(3);
            miniMap.rotate(0);
        }

        override public function remove()
        {
            blockBackground.clearMoveInterval();
            var_14.removeEventListener(MouseEvent.CLICK, this.method_430);
            removeEventListener(Event.ENTER_FRAME, this.go);
            this.m.back_bt.removeEventListener(MouseEvent.CLICK, this.clickBack);
            this.m.restart_bt.removeEventListener(MouseEvent.CLICK, this.clickRestart);
            this.statsSelect.remove();
            this.hatPicker.remove();
            this.hatPicker = null;
            this.m = null;
            this.statsSelect = null;
            this.variables = null;
            super.remove();
        }


    }
}//package package_6

