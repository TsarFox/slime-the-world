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

;; Returns the tile at the given grid coordinates.
(fn tile-at [map x y]
  (if (and (>= x 0)
           (< x (. map :width))
           (>= y 0)
           (< y (. map :height)))
      (. map :tiles (+ 1 y) (+ 1 x))
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
      (draw-slime-decal tile orientation x y))))

;; Draws a single tile at the screen coordinates, (`x', `y').
(fn draw-tile [tile x y]
  (let [tile-offset (. tile-sheet :offsets (. tile :type))]
    (draw.tile x y tile-sheet tile-offset 0)
    (draw-slime tile x y)))

;; ;; Drawing routine for rendering the tiles visible from a given camera offset.
(fn draw-map [map camera-x camera-y screen-width screen-height]
  (let [tile-width (. tile-sheet :width)
        tile-height (. tile-sheet :height)
        how-many-x (+ 1 (/ screen-width tile-width))
        how-many-y (+ 1 (/ screen-height tile-height))
        start-x (math.floor (/ camera-x tile-width))
        start-y (math.floor (/ camera-y tile-height))
        width (. map :width)
        height (. map :height)]
    (for [x-offset 0 how-many-x]
      (for [y-offset 0 how-many-y]
        (when (and (and (>= (+ start-x x-offset) 0) (< (+ start-x x-offset) width))
                   (and (>= (+ start-y y-offset) 0) (< (+ start-y y-offset) height)))
          (let [tile (tile-at map (+ start-x x-offset) (+ start-y y-offset))
                screen-x (- (* x-offset tile-width) (% camera-x tile-width))
                screen-y (- (* y-offset tile-height) (% camera-y tile-height))]
            (when (~= :empty (. tile :type))
              (draw-tile tile screen-x screen-y))))))))

;; Returns whether or not `tile' exists in `checked'.
(fn tile-checked [tile checked]
  (var res false)
  (each [_ other (ipairs checked)]
    (when (and (= (. tile :x-pos) (. other :x-pos))
               (= (. tile :y-pos) (. other :y-pos)))
      (set res true)))
  res)

;; Modified implementation of <https://en.wikipedia.org/wiki/Flood_fill>.
(fn count-surfaces-recur [map tile checked]
  (var surfaces 0)

  (when (not (tile-checked tile checked))
    (table.insert checked tile)

    (let [x (/ (. tile :x-pos) (. tile-sheet :width))
          y (/ (. tile :y-pos) (. tile-sheet :height))
          width (. map :width)
          height (. map :height)]
      (when (>= x 0)
        (let [tile (tile-at map (- x 1) y)]
          (if (= :empty (. tile :type))
              (set surfaces (+ surfaces (count-surfaces-recur map tile checked)))
              (set surfaces (+ 1 surfaces)))))

      (when (< x width)
        (let [tile (tile-at map (+ x 1) y)]
          (if (= :empty (. tile :type))
              (set surfaces (+ surfaces (count-surfaces-recur map tile checked)))
              (set surfaces (+ 1 surfaces)))))

      (when (>= y 0)
        (let [tile (tile-at map x (- y 1))]
          (if (= :empty (. tile :type))
              (set surfaces (+ surfaces (count-surfaces-recur map tile checked)))
              (set surfaces (+ 1 surfaces)))))

      (when (< y height)
        (let [tile (tile-at map x (+ y 1))]
          (if (= :empty (. tile :type))
              (set surfaces (+ surfaces (count-surfaces-recur map tile checked)))
              (set surfaces (+ 1 surfaces)))))))

  surfaces)

;; Returns some tile in `map' of type `tile-type', or nil if no such tile is
;; present.
(fn find-any [tile-type map]
  (var res nil)
  (let [width (. map :width)
        height (. map :height)]
    (for [x 0 (- width 1)]
      (for [y 0 (- height 1)]
        (let [tile (tile-at map x y)]
          (when (= tile-type (. tile :type))
            (set res tile))))))
  res)

;; Returns the number of slime-able surfaces in the given grid of tiles.
(fn count-surfaces [map]
  (let [seed (find-any :empty map)]
    (when seed
      (count-surfaces-recur map seed []))))

(fn add-player-to-collision-map [collision-map player]
  (let [x (. player :x-pos)
        y (. player :y-pos)
        width (. player :width)
        height (. player :height)]
    (: collision-map :add player x y width height)))

(fn add-tile-to-collision-map [collision-map tile]
  (let [x (. tile :x-pos)
        y (. tile :y-pos)
        width (. tile :width)
        height (. tile :height)]
    (: collision-map :add tile (* x width) (* y height) width height)))

;; Returns a new collision map containing `player' and everything in `map'.
(fn new-collision-map [map player]
  (let [collision-map (bump.newWorld 32)
        width (. map :width)
        height (. map :height)]
    (add-player-to-collision-map collision-map player)
    (for [x 0 (- width 1)]
      (for [y 0 (- height 1)]
        (let [tile (tile-at map x y)]
          (when (~= :empty (. tile :type))
            (add-tile-to-collision-map collision-map tile)))))
    collision-map))

;; Creates a new tile object of the given `type-type' positioned at world
;; coordinates (`x', `y').
(fn new-tile [tile-type x y]
  {:width (. tile-sheet :width)
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

;; Loads the map of the given name into a new world containing `player'. Will
;; error out if either 'maps/${name}.png' or 'maps/${name}.fnl' do not exist.
(fn new-world [name player]
  (let [tiles-path (.. "maps/" name ".png")
        meta-path (.. "maps/" name ".fnl")
        res (load-tiles (love.image.newImageData tiles-path))
        res (lume.extend res {:surfaces-slimed 0 :meta (load-meta meta-path)})
        res (lume.extend res {:surfaces-total (count-surfaces res)})
        res (lume.extend res {:collision-map (new-collision-map res player)})
        res (lume.extend res {:draw draw-map})]
    res))

{:tile-at tile-at
 :new new-world}
