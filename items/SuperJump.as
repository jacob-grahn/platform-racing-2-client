// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// items.SuperJump

package items
{
    import package_8.Racer;
    import sounds.SoundEffects;

    public class SuperJump extends Item 
    {

        public function SuperJump(r:Racer)
        {
            super(r);
        }

        override public function useItem()
        {
            if (!racer.crouching) {
                SoundEffects.playSound(new SuperJumpSound(), 1 * (Main.soundLevel / 100));
                racer.velY = racer.velY - 25;
                super.useItem();
            }
        }


    }
}
