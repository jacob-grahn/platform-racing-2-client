// items.Lightning

package items
{
    import package_8.Racer;
    import package_9.Zap;

    public class Lightning extends Item 
    {

        public function Lightning(r:Racer)
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
