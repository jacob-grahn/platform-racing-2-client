//character.RainbowStarEmitter

package character
{
    import flash.display.DisplayObject;
    import effects.StarEffect;
    import flash.geom.ColorTransform;

    public class RainbowStarEmitter extends ParticleEmitter 
    {

        public function RainbowStarEmitter(_arg_1:int, _arg_2:int, _arg_3:DisplayObject)
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
}//package character

