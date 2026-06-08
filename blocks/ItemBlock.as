// blocks.ItemBlock = blocks.class_40

package blocks
{
    import blocks.options.ItemBlockOptions;
    import com.jiggmin.data.Settings;
    import gameplay.Course;
    import package_8.LocalCharacter;
    import sounds.SoundEffects;
    import page.GamePage;
    import items.Items;

    public class ItemBlock extends SupplyBlock
    {

        public function ItemBlock(bCode:int = 110) // single item block code
        {
            optionsMenu = ItemBlockOptions;
            super(bCode);
        }

        public function applyOptions(optsStr:String)
        {
            if (GamePage.course == null) {
                return;
            }
            var newItems:Vector.<int> = Vector.<int>(optsStr.split('-')).sort(Array.NUMERIC);
            var blockItems:Vector.<int> = Vector.<int>(options.split('-')).sort(Array.NUMERIC);
            var gameItems:Vector.<int> = GamePage.course.allowedItems.sort(Array.NUMERIC);
            if (newItems.toString() == gameItems.toString() || (newItems.toString() == '0' && gameItems.toString() == '')) {
                options = '';
            } else if (newItems == blockItems) {
                return;
            } else if (newItems.length == 0 || (newItems.length == 1 && newItems[0] == 0)) {
                options = 'none';
            } else {
                options = newItems.join('-');
            }
        }

        public function updateGameItems()
        {
            var allowedItems:Vector.<int> = GamePage.course.allowedItems.sort(Array.NUMERIC);
            if (options == '') {
                return;
            } else if (options == allowedItems.join('-') || (options == 'none' && allowedItems.length == 0)) {
                options = '';
            }
        }

        override protected function useSupply(player:LocalCharacter)
        {
            super.useSupply(player);
            var itemsArr:Vector.<int> = new Vector.<int>;
            if (options == '') {
                itemsArr = GamePage.course.allowedItems.sort(Array.NUMERIC);
            } else if (options != 'none') {
                itemsArr = Vector.<int>(options.split('-'));
            }
            if (itemsArr.length > 0) {
                var randNum:Number = Math.floor(Math.random() * itemsArr.length);
                var itemId:int = itemsArr[randNum];
                player.setItem(itemId);
            }
            SoundEffects.playSound(new StarSound(), 0.6 * (Settings.soundLevel / 100));
        }


    }
}
