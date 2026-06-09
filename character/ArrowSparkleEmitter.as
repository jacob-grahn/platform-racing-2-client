// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//character.ArrowSparkleEmitter

package character
{
    import flash.display.DisplayObject;
    import effects.ArrowEffect;
    import flash.geom.ColorTransform;

    public class ArrowSparkleEmitter extends ParticleEmitter 
    {

        public function ArrowSparkleEmitter(_arg_1:int, _arg_2:int, _arg_3:DisplayObject)
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
}//package character

