// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//levelEditor.class_132

package levelEditor
{
    import flash.geom.Point;
    import data.Objects;
    import flash.events.MouseEvent;
    import levelEditor.LevelEditor;

    public class class_132 extends class_130 
    {

        private var segSize:Number = LevelEditor.segSize;
        private var lastX:Number;
        private var lastY:Number;
        public var segX:int;
        public var segY:int;
        public var posX:Number;
        public var posY:Number;

        public function class_132(_arg_1:int, _arg_2:Number, _arg_3:Number)
        {
            super(_arg_1, _arg_2, _arg_3);
            this.displayCode = _arg_1;
            this.lastX = (x = this.method_103(_arg_2));
            this.lastY = (y = this.method_103(_arg_3));
            this.segX = Math.floor((x / 30));
            this.segY = Math.floor((y / 30));
            this.posX = x;
            this.posY = y;
            var_505 = false;
        }

        public function setSeg(_arg_1:int, _arg_2:int)
        {
            this.segX = _arg_1;
            this.segY = _arg_2;
            this.posX = (x = (_arg_1 * 30));
            this.posY = (y = (_arg_2 * 30));
        }

        public function getSeg():Point
        {
            return (new Point(this.segX, this.segY));
        }

        override protected function endDrag(_arg_1:MouseEvent)
        {
            var _local_2:Number;
            var _local_3:Number;
            _local_2 = this.method_103(x);
            _local_3 = this.method_103(y);
            x = this.lastX;
            y = this.lastY;
            var _local_4:class_132 = editor.blockBG.getBlockAt(_local_2, _local_3);
            var _local_5:Boolean = true;
            if (((!(_local_4 == null)) && (!(_local_4 == this)))) {
                if (((((_local_4.displayCode == Objects.Start1BlockCode) || (_local_4.displayCode == Objects.Start2BlockCode)) || (_local_4.displayCode == Objects.Start3BlockCode)) || (_local_4.displayCode == Objects.Start4BlockCode))) {
                    _local_5 = false;
                } else {
                    editor.cur.recordDelete(this);
                    _local_4.remove();
                }
            }
            if (_local_5 == true) {
                this.lastX = (x = _local_2);
                this.lastY = (y = _local_3);
            }
            editor.blockBG.moveBlock(new Point(this.segX, this.segY), new Point(Math.round((x / 30)), Math.round((y / 30))));
            super.endDrag(_arg_1);
        }

        private function method_103(_arg_1:Number):Number
        {
            return (Math.round((_arg_1 / this.segSize)) * this.segSize);
        }

        override public function remove()
        {
            LevelEditor.editor.blockBG.method_259(this);
            LevelEditor.editor.blockBG.var_323--;
            super.remove();
        }


    }
}//package levelEditor

