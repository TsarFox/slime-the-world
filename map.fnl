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

(local tileset-values
       {:empty [1 0 0 0]
        :bricks [0 0 0 1]})

;; Returns the keyword for a given tile pixel.
(fn get-tile [image x y]
  (var res :empty)
  (let [(r g b a) (: image :getPixel x y)]
    (each [name colors (pairs tileset-values)]
      (when (and (= (. colors 1) r)
                 (= (. colors 2) g)
                 (= (. colors 3) b)
                 (= (. colors 4) a))
        (set res name))))
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

;; (for [y 0 (- height 1)]
;;   (for [x 0 (- width 1)]
;;     (let [tile (. tiles (+ 1 y) (+ 1 x))]
;;       (if (= tile :empty)
;;           (io.write " ")
;;           :else
;;           (io.write "b"))))
;;   (print))

;; Returns the metadata and objects stored in the metadata file at the given
;; path.
(fn load-meta [path]
  (fennel.dofile path))

(fn load [name]
  (let [tiles-path (.. "maps/" name ".png")
        meta-path (.. "maps/" name ".fnl")]
    (let [(tiles width height) (load-tiles (love.image.newImageData tiles-path))]
      {:tiles tiles
       :width width
       :height height
       :meta (load-meta meta-path)})))

{:load load}
