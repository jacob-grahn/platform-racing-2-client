package pr2.level;

import pr2.level.ServerLevelArtCursor.ArtDrawCursor;
import pr2.level.ServerLevelArtRasterizer.ArtRasterBudget;
import pr2.level.ServerLevelArtRasterizer.ArtRasterTiles;
import pr2.level.ServerLevelArtCursor.ArtStrokeState;

import com.jiggmin.data.Objects;
import haxe.Timer;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;
import openfl.utils.AssetType;
import openfl.utils.Assets;
import pr2.Constants;
import pr2.gameplay.PrizePopup;
import pr2.lobby.account.Settings;
import pr2.lobby.dialogs.MessagePopup;
import pr2.lobby.dialogs.Popup;
import pr2.level.ServerLevel.DecodedArtLayer;
import pr2.level.ServerLevel.DecodedArtObject;
import pr2.level.ServerLevel.DecodedBlock;
import pr2.level.ServerLevel.DecodedDrawAction;
import pr2.level.ServerLevel.DecodedTextObject;
import pr2.effects.BlockPiece;
import pr2.effects.MineAppear;
import pr2.effects.MineExplosion;
import pr2.effects.TeleportPop;
import pr2.runtime.PR2MovieClip;
import pr2.runtime.FontResolver;

typedef ArtRenderOptions = {
	@:optional var onArtWarning:String->Void;
	@:optional var suppressArtWarningPopup:Bool;
	@:optional var artDrawFaultInjector:Int->Void;
	@:optional var rasterTileLimit:Int;
	@:optional var editorWarning:Bool;
}

/**
	Renders the decoded server block layer in original PR2 pixel units.

	Server levels are stored around large editor coordinates (~10000 px). This
	renderer keeps the 30 px block scale and translates the world so a chosen
	focus point, usually the first start block, appears at a stable stage point.
**/
class ServerLevelRenderer extends Sprite {
	public static inline var TILE_SIZE:Int = 30;
	private static inline var TELEPORT_DEFAULT_COLOR:Int = 0xFF7F50;
	// Edge length of the transparent square that stroke art is rasterized onto,
	// mirroring DrawableBackground.rasterTileSize. Kept well under the WebGL
	// MAX_TEXTURE_SIZE (8192 on many GPUs, 4096 on some) so a single tile never
	// fails to upload. See rasterizeBrushInto.
	public static inline var ART_RASTER_TILE_SIZE:Int = 512;
	public static inline var DEFAULT_ART_RASTER_TILE_LIMIT:Int = 750;
	public static inline var DEFAULT_ART_BRUSH_SIZE:Float = 4.0;
	private static inline var ART_DRAW_ACTION_BATCH_LIMIT:Int = 8;
	public static inline var ART_DRAW_BATCH_MAX_TILE_COUNT:Int = 24;
	public static inline var ART_DRAW_BATCH_MAX_TILE_SPAN:Int = 2;
	private static inline var ART_DRAW_FRAME_BUDGET_SECONDS:Float = 0.008;
	private static inline var ART_DRAW_SLOW_PROFILE_MS:Float = 50.0;
	private static inline var RENDER_FRAME_ESCAPE_SECONDS:Float = 0.1;
	public static inline var ART_RASTER_VIEW_MARGIN_TILES:Int = 1;
	public static inline var ART_RASTER_VIEW_REBUILD_THRESHOLD:Int = 1;
	public static inline var ART_RASTER_ATTACH_TILES_PER_FRAME:Int = 1;
	public static inline var DEFAULT_FOCUS_X:Float = 180;
	public static inline var DEFAULT_FOCUS_Y:Float = 280;
	public static inline var DEFAULT_BLOCKS_PER_FRAME:Int = 50;
	public static inline var BG5_CODE:Int = 205;
	public static inline var ART_LOAD_WARNING_GAME:String = "Error: Some art didn't load correctly. Don't worry! You can still play the level.\n\nIf this persists, please contact a member of the PR2 staff team.";
	public static inline var ART_LOAD_WARNING_EDITOR:String = "Error: Some art didn't load correctly. This could be because there's too much art on your level. Saving the level now may cause permanent damage to its playability. Try undoing your recent changes until you don't get this error, and then saving your work.\n\nIf this persists, please contact a member of the PR2 staff team.";
	public static inline var ART_RASTER_STOP_WARNING:String = "Error: Some art didn't load correctly. Don't worry! You can still play the level.\n\nYou can prevent this in the future by enabling lossless art quality in the options menu.";
	private static inline var ICE_OVERLAY_NAME:String = "iceOverlay";
	private static inline var ART_RASTER_CANVAS_NAME:String = "artRasterCanvas";
	// View-window culling (mirrors Flash background.Background.updateViewWindow):
	// only blocks within VIEW_MARGIN_SEGMENTS of the visible stage are attached to
	// blockLayer. Without this the whole level (18k+ blocks on big maps) stays on
	// the display list, giving one WebGL draw call per block and ~3fps; Flash keeps
	// just the on-screen window attached and recycles blocks as the camera scrolls.
	public static inline var VIEW_MARGIN_SEGMENTS:Int = 2;
	// Only rebuild the window once the camera has scrolled this many segments, so a
	// slow pan does not churn addChild/removeChild every frame. Keep this no larger
	// than the margin, otherwise blocks can enter the visible stage before the
	// window refreshes and visibly pop in at the edge.
	public static inline var VIEW_REBUILD_THRESHOLD:Int = VIEW_MARGIN_SEGMENTS;

	private final level:ServerLevel;
	private var offsetX:Float;
	private var offsetY:Float;
	// Unrounded camera offset, kept so the parallax layers can re-derive their
	// rounded per-plane offset whenever the committed rotation changes.
	private var rawOffsetX:Float;
	private var rawOffsetY:Float;
	// Holds the parallax art layers and the block layer — everything that spins
	// when a rotate block fires. Mirrors Flash, which rotates the whole Course
	// during the tween (worldContainer here) and bakes the committed 90-degree
	// step into blockBackground/bg* (blockLayer + art layer rotation here). The
	// solid background and themed art-background container stay direct children
	// of `this` so they remain upright, like Flash's counter-rotated `bg`.
	private final worldContainer:Sprite = new Sprite();
	// Committed course rotation (a multiple of 90), baked about the block layer's
	// own origin. `tweenRotation` is the in-progress smooth spin applied to the
	// whole world about the screen centre while a rotate block animates.
	private var courseRotation:Int = 0;
	private var tweenRotation:Float = 0;
	private final blockLayer:Sprite = new Sprite();
	private var backCharacterLayer:Null<Sprite>;
	private var frontCharacterLayer:Null<Sprite>;
	private var effectLayer:Null<Sprite>;
	private final artLayerContainers:Array<Sprite> = [];
	private final artRasterTileLayers:Array<ArtRasterTiles> = [];
	private var solidBackground:Null<Shape>;
	private var artBackgroundContainer:Null<Sprite>;
	private var currentBackgroundColor:Int;
	private var artBackgroundTintScale:Float = 1;
	private final artBackgroundChildren:Array<DisplayObject> = [];
	private var artCachingEnabled:Bool = true;
	private final blockDisplays:Map<String, Sprite> = new Map();
	// Block sprites keyed by segment (column -> row -> sprite), mirroring Flash's
	// blockArray[segX][segY]. Used to attach/detach only the on-screen window
	// without scanning every block. Every block lives here whether attached or not.
	private final blockGrid:Map<Int, Map<Int, Sprite>> = new Map();
	private var viewColMin:Int = 0;
	private var viewColMax:Int = 0;
	private var viewRowMin:Int = 0;
	private var viewRowMax:Int = 0;
	private var viewInitialized:Bool = false;
	private final arrowDisplays:Map<String, PR2MovieClip> = new Map();
	private final arrowCompletionHandlers:Map<String, Event->Void> = new Map();
	private final moveArrowDisplays:Map<String, PR2MovieClip> = new Map();
	private final waterRippleFrames:Map<String, Int> = new Map();
	private final blockBounceVelocities:Map<String, Point> = new Map();
	private final artDrawCursors:Array<ArtDrawCursor> = [];
	private var nextBlockToDraw:Int = 0;
	private var nextArtLayerToDraw:Int = 0;
	private var drawnArtItems:Int = 0;
	private var totalArtItems:Int = 0;
	private var incrementalBlocks:Bool = false;
	private var blocksPerFrame:Int = DEFAULT_BLOCKS_PER_FRAME;
	private final drawArtEnabled:Bool;
	private final artOptions:Null<ArtRenderOptions>;
	private final artRasterBudget:ArtRasterBudget;
	private final blockFactory:ServerLevelBlockFactory;
	private var attemptedArtItems:Int = 0;
	private var artLoadWarningShown:Bool = false;
	private var rasterStopNotified:Bool = false;
	private var artRasterAttachActive:Bool = false;
	public var artWarningMessage(default, null):Null<String>;
	public var stoppedRasterizing(default, null):Bool = false;
	public var artProfileLastMs(default, null):Float = 0;
	public var artProfileLastLayer(default, null):Int = -1;
	public var artProfileLastAction(default, null):Int = -1;
	public var artProfileLastKind(default, null):String = "";
	public var artProfileLastPath(default, null):String = "";
	public var artProfileLastMode(default, null):String = "";
	public var artProfileLastItems(default, null):Int = 0;
	public var artProfileLastValues(default, null):Int = 0;
	public var artProfileLastTiles(default, null):Int = 0;
	public var artProfileLastSpanX(default, null):Int = 0;
	public var artProfileLastSpanY(default, null):Int = 0;
	public var artProfileSlowCount(default, null):Int = 0;
	public var artProfileMaxMs(default, null):Float = 0;
	public var artProfileMaxLayer(default, null):Int = -1;
	public var artProfileMaxAction(default, null):Int = -1;
	public var artProfileMaxKind(default, null):String = "";
	public var artProfileMaxPath(default, null):String = "";
	public var artProfileMaxMode(default, null):String = "";
	public var artProfileMaxItems(default, null):Int = 0;
	public var artProfileMaxValues(default, null):Int = 0;
	public var artProfileMaxTiles(default, null):Int = 0;
	public var artProfileMaxSpanX(default, null):Int = 0;
	public var artProfileMaxSpanY(default, null):Int = 0;

	public function new(level:ServerLevel, ?focusBlock:DecodedBlock, focusScreenX:Float = DEFAULT_FOCUS_X, focusScreenY:Float = DEFAULT_FOCUS_Y,
			incrementalBlocks:Bool = false, blocksPerFrame:Int = DEFAULT_BLOCKS_PER_FRAME, ?artOptions:ArtRenderOptions) {
		super();
		this.level = level;
		blockFactory = new ServerLevelBlockFactory(this);
		this.incrementalBlocks = incrementalBlocks;
		this.blocksPerFrame = blocksPerFrame <= 0 ? DEFAULT_BLOCKS_PER_FRAME : blocksPerFrame;
		this.drawArtEnabled = Settings.getValue(Settings.DRAW_ART, true) != false;
		this.artOptions = artOptions;
		this.artRasterBudget = new ArtRasterBudget(artOptions != null && artOptions.rasterTileLimit != null ? artOptions.rasterTileLimit
			: DEFAULT_ART_RASTER_TILE_LIMIT, notifyRasterStopped);
		this.currentBackgroundColor = level.bgColor;

		var focus = focusBlock == null ? firstRenderableBlock(level) : focusBlock;
		if (focus == null) {
			offsetX = 0;
			offsetY = 0;
		} else {
			offsetX = focusScreenX - focus.x;
			offsetY = focusScreenY - focus.y;
		}
		rawOffsetX = offsetX;
		rawOffsetY = offsetY;

		drawBackground();
		drawArtBackground();
		// The block and parallax art layers live inside the rotating world
		// container; the solid background and art-background bitmap above stay on
		// `this` so they remain upright when the course spins.
		addChild(worldContainer);
		// Course.attachBackgrounds places bg3/bg2/bg1 behind the map and bg4/bg5
		// in front. Preserve that authored depth order instead of flattening all
		// five drawing planes behind the blocks.
		drawArtLayer(2);
		drawArtLayer(1);
		drawArtLayer(0);
		drawBlocks();
		drawArtLayer(3);
		drawArtLayer(4);
		applyBackgroundColorTransforms();
		setArtCaching(true);
		if (incrementalBlocks && totalArtItems > 0) {
			addEventListener(Event.ENTER_FRAME, drawArtBatch);
		}
	}

	public function isBlockDrawingComplete():Bool {
		return nextBlockToDraw >= level.blocks.length;
	}

	public static inline function isArtDrawBatchWithinLimits(tileCount:Int, tileSpanX:Int, tileSpanY:Int):Bool {
		return tileCount <= ART_DRAW_BATCH_MAX_TILE_COUNT && tileSpanX <= ART_DRAW_BATCH_MAX_TILE_SPAN && tileSpanY <= ART_DRAW_BATCH_MAX_TILE_SPAN;
	}

	public function isDrawingComplete():Bool {
		return isBlockDrawingComplete() && drawnArtItems >= totalArtItems;
	}

	public function drawnBlockCount():Int {
		return nextBlockToDraw;
	}

	public function drawnArtItemCount():Int {
		return drawnArtItems;
	}

	public function artProfileDebugState():String {
		if (artProfileLastAction < 0 && artProfileMaxAction < 0) {
			return "";
		}
		return ';artLastMs=${round1(artProfileLastMs)}'
			+ ';artLastLayer=$artProfileLastLayer'
			+ ';artLastAction=$artProfileLastAction'
			+ ';artLastKind=$artProfileLastKind'
			+ ';artLastPath=$artProfileLastPath'
			+ ';artLastMode=$artProfileLastMode'
			+ ';artLastItems=$artProfileLastItems'
			+ ';artLastValues=$artProfileLastValues'
			+ ';artLastTiles=$artProfileLastTiles'
			+ ';artLastSpan=${artProfileLastSpanX}x${artProfileLastSpanY}'
			+ ';artSlow=$artProfileSlowCount'
			+ ';artMaxMs=${round1(artProfileMaxMs)}'
			+ ';artMaxLayer=$artProfileMaxLayer'
			+ ';artMaxAction=$artProfileMaxAction'
			+ ';artMaxKind=$artProfileMaxKind'
			+ ';artMaxPath=$artProfileMaxPath'
			+ ';artMaxMode=$artProfileMaxMode'
			+ ';artMaxItems=$artProfileMaxItems'
			+ ';artMaxValues=$artProfileMaxValues'
			+ ';artMaxTiles=$artProfileMaxTiles'
			+ ';artMaxSpan=${artProfileMaxSpanX}x${artProfileMaxSpanY}';
	}

	// World points handed in here (player, eggs, mines) are already expressed in
	// the current rotated frame, so they only need the camera translation plus
	// the in-progress tween spin about the screen centre. The committed course
	// rotation is baked into the block layer, which stores its blocks in the
	// original frame, so it must not be applied again here.
	public function worldToScreen(x:Float, y:Float):Point {
		var point = new Point(x + offsetX, y + offsetY);
		return tweenRotation == 0 ? point : worldContainer.transform.matrix.transformPoint(point);
	}

	public function worldToCharacterLayer(x:Float, y:Float):Point {
		// Character planes now mirror Flash frontBackground/backBackground and
		// carry the camera translation themselves, so their local coordinates are
		// the unchanged map/world coordinates.
		return new Point(x, y);
	}

	public function screenToWorld(x:Float, y:Float):Point {
		var point = new Point(x, y);
		if (tweenRotation != 0) {
			var inverse = worldContainer.transform.matrix.clone();
			inverse.invert();
			point = inverse.transformPoint(point);
		}
		return new Point(point.x - offsetX, point.y - offsetY);
	}

	public function cameraOffset():Point {
		return new Point(offsetX, offsetY);
	}

	/** Convert an original-frame block point into the committed rotated world frame. */
	public function blockWorldToRotatedWorld(x:Float, y:Float):Point {
		return layerMatrix(0, 0).transformPoint(new Point(x, y));
	}

	/**
		Applies the rotate-block course rotation. `courseRotation` is the committed
		multiple of 90 degrees, baked into the block and parallax layers about their
		own origin (Flash `blockBackground.rotation`/`bg*.rotation`). `tweenRotation`
		is the in-progress smooth spin applied to the whole world about the screen
		centre while the block animates (Flash rotating the Course during the tween).
	**/
	public function setCourseRotation(courseRotation:Int, tweenRotation:Float):Void {
		if (this.courseRotation != courseRotation) {
			this.courseRotation = courseRotation;
			applyLayerTransforms();
			updateViewWindow(true);
			updateArtViewWindows(true);
		}
		if (this.tweenRotation != tweenRotation) {
			this.tweenRotation = tweenRotation;
			applyTweenRotation();
			updateViewWindow(false);
			updateArtViewWindows(false);
		}
	}

	// Builds the block/art layer matrix in the same authored world frame used by
	// gameplay. Committed course rotation turns about world (0, 0).
	private function layerMatrix(translateX:Float, translateY:Float, includeCourseRotation:Bool = true):Matrix {
		var matrix = new Matrix();
		if (includeCourseRotation && courseRotation != 0) {
			matrix.rotate(courseRotation * Math.PI / 180);
		}
		matrix.translate(translateX, translateY);
		return matrix;
	}

	private function applyLayerTransforms():Void {
		blockLayer.transform.matrix = layerMatrix(offsetX, offsetY);
		// Match Flash Background.setPos: characters retain map/world coordinates
		// while their front/back parent planes carry the camera translation.
		if (backCharacterLayer != null) {
			backCharacterLayer.transform.matrix = layerMatrix(offsetX, offsetY, false);
		}
		if (frontCharacterLayer != null) {
			frontCharacterLayer.transform.matrix = layerMatrix(offsetX, offsetY, false);
		}
		if (effectLayer != null) {
			// Attack effects use the same already-rotated world coordinates as the
			// character plane. They still need the camera translation, especially
			// for editor levels whose authored coordinates are far from (0, 0).
			effectLayer.transform.matrix = layerMatrix(offsetX, offsetY, false);
		}
		for (i in 0...artLayerContainers.length) {
			if (artLayerContainers[i] == null) {
				continue;
			}
			var layer = level.artLayers[i];
			artLayerContainers[i].transform.matrix = layerMatrix(parallaxOffset(rawOffsetX, layer.scale), parallaxOffset(rawOffsetY, layer.scale));
		}
	}

	private function applyTweenRotation():Void {
		if (tweenRotation == 0) {
			worldContainer.transform.matrix = new Matrix();
			return;
		}
		var pivotX = Constants.STAGE_WIDTH / 2;
		var pivotY = Constants.STAGE_HEIGHT / 2;
		var matrix = new Matrix();
		matrix.translate(-pivotX, -pivotY);
		matrix.rotate(tweenRotation * Math.PI / 180);
		matrix.translate(pivotX, pivotY);
		worldContainer.transform.matrix = matrix;
	}

	/** Applies Course.setPos camera translation to world and parallax layers. */
	public function setCameraOffset(x:Float, y:Float):Void {
		rawOffsetX = x;
		rawOffsetY = y;
		offsetX = Math.round(x);
		offsetY = Math.round(y);
		applyLayerTransforms();
		updateViewWindow(false);
		updateArtViewWindows(false);
	}

	/** Applies Flash `Course.setColor`/`Background.applyColorTransform` to rendered planes. */
	public function setBackgroundColor(color:Int):Void {
		currentBackgroundColor = color;
		redrawSolidBackground();
		applyBackgroundColorTransforms();
	}

	public function setArtCaching(enabled:Bool):Void {
		artCachingEnabled = enabled;
		for (container in artLayerContainers) {
			if (container == null) {
				continue;
			}
			for (i in 0...container.numChildren) {
				var child = container.getChildAt(i);
				if (child.name == ART_RASTER_CANVAS_NAME) {
					child.cacheAsBitmap = false;
				} else {
					child.cacheAsBitmap = enabled;
				}
			}
		}
	}

	public function debugArtCachingEnabled():Bool {
		return artCachingEnabled;
	}

	public function setBlockAlpha(worldX:Int, worldY:Int, alpha:Float):Void {
		var display = blockDisplays.get(blockKey(worldX, worldY));
		if (display != null) {
			display.alpha = alpha;
		}
	}

	public function setBlockColorMultiplier(worldX:Int, worldY:Int, multiplier:Float):Void {
		var display = blockDisplays.get(blockKey(worldX, worldY));
		if (display != null) {
			display.transform.colorTransform = new ColorTransform(multiplier, multiplier, multiplier);
		}
	}

	public function setBlockIceOverlayAlpha(worldX:Int, worldY:Int, alpha:Float):Void {
		var display = blockDisplays.get(blockKey(worldX, worldY));
		if (display == null) {
			return;
		}
		var overlay = display.getChildByName(ICE_OVERLAY_NAME);
		if (alpha <= 0) {
			if (overlay != null) {
				display.removeChild(overlay);
			}
			return;
		}
		if (overlay == null) {
			overlay = createIceOverlay();
			display.addChild(overlay);
		}
		overlay.alpha = alpha;
	}

	public function blockIceOverlayAlphaAt(worldX:Int, worldY:Int):Float {
		var display = blockDisplays.get(blockKey(worldX, worldY));
		var overlay = display == null ? null : display.getChildByName(ICE_OVERLAY_NAME);
		return overlay == null ? 0 : overlay.alpha;
	}

	public function blockIsBouncingAt(worldX:Int, worldY:Int):Bool {
		return blockBounceVelocities.exists(blockKey(worldX, worldY));
	}

	public function attachBackCharacterLayer(layer:Sprite):Void {
		backCharacterLayer = layer;
		if (layer.parent == worldContainer) {
			return;
		}
		// Flash keeps a swimming character in `backBackground`, the plane sitting
		// between the rear parallax art (bg1/bg2/bg3) and the block map. Insert the
		// back character layer just below the block layer inside the rotating world
		// so a character in water renders behind the blocks but still in front of
		// the background art. Placing it below `worldContainer` (as before) buried
		// it behind every background art layer, so it vanished in water on any
		// level with a drawn background (e.g. Underwater World).
		worldContainer.addChildAt(layer, worldContainer.getChildIndex(blockLayer));
	}

	// Test seam: depth of `child` within the rotating world container, or -1 when
	// it is not a direct child of it. Lets the shell test assert the back
	// character layer sits below the blocks (and thus above the background art).
	@:allow(pr2.gameplay.GameShellMountTest)
	private function worldChildDepth(child:openfl.display.DisplayObject):Int {
		return child.parent == worldContainer ? worldContainer.getChildIndex(child) : -1;
	}

	@:allow(pr2.gameplay.GameShellMountTest)
	private function blockLayerDepth():Int {
		return worldContainer.getChildIndex(blockLayer);
	}

	public function attachFrontCharacterLayer(layer:Sprite):Void {
		frontCharacterLayer = layer;
		if (layer.parent == worldContainer) {
			return;
		}
		// Flash order is blockBackground, frontBackground, effectBackground,
		// bg4, bg5. Keep the player above the blocks but below art 0 and art 00.
		var firstForegroundArt = artLayerContainers.length > 3 ? artLayerContainers[3] : null;
		if (firstForegroundArt != null && firstForegroundArt.parent == worldContainer) {
			worldContainer.addChildAt(layer, worldContainer.getChildIndex(firstForegroundArt));
		} else {
			worldContainer.addChild(layer);
		}
	}

	public function attachEffectLayer(layer:Sprite):Void {
		effectLayer = layer;
		layer.transform.matrix = layerMatrix(offsetX, offsetY, false);
		if (layer.parent == worldContainer) {
			return;
		}
		// Effects sit above frontBackground (characters) but remain below the two
		// foreground art planes, matching Course.attachBackgrounds in Flash.
		var firstForegroundArt = artLayerContainers.length > 3 ? artLayerContainers[3] : null;
		if (firstForegroundArt != null && firstForegroundArt.parent == worldContainer) {
			worldContainer.addChildAt(layer, worldContainer.getChildIndex(firstForegroundArt));
		} else {
			worldContainer.addChild(layer);
		}
	}

	@:allow(pr2.gameplay.GameShellMountTest)
	private function artLayerDepth(index:Int):Int {
		if (index < 0 || index >= artLayerContainers.length) {
			return -1;
		}
		return worldChildDepth(artLayerContainers[index]);
	}

	public function animateArrow(worldX:Int, worldY:Int):Void {
		var key = blockKey(worldX, worldY);
		var arrow = arrowDisplays.get(key);
		if (arrow == null) {
			return;
		}
		if (arrow.currentFrame < 5) {
			arrow.gotoAndPlay(arrow.currentFrame + 1);
		} else if (arrow.currentFrame > 5) {
			arrow.gotoAndPlay(arrow.currentFrame - 1);
		}
	}

	public function arrowFrameAt(worldX:Int, worldY:Int):Null<Int> {
		var arrow = arrowDisplays.get(blockKey(worldX, worldY));
		return arrow == null ? null : arrow.currentFrame;
	}

	public function activateVanish(worldX:Int, worldY:Int):Void {
		var display = blockDisplays.get(blockKey(worldX, worldY));
		if (display != null) {
			display.alpha = 0;
		}
	}

	public function animateBlockBump(worldX:Int, worldY:Int, hitX:Float = 0, hitY:Float = -15):Void {
		var key = blockKey(worldX, worldY);
		if (!blockDisplays.exists(key)) {
			return;
		}
		blockBounceVelocities.set(key, new Point(hitX, hitY));
		addEventListener(Event.ENTER_FRAME, onBlockBounceFrame);
	}

	public function triggerWaterRipple(worldX:Int, worldY:Int):Void {
		var key = blockKey(worldX, worldY);
		var display = blockDisplays.get(key);
		if (display == null) {
			return;
		}
		display.alpha -= 0.1;
		if (display.alpha < 0.5) {
			display.alpha = 0.5;
		}
		waterRippleFrames.set(key, 1);
		addEventListener(Event.ENTER_FRAME, onWaterRippleFrame);
	}

	public function blockAlphaAt(worldX:Int, worldY:Int):Null<Float> {
		var display = blockDisplays.get(blockKey(worldX, worldY));
		return display == null ? null : display.alpha;
	}

	public function removeBlockDisplay(worldX:Int, worldY:Int):Bool {
		var key = blockKey(worldX, worldY);
		var display = blockDisplays.get(key);
		if (display == null) {
			return false;
		}
		blockDisplays.remove(key);
		removeFromBlockGrid(worldX, worldY);
		arrowDisplays.remove(key);
		moveArrowDisplays.remove(key);
		blockBounceVelocities.remove(key);
		disposeAnimatedChildren(display);
		if (display.parent != null) {
			display.parent.removeChild(display);
		}
		return true;
	}

	public function moveBlockDisplay(fromWorldX:Int, fromWorldY:Int, toWorldX:Int, toWorldY:Int):Void {
		if (fromWorldX == toWorldX && fromWorldY == toWorldY) {
			return;
		}
		var fromKey = blockKey(fromWorldX, fromWorldY);
		var display = blockDisplays.get(fromKey);
		if (display == null) {
			return;
		}

		blockDisplays.remove(fromKey);
		removeFromBlockGrid(fromWorldX, fromWorldY);

		display.x = toWorldX;
		display.y = toWorldY;
		var toKey = blockKey(toWorldX, toWorldY);
		blockDisplays.set(toKey, display);
		var bounceVelocity = blockBounceVelocities.get(fromKey);
		if (bounceVelocity != null) {
			blockBounceVelocities.remove(fromKey);
			blockBounceVelocities.set(toKey, bounceVelocity);
		}
		var moveArrow = moveArrowDisplays.get(fromKey);
		if (moveArrow != null) {
			moveArrowDisplays.remove(fromKey);
			moveArrowDisplays.set(toKey, moveArrow);
		}
		addToBlockGrid(toWorldX, toWorldY, display);

		if (isInView(segmentOf(toWorldX), segmentOf(toWorldY))) {
			if (display.parent != blockLayer) {
				blockLayer.addChild(display);
			}
		} else if (display.parent == blockLayer) {
			blockLayer.removeChild(display);
		}
	}

	public function showMoveBlockArrow(worldX:Int, worldY:Int, direction:Int):Void {
		var key = blockKey(worldX, worldY);
		var display = blockDisplays.get(key);
		if (display == null) {
			return;
		}
		var arrow = moveArrowDisplays.get(key);
		if (arrow == null) {
			arrow = PR2MovieClip.fromLinkage("MoveArrow", {maxNestedDepth: 2});
			arrow.x = TILE_SIZE / 2;
			arrow.y = TILE_SIZE / 2;
			display.addChild(arrow);
			moveArrowDisplays.set(key, arrow);
		}
		arrow.rotation = moveBlockArrowRotation(direction);
	}

	public function hideMoveBlockArrow(worldX:Int, worldY:Int):Void {
		var key = blockKey(worldX, worldY);
		var arrow = moveArrowDisplays.get(key);
		if (arrow == null) {
			return;
		}
		if (arrow.parent != null) {
			arrow.parent.removeChild(arrow);
		}
		moveArrowDisplays.remove(key);
	}

	public function moveBlockArrowRotationAt(worldX:Int, worldY:Int):Null<Float> {
		var arrow = moveArrowDisplays.get(blockKey(worldX, worldY));
		return arrow == null ? null : arrow.rotation;
	}

	public function showMineExplosion(worldX:Float, worldY:Float, playSound:Bool = true):MineExplosion {
		var effect = new MineExplosion(worldX, worldY, offsetX, offsetY, playSound);
		blockLayer.addChild(effect);
		return effect;
	}

	public function showMineAppear(worldX:Float, worldY:Float, tileWorldX:Int, tileWorldY:Int, rotationDegrees:Float = 0, playSound:Bool = true):MineAppear {
		var effect = new MineAppear(worldX, worldY, rotationDegrees, offsetX, offsetY, function():Void {
			if (!blockDisplays.exists(blockKey(tileWorldX, tileWorldY))) {
				addBlockDisplay(new DecodedBlock(ObjectCodes.BLOCK_MINE, tileWorldX, tileWorldY));
			}
		}, playSound);
		blockLayer.addChild(effect);
		return effect;
	}

	public function showTeleportPop(worldX:Float, worldY:Float, playSound:Bool = true):TeleportPop {
		var effect = new TeleportPop(worldX, worldY, offsetX, offsetY, playSound);
		blockLayer.addChild(effect);
		return effect;
	}

	public function worldEffectLayer():DisplayObjectContainer {
		return blockLayer;
	}

	public function resetRuntimeState():Void {
		clearRuntimeEffects();
		setCourseRotation(0, 0);
		updateViewWindow(true);
	}

	public function teleportPopCountForTests():Int {
		var count = 0;
		for (i in 0...blockLayer.numChildren) {
			if (Std.isOfType(blockLayer.getChildAt(i), TeleportPop)) {
				count++;
			}
		}
		return count;
	}

	private function clearRuntimeEffects():Void {
		var i = blockLayer.numChildren - 1;
		while (i >= 0) {
			var child = blockLayer.getChildAt(i);
			if (Std.isOfType(child, TeleportPop)) {
				(cast child : TeleportPop).remove();
			} else if (Std.isOfType(child, MineExplosion)) {
				(cast child : MineExplosion).remove();
			} else if (Std.isOfType(child, MineAppear)) {
				(cast child : MineAppear).remove(false);
			} else if (Std.isOfType(child, BlockPiece)) {
				(cast child : BlockPiece).remove();
			}
			i--;
		}
	}

	public function showBlockPieces(linkage:String, worldX:Float, worldY:Float, count:Int, spreadX:Float, spreadY:Float,
			spreadRot:Float, gravity:Float = BlockPiece.GRAVITY, friction:Float = BlockPiece.FRICTION, fadeRate:Float = BlockPiece.FADE_RATE,
			?random:Void->Float):Array<BlockPiece> {
		var nextRandom = random == null ? Math.random : random;
		var pieces:Array<BlockPiece> = [];
		for (_ in 0...count) {
			var piece = new BlockPiece(linkage, gravity, friction, fadeRate, spreadX, spreadY, spreadRot, worldX + nextRandom() * TILE_SIZE,
				worldY + nextRandom() * TILE_SIZE, nextRandom);
			blockLayer.addChild(piece);
			pieces.push(piece);
		}
		return pieces;
	}

	/** Brick-break motion using six actual cropped sections of a basic-block bitmap. */
	public function showBasicBlockPieces(worldX:Int, worldY:Int, count:Int = 6, spreadX:Float = 10, spreadY:Float = 10,
			spreadRot:Float = 25, ?random:Void->Float):Array<BlockPiece> {
		var source = blockDisplays.get(blockKey(worldX, worldY));
		if (source == null) {
			return showBlockPieces("BrickPieceGraphic", worldX, worldY, count, spreadX, spreadY, spreadRot, 0.75, 0.95, 0.05, random);
		}
		// Snapshot the actual rendered basic tile. This works for both the bitmap
		// assets used by HTML5 and the vector fallback used by headless tests, and
		// still works after collision state has hidden the source display.
		var oldX = source.x;
		var oldY = source.y;
		var oldAlpha = source.alpha;
		source.x = 0;
		source.y = 0;
		source.alpha = 1;
		var data = new BitmapData(TILE_SIZE, TILE_SIZE, true, 0);
		data.draw(source);
		source.x = oldX;
		source.y = oldY;
		source.alpha = oldAlpha;
		var nextRandom = random == null ? Math.random : random;
		var pieces:Array<BlockPiece> = [];
		for (i in 0...count) {
			var section = i % 6;
			var column = section % 3;
			var row = Std.int(section / 3);
			var left = Std.int(Math.floor(data.width * column / 3));
			var top = Std.int(Math.floor(data.height * row / 2));
			var right = Std.int(Math.floor(data.width * (column + 1) / 3));
			var bottom = Std.int(Math.floor(data.height * (row + 1) / 2));
			var fragmentData = new BitmapData(right - left, bottom - top, true, 0);
			fragmentData.copyPixels(data, new Rectangle(left, top, right - left, bottom - top), new Point());
			var fragment = new Bitmap(fragmentData);
			fragment.width = TILE_SIZE / 3;
			fragment.height = TILE_SIZE / 2;
			var piece = new BlockPiece(null, 0.75, 0.95, 0.05, spreadX, spreadY, spreadRot,
				worldX + nextRandom() * TILE_SIZE, worldY + nextRandom() * TILE_SIZE, nextRandom, fragment);
			blockLayer.addChild(piece);
			pieces.push(piece);
		}
		data.dispose();
		return pieces;
	}

	private static inline function parallaxOffset(screenOffset:Float, scale:Float):Float {
		return Math.round(screenOffset * scale);
	}

	public static inline function isStartBlockCode(code:Int):Bool {
		return code >= ObjectCodes.BLOCK_START1 && code <= ObjectCodes.BLOCK_START4;
	}

	public static inline function isSpawnMarkerBlockCode(code:Int):Bool {
		return isStartBlockCode(code) || code == ObjectCodes.BLOCK_MINION_EGG;
	}

	public static function blockAssetPath(code:Int):String {
		return switch (code) {
			case ObjectCodes.BLOCK_BASIC1: "assets/blocks/basic1.png";
			case ObjectCodes.BLOCK_BASIC2: "assets/blocks/basic2.png";
			case ObjectCodes.BLOCK_BASIC3: "assets/blocks/basic3.png";
			case ObjectCodes.BLOCK_BASIC4: "assets/blocks/basic4.png";
			case ObjectCodes.BLOCK_BRICK: "assets/blocks/brick.png";
			case ObjectCodes.BLOCK_MINE: "assets/blocks/mine_block.png";
			case ObjectCodes.BLOCK_ITEM: "assets/blocks/item.png";
			case ObjectCodes.BLOCK_START1 | ObjectCodes.BLOCK_START2 | ObjectCodes.BLOCK_START3 | ObjectCodes.BLOCK_START4: "assets/blocks/start.png";
			case ObjectCodes.BLOCK_ICE: "assets/blocks/ice.png";
			case ObjectCodes.BLOCK_FINISH: "assets/blocks/finish.png";
			case ObjectCodes.BLOCK_CRUMBLE: "assets/blocks/crumble.png";
			case ObjectCodes.BLOCK_VANISH: "assets/blocks/vanish.png";
			case ObjectCodes.BLOCK_MOVE: "assets/blocks/move.png";
			case ObjectCodes.BLOCK_WATER: "assets/blocks/water.png";
			case ObjectCodes.BLOCK_ROTATE_RIGHT: "assets/blocks/rotate_right.png";
			case ObjectCodes.BLOCK_ROTATE_LEFT: "assets/blocks/rotate_left.png";
			case ObjectCodes.BLOCK_PUSH: "assets/blocks/push.png";
			case ObjectCodes.BLOCK_SAFETY: "assets/blocks/safety_net.png";
			case ObjectCodes.BLOCK_ITEM_INF: "assets/blocks/infinite_item.png";
			case ObjectCodes.BLOCK_HAPPY: "assets/blocks/happy.png";
			case ObjectCodes.BLOCK_SAD: "assets/blocks/sad.png";
			case ObjectCodes.BLOCK_HEART: "assets/blocks/heart.png";
			case ObjectCodes.BLOCK_TIME: "assets/blocks/time.png";
			case ObjectCodes.BLOCK_CUSTOM_STATS: "assets/blocks/custom_stats.png";
			case ObjectCodes.BLOCK_TELEPORT: "assets/blocks/teleport_block.png";
			// ArrowBlock uses a basic2 tile as its base (Blocks.getBlock) and adds
			// the rotated arrow overlay on top; see arrowOverlayAssetPath.
			case ObjectCodes.BLOCK_ARROW_DOWN | ObjectCodes.BLOCK_ARROW_UP | ObjectCodes.BLOCK_ARROW_LEFT | ObjectCodes.BLOCK_ARROW_RIGHT:
				"assets/blocks/basic2.png";
			default: "";
		}
	}

	/** Animate-exported vector used by the editor preview. */
	public static inline function arrowOverlayAssetPath():String {
		return "assets/svg/blocks/arrow_overlay.svg";
	}

	/**
		Arrow overlay rotation in degrees, matching ArrowUp/Down/Left/RightBlock's
		`rot` argument to ArrowBlock. Null for non-arrow blocks.
	**/
	public static function arrowOverlayRotation(code:Int):Null<Float> {
		return switch (code) {
			case ObjectCodes.BLOCK_ARROW_UP: 0;
			case ObjectCodes.BLOCK_ARROW_DOWN: 180;
			case ObjectCodes.BLOCK_ARROW_LEFT: -90;
			case ObjectCodes.BLOCK_ARROW_RIGHT: 90;
			default: null;
		}
	}

	public static function artBackgroundAssetPath(code:Int):String {
		return switch (code) {
			case 201: "assets/svg/backgrounds/bg1.svg";
			case 202: "assets/svg/backgrounds/bg2.svg";
			case 203: "assets/svg/backgrounds/bg3.svg";
			case 204: "assets/svg/backgrounds/bg4.svg";
			case 205: "assets/svg/backgrounds/bg5.svg";
			case 206: "assets/svg/backgrounds/bg6.svg";
			case 207: "assets/svg/backgrounds/bg7.svg";
			default: "";
		}
	}

	public static function stampAssetPath(code:Int):String {
		return switch (code) {
			case 0: "assets/svg/stamps/tree1.svg";
			case 1: "assets/svg/stamps/tree2.svg";
			case 2: "assets/svg/stamps/tree3.svg";
			case 3: "assets/svg/stamps/petrified_tree.svg";
			case 5: "assets/svg/stamps/rock1.svg";
			case 6: "assets/svg/stamps/rock2.svg";
			case 7: "assets/svg/stamps/spire1.svg";
			case 8: "assets/svg/stamps/spire2.svg";
			default: "";
		}
	}

	private function drawBackground():Void {
		solidBackground = new Shape();
		redrawSolidBackground();
		addChild(solidBackground);
	}

	private function drawBlocks():Void {
		blockLayer.x = offsetX;
		blockLayer.y = offsetY;
		worldContainer.addChild(blockLayer);
		// Establish the initial window from the start-focus offset so blocks that
		// fall on screen are attached as they are created, and the rest stay off
		// the display list until the camera scrolls to them.
		updateViewWindow(true);
		if (incrementalBlocks) {
			addEventListener(Event.ENTER_FRAME, drawBlockBatch);
			return;
		}
		drawNextBlocks(level.blocks.length);
	}

	private function drawBlockBatch(event:Event):Void {
		drawNextBlocks(blocksPerFrame, Timer.stamp() + RENDER_FRAME_ESCAPE_SECONDS);
		if (isBlockDrawingComplete()) {
			removeEventListener(Event.ENTER_FRAME, drawBlockBatch);
		}
	}

	private function drawArtBatch(event:Event):Void {
		var deadline = Timer.stamp() + RENDER_FRAME_ESCAPE_SECONDS;
		try {
			drawNextArtItemsForFrame(deadline);
			if (Timer.stamp() < deadline) {
				attachArtRasterTiles(ART_RASTER_ATTACH_TILES_PER_FRAME, deadline);
			}
		} catch (error:Dynamic) {
			handleArtDrawFailure(error);
		}
		if (drawnArtItems >= totalArtItems) {
			removeEventListener(Event.ENTER_FRAME, drawArtBatch);
			finishArtRasterAttaching();
		}
	}

	private function drawNextArtItemsForFrame(escapeDeadline:Float):Void {
		var deadline = blocksPerFrame == DEFAULT_BLOCKS_PER_FRAME
			? Math.min(Timer.stamp() + ART_DRAW_FRAME_BUDGET_SECONDS, escapeDeadline)
			: escapeDeadline;
		var drawnThisFrame = 0;
		var actionBatchLimit = blocksPerFrame == DEFAULT_BLOCKS_PER_FRAME ? ART_DRAW_ACTION_BATCH_LIMIT : 1;
		var maxItemsThisFrame = blocksPerFrame == DEFAULT_BLOCKS_PER_FRAME ? 1000000 : blocksPerFrame;
		while (drawnArtItems < totalArtItems && drawnThisFrame < maxItemsThisFrame && (drawnThisFrame == 0 || Timer.stamp() < deadline)) {
			var before = drawnArtItems;
			drawNextArtItems(actionBatchLimit, deadline);
			if (drawnArtItems == before) {
				return;
			}
			drawnThisFrame += drawnArtItems - before;
		}
	}

	private function onWaterRippleFrame(event:Event):Void {
		for (key in [for (k in waterRippleFrames.keys()) k]) {
			var display = blockDisplays.get(key);
			if (display == null) {
				waterRippleFrames.remove(key);
				continue;
			}
			display.alpha += 0.03;
			if (display.alpha >= 1) {
				display.alpha = 1;
				waterRippleFrames.remove(key);
			}
		}
		if (!waterRippleFrames.keys().hasNext()) {
			removeEventListener(Event.ENTER_FRAME, onWaterRippleFrame);
		}
	}

	private function onBlockBounceFrame(event:Event):Void {
		for (key in [for (k in blockBounceVelocities.keys()) k]) {
			var display = blockDisplays.get(key);
			if (display == null) {
				blockBounceVelocities.remove(key);
				continue;
			}
			var velocity = blockBounceVelocities.get(key);
			velocity.x *= 0.5;
			velocity.y *= 0.5;
			var origin = blockOrigin(key);
			display.x += velocity.x;
			display.x += (origin.x - display.x) * 0.35;
			display.y += velocity.y;
			display.y += (origin.y - display.y) * 0.35;
			if (Math.abs(origin.y - display.y) < 0.25 && Math.abs(origin.y - display.x) < 0.25) {
				display.x = origin.x;
				display.y = origin.y;
				blockBounceVelocities.remove(key);
			}
		}
		if (!blockBounceVelocities.keys().hasNext()) {
			removeEventListener(Event.ENTER_FRAME, onBlockBounceFrame);
		}
	}

	private function drawNextBlocks(limit:Int, ?deadline:Null<Float>):Void {
		var end = Std.int(Math.min(level.blocks.length, nextBlockToDraw + limit));
		var drawn = 0;
		while (nextBlockToDraw < end) {
			if (deadline != null && drawn > 0 && Timer.stamp() >= deadline) {
				break;
			}
			var block = level.blocks[nextBlockToDraw++];
			addBlockDisplay(block);
			drawn++;
		}
	}

	private function addBlockDisplay(block:DecodedBlock):Void {
		// Start and minion-egg blocks are spawn markers, not scenery. Flash's
		// gameplay Map records their positions and never adds them to the block
		// display list.
		if (isSpawnMarkerBlockCode(block.code)) {
			return;
		}
		var display = createBlockDisplay(block);
		blockDisplays.set(blockKey(block.x, block.y), display);
		addToBlockGrid(block.x, block.y, display);
		var segX = segmentOf(block.x);
		var segY = segmentOf(block.y);
		// Attach only if the block currently falls inside the view window; otherwise
		// it stays in the grid and is attached later when the camera scrolls to it.
		if (isInView(segX, segY)) {
			blockLayer.addChild(display);
		}
	}

	private function addToBlockGrid(worldX:Int, worldY:Int, display:Sprite):Void {
		var segX = segmentOf(worldX);
		var segY = segmentOf(worldY);
		var col = blockGrid.get(segX);
		if (col == null) {
			col = new Map();
			blockGrid.set(segX, col);
		}
		col.set(segY, display);
	}

	private function removeFromBlockGrid(worldX:Int, worldY:Int):Void {
		var segX = segmentOf(worldX);
		var segY = segmentOf(worldY);
		var col = blockGrid.get(segX);
		if (col == null) {
			return;
		}
		col.remove(segY);
	}

	private static inline function segmentOf(coord:Int):Int {
		return Math.round(coord / TILE_SIZE);
	}

	private inline function isInView(segX:Int, segY:Int):Bool {
		return viewInitialized && segX >= viewColMin && segX <= viewColMax && segY >= viewRowMin && segY <= viewRowMax;
	}

	private function setBlockAttached(segX:Int, segY:Int, attach:Bool):Void {
		var col = blockGrid.get(segX);
		if (col == null) {
			return;
		}
		var display = col.get(segY);
		if (display == null) {
			return;
		}
		if (attach) {
			if (display.parent != blockLayer) {
				blockLayer.addChild(display);
			}
		} else if (display.parent == blockLayer) {
			blockLayer.removeChild(display);
		}
	}

	/**
		Attaches the on-screen block window and detaches what scrolled out, mirroring
		Flash `background.Background.updateViewWindow`. Only the window perimeter is
		walked (a few hundred segment cells), never the full block list.
	**/
	private function updateViewWindow(force:Bool):Void {
		// Map the visible stage rectangle into the block layer's local (original,
		// pre-rotation) frame so culling stays correct when a rotate block spins the
		// course. Mirrors Flash background.Background.updateViewWindow, which rotates
		// the camera window into the block layer's frame before picking the column/
		// row range. The combined matrix folds in both the committed block rotation
		// and the in-progress tween, so the bounding box covers the rotated window.
		var toLocal = blockLayer.transform.matrix.clone();
		toLocal.concat(worldContainer.transform.matrix);
		toLocal.invert();
		var minX = Math.POSITIVE_INFINITY;
		var minY = Math.POSITIVE_INFINITY;
		var maxX = Math.NEGATIVE_INFINITY;
		var maxY = Math.NEGATIVE_INFINITY;
		for (corner in [new Point(0, 0), new Point(Constants.STAGE_WIDTH, 0), new Point(0, Constants.STAGE_HEIGHT),
			new Point(Constants.STAGE_WIDTH, Constants.STAGE_HEIGHT)]) {
			var local = toLocal.transformPoint(corner);
			if (local.x < minX) minX = local.x;
			if (local.x > maxX) maxX = local.x;
			if (local.y < minY) minY = local.y;
			if (local.y > maxY) maxY = local.y;
		}
		var colMin = Math.floor(minX / TILE_SIZE) - VIEW_MARGIN_SEGMENTS;
		var colMax = Math.ceil(maxX / TILE_SIZE) + VIEW_MARGIN_SEGMENTS;
		var rowMin = Math.floor(minY / TILE_SIZE) - VIEW_MARGIN_SEGMENTS;
		var rowMax = Math.ceil(maxY / TILE_SIZE) + VIEW_MARGIN_SEGMENTS;
		if (!force
			&& viewInitialized
			&& intAbs(colMin - viewColMin) <= VIEW_REBUILD_THRESHOLD
			&& intAbs(colMax - viewColMax) <= VIEW_REBUILD_THRESHOLD
			&& intAbs(rowMin - viewRowMin) <= VIEW_REBUILD_THRESHOLD
			&& intAbs(rowMax - viewRowMax) <= VIEW_REBUILD_THRESHOLD) {
			return;
		}
		// Detach cells leaving the window.
		if (viewInitialized) {
			for (segX in viewColMin...viewColMax + 1) {
				for (segY in viewRowMin...viewRowMax + 1) {
					if (segX < colMin || segX > colMax || segY < rowMin || segY > rowMax) {
						setBlockAttached(segX, segY, false);
					}
				}
			}
		}
		// Attach cells entering the window (skip those already inside the old one).
		for (segX in colMin...colMax + 1) {
			for (segY in rowMin...rowMax + 1) {
				if (!viewInitialized || segX < viewColMin || segX > viewColMax || segY < viewRowMin || segY > viewRowMax) {
					setBlockAttached(segX, segY, true);
				}
			}
		}
		viewColMin = colMin;
		viewColMax = colMax;
		viewRowMin = rowMin;
		viewRowMax = rowMax;
		viewInitialized = true;
	}

	private function updateArtViewWindows(force:Bool):Void {
		for (tiles in artRasterTileLayers) {
			if (tiles != null) {
				updateArtViewWindow(tiles, force);
			}
		}
		if (drawnArtItems >= totalArtItems) {
			finishArtRasterAttaching();
		}
	}

	private function updateArtViewWindow(tiles:ArtRasterTiles, force:Bool):Void {
		var rasterCanvas = tiles.rasterCanvas;
		if (rasterCanvas.parent == null) {
			return;
		}
		var toLocal = rasterCanvas.transform.matrix.clone();
		toLocal.concat(rasterCanvas.parent.transform.matrix);
		toLocal.concat(worldContainer.transform.matrix);
		toLocal.invert();
		var minX = Math.POSITIVE_INFINITY;
		var minY = Math.POSITIVE_INFINITY;
		var maxX = Math.NEGATIVE_INFINITY;
		var maxY = Math.NEGATIVE_INFINITY;
		for (corner in [new Point(0, 0), new Point(Constants.STAGE_WIDTH, 0), new Point(0, Constants.STAGE_HEIGHT),
			new Point(Constants.STAGE_WIDTH, Constants.STAGE_HEIGHT)]) {
			var local = toLocal.transformPoint(corner);
			if (local.x < minX) minX = local.x;
			if (local.x > maxX) maxX = local.x;
			if (local.y < minY) minY = local.y;
			if (local.y > maxY) maxY = local.y;
		}
		var tile = ART_RASTER_TILE_SIZE;
		var margin = ART_RASTER_VIEW_MARGIN_TILES * tile;
		tiles.setVisibleTileWindow(
			artTileOrigin(Std.int(Math.floor(minX))) - margin,
			artTileOrigin(Std.int(Math.floor(maxX))) + margin,
			artTileOrigin(Std.int(Math.floor(minY))) - margin,
			artTileOrigin(Std.int(Math.floor(maxY))) + margin,
			force
		);
	}

	private static inline function intAbs(value:Int):Int {
		return value < 0 ? -value : value;
	}

	private static inline function round1(value:Float):Float {
		return Math.round(value * 10) / 10;
	}

	private static inline function artTileOrigin(pixel:Int):Int {
		var tile = ART_RASTER_TILE_SIZE;
		return Std.int(Math.floor(pixel / tile)) * tile;
	}

	public function remove():Void {
		removeEventListener(Event.ENTER_FRAME, drawBlockBatch);
		removeEventListener(Event.ENTER_FRAME, drawArtBatch);
		removeEventListener(Event.ENTER_FRAME, onArtRasterAttachFrame);
		removeEventListener(Event.ENTER_FRAME, onWaterRippleFrame);
		removeEventListener(Event.ENTER_FRAME, onBlockBounceFrame);
		artRasterAttachActive = false;
		waterRippleFrames.clear();
		blockBounceVelocities.clear();
		// Dispose every arrow movie clip, including off-screen ones that culling left
		// detached from blockLayer so the tree walk below would not reach them.
		for (key in arrowDisplays.keys()) {
			var arrow = arrowDisplays.get(key);
			var handler = arrowCompletionHandlers.get(key);
			if (handler != null) {
				arrow.removeEventListener(Event.ENTER_FRAME, handler);
			}
			arrow.dispose();
		}
		arrowDisplays.clear();
		arrowCompletionHandlers.clear();
		disposeAnimatedChildren(this);
		if (parent != null) {
			parent.removeChild(this);
		}
	}

	private function disposeAnimatedChildren(container:Sprite):Void {
		var i = container.numChildren - 1;
		while (i >= 0) {
			var child = container.getChildAt(i);
			var mineExplosion = Std.downcast(child, MineExplosion);
			if (mineExplosion != null) {
				mineExplosion.remove();
				i--;
				continue;
			}
			var mineAppear = Std.downcast(child, MineAppear);
			if (mineAppear != null) {
				mineAppear.remove();
				i--;
				continue;
			}
			var blockPiece = Std.downcast(child, BlockPiece);
			if (blockPiece != null) {
				blockPiece.remove();
				i--;
				continue;
			}
			var arrowEffect = Std.downcast(child, pr2.effects.ArrowEffect);
			if (arrowEffect != null) {
				arrowEffect.remove();
				i--;
				continue;
			}
			var starEffect = Std.downcast(child, pr2.effects.StarEffect);
			if (starEffect != null) {
				starEffect.remove();
				i--;
				continue;
			}
			var physicsParticle = Std.downcast(child, pr2.character.PhysicsParticle);
			if (physicsParticle != null) {
				physicsParticle.remove();
				i--;
				continue;
			}
			var clip = Std.downcast(child, PR2MovieClip);
			if (clip != null) {
				clip.dispose();
			}
			var childContainer = Std.downcast(child, Sprite);
			if (childContainer != null) {
				disposeAnimatedChildren(childContainer);
			}
			i--;
		}
	}

	private static inline function blockKey(x:Int, y:Int):String {
		return x + "," + y;
	}

	private static function blockOrigin(key:String):Point {
		var comma = key.indexOf(",");
		return new Point(Std.parseInt(key.substring(0, comma)), Std.parseInt(key.substring(comma + 1)));
	}

	private function drawArtBackground():Void {
		if (!drawArtEnabled) {
			return;
		}
		if (level.artBackgroundCode == null) {
			return;
		}
		var backgroundCode = level.artBackgroundCode;
		artBackgroundContainer = new Sprite();
		addChild(artBackgroundContainer);
		artBackgroundTintScale = backgroundCode == 204 || backgroundCode == BG5_CODE ? 0 : 1;
		var assetPath = artBackgroundAssetPath(level.artBackgroundCode);
		if (assetPath != "" && Assets.exists(assetPath, AssetType.TEXT)) {
			addArtBackgroundChild(pr2.runtime.SvgAsset.createFitted(assetPath, Constants.STAGE_WIDTH, Constants.STAGE_HEIGHT), 0);
		}
		if (backgroundCode == BG5_CODE) {
			var grid = createBg5CircleGrid();
			addArtBackgroundChild(grid);
		}
	}

	private function addArtBackgroundChild(child:DisplayObject, ?index:Int):Void {
		if (artBackgroundContainer == null) {
			return;
		}
		if (index != null && index >= 0 && index < artBackgroundContainer.numChildren) {
			artBackgroundContainer.addChildAt(child, index);
		} else {
			artBackgroundContainer.addChild(child);
		}
		child.transform.colorTransform = backgroundColorTransform(artBackgroundTintScale);
		artBackgroundChildren.push(child);
	}

	private function drawArtLayer(index:Int):Void {
		if (!drawArtEnabled) return;
		if (index >= level.artLayers.length) return;
		var layer = level.artLayers[index];
		var container = new Sprite();
		container.name = 'artLayer${index + 1}';
		// Background.setPos rounds camera movement after applying the plane's
		// parallax scale. DrawableBackground applies that scale to placed objects
		// and text individually rather than scaling its stroke canvas.
		container.x = parallaxOffset(offsetX, layer.scale);
		container.y = parallaxOffset(offsetY, layer.scale);
		artLayerContainers[index] = container;
		// Brush strokes are rasterized onto this canvas, which sits beneath the
		// placed objects and text — the rasterCanvas/objCanvas split from
		// DrawableBackground. Drawing the strokes straight into the container's
		// vector graphics instead would make OpenFL's HTML5 backend rasterize the
		// whole (potentially level-spanning) layer into one offscreen texture.
		var rasterCanvas = new Sprite();
		rasterCanvas.name = ART_RASTER_CANVAS_NAME;
		container.addChild(rasterCanvas);
		var strokeTiles = new ArtRasterTiles(rasterCanvas, artRasterBudget);
		artRasterTileLayers[index] = strokeTiles;
		if (incrementalBlocks) {
			totalArtItems += layer.drawActions.length + layer.objects.length + layer.texts.length;
			artDrawCursors[index] = new ArtDrawCursor(container, strokeTiles, layer);
		} else {
			try {
				strokeTiles.applyAll(layer.drawActions);
				drawLayerObjects(container, layer.objects, layer.scale);
				drawLayerTexts(container, layer.texts, layer.scale);
			} catch (error:Dynamic) {
				handleArtDrawFailure(error);
			}
		}
		worldContainer.addChild(container);
		updateArtViewWindow(strokeTiles, true);
		if (!incrementalBlocks) {
			strokeTiles.attachQueuedTiles(1000000);
		}
	}

	private function redrawSolidBackground():Void {
		if (solidBackground == null) {
			return;
		}
		solidBackground.graphics.clear();
		solidBackground.graphics.beginFill(currentBackgroundColor);
		solidBackground.graphics.drawRect(0, 0, Constants.STAGE_WIDTH, Constants.STAGE_HEIGHT);
		solidBackground.graphics.endFill();
	}

	private function applyBackgroundColorTransforms():Void {
		for (child in artBackgroundChildren) {
			child.transform.colorTransform = backgroundColorTransform(artBackgroundTintScale);
		}
		blockLayer.transform.colorTransform = backgroundColorTransform(1);
		for (i in 0...artLayerContainers.length) {
			var container = artLayerContainers[i];
			if (container != null && i < level.artLayers.length) {
				container.transform.colorTransform = backgroundColorTransform(level.artLayers[i].scale);
			}
		}
	}

	private function backgroundColorTransform(layerScale:Float):ColorTransform {
		var amount = ((1 - layerScale) * 0.4) + 0.1;
		var red = (currentBackgroundColor >> 16) & 0xFF;
		var green = (currentBackgroundColor >> 8) & 0xFF;
		var blue = currentBackgroundColor & 0xFF;
		return new ColorTransform(1 - amount, 1 - amount, 1 - amount, 1, red * amount, green * amount, blue * amount, 0);
	}

	public static function createBg5CircleGrid(?random:Void->Float):Sprite {
		var nextRandom = random == null ? Math.random : random;
		var grid = new Sprite();
		grid.name = "bg5CircleGrid";
		grid.mouseEnabled = false;
		grid.mouseChildren = false;
		var tileSize = 50;
		var cols = Std.int(Constants.STAGE_WIDTH / tileSize);
		var rows = Std.int(Constants.STAGE_HEIGHT / tileSize);
		for (col in 0...cols) {
			for (row in 0...rows) {
				var circle = new Shape();
				circle.graphics.beginFill(Std.int(nextRandom() * 0xFFFFFF));
				circle.graphics.drawCircle(0, 0, 12.5);
				circle.graphics.endFill();
				circle.x = col * tileSize + 20;
				circle.y = row * tileSize + 20;
				grid.addChild(circle);
			}
		}
		return grid;
	}

	private function drawNextArtItems(limit:Int, ?deadline:Null<Float>):Void {
		var remaining = limit;
		while (remaining > 0 && drawnArtItems < totalArtItems) {
			while (nextArtLayerToDraw < artDrawCursors.length && artDrawCursors[nextArtLayerToDraw] == null) {
				nextArtLayerToDraw++;
			}
			if (nextArtLayerToDraw >= artDrawCursors.length) {
				return;
			}
			var cursor = artDrawCursors[nextArtLayerToDraw];
			if (artOptions != null && artOptions.artDrawFaultInjector != null) {
				artOptions.artDrawFaultInjector(attemptedArtItems);
			}
			var started = Timer.stamp();
			var drawn = cursor.drawNext(artOptions != null && artOptions.artDrawFaultInjector != null ? 1 : remaining, deadline);
			recordArtDrawProfile(cursor, nextArtLayerToDraw, drawn, (Timer.stamp() - started) * 1000);
			if (drawn > 0) {
				attemptedArtItems += drawn;
				drawnArtItems += drawn;
				remaining -= drawn;
			}
			if (cursor.isComplete()) {
				nextArtLayerToDraw++;
			}
			if (deadline != null && Timer.stamp() >= deadline) {
				return;
			}
		}
	}

	private function recordArtDrawProfile(cursor:ArtDrawCursor, layerIndex:Int, drawn:Int, elapsedMs:Float):Void {
		artProfileLastMs = cursor.lastProfileMs > 0 ? cursor.lastProfileMs : elapsedMs;
		artProfileLastLayer = layerIndex;
		artProfileLastAction = cursor.lastProfileActionIndex;
		artProfileLastKind = cursor.lastProfileKind;
		artProfileLastPath = cursor.lastProfilePath;
		artProfileLastMode = cursor.lastProfileMode;
		artProfileLastItems = drawn;
		artProfileLastValues = cursor.lastProfileValueCount;
		artProfileLastTiles = cursor.lastProfileTileCount;
		artProfileLastSpanX = cursor.lastProfileTileSpanX;
		artProfileLastSpanY = cursor.lastProfileTileSpanY;
		if (elapsedMs >= ART_DRAW_SLOW_PROFILE_MS) {
			artProfileSlowCount++;
		}
		if (elapsedMs > artProfileMaxMs) {
			artProfileMaxMs = elapsedMs;
			artProfileMaxLayer = artProfileLastLayer;
			artProfileMaxAction = artProfileLastAction;
			artProfileMaxKind = artProfileLastKind;
			artProfileMaxPath = artProfileLastPath;
			artProfileMaxMode = artProfileLastMode;
			artProfileMaxItems = artProfileLastItems;
			artProfileMaxValues = artProfileLastValues;
			artProfileMaxTiles = artProfileLastTiles;
			artProfileMaxSpanX = artProfileLastSpanX;
			artProfileMaxSpanY = artProfileLastSpanY;
		}
	}

	private function handleArtDrawFailure(error:Dynamic):Void {
		if (!artLoadWarningShown) {
			artLoadWarningShown = true;
			emitArtWarning(artOptions != null && artOptions.editorWarning == true ? ART_LOAD_WARNING_EDITOR : ART_LOAD_WARNING_GAME, true);
		}
		finishArtDrawingAfterFailure();
	}

	private function finishArtDrawingAfterFailure():Void {
		drawnArtItems = totalArtItems;
		nextArtLayerToDraw = artDrawCursors.length;
		removeEventListener(Event.ENTER_FRAME, drawArtBatch);
		finishArtRasterAttaching();
	}

	private function finishArtRasterAttaching():Void {
		if (hasQueuedVisibleArtRasterTiles() && !artRasterAttachActive) {
			artRasterAttachActive = true;
			addEventListener(Event.ENTER_FRAME, onArtRasterAttachFrame);
		}
	}

	private function onArtRasterAttachFrame(event:Event):Void {
		attachArtRasterTiles(ART_RASTER_ATTACH_TILES_PER_FRAME, Timer.stamp() + RENDER_FRAME_ESCAPE_SECONDS);
		if (!hasQueuedVisibleArtRasterTiles()) {
			artRasterAttachActive = false;
			removeEventListener(Event.ENTER_FRAME, onArtRasterAttachFrame);
		}
	}

	private function attachArtRasterTiles(limit:Int, ?deadline:Null<Float>):Int {
		var remaining = limit;
		for (tiles in artRasterTileLayers) {
			if (remaining <= 0) {
				break;
			}
			if (deadline != null && remaining < limit && Timer.stamp() >= deadline) {
				break;
			}
			if (tiles != null) {
				remaining -= tiles.attachQueuedTiles(remaining);
			}
		}
		return limit - remaining;
	}

	private function hasQueuedVisibleArtRasterTiles():Bool {
		for (tiles in artRasterTileLayers) {
			if (tiles != null && tiles.hasQueuedVisibleTiles()) {
				return true;
			}
		}
		return false;
	}

	private function notifyRasterStopped():Void {
		stoppedRasterizing = true;
		if (!rasterStopNotified) {
			rasterStopNotified = true;
			emitArtWarning(ART_RASTER_STOP_WARNING, false);
		}
	}

	private function emitArtWarning(message:String, gatePopup:Bool):Void {
		artWarningMessage = message;
		if (artOptions != null && artOptions.onArtWarning != null) {
			artOptions.onArtWarning(message);
			return;
		}
		if (artOptions != null && artOptions.suppressArtWarningPopup == true) {
			return;
		}
		if (!gatePopup || canOpenArtWarningPopup()) {
			new MessagePopup(message);
		}
	}

	private static function canOpenArtWarningPopup():Bool {
		var open = Popup.getOpen();
		return open.length == 0 || (open.length == 1 && Std.isOfType(open[0], PrizePopup));
	}

	public static function drawLayerStrokes(brushCanvas:Sprite, actions:Array<DecodedDrawAction>):Void
		ServerLevelArtFactory.drawLayerStrokes(brushCanvas, actions);

	public static function renderLayerStrokes(rasterCanvas:Sprite, actions:Array<DecodedDrawAction>, ?budget:ArtRasterBudget):Void
		ServerLevelArtFactory.renderLayerStrokes(rasterCanvas, actions, budget);

	public static function rasterizeBrushInto(rasterCanvas:Sprite, brushCanvas:Sprite):Void
		ServerLevelArtFactory.rasterizeBrushInto(rasterCanvas, brushCanvas);

	public static function drawStrokeAction(container:Sprite, color:Int, size:Float, mode:String, action:DecodedDrawAction):ArtStrokeState
		return ServerLevelArtFactory.drawStrokeAction(container, color, size, mode, action);

	private function drawLayerObjects(container:Sprite, objects:Array<DecodedArtObject>, layerScale:Float):Void
		ServerLevelArtFactory.drawLayerObjects(container, objects, layerScale);

	private function drawLayerTexts(container:Sprite, texts:Array<DecodedTextObject>, layerScale:Float):Void
		ServerLevelArtFactory.drawLayerTexts(container, texts, layerScale);

	public static function addLayerObject(container:Sprite, object:DecodedArtObject, layerScale:Float):Void
		ServerLevelArtFactory.addLayerObject(container, object, layerScale);

	public static function addLayerText(container:Sprite, text:DecodedTextObject, layerScale:Float):Void
		ServerLevelArtFactory.addLayerText(container, text, layerScale);

	private function createBlockDisplay(block:DecodedBlock):Sprite return blockFactory.createBlockDisplay(block);
	private function createIceOverlay():Sprite return blockFactory.createIceOverlay();
	private static function moveBlockArrowRotation(direction:Int):Float return ServerLevelBlockFactory.moveBlockArrowRotation(direction);
	private static function teleportBlockColor(options:String):Int return ServerLevelBlockFactory.teleportBlockColor(options);

	private static function firstRenderableBlock(level:ServerLevel):Null<DecodedBlock> {
		return level.blocks.length == 0 ? null : level.blocks[0];
	}

	private static function parseTextObjectText(value:String):String {
		return StringTools.replace(StringTools.replace(value, "|", ","), "<br>", "\n");
	}
}
