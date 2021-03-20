// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//package_19.class_221

package package_19
{
    import com.jiggmin.data.Data;
    import com.jiggmin.data.Objects;
    import flash.display.Sprite;
    import flash.display.DisplayObject;
    import flash.events.MouseEvent;
    import package_20.class_269;
    import ui.CustomCursor;

    public class class_221 extends Sprite 
    {

        protected var displayCode:int;

        public function class_221(_arg_1:int)
        {
            var _local_2:Square;
            super();
            this.displayCode = _arg_1;
            _local_2 = new Square();
            _local_2.width = (_local_2.height = 30);
            _local_2.x = (_local_2.y = 15);
            _local_2.alpha = 0;
            addChild(_local_2);
            var _local_3:DisplayObject = Objects.getFromCode(_arg_1);
            this.fit(_local_3);
            addChild(_local_3);
            addEventListener(MouseEvent.MOUSE_DOWN, this.select);
        }

        protected function fit(_arg_1:DisplayObject)
        {
            var _local_2:Number;
            _local_2 = 24;
            Data.method_314(_arg_1, _local_2, _local_2);
            _arg_1.x = (((_local_2 - _arg_1.width) / 2) + 3);
            _arg_1.y = (((_local_2 - _arg_1.height) / 2) + 3);
        }

        protected function select(_arg_1:MouseEvent)
        {
            _arg_1.stopImmediatePropagation();
            CustomCursor.change(new class_269(this.displayCode));
        }

        public function remove()
        {
            removeEventListener(MouseEvent.MOUSE_DOWN, this.select);
            parent.removeChild(this);
        }


    }
}//package package_19

