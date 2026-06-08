package gameplay
{
    import com.jiggmin.data.Data;
    import flash.events.MouseEvent;
    import flash.utils.clearTimeout;
    import flash.utils.setTimeout;
    import dialogs.HoverPopup;

    public class StatsDisplay extends Removable 
    {

        private var m:StatsDisplayGraphic = new StatsDisplayGraphic();
        private var target:Course;
        private var pop:HoverPopup;
        private var hoverTimeout:uint;

        public function StatsDisplay(c:Course)
        {
            this.target = c;
            addChild(this.m);
        }

        public function onMouse(e:MouseEvent)
        {
            if (e.type == MouseEvent.MOUSE_OUT) {
                clearTimeout(this.hoverTimeout);
                if (this.pop != null) {
                    this.pop.remove();
                    this.pop = null;
                }
            } else {
                this.hoverTimeout = setTimeout(this.showHover, 250);
            }
        }

        private function showHover()
        {
            clearTimeout(this.hoverTimeout);
            this.pop = new HoverPopup('Current Stats', 'Speed: ' + this.m.speedBox.text + '\nAcceleration: ' + this.m.accelBox.text + '\nJumping: ' + this.m.jumpBox.text, this);
        }

        public function setStats(speed:int, accel:int, jump:int)
        {
            this.m.speedBox.text = speed;
            this.m.accelBox.text = accel;
            this.m.jumpBox.text = jump;
        }

        override public function remove()
        {
            dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OUT));
            super.remove();
        }


    }
}
