// items.Lightning

package items
{
    import package_8.LocalCharacter;
    import package_9.Zap;

    public class Lightning extends Item 
    {

        public function Lightning(p:LocalCharacter)
        {
            super(p);
        }

        override public function useItem()
        {
            new Zap(player, false);
            Main.socket.write("zap`");
            super.useItem();
        }


    }
}
