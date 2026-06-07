// items.Lightning

package items
{
    import package_8.LocalCharacter;
    import effects.Zap;

    public class Lightning extends Item 
    {

        public function Lightning(lc:LocalCharacter)
        {
            super(lc);
        }

        override public function useItem()
        {
            new Zap(character, false);
            Main.socket.write("zap`");
            super.useItem();
        }


    }
}
