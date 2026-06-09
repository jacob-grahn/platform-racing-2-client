// items.Lightning

package items
{
    import character.LocalCharacter;
    import effects.Zap;

    public class Lightning extends Item 
    {

        public function Lightning(lc:LocalCharacter)
        {
            super(lc);
        }

        override public function useItem()
        {
            new Zap(this.localChar, false);
            Main.socket.write("zap`");
            super.useItem();
        }


    }
}
