// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// effects.Effect = effects.class_80

package effects
{
    import background.EffectBackground;
    import flash.utils.setTimeout;
    import flash.utils.clearTimeout;

    public class Effect extends Removable 
    {

        private var removeTimeout:uint;

        public function Effect(startX:Number=0, startY:Number=0)
        {
            x = startX;
            y = startY;
            EffectBackground.instance.addChild(this);
        }

        protected function scheduleRemove(frames:int)
        {
            var ms:int = int((frames * (1 / 24)) * 1000);
            this.removeTimeout = setTimeout(this.remove, ms);
        }

        override public function remove()
        {
            clearTimeout(this.removeTimeout);
            super.remove();
        }


    }
}//package effects

