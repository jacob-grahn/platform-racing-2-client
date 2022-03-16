// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// MiniMapDot = class_138

package 
{
    import com.jiggmin.data.ColorUtil;
    import flash.display.MovieClip;
    import flash.events.MouseEvent;
    import package_4.HoverPopup;
    import package_6.Course;
    import package_8.Character;
    import package_6.Game;
    import package_8.LocalCharacter;

    public dynamic class MiniMapDot extends MovieClip 
    {
        private const remote0Color:uint = /*0x0066FF;*/0x10B6DE;
        private const remote1Color:uint = 0xFFFF00;//0xCC3333;
        private const remote2Color:uint = 0x00FF00;//0x009900;//0xFF6633;
        private const remote3Color:uint = 0x999999;//FF00FF;//0xCA6EED;
        private const localColor:uint = 0xFFFF00;

        private var tempID:int = -1;

        private var infoHover:HoverPopup;


        public function MiniMapDot()
        {
            stop();
            this.addEventListener(MouseEvent.MOUSE_OVER, this.infoMouseEvent, false, 0, true);
            this.addEventListener(MouseEvent.MOUSE_OUT, this.infoMouseEvent, false, 0, true);
        }

        public function setTempID(id:int, local:Boolean = false)
        {
            if (this.tempID == -1 && id >= 0 && id <= 3) {
                this.tempID = id;
                gotoAndStop(local ? 'local' : 'remote' + this.tempID.toString());
            }
        }

        // method_331 = clickLoadouts -- changed to loadoutsMouseEvent in 161
        public function infoMouseEvent(e:MouseEvent = null)
        {
            if ((Course.course == null || !(Course.course is Game)) && e != null) {
                return;
            }

            // remove popup if already exists
            if (this.infoHover != null) {
                this.infoHover.remove();
                this.infoHover = null;
            }

            // stop here if from mouseout
            if (e == null || e.type == MouseEvent.MOUSE_OUT) {
                return;
            } else if (e.type == MouseEvent.MOUSE_OVER) {
                var c:Character = Course.course.playerArray[this.tempID];
                this.infoHover = new HoverPopup('Player ' + (this.tempID + 1), c is LocalCharacter ? Main.loggedInAs : c.getName(), this);
            }
        }

        public function getColor(tempId:int)
        {
            if (tempId >= 0 && tempId <= 3) {
                return this['remote' + tempId + 'Color'];
            } else {
                return this.localColor;
            }
        }

        public function remove()
        {
            this.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OUT));
        }
    }
}//package 

