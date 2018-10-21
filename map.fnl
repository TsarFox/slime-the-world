;;;; Copyright (C) 2018 Jakob L. Kreuze, All Rights Reserved.
;;;;
;;;; This file is part of swanky.
;;;;
;;;; swanky is free software: you can redistribute it and/or modify it under the
;;;; terms of the GNU General Public License as published by the Free Software
;;;; Foundation, either version 3 of the License, or (at your option) any later
;;;; version.
;;;;
;;;; swanky is distributed in the hope that it will be useful, but WITHOUT ANY
;;;; WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
;;;; FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
;;;; details.
;;;;
;;;; You should have received a copy of the GNU General Public License along
;;;; with swanky. If not, see <http://www.gnu.org/licenses/>.

(local tiles
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
  (var res (make-tile :empty (* x (. tiles :width)) (* y (. tiles :width))))
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
    (let [(tiles width height) (load-tiles (love.image.newImageData tiles-path))]
      {:tiles tiles
       :width width
       :height height
       :meta (load-meta meta-path)})))

{:tiles tiles
 :slime slime
 :load load}
