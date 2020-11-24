package package_19
{
    import fl.controls.CheckBox;
    import flash.display.MovieClip;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import levelEditor.LevelEditor;
    import package_4.class_264;
    import package_4.HoverPopup;
    import page.GamePage;

    public class HatsMenu extends class_264 
    {
        private var m:HatsMenuGraphic = new HatsMenuGraphic();
        private var highestHatID:int = Parts.getPartArray('HAT').length + 1;
        private var hover:HoverPopup = null;

        public function HatsMenu(button:HatsMenuButton)
        {
            addChild(this.m);
            super(button);
            var badHats:Vector.<int> = GamePage.course.badHats;
            var i:int = 2;
            while (i <= this.highestHatID) {
                var chk:CheckBox = this.m["hat" + i];
                if (badHats.indexOf(i) != -1) {
                    chk.selected = false;
                }
                i++;
            }
            if (GamePage.course.gameMode == 'hat') {
                this.m.hat14.selected = false;
                this.m.hat14.addEventListener(MouseEvent.MOUSE_OVER, this.maybeAddHover, false, 0, true);
                this.m.hat14.addEventListener(Event.CHANGE, this.maybeAddHover, false, 0, true);
                this.m.hat14.addEventListener(MouseEvent.MOUSE_OUT, this.removeHover, false, 0, true);
            }
            this.m.hat5.addEventListener(MouseEvent.MOUSE_OVER, this.maybeAddHover, false, 0, true);
            this.m.hat5.addEventListener(Event.CHANGE, this.maybeAddHover, false, 0, true);
            this.m.hat5.addEventListener(MouseEvent.MOUSE_OUT, this.removeHover, false, 0, true);
        }

        private function maybeAddHover(e:Event)
        {
            var target:CheckBox = e.currentTarget;
            if (target == this.m.hat5) {
                if (this.hover == null && GamePage.course.cowboyChance > 0 && !this.m.hat5.selected) {
                    this.hover = new HoverPopup('Cowboy Mode', 'Disabling the cowboy hat here won\'t override your setting for chance of cowboy mode.', this.m.hat5);
                } else {
                    this.removeHover();
                }
            } else if (target == this.m.hat14 && GamePage.course.gameMode === 'hat') {
                if (this.hover != null) {
                    this.removeHover();
                    if (e.type == MouseEvent.MOUSE_OUT) {
                        return;
                    }
                }
                this.hover = new HoverPopup('Artifact in Hat Attack', 'This setting won\'t have any effect since the artifact hat cannot be used in hat attack mode.', this.m.hat14);
            }
        }

        private function removeHover(e:MouseEvent = null)
        {
            if (this.hover != null) {
                this.hover.remove();
                this.hover = null;
            }
        }

        override public function remove()
        {
            if (GamePage.course != null) {
                GamePage.course.badHats = new Vector.<int>();
                var i:int = 2;
                while (i <= this.highestHatID) {
                    var chk:CheckBox = this.m["hat" + i];
                    if (!chk.selected) {
                        GamePage.course.badHats.push(i);
                    }
                    i++;
                }
            }
            this.m.hat5.removeEventListener(MouseEvent.MOUSE_OVER, this.maybeAddHover);
            this.m.hat5.removeEventListener(Event.CHANGE, this.maybeAddHover)
            this.m.hat5.removeEventListener(MouseEvent.MOUSE_OUT, this.removeHover);
            this.m.hat14.removeEventListener(MouseEvent.MOUSE_OVER, this.maybeAddHover);
            this.m.hat14.removeEventListener(Event.CHANGE, this.maybeAddHover);
            this.m.hat14.removeEventListener(MouseEvent.MOUSE_OUT, this.removeHover);
            this.removeHover();
            super.remove();
        }


    }
}
