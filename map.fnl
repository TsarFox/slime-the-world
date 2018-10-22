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

(local tile-sheet
       {:img (love.graphics.newImage "art/tiles.png")
        :width 32 :height 32
        :padding-x 8 :padding-y 8
        :offsets {:bricks 0}})

(local tile-values
       {:empty [1 0 0 0]
        :bricks [0 0 0 1]})

(local slime
       {:img (love.graphics.newImage "art/slime.png")
        :width 32 :height 32
        :padding-x 8 :padding-y 8
        :offsets {:top 0 :bottom 1 :left 2 :right 3}})

(fn tile-at [tiles x y]
  (if (and (>= x 0)
           (< x (. tiles :width))
           (>= y 0)
           (< y (. tiles :height)))
      (. tiles :tiles (+ 1 y) (+ 1 x))
      nil))

(fn find-first [tile-type tiles]
  (var res nil)
  (each [_ row (ipairs (. tiles :tiles))]
    (each [_ tile (ipairs row)]
      (when (= tile-type (. tile :type))
        (set res tile))))
  res)

(fn tile-checked [tile checked]
  (var res false)
  (each [_ other (ipairs checked)]
    (when (and (= (. tile :x-pos) (. other :x-pos))
               (= (. tile :y-pos) (. other :y-pos)))
      (set res true)))
  res)

(fn count-surfaces-recur [tiles tile checked]
  (var surfaces 0)

  (when (not (tile-checked tile checked))
    (table.insert checked tile)

    (let [x (/ (. tile :x-pos) (. tile-sheet :width))
          y (/ (. tile :y-pos) (. tile-sheet :height))
          width (. tiles :width)
          height (. tiles :height)]
      (when (>= x 0)
        (let [tile (tile-at tiles (- x 1) y)]
          (if (= :empty (. tile :type))
              (set surfaces (+ surfaces (count-surfaces-recur tiles tile checked)))
              (set surfaces (+ 1 surfaces)))))

      (when (< x width)
        (let [tile (tile-at tiles (+ x 1) y)]
          (if (= :empty (. tile :type))
              (set surfaces (+ surfaces (count-surfaces-recur tiles tile checked)))
              (set surfaces (+ 1 surfaces)))))

      (when (>= y 0)
        (let [tile (tile-at tiles x (- y 1))]
          (if (= :empty (. tile :type))
              (set surfaces (+ surfaces (count-surfaces-recur tiles tile checked)))
              (set surfaces (+ 1 surfaces)))))

      (when (< y height)
        (let [tile (tile-at tiles x (+ y 1))]
          (if (= :empty (. tile :type))
              (set surfaces (+ surfaces (count-surfaces-recur tiles tile checked)))
              (set surfaces (+ 1 surfaces)))))))

  surfaces)

(fn count-surfaces [tiles]
  (let [seed (find-first :empty tiles)]
    (when seed
      (count-surfaces-recur tiles seed []))))

;; Creates a new tile object of the given `type-type' positioned at world
;; coordinates (`x', `y').
(fn make-tile [tile-type x y]
  {:x-pos x
   :y-pos y
   :type tile-type
   :slimed {:top false
            :bottom false
            :left false
            :right false}})

;; Returns the tile object for a given pixel in `image'.
(fn get-tile [image x y]
  (var res (make-tile :empty (* x (. tile-sheet :width)) (* y (. tile-sheet :width))))
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
    (values tiles width height)))

;; Returns the metadata and objects stored in the metadata file at the given
;; path.
(fn load-meta [path]
  (fennel.dofile path))

;; Loads the map of the given name. Will error out if either 'maps/${name}.png'
;; or 'maps/${name}.fnl' do not exist.
(fn load [name]
  (let [tiles-path (.. "maps/" name ".png")
        meta-path (.. "maps/" name ".fnl")]
    (let [(tiles width height) (load-tiles (love.image.newImageData tiles-path))
          tiles-temp {:tiles tiles :width width :height height}]
      {:tiles tiles
       :width width
       :height height

       :surfaces-slimed 0
       :surfaces-total (count-surfaces tiles-temp)

       :meta (load-meta meta-path)})))

{:tiles tile-sheet
 :slime slime
 :load load}
