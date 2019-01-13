// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//package_19.class_228

package package_19
{
    import flash.display.DisplayObject;
    import ui.class_8;
    import package_20.class_275;
    import flash.events.MouseEvent;

    public class class_228 extends class_221 
    {

        public function class_228(_arg_1:int)
        {
            super(_arg_1);
        }

        override protected function fit(_arg_1:DisplayObject)
        {
        }

        override protected function select(_arg_1:MouseEvent)
        {
            _arg_1.stopImmediatePropagation();
            class_8.method_28(new class_275(displayCode));
        }


    }
}//package package_19

