// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//package_8.class_126

package package_8
{
    import flash.display.DisplayObject;
    import effects.StarEffect;
    import flash.geom.ColorTransform;

    public class class_126 extends class_125 
    {

        public function class_126(_arg_1:int, _arg_2:int, _arg_3:DisplayObject)
        {
            super(_arg_1, _arg_2, _arg_3);
        }

        override protected function createParticle(_arg_1:Number, _arg_2:Number):DisplayObject
        {
            var star:StarEffect = new StarEffect(_arg_1, _arg_2);
            star.rotation = (Math.random() * 360);
            star.transform.colorTransform = new ColorTransform(Math.random(), Math.random(), Math.random(), Math.random(), Math.random(), Math.random(), Math.random(), Math.random());
            return (star);
        }


    }
}//package package_8

