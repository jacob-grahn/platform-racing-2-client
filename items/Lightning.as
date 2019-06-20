// items.Lightning

package items
{
    import package_8.LocalCharacter;
    import package_9.Zap;

    public class Lightning extends Item 
    {

        public function Lightning(r:LocalCharacter)
        {
            super(r);
        }

        override public function useItem()
        {
            new Zap(racer, false);
            Main.socket.write("zap`");
            super.useItem();
        }


    }
}
