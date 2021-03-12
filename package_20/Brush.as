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
        private var drawableBG:DrawableBackground; // var_151
        private var mousePos:Point = new Point(); // var_211
        private var rdInt:uint; // var_441
        protected var size:Number = 4;
        protected var color:Number = 0;
        protected var mode:String = "draw";
        protected var zoomMultiplier:Number = 1; // var_574
        protected var drawing:Boolean = false;
        private var lastX:Number = -1;
        private var lastY:Number = -1;
        private var drawStartX:int; // var_550
        private var drawStartY:int; // var_587

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
            clearInterval(this.rdInt);
            this.rdInt = setInterval(this.restartDrawing, 10000);
        }

        override public function pause()
        {
            super.pause();
            removeEventListener(Event.ENTER_FRAME, this.go);
            clearInterval(this.rdInt);
        }

        // _loc2 = currentPos
        private function go(e:Event)
        {
            if (this.drawing == true) {
                if (!this.drawableBG.drawing) {
                    var currentPos:Point = this.roundPoint(this.mousePos);
                    if (currentPos.x != this.lastX || currentPos.y != this.lastY) {
                        this.drawableBG.lineTo(currentPos.x, currentPos.y);
                        this.lastX = currentPos.x;
                        this.lastY = currentPos.y;
                    }
                    if (Math.abs(this.drawStartX - currentPos.x) > 400 || Math.abs(this.drawStartY - currentPos.y) > 400) {
                        this.restartDrawing();
                    }
                } else {
                    this.stopDrawing();
                }
            }
        }

        // method_304 = restartDrawing
        private function restartDrawing()
        {
            if (this.drawing == true) {
                this.stopDrawing();
                this.startDrawing();
            }
        }

        public function setSize(s:Number = 4)
        {
            this.size = s;
            this.circle.width = this.circle.height = this.size * this.zoomMultiplier;
        }

        // _loc2 = ct
        public function setColor(c:Number=0)
        {
            this.color = c;
            var ct:ColorTransform = new ColorTransform();
            ct.color = c;
            this.circle.transform.colorTransform = ct;
        }

        public function setZoom(z:Number)
        {
            this.zoomMultiplier = z;
            this.setSize(this.size);
        }

        // _loc2 = objClicked
        override protected function mouseDownHandler(e:MouseEvent)
        {
            super.mouseDownHandler(e);
            if (e.target.parent != null) {
                var objClicked:String = e.target.parent.toString();
                if (objClicked == "[object DrawableBackground]" || objClicked == "[object LevelEditor]" || e.target.toString() == "[object LineBackground]") {
                    if (!LevelEditor.editor.menu.hitTestPoint(e.stageX, e.stageY, true)) {
                        this.mousePos = new Point(e.stageX, e.stageY);
                        this.startDrawing();
                    }
                }
            }
        }

        override protected function mouseUpHandler(e:MouseEvent)
        {
            super.mouseUpHandler(e);
            if (this.drawing) {
                this.stopDrawing();
            }
        }

        override protected function mouseMoveHandler(e:MouseEvent)
        {
            super.mouseMoveHandler(e);
            this.mousePos.x = e.stageX;
            this.mousePos.y = e.stageY;
            visible = !LevelEditor.editor.menu.hitTestPoint(e.stageX, e.stageY, true);
        }

        // _loc1 = startPt
        protected function startDrawing()
        {
            this.drawing = true;
            this.drawableBG = LevelEditor.editor.var_220;
            this.drawableBG.method_585(this.color);
            this.drawableBG.method_708(this.size);
            this.drawableBG.setMode(this.mode);
            var startPt:Point = this.roundPoint(this.mousePos);
            this.drawableBG.moveTo(startPt.x, startPt.y);
            this.drawStartX = startPt.x;
            this.drawStartY = startPt.y;
        }

        protected function stopDrawing()
        {
            this.drawing = false;
            LevelEditor.editor.var_220.rasterize();
        }

        // method_398 = roundPoint
        private function roundPoint(pt:Point):Point
        {
            pt = this.drawableBG.globalToLocal(pt);
            pt.x = Math.round(pt.x);
            pt.y = Math.round(pt.y);
            return pt;
        }

        override public function remove()
        {
            this.circle = null;
            this.drawableBG = null;
            this.mousePos = null;
            super.remove();
        }


    }
}//package package_20

