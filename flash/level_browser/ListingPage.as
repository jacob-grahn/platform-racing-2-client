

package level_browser
{
    import __AS3__.vec.Vector;
    import __AS3__.vec.*;

    public class ListingPage extends PaginatedPage 
    {

        private var listings:Vector.<ListingEntry> = new Vector.<ListingEntry>();
        private var itemSpacing:int = 50;

        public function ListingPage()
        {
            super(SuperLoader.j);
        }

        override protected function displayData(data:Object)
        {
            var _local_2:Object;
            var item:ListingEntry;
            super.displayData(data);
            for each (var entry:Object in data.listings) {
                item = new ListingEntry(entry);
                item.y = (this.listings.length * this.itemSpacing);
                this.listings.push(item);
                addChild(item);
            }
        }

        override protected function clear()
        {
            var item:ListingEntry;
            for each (item in this.listings) {
                item.remove();
            }
            this.listings = new Vector.<ListingEntry>();
            super.clear();
        }


    }
}//package level_browser

