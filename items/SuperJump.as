// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// items.SuperJump

package items
{
    import com.jiggmin.data.Settings;
    import character.LocalCharacter;
    import sounds.SoundEffects;

    public class SuperJump extends Item 
    {

        public function SuperJump(lc:LocalCharacter)
        {
            super(lc);
        }

        override public function useItem()
        {
            if (!this.localChar.crouching) {
                SoundEffects.playSound(new SuperJumpSound(), Settings.soundLevel / 100);
                this.localChar.velY -= 25;
                super.useItem();
            }
        }


    }
}
