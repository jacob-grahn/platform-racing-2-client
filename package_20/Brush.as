// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//package_20.Brush

package package_20
{
    import ui.CustomCursor;
    import background.DrawableBackground;
    import flash.geom.Point;
    import flash.events.Event;
    import flash.utils.clearInterval;
    import flash.utils.setInterval;
    import flash.geom.ColorTransform;
    import levelEditor.LevelEditor;
    import flash.events.MouseEvent;

    public class Brush extends CustomCursor 
    {

        private var circle:Circle = new Circle();
        private var var_151:DrawableBackground;
        private var var_211:Point = new Point();
        private var var_441:uint;
        protected var size:Number = 4;
        protected var color:Number = 0;
        protected var mode:String = "draw";
        protected var var_574:Number = 1;
        protected var drawing:Boolean = false;
        private var lastX:Number = -1;
        private var lastY:Number = -1;
        private var var_550:int;
        private var var_587:int;

        public function Brush()
        {
            var_411 = false;
            addChild(this.circle);
            this.setSize(this.size);
        }

        override public function init()
        {
            super.init();
            addEventListener(Event.ENTER_FRAME, this.go);
            clearInterval(this.var_441);
            this.var_441 = setInterval(this.method_304, 10000);
        }

        override public function pause()
        {
            super.pause();
            removeEventListener(Event.ENTER_FRAME, this.go);
            clearInterval(this.var_441);
        }

        private function go(_arg_1:Event)
        {
            var _local_2:Point;
            if (this.drawing == true) {
                if (!this.var_151.drawing) {
                    _local_2 = this.method_398(this.var_211);
                    if (((!(_local_2.x == this.lastX)) || (!(_local_2.y == this.lastY)))) {
                        this.var_151.lineTo(_local_2.x, _local_2.y);
                        this.lastX = _local_2.x;
                        this.lastY = _local_2.y;
                    }
                    if (Math.abs(this.var_550 - _local_2.x) > 400 || Math.abs(this.var_587 - _local_2.y) > 400) {
                        this.method_304();
                    }
                } else {
                    this.stopDrawing();
                }
            }
        }

        private function method_304()
        {
            if (this.drawing == true) {
                this.stopDrawing();
                this.startDrawing();
            }
        }

        public function setSize(_arg_1:Number=4)
        {
            this.size = _arg_1;
            this.circle.width = (this.circle.height = (_arg_1 * this.var_574));
        }

        public function setColor(_arg_1:Number=0)
        {
            this.color = _arg_1;
            var _local_2:ColorTransform = new ColorTransform();
            _local_2.color = _arg_1;
            this.circle.transform.colorTransform = _local_2;
        }

        public function setZoom(_arg_1:Number)
        {
            this.var_574 = _arg_1;
            this.setSize(this.size);
        }

        override protected function mouseDownHandler(_arg_1:MouseEvent)
        {
            var _local_2:String;
            super.mouseDownHandler(_arg_1);
            if (_arg_1.target.parent != null) {
                _local_2 = _arg_1.target.parent.toString();
                if ((((_local_2 == "[object DrawableBackground]") || (_local_2 == "[object LevelEditor]")) || (_arg_1.target.toString() == "[object LineBackground]"))) {
                    if (!LevelEditor.editor.menu.hitTestPoint(_arg_1.stageX, _arg_1.stageY, true)) {
                        this.var_211 = new Point(_arg_1.stageX, _arg_1.stageY);
                        this.startDrawing();
                    }
                }
            }
        }

        override protected function mouseUpHandler(_arg_1:MouseEvent)
        {
            super.mouseUpHandler(_arg_1);
            if (this.drawing) {
                this.stopDrawing();
            }
        }

        override protected function mouseMoveHandler(_arg_1:MouseEvent)
        {
            super.mouseMoveHandler(_arg_1);
            this.var_211.x = _arg_1.stageX;
            this.var_211.y = _arg_1.stageY;
            if (LevelEditor.editor.menu.hitTestPoint(_arg_1.stageX, _arg_1.stageY, true)) {
                visible = false;
            } else {
                visible = true;
            }
        }

        protected function startDrawing()
        {
            this.drawing = true;
            this.var_151 = LevelEditor.editor.var_220;
            this.var_151.method_585(this.color);
            this.var_151.method_708(this.size);
            this.var_151.setMode(this.mode);
            var _local_1:Point = this.method_398(this.var_211);
            this.var_151.moveTo(_local_1.x, _local_1.y);
            this.var_550 = _local_1.x;
            this.var_587 = _local_1.y;
        }

        protected function stopDrawing()
        {
            this.drawing = false;
            LevelEditor.editor.var_220.rasterize();
        }

        private function method_398(_arg_1:Point):Point
        {
            _arg_1 = this.var_151.globalToLocal(_arg_1);
            _arg_1.x = Math.round(_arg_1.x);
            _arg_1.y = Math.round(_arg_1.y);
            return (_arg_1);
        }

        override public function remove()
        {
            this.circle = null;
            this.var_151 = null;
            this.var_211 = null;
            super.remove();
        }


    }
}//package package_20

