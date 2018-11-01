;;;; Copyright (C) 2018 Jakob L. Kreuze, All Rights Reserved.
;;;;
;;;; This file is part of slime-the-world.
;;;;
;;;; slime-the-world is free software: you can redistribute it and/or modify it
;;;; under the terms of the GNU General Public License as published by the Free
;;;; Software Foundation, either version 3 of the License, or (at your option)
;;;; any later version.
;;;;
;;;; slime-the-world is distributed in the hope that it will be useful, but
;;;; WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
;;;; or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
;;;; more details.
;;;;
;;;; You should have received a copy of the GNU General Public License along
;;;; with slime-the-world. If not, see <http://www.gnu.org/licenses/>.

(local bump (require :lib.bump))
(local lume (require :lib.lume))

(local draw (require :draw))

;; Updates the position of the player contained in `world' to the world
;; coordinates, (`x', `y').
(fn position-player-at [world x y]
  (let [player (. world :player)
        collision-map (. world :collision-map)]
  (tset player :x-pos x)
  (tset player :y-pos y)
  (: collision-map :update player x y)))

;; Returns the tile at the given grid coordinates.
(fn tile-at [world x y]
  (if (and (>= x 0)
           (< x (. world :width))
           (>= y 0)
           (< y (. world :height)))
      (. world :tiles (+ 1 y) (+ 1 x))
      nil))

(local tile-sheet
       {:img (love.graphics.newImage "art/tiles.png")
        :width 32 :height 32
        :padding-x 8 :padding-y 8
        :offsets {:bricks 0}})

(local slime-sheet
       {:img (love.graphics.newImage "art/slime.png")
        :width 32 :height 32
        :padding-x 8 :padding-y 8
        :offsets {:top 0 :bottom 1 :left 2 :right 3}})

;; Draws the slime decal for a given orientation at the screen coordinates,
;; (`x', `y').
(fn draw-slime-decal [orientation x y]
  (let [tile-offset (. slime-sheet :offsets orientation)]
    (draw.tile x y slime-sheet tile-offset 0)))

;; Draws all slimed surfaces for a tile at screen coordinates, (`x', `y').
(fn draw-slime [tile x y]
  (each [orientation slimed (pairs (. tile :slimed))]
    (when slimed
      (draw-slime-decal orientation x y))))

;; Draws a single tile at the screen coordinates, (`x', `y').
(fn draw-tile [tile x y]
  (let [tile-offset (. tile-sheet :offsets (. tile :type))]
    (draw.tile x y tile-sheet tile-offset 0)
    (draw-slime tile x y)))

;; ;; Drawing routine for rendering the tiles visible from a given camera offset.
(fn draw-map [world camera-x camera-y screen-width screen-height]
  (let [tile-width (. tile-sheet :width)
        tile-height (. tile-sheet :height)
        how-many-x (+ 1 (/ screen-width tile-width))
        how-many-y (+ 1 (/ screen-height tile-height))
        start-x (math.floor (/ camera-x tile-width))
        start-y (math.floor (/ camera-y tile-height))
        width (. world :width)
        height (. world :height)]
    (for [x-offset 0 how-many-x]
      (for [y-offset 0 how-many-y]
        (when (and (and (>= (+ start-x x-offset) 0) (< (+ start-x x-offset) width))
                   (and (>= (+ start-y y-offset) 0) (< (+ start-y y-offset) height)))
          (let [tile (tile-at world (+ start-x x-offset) (+ start-y y-offset))
                screen-x (- (* x-offset tile-width) (% camera-x tile-width))
                screen-x (lume.round screen-x)
                screen-y (- (* y-offset tile-height) (% camera-y tile-height))
                screen-y (lume.round screen-y)]
            (when (~= :empty (. tile :type))
              (draw-tile tile screen-x screen-y))))))))

(fn draw-hud [world screen-width screen-height]
  (let [font-height (: (love.graphics.getFont) :getHeight)
        surfaces-slimed (. world :surfaces-slimed)
        surfaces-total (. world :surfaces-total)
        slime-msg (string.format "%d/%d" surfaces-slimed surfaces-total)]
    (love.graphics.print slime-msg 0 (- screen-height font-height))))

(fn draw-object [object camera-x camera-y]
  (let [x-pos (. object :x-pos)
        y-pos (. object :y-pos)
        x (- x-pos camera-x)
        y (- y-pos camera-y)]
    (: object :draw x y)))

(fn draw-world [world camera-x camera-y screen-width screen-height]
  (love.graphics.clear 0.1 0.1 0.1)
  (draw-map world camera-x camera-y screen-width screen-height)
  (each [_ slimeball (ipairs (. world :slimeballs))]
    (draw-object slimeball camera-x camera-y))
  (draw-object (. world :player) camera-x camera-y)
  (draw-hud world screen-width screen-height))

;; Returns whether or not `tile' exists in `checked'.
(fn tile-checked [tile checked]
  (var res false)
  (each [_ other (ipairs checked)]
    (when (and (= (. tile :x-pos) (. other :x-pos))
               (= (. tile :y-pos) (. other :y-pos)))
      (set res true)))
  res)

;; Modified implementation of <https://en.wikipedia.org/wiki/Flood_fill>.
(fn count-surfaces-recur [world tile checked]
  (var surfaces 0)

  (when (not (tile-checked tile checked))
    (table.insert checked tile)

    (let [x (/ (. tile :x-pos) (. tile-sheet :width))
          y (/ (. tile :y-pos) (. tile-sheet :height))
          width (. world :width)
          height (. world :height)]
      (when (>= x 0)
        (let [tile (tile-at world (- x 1) y)]
          (if (= :empty (. tile :type))
              (set surfaces (+ surfaces (count-surfaces-recur world tile checked)))
              (set surfaces (+ 1 surfaces)))))

      (when (< x width)
        (let [tile (tile-at world (+ x 1) y)]
          (if (= :empty (. tile :type))
              (set surfaces (+ surfaces (count-surfaces-recur world tile checked)))
              (set surfaces (+ 1 surfaces)))))

      (when (>= y 0)
        (let [tile (tile-at world x (- y 1))]
          (if (= :empty (. tile :type))
              (set surfaces (+ surfaces (count-surfaces-recur world tile checked)))
              (set surfaces (+ 1 surfaces)))))

      (when (< y height)
        (let [tile (tile-at world x (+ y 1))]
          (if (= :empty (. tile :type))
              (set surfaces (+ surfaces (count-surfaces-recur world tile checked)))
              (set surfaces (+ 1 surfaces)))))))

  surfaces)

;; Returns some tile in `world' of type `tile-type', or nil if no such tile is
;; present.
(fn find-any [tile-type world]
  (var res nil)
  (let [width (. world :width)
        height (. world :height)]
    (for [x 0 (- width 1)]
      (for [y 0 (- height 1)]
        (let [tile (tile-at world x y)]
          (when (= tile-type (. tile :type))
            (set res tile))))))
  res)

;; Returns the number of slime-able surfaces in the given grid of tiles.
(fn count-surfaces [world]
  (let [seed (find-any :empty world)]
    (when seed
      (count-surfaces-recur world seed []))))

(fn add-object-to-collision-map [collision-map object]
  (let [x (. object :x-pos)
        y (. object :y-pos)
        width (. object :width)
        height (. object :height)]
    (: collision-map :add object x y width height)))

(fn add-tile-to-collision-map [collision-map tile]
  (let [x (. tile :x-pos)
        y (. tile :y-pos)
        width (. tile :width)
        height (. tile :height)]
    (: collision-map :add tile x y width height)))

;; Returns a new collision map containing `player' and everything in `map'.
(fn new-collision-map [world player]
  (let [collision-map (bump.newWorld 32)
        width (. world :width)
        height (. world :height)]
    (add-object-to-collision-map collision-map player)
    (for [x 0 (- width 1)]
      (for [y 0 (- height 1)]
        (let [tile (tile-at world x y)]
          (when (~= :empty (. tile :type))
            (add-tile-to-collision-map collision-map tile)))))
    collision-map))

;; Creates a new tile object of the given `type-type' positioned at world
;; coordinates (`x', `y').
(fn new-tile [tile-type x y]
  {:is-tile true

   :width (. tile-sheet :width)
   :height (. tile-sheet :height)

   :x-pos x
   :y-pos y

   :type tile-type

   :slimed {:top false
            :bottom false
            :left false
            :right false}})

;; Returns the tile object for a given pixel in `image'.
(fn get-tile [image x y]
  (local tile-values
         {:empty [1 0 0 0]
          :bricks [0 0 0 1]})
  (var res (new-tile :empty (* x (. tile-sheet :width)) (* y (. tile-sheet :height))))
  (let [(r g b a) (: image :getPixel x y)]
    (each [tile-type colors (pairs tile-values)]
      (when (and (= (. colors 1) r)
                 (= (. colors 2) g)
                 (= (. colors 3) b)
                 (= (. colors 4) a))
        (tset res :type tile-type))))
  res)

;; Loads the tile layout of the level from the given ImageData, returning a
;; rectangular two-dimensional array.
(fn load-tiles [image]
  (var tiles [])
  (let [width (: image :getWidth)
        height (: image :getHeight)]
    (for [y 0 (- height 1)]
      (var row [])
      (for [x 0 (- width 1)]
        (table.insert row (get-tile image x y)))
      (table.insert tiles row))
    {:tiles tiles :width width :height height}))

;; Returns the metadata and objects stored in the metadata file at the given
;; path.
(fn load-meta [path]
  (fennel.dofile path))

(fn slime-tile [world tile orientation]
  (when (not (. tile :slimed orientation))
    (let [surfaces-slimed (. world :surfaces-slimed)]
      (tset world :surfaces-slimed (+ 1 surfaces-slimed))
      (tset tile :slimed orientation true))))

(fn move-slimeball [world slimeball dt]
  (let [collision-map (. world :collision-map)
        (goal-x goal-y) (: slimeball :next-position dt)
        filter (fn [_ other] (if (. other :is-tile) "touch" "cross"))
        (x y collisions _) (: collision-map :move slimeball goal-x goal-y filter)]
    (each [_ collision (ipairs collisions)]
      (let [other (. collision :other)
            x-normal (. collision :normal :x)
            y-normal (. collision :normal :y)]
        (when (. other :is-tile)
          (if (> 0 y-normal) (slime-tile world other :top)
              (< 0 y-normal) (slime-tile world other :bottom)
              (> 0 x-normal) (slime-tile world other :left)
              (< 0 x-normal) (slime-tile world other :right))

          (for [i 1 (# (. world :slimeballs))]
            (when (= slimeball (. (. world :slimeballs) i))
              (table.remove (. world :slimeballs) i))))))
    (tset slimeball :x-pos x)
    (tset slimeball :y-pos y)))

(fn update-world [world dt]
  (let [player (. world :player)
        slimeballs (. world :slimeballs)
        collision-map (. world :collision-map)
        (goal-x goal-y) (: player :next-position dt)
        filter (fn [_ other] (if (. other :is-tile) "slide" "cross"))
        (x y collisions _) (: collision-map :move player goal-x goal-y filter)]
    (each [_ slimeball (ipairs slimeballs)]
      (move-slimeball world slimeball dt)
      (: slimeball :update dt))

    (tset player :x-pos x)
    (tset player :y-pos y)

    (tset player :grounded false)
    (each [_ collision (ipairs collisions)]
      (let [other (. collision :other)
            x-normal (. collision :normal :x)
            y-normal (. collision :normal :y)]
        (when (. other :is-tile)
          ;; Touching top of surface.
          (when (> 0 y-normal)
            (tset player :grounded true)
            (slime-tile world other :top))

          ;; Touching bottom of surface.
          (when (< 0 y-normal)
            (slime-tile world other :bottom)
            (tset player :y-vel 0))

          ;; Touching left of surface.
          (when (> 0 x-normal)
            (slime-tile world other :left)
            (: player :bounce x-normal y-normal))

          ;; Touching right of surface.
          (when (< 0 x-normal)
            (slime-tile world other :right)
            (: player :bounce x-normal y-normal)))))

    (tset player :x-vel (: player :next-x-vel dt))
    (tset player :y-vel (: player :next-y-vel dt))))

(fn add-slimeball [world slimeball]
  (table.insert (. world :slimeballs) slimeball)
  (add-object-to-collision-map (. world :collision-map) slimeball))

;; Loads the map of the given name into a new world containing `player'. Will
;; error out if either 'maps/${name}.png' or 'maps/${name}.fnl' do not exist.
(fn new-world [name player]
  (let [tiles-path (.. "maps/" name ".png")
        meta-path (.. (love.filesystem.getSource) "/maps/" name ".fnl")
        res (load-tiles (love.image.newImageData tiles-path))
        res (lume.extend res {:player player})
        res (lume.extend res {:slimeballs []})
        res (lume.extend res {:surfaces-slimed 0})
        res (lume.extend res (load-meta meta-path))
        res (lume.extend res {:surfaces-total (count-surfaces res)})
        res (lume.extend res {:collision-map (new-collision-map res player)})
        res (lume.extend res {:add-slimeball add-slimeball})
        res (lume.extend res {:draw draw-world})
        res (lume.extend res {:update update-world})]
    (position-player-at res (. res :player-spawn-x) (. res :player-spawn-y))
    res))

{:tile-sheet tile-sheet
 :tile-at tile-at
 :new new-world}
