//ui.CustomScrollBar

package ui
{
    import flash.display.MovieClip;
    import flash.display.DisplayObject;
    import flash.display.Stage;
    import flash.events.MouseEvent;
    import flash.events.Event;
    import flash.geom.Point;

    public class CustomScrollBar extends MovieClip 
    {

        private var m:CustomScrollBarGraphic;
        private var target:DisplayObject;
        private var stageRef:Stage = Main.stage;
        private var var_312:Number;
        private var var_353:Number;
        private var var_337:Number;
        private var var_610:Number;
        private var pos:Number = 0;
        private var var_586:Number = 5;
        private var var_595:Number;

        public function CustomScrollBar()
        {
            this.m = new CustomScrollBarGraphic();
            addChild(this.m);
            this.m.thumb.addEventListener(MouseEvent.MOUSE_DOWN, this.onThumbDown, false, 0, true);
            this.m.upArrow.addEventListener(MouseEvent.MOUSE_DOWN, this.onUpArrowDown, false, 0, true);
            this.m.downArrow.addEventListener(MouseEvent.MOUSE_DOWN, this.onDownArrowDown, false, 0, true);
        }

        public function init(_arg_1:DisplayObject, _arg_2:Number, _arg_3:Number)
        {
            this.m.track.height = _arg_2 - 15;
            this.m.downArrow.y = _arg_2 - this.m.downArrow.height;
            this.var_353 = this.m.downArrow.y - this.m.thumb.height / 2;
            this.var_312 = this.m.upArrow.height + this.m.thumb.height / 2;
            this.var_337 = _arg_1.y;
            this.target = _arg_1;
            this.var_610 = _arg_3;
            scaleX = scaleY = 1;
        }

        private function onThumbDown(_arg_1:MouseEvent)
        {
            this.stageRef.addEventListener(MouseEvent.MOUSE_UP, this.onThumbUp, false, 0, true);
            this.stageRef.addEventListener(MouseEvent.MOUSE_MOVE, this.onThumbDrag, false, 0, true);
        }

        private function onUpArrowDown(_arg_1:MouseEvent)
        {
            this.startContinuousScroll(-this.var_586);
        }

        private function onDownArrowDown(_arg_1:MouseEvent)
        {
            this.startContinuousScroll(this.var_586);
        }

        private function startContinuousScroll(_arg_1:Number)
        {
            removeEventListener(Event.ENTER_FRAME, this.scroll);
            addEventListener(Event.ENTER_FRAME, this.scroll, false, 0, true);
            this.stageRef.addEventListener(MouseEvent.MOUSE_UP, this.onArrowUp, false, 0, true);
            this.var_595 = _arg_1;
        }

        private function onArrowUp(_arg_1:MouseEvent)
        {
            removeEventListener(Event.ENTER_FRAME, this.scroll);
        }

        private function scroll(_arg_1:Event)
        {
            this.position(this.pos + this.var_595);
        }

        private function onThumbUp(_arg_1:MouseEvent)
        {
            this.stageRef.removeEventListener(MouseEvent.MOUSE_UP, this.onThumbUp);
            this.stageRef.removeEventListener(MouseEvent.MOUSE_MOVE, this.onThumbDrag);
        }

        private function onThumbDrag(_arg_1:MouseEvent)
        {
            var _local_2:Number = _arg_1.stageY;
            var _local_3:Point = new Point(0, _local_2);
            _local_3 = globalToLocal(_local_3);
            _local_2 = _local_3.y;
            this.position(_local_2);
        }

        public function position(_arg_1:Number)
        {
            if (_arg_1 > this.var_353) {
                _arg_1 = this.var_353;
            }
            if (_arg_1 < this.var_312) {
                _arg_1 = this.var_312;
            }
            this.m.thumb.y = this.pos = _arg_1;
            var _local_2:Number = (this.m.thumb.y - this.var_312) / (this.var_353 - this.var_312);
            var _local_3:Number = this.target.height - this.var_610;
            this.target.y = this.var_337 - (_local_2 * _local_3);
            if (this.target.y > this.var_337) {
                this.target.y = this.var_337;
            }
            this.target.y = Math.round(this.target.y);
        }

        public function remove()
        {
            this.m.thumb.removeEventListener(MouseEvent.MOUSE_DOWN, this.onThumbDown);
            this.m.upArrow.removeEventListener(MouseEvent.MOUSE_DOWN, this.onUpArrowDown);
            this.m.downArrow.removeEventListener(MouseEvent.MOUSE_DOWN, this.onDownArrowDown);
            removeEventListener(Event.ENTER_FRAME, this.scroll);
            this.stageRef.removeEventListener(MouseEvent.MOUSE_UP, this.onArrowUp);
            this.stageRef.removeEventListener(MouseEvent.MOUSE_UP, this.onThumbUp);
            this.stageRef.removeEventListener(MouseEvent.MOUSE_MOVE, this.onThumbDrag);
            this.target = null;
            this.stageRef = null;
            this.m = null;
        }


    }
}
