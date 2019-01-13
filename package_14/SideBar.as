// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_14.SideBar = package_14.class_169

package package_14
{
    import flash.display.Sprite;
    import ui.CustomScrollBar;
    import package_19.class_214;
    import flash.display.DisplayObject;

    public class SideBar extends Sprite 
    {

        private var scrollBar:CustomScrollBar = new CustomScrollBar();
        private var scroll:Sprite = new Sprite();
        private var var_126:Sprite = new Sprite();
        private var posX:Number = 0;
        private var posY:Number = 0;
        private var var_388:Number = 10;

        public function SideBar()
        {
            addChild(this.scrollBar);
            addChild(this.scroll);
            addChild(this.var_126);
            this.scroll.y = 4;
            this.scrollBar.x = 35;
            this.scrollBar.y = 2;
            this.scrollBar.init(this.scroll, 348, 346);
            x = 222;
            y = -195;
            this.method_711();
        }

        private function method_711()
        {
            var _local_1:Number = 0;
            var _local_2:Number = 2;
            var _local_3:Number = 30;
            var _local_4:Number = 348;
            var _local_5:Number = (_local_1 + _local_3);
            var _local_6:Number = (_local_2 + _local_4);
            this.var_126.graphics.beginFill(0);
            this.var_126.graphics.moveTo(_local_1, _local_2);
            this.var_126.graphics.lineTo(_local_1, _local_6);
            this.var_126.graphics.lineTo(_local_5, _local_6);
            this.var_126.graphics.lineTo(_local_5, _local_2);
            this.var_126.graphics.lineTo(_local_1, _local_2);
            this.var_126.graphics.endFill();
            this.scroll.mask = this.var_126;
        }

        protected function addItem(_arg_1:DisplayObject, _arg_2:String="", _arg_3:String="")
        {
            var _local_4:class_214;
            _local_4 = new class_214(_arg_1, _arg_2, _arg_3);
            this.scroll.addChild(_local_4);
            _local_4.x = this.posX;
            _local_4.y = this.posY;
            this.posY = (this.posY + (_local_4.height + this.var_388));
        }

        public function init()
        {
        }

        public function exit()
        {
            if (parent != null) {
                parent.removeChild(this);
            }
        }

        public function remove()
        {
            while (this.scroll.numChildren > 0) {
                class_214(this.scroll.getChildAt(0)).remove();
            }
            this.scrollBar.remove();
            if (parent != null) {
                parent.removeChild(this);
            }
        }


    }
}//package package_14

