// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// items.SuperJump

package items
{
    import com.jiggmin.data.Settings;
    import package_8.LocalCharacter;
    import sounds.SoundEffects;

    public class SuperJump extends Item 
    {

        public function SuperJump(lc:LocalCharacter)
        {
            super(lc);
        }

        override public function useItem()
        {
            if (!character.crouching) {
                SoundEffects.playSound(new SuperJumpSound(), Settings.soundLevel / 100);
                character.velY -= 25;
                super.useItem();
            }
        }


    }
}
