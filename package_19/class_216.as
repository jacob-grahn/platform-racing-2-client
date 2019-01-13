// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//package_19.class_216

package package_19
{
    import flash.events.MouseEvent;

    public class class_216 extends class_215 
    {

        public function class_216(_arg_1:Number=0)
        {
            addChild(new ItemButtonGraphic());
        }

        override protected function onClick(e:MouseEvent)
        {
            e.stopImmediatePropagation();
            new class_265(this);
        }


    }
}
