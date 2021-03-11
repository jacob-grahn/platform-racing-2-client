// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// items.SuperJump

package items
{
    import com.jiggmin.data.Settings;
    import package_8.LocalPlayer;
    import sounds.SoundEffects;

    public class SuperJump extends Item 
    {

        public function SuperJump(p:LocalPlayer)
        {
            super(p);
        }

        override public function useItem()
        {
            if (!player.crouching) {
                SoundEffects.playSound(new SuperJumpSound(), 1 * (Settings.soundLevel / 100));
                player.velY = player.velY - 25;
                super.useItem();
            }
        }


    }
}
