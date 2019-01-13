// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//package_19.class_219

package package_19
{
    import flash.events.MouseEvent;

    public class class_219 extends class_215 
    {

        private var m:ValueButtonGraphic = new ValueButtonGraphic();
        private var value:String;

        public function class_219()
        {
            addChild(this.m);
            this.m.titleBox.text = "mode";
            this.setValue("race");
        }

        public function setValue(_arg_1:String)
        {
            this.value = _arg_1;
            this.m.var_18.text = _arg_1;
        }

        override protected function onClick(_arg_1:MouseEvent)
        {
            new class_268(this);
        }


    }
}//package package_19

