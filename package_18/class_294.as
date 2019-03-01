// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//package_18.class_294

package package_18
{
    import flash.display.Sprite;
    import ui.class_311;
    import com.jiggmin.ColorPicker.ColorPicker;
    import flash.display.DisplayObject;
    import flash.events.Event;

    public class class_294 extends Sprite
    {

        private var var_173:class_311;
        private var var_12:ColorPicker;
        private var cp2:ColorPicker;
        private var color:int = 0;
        private var color2:int = 0;
        private var value:int = 0;
        private var var_422:Array;
        private var var_182:DisplayObject;

        public function class_294(_arg_1:Array, _arg_2:*, _arg_3:int, _arg_4:Array, _arg_5:int)
        {
            this.value = _arg_2;
            this.color = _arg_3;
            this.color2 = _arg_5;
            this.var_422 = _arg_4;
            this.var_12 = new ColorPicker();
            this.var_12.addEventListener(Event.CLOSE, this.method_120, false, 0, true);
            this.var_12.width = (this.var_12.height = 20);
            this.var_12.setColor(this.color);
            this.var_12.x = 120;
            addChild(this.var_12);
            this.cp2 = new ColorPicker();
            this.cp2.addEventListener(Event.CLOSE, this.method_120, false, 0, true);
            this.cp2.width = (this.cp2.height = 20);
            this.cp2.setColor(_arg_5);
            this.cp2.x = 120;
            addChild(this.cp2);
            var _local_6:DisplayObject = this.method_737(this.var_12.width, this.var_12.height);
            _local_6.x = this.cp2.x;
            _local_6.y = this.cp2.y;
            addChild(_local_6);
            this.cp2.mask = _local_6;
            this.var_182 = this.method_809((this.var_12.width - 6), (this.var_12.height - 6));
            this.var_182.x = (this.cp2.x + 3);
            this.var_182.y = (this.cp2.y + 3);
            addChild(this.var_182);
            this.method_159();
            this.var_173 = new class_311(_arg_1, _arg_2);
            this.var_173.addEventListener(Event.CHANGE, this.method_329, false, 0, true);
            addChild(this.var_173);
        }

        public function method_12():int
        {
            return (this.color);
        }

        public function getColor2():int
        {
            var _local_1:int = this.color2;
            if (!this.method_449()) {
                _local_1 = -1;
            }
            return (_local_1);
        }

        public function getValue():int
        {
            return (int(this.value));
        }

        public function setValue(_arg_1:int)
        {
            this.value = (this.var_173.value = _arg_1);
        }

        public function setColors(_arg_1:int, _arg_2:int)
        {
            this.var_12.setColor(_arg_1);
            this.cp2.setColor(_arg_2);
            this.color = _arg_1;
            this.color2 = _arg_2;
            this.method_159();
        }

        public function method_449():Boolean
        {
            return ((!(this.var_422.indexOf(this.value.toString()) == -1)) || (!(this.var_422.indexOf("*") == -1)));
        }

        private function method_737(_arg_1:int, _arg_2:int):DisplayObject
        {
            var _local_3:Sprite = new Sprite();
            _local_3.graphics.beginFill(0);
            _local_3.graphics.moveTo(0, _arg_2);
            _local_3.graphics.lineTo(_arg_1, _arg_2);
            _local_3.graphics.lineTo(_arg_1, 0);
            _local_3.graphics.lineTo(0, _arg_2);
            _local_3.graphics.endFill();
            return (_local_3);
        }

        private function method_809(_arg_1:int, _arg_2:int):DisplayObject
        {
            var _local_3:Sprite = new Sprite();
            _local_3.graphics.lineStyle(1, 0);
            _local_3.graphics.moveTo(0, _arg_2);
            _local_3.graphics.lineTo(_arg_1, 0);
            _local_3.alpha = 0.5;
            _local_3.mouseEnabled = false;
            _local_3.mouseChildren = false;
            return (_local_3);
        }

        private function method_120(_arg_1:Event)
        {
            this.color = this.var_12.method_12();
            this.color2 = this.cp2.method_12();
            dispatchEvent(new Event(Event.CHANGE));
        }

        private function method_329(_arg_1:Event)
        {
            this.value = this.var_173.value;
            this.method_159();
            dispatchEvent(new Event(Event.CHANGE));
        }

        private function method_159()
        {
            if (this.method_449()) {
                this.cp2.visible = true;
                this.var_182.visible = true;
            } else {
                this.cp2.visible = false;
                this.var_182.visible = false;
            }
        }

        public function remove()
        {
            this.var_12.removeEventListener(Event.CLOSE, this.method_120);
            this.var_12.remove();
            this.var_12 = null;
            this.cp2.removeEventListener(Event.CLOSE, this.method_120);
            this.cp2.remove();
            this.cp2 = null;
            this.var_173.removeEventListener(Event.CHANGE, this.method_329);
            this.var_173.remove();
            this.var_173 = null;
            removeChild(this.var_182);
            this.var_182 = null;
            if (parent != null) {
                parent.removeChild(this);
            }
        }


    }
}//package package_18
