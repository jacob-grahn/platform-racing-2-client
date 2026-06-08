// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// gameplay.TestCourse = gameplay.class_171

package gameplay
{
    import blocks.TeleportBlock;
    import com.jiggmin.data.Settings;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.geom.Point;
    import flash.net.URLVariables;
    import levelEditor.HatPicker;
    import levelEditor.LevelEditor;
    import package_8.LocalCharacter;
    import effects.TeleportPop;
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

        // _loc1 = player1Start
        override public function initialize()
        {
            super.initialize();
            setVariables(this.variables);
            this.m.back_bt.addEventListener(MouseEvent.CLICK, this.clickBack);
            this.m.restart_bt.addEventListener(MouseEvent.CLICK, this.clickRestart);
            holder.addChild(this.m);
            musicSelection.x = -130;
            var savedStats:Object = Settings.getValue(Settings.LE_TEST_STATS, Settings.DEFAULT_LE_TEST_STATS);
            localPlayer = new LocalCharacter(0, this, blockBackground, miniMap.getDot(), itemDisplay, this.variables.gravity, savedStats.speed, savedStats.acceleration, savedStats.jumping);
            localPlayer.setColors(0xFFFFFF, -1, 0xFFFFFF, -1, 0xFFFFFF, -1, 0xFFFFFF, -1);
            localPlayer.testMode = true;
            playerArray.push(localPlayer);
            this.statsSelect = new StatsSelect(300, savedStats.speed, savedStats.acceleration, savedStats.jumping, localPlayer);
            this.statsSelect.x = -265;
            this.statsSelect.y = 90;
            this.statsSelect.scaleX = this.statsSelect.scaleY = 0.66;
            holder.addChild(this.statsSelect);
            this.hatPicker = new HatPicker(localPlayer);
            this.hatPicker.x = -260;
            this.hatPicker.y = 65;
            this.hatPicker.scaleX = this.hatPicker.scaleY = 0.7;
            holder.addChild(this.hatPicker);
            var player1Start:Point = startPosArray[0];
            localPlayer.setPos(player1Start.x, player1Start.y);
            posX = -player1Start.x;
            posY = -player1Start.y;
            setPos(posX, posY);
            frontBackground.addChild(localPlayer);
            addEventListener(Event.ENTER_FRAME, this.go);
            var_14.addEventListener(MouseEvent.CLICK, this.teleportToClickPos, false, 0, true);
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
            this.restart();
        }

        override public function finish(finishId:int=-1, finishX:int=0, finishY:int=0)
        {
            if (this.gameMode != Modes.obj) {
                this.restart();
            } else {
                miniMap.removeFinish(finishX, finishY);
            }
            SoundEffects.playSound(new VictorySound(), 1 * (Settings.soundLevel / 100));
        }

        // _loc2 = target
        // _loc3 = newX
        // _loc4 = newY
        // method_430 = teleportToClickPos
        private function teleportToClickPos(e:MouseEvent)
        {
            var target:Point = var_14.globalToLocal(new Point(e.stageX, e.stageY));
            var newX:int = -frontBackground.x + target.x;
            var newY:int = -frontBackground.y + target.y;
            new TeleportPop(localPlayer.x, localPlayer.y);
            localPlayer.setPos(newX, newY);
            new TeleportPop(localPlayer.x, localPlayer.y);
        }

        public function statsSelectSetFromCharacter()
        {
            this.statsSelect.setStatsFromCharacter();
        }

        // _loc1 = player1Start
        // method_370 = restart
        private function restart()
        {
            Main.stage.focus = Main.stage;
            TeleportBlock.resetAll();
            blockBackground.rotation = bg1.rotation = bg2.rotation = bg3.rotation = bg4.rotation = bg5.rotation = 0;
            timer.setTime(Number(maxTime));
            effectBackground.clear();
            blockBackground.clear();
            miniMap.clear();
            blockBackground.draw();
            blockBackground.method_578();
            var player1Start:Point = startPosArray[0];
            localPlayer.setPos(player1Start.x, player1Start.y);
            localPlayer.setItem(0);
            localPlayer.setLife(3);
            this.hatPicker.resetHat();
            var savedStats:Object = Settings.getValue(Settings.LE_TEST_STATS, Settings.DEFAULT_LE_TEST_STATS);
            localPlayer.setStats(savedStats.speed, savedStats.acceleration, savedStats.jumping);
            this.statsSelectSetFromCharacter();
            miniMap.rotate(0);
        }

        override public function remove()
        {
            blockBackground.clearMoveInterval();
            TeleportBlock.resetAll();
            var_14.removeEventListener(MouseEvent.CLICK, this.teleportToClickPos);
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
}
