// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//package_19.class_222

package package_19
{
    import levelEditor.LevelEditor;
    import flash.events.MouseEvent;

    public class class_222 extends StampButton 
    {

        private var color:Number;

        public function class_222(_arg_1:int, _arg_2:Number=0)
        {
            super(_arg_1);
            this.color = _arg_2;
        }

        override protected function select(_arg_1:MouseEvent)
        {
            _arg_1.stopImmediatePropagation();
            LevelEditor.editor.setColor(this.color);
            LevelEditor.editor.bg.method_338(displayCode);
        }


    }
}//package package_19

