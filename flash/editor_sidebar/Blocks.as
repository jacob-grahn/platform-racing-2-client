

package editor_sidebar
{
    import editor_tools.ObjectDeleterButton;
    import editor_tools.BlockPlacerButton;
    import com.jiggmin.data.Objects;

    public class Blocks extends SideBar 
    {

        public function Blocks()
        {
            addItem(new ObjectDeleterButton(), "Delete Tool", "Click and drag the mouse to delete things with remarkable speed!");
            addItem(new BlockPlacerButton(Objects.BLOCK_BASIC1), "Basic Block 1", "Normal old every day run of the mill squarish thing that you can stand on.");
            addItem(new BlockPlacerButton(Objects.BLOCK_BASIC2), "Basic Block 2", "Normal old every day run of the mill squarish thing that you can stand on.");
            addItem(new BlockPlacerButton(Objects.BLOCK_BASIC3), "Basic Block 3", "Normal old every day run of the mill squarish thing that you can stand on.");
            addItem(new BlockPlacerButton(Objects.BLOCK_BASIC4), "Basic Block 4", "Normal old every day run of the mill squarish thing that you can stand on.");
            addItem(new BlockPlacerButton(Objects.BLOCK_BRICK), "Brick Block", "A block of poorly mortared bricks that will shatter if it is bumped from below.");
            addItem(new BlockPlacerButton(Objects.BLOCK_FINISH), "Finish Block", "Bumping this marks the end of the race.");
            addItem(new BlockPlacerButton(Objects.BLOCK_ICE), "Ice Block", "Sliperyyyyiiiee.");
            addItem(new BlockPlacerButton(Objects.BLOCK_ITEM), "Item Block", "A block that provides rather lovely and mischievous items when bumped. This can only be used once.");
            addItem(new BlockPlacerButton(Objects.BLOCK_ITEM_INF), "Infinite Item Block", "This is an item block that will never run out of items.");
            addItem(new BlockPlacerButton(Objects.BLOCK_ARROW_LEFT), "Left Block", "Anyone standing on this will be pushed to the left.");
            addItem(new BlockPlacerButton(Objects.BLOCK_ARROW_RIGHT), "Right Block", "Anyone standing on this will be pushed to the right.");
            addItem(new BlockPlacerButton(Objects.BLOCK_ARROW_UP), "Up Block", "Anyone who stands on this will be bumped upwards.");
            addItem(new BlockPlacerButton(Objects.BLOCK_ARROW_DOWN), "Down Block", "Anyone who stands on this will have difficulty jumping.");
            addItem(new BlockPlacerButton(Objects.BLOCK_TELEPORT), "Teleport Block", "Bump this to be teleported to another one of these with the same color.");
            addItem(new BlockPlacerButton(Objects.BLOCK_MINE), "Mine Block", "Mines explode rather painfully if you touch them.");
            addItem(new BlockPlacerButton(Objects.BLOCK_CRUMBLE), "Crumble Block", "This will crumble into pieces if it is hit too hard.");
            addItem(new BlockPlacerButton(Objects.BLOCK_VANISH), "Vanish Block", "Don't stand for too long, or you'll find yourself falling through the floor.");
            addItem(new BlockPlacerButton(Objects.BLOCK_MOVE), "Move Block", "Where will it end up? Nobody knows! Every so often, this will move one space in a random direction. Use sparingly, too many of these can slow the game down.");
            addItem(new BlockPlacerButton(Objects.BLOCK_WATER), "Water Block", "Swim!");
            addItem(new BlockPlacerButton(Objects.BLOCK_ROTATE_RIGHT), "Rotate Right Block", "The wheels on the bus go round and round, round and round, round and round.");
            addItem(new BlockPlacerButton(Objects.BLOCK_ROTATE_LEFT), "Rotate Left Block", "The wheels on the bus go round and round, round and round, round and round.");
            addItem(new BlockPlacerButton(Objects.BLOCK_PUSH), "Push Block", "This block can be pushed around.");
            addItem(new BlockPlacerButton(Objects.BLOCK_HAPPY), "Happy Block", "Bump this to increase your stats for the rest of the race.");
            addItem(new BlockPlacerButton(Objects.BLOCK_SAD), "Sad Block", "Bumping one of these will decrease your stats for the rest of the race.");
            addItem(new BlockPlacerButton(Objects.BLOCK_CUSTOM_STATS), "Custom Stats Block", "Bumping this will set the player's stats to what you specify. The default is 50-50-50.");
            addItem(new BlockPlacerButton(Objects.BLOCK_SAFETY), "Safety Net", "Touching this will teleport you back to your last safe location. It's the same as falling off of the course.");
            addItem(new BlockPlacerButton(Objects.BLOCK_HEART), "Heart Block", "This block grants you one extra heart in Deathmatch mode, and renders you invincible for five fantastic seconds.");
            addItem(new BlockPlacerButton(Objects.BLOCK_TIME), "Time Block", "Adds 10 seconds to your timer.");
            addItem(new BlockPlacerButton(Objects.BLOCK_MINION_EGG), "Egg Minion", "Romps about with evil intent.");
        }

    }
}

