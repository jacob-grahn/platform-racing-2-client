// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// ui.ProgressBar = ui.class_163

package ui
{
    import flash.display.Sprite;
    import flash.filters.DropShadowFilter;
    import flash.events.Event;

    public class ProgressBar extends Sprite 
    {

        private var bar:ProgressBarGraphic = new ProgressBarGraphic();
        private var totalPx:Number = 0;
        private var percentComplete:Number = 0;
        private var widthPx:Number = 0;
        private var lerpFactor:Number;

        public function ProgressBar(px:Number = 200, _arg_2:Number = 0.3)
        {
            this.lerpFactor = _arg_2;
            var shadow:DropShadowFilter = new DropShadowFilter(2, 45, 0, 1, 2, 2);
            this.bar.filters = new Array(shadow);
            addChild(this.bar);
            this.bar.width = px;
            this.bar.bar.width = px - 4;
            this.totalPx = px - 4;
            addEventListener(Event.ENTER_FRAME, this.go, false, 0, true);
        }

        private function go(e:Event)
        {
            this.widthPx = this.widthPx + ((this.percentComplete - this.widthPx) * this.lerpFactor);
            this.bar.bar.width = this.widthPx;
        }

        public function incProgress(progressDecimal:Number)
        {
            if (progressDecimal > 1) {
                progressDecimal = 1;
            }
            if (progressDecimal < 0) {
                progressDecimal = 0;
            }
            this.percentComplete = this.totalPx * progressDecimal;
        }

        public function remove()
        {
            removeEventListener(Event.ENTER_FRAME, this.go);
            if (this.bar != null && this.bar.parent == this) {
                removeChild(this.bar);
                this.bar = null;
            }
            if (parent != null) {
                parent.removeChild(this);
            }
        }


    }
}//package ui
