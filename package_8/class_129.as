// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//package_8.class_129

package package_8
{
    import flash.display.DisplayObject;
    import effects.ArrowEffect;
    import flash.geom.ColorTransform;

    public class class_129 extends class_125 
    {

        public function class_129(_arg_1:int, _arg_2:int, _arg_3:DisplayObject)
        {
            super(_arg_1, _arg_2, _arg_3);
        }

        override protected function createParticle(_arg_1:Number, _arg_2:Number):DisplayObject
        {
            var arrow:ArrowEffect = new ArrowEffect(_arg_1, _arg_2);
            arrow.transform.colorTransform = new ColorTransform(Math.random(), Math.random(), Math.random(), Math.random(), Math.random(), Math.random(), Math.random(), Math.random());
            return (arrow);
        }


    }
}//package package_8

