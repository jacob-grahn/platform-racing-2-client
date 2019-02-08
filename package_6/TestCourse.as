// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_6.TestCourse = package_6.class_171

package package_6
{
    import flash.net.URLVariables;
    import ui.StatsSelect;
    import levelEditor.HatPicker;
    import flash.geom.Point;
    import flash.events.MouseEvent;
    import package_8.Racer;
    import flash.events.Event;
    import levelEditor.LevelEditor;
    import sounds.SoundEffects;
    import package_9.TeleportPop;

    public class TestCourse extends Course 
    {

        private var m:TestCourseGraphic = new TestCourseGraphic();
        private var variables:URLVariables;
        private var var_158:StatsSelect;
        private var var_130:HatPicker;

        public function TestCourse(v:URLVariables)
        {
            this.variables = v;
        }

        override public function initialize()
        {
            super.initialize();
            setVariables(this.variables);
            this.m.var_81.addEventListener(MouseEvent.CLICK, this.method_354);
            this.m.var_92.addEventListener(MouseEvent.CLICK, this.method_371);
            holder.addChild(this.m);
            musicSelection.x = -130;
            var_9 = new Racer(0, this, blockBackground, miniMap.getDot(), itemDisplay, this.variables.gravity);
            var_9.setColors(0xFFFFFF, -1, 0xFFFFFF, -1, 0xFFFFFF, -1, 0xFFFFFF, -1);
            var_9.testMode = true;
            var_40.push(var_9);
            this.var_158 = new StatsSelect(300, 50, 50, 50, var_9);
            this.var_158.x = -265;
            this.var_158.y = 90;
            this.var_158.scaleX = this.var_158.scaleY = 0.66;
            holder.addChild(this.var_158);
            this.var_130 = new HatPicker(var_9);
            this.var_130.x = -260;
            this.var_130.y = 65;
            this.var_130.scaleX = this.var_130.scaleY = 0.7;
            holder.addChild(this.var_130);
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

        private function method_354(e:MouseEvent)
        {
            Main.pageHolder.changePage(new LevelEditor(this.variables));
        }

        private function method_371(e:MouseEvent)
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
            SoundEffects.playSound(new VictorySound(), 1 * (Main.soundLevel / 100));
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
            blockBackground.rotation = (bg1.rotation = (bg2.rotation = (bg3.rotation = 0)));
            timer.setTime(Number(maxTime));
            var_201.clear();
            blockBackground.clear();
            miniMap.clear();
            blockBackground.draw();
            var _local_1:Point = var_197[0];
            var_9.setPos(_local_1.x, _local_1.y);
            var_9.setLife(3);
            miniMap.rotate(0);
        }

        override public function remove()
        {
            var_14.removeEventListener(MouseEvent.CLICK, this.method_430);
            removeEventListener(Event.ENTER_FRAME, this.go);
            this.m.var_81.removeEventListener(MouseEvent.CLICK, this.method_354);
            this.m.var_92.removeEventListener(MouseEvent.CLICK, this.method_371);
            this.var_158.remove();
            this.var_130.remove();
            this.var_130 = null;
            this.m = null;
            this.var_158 = null;
            this.variables = null;
            super.remove();
        }


    }
}//package package_6

