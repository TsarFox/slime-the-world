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

(local bump (require :lib.bump))
(local map (require :map))

(local sandbox (map.load "sandbox"))

;; (var swanky-frame 0)

;; (fn load-sprite [name frame-width frame-height]
;;   (let [img (love.graphics.newImage name)]
;;     {:img img
;;      :frame-width frame-width
;;      :frame-height frame-height}))

;; (fn draw-animated [x y sprite animation frame]
;;   (let [img (. sprite :img)
;;         width (. sprite :frame-width)
;;         height (. sprite :frame-height)]
;;     (let [quad (love.graphics.newQuad (* frame width)
;;                                       (* animation height)
;;                                       width
;;                                       height
;;                                       (: img :getWidth)
;;                                       (: img :getHeight))]
;;       (love.graphics.draw img quad x y 0 1 1 0 0))))

;; (fn load-player [])

(local tiles (love.graphics.newImage "art/tiles.png"))
(local tile-width 32)
(local tile-height 32)
(local tile-offsets {:bricks 0})

;; Drawing routine for rendering the tiles visible from a given camera offset.
(fn draw-tiles [map camera-x camera-y]
  (let [how-many-x (math.floor (/ canvas-width tile-width))
        how-many-y (math.floor (/ canvas-height tile-height))
        start-x (math.floor (/ camera-x tile-width))
        start-y (math.floor (/ camera-y tile-height))
        width (. map :width)
        height (. map :height)]
    (for [x 0 how-many-x]
      (for [y 0 how-many-y]
        (each [tile offset (pairs tile-offsets)]
          (when (and (and (>= (+ x start-x) 0) (< (+ x start-x) width))
                     (and (>= (+ y start-y) 0) (< (+ y start-y) height))
                     (= tile (. map :tiles (+ y start-y 1) (+ x start-x 1))))
            (let [x (- (* x tile-width) (% camera-x tile-width))
                  y (- (* y tile-height) (% camera-y tile-height))
                  quad (love.graphics.newQuad (* tile-width offset)
                                              0
                                              tile-width
                                              tile-height
                                              (: tiles :getWidth)
                                              (: tiles :getHeight))]
            (love.graphics.draw tiles quad x y 0 1 1 0 0))))))))

(var camera-x 64)
(var camera-y 64)
(var camera-x-vel 0)
(var camera-y-vel 0)
(var camera-animation-theta 0)

(fn draw [message]
  (love.graphics.clear 255 255 255)
  (draw-tiles sandbox camera-x camera-y)
  (love.graphics.print (.. "Welcome to " (. sandbox :meta :name)) 0 0))

(fn update [dt set-mode]
  (set camera-animation-theta (+ camera-animation-theta (/ math.pi 16)))
  (when (>= camera-animation-theta (* 2 math.pi))
    (set camera-animation-theta 0))
  (set camera-x-vel (* 8 (math.sin camera-animation-theta)))
  (set camera-y-vel (* 8 (math.cos camera-animation-theta)))
  (set camera-x (+ camera-x camera-x-vel))
  (set camera-y (+ camera-y camera-y-vel)))

(fn keypressed [key set-mode])

{:draw draw
 :update update
 :keypressed keypressed}
