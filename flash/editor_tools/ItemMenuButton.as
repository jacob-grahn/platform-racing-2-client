

package editor_tools
{
    import flash.events.MouseEvent;

    public class ItemMenuButton extends MenuButton 
    {

        public function ItemMenuButton()
        {
            addChild(new ItemButtonGraphic());
        }

        override protected function onClick(e:MouseEvent)
        {
            e.stopImmediatePropagation();
            new ItemMenu(this);
        }


    }
}
