

package level_browser
{
    import flash.events.MouseEvent;

    public class Slot extends Removable 
    {

        private var target:LevelItem;
        public var courseMenu:CourseMenu;
        private var m:SlotGraphic = new SlotGraphic();
        private var status:String = "empty";
        private var num:Number;

        public function Slot(i:int, levelItem:LevelItem)
        {
            this.num = i;
            this.target = levelItem;
            addChild(this.m);
            this.m.bg.stop();
            addEventListener(MouseEvent.MOUSE_OVER, this.overHandler, false, 0, true);
            addEventListener(MouseEvent.MOUSE_OUT, this.outHandler, false, 0, true);
            addEventListener(MouseEvent.CLICK, this.clickHandler, false, 0, true);
        }

        public function fillSlot(name:String, rank:Number, me:String)
        {
            this.clearSlot();
            this.m.rankBox.text = rank.toString();
            this.m.nameBox.text = name;
            this.changeStatus("filled");
            if (me == "me") {
                this.courseMenu = new CourseMenu(this);
            }
        }

        public function confirmSlot()
        {
            this.changeStatus("confirmed");
        }

        public function clearSlot()
        {
            this.m.rankBox.text = "";
            this.m.nameBox.text = "";
            this.changeStatus("empty");
        }

        private function changeStatus(s:String)
        {
            this.status = s;
            this.m.bg.gotoAndStop(this.status + "Up");
        }

        private function overHandler(e:MouseEvent)
        {
            this.m.bg.gotoAndStop(this.status + "Over");
        }

        private function outHandler(e:MouseEvent)
        {
            this.m.bg.gotoAndStop(this.status + "Up");
        }

        private function clickHandler(e:MouseEvent)
        {
            this.m.bg.gotoAndStop("pending");
            this.target.sendFillSlot(this.num);
        }

        public function sendConfirmSlot()
        {
            this.target.sendConfirmSlot();
        }

        public function sendClearSlot()
        {
            this.target.sendClearSlot();
            if (this.courseMenu != null) {
                this.courseMenu = null;
            }
        }

        override public function remove()
        {
            removeEventListener(MouseEvent.MOUSE_OVER, this.overHandler);
            removeEventListener(MouseEvent.MOUSE_OUT, this.outHandler);
            removeEventListener(MouseEvent.CLICK, this.clickHandler);
            if (this.courseMenu != null) {
                this.courseMenu.remove();
            }
            this.courseMenu = null;
            this.target = null;
            removeChild(this.m);
            this.m = null;
            super.remove();
        }


    }
}
