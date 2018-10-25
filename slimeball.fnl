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

(local draw (require :draw))

(local gravity 128)

(local slimeball-sheet
       {:img (love.graphics.newImage "art/slimeball.png")
        :width 16 :height 16
        :padding-x 0 :padding-y 0})

(fn draw-slimeball [slimeball x y]
  (draw.tile x y slimeball-sheet 0 0))

(fn update-slimeball [slimeball dt]
  (tset slimeball :y-vel (+ (. slimeball :y-vel) (* gravity dt))))

(fn next-position [slimeball dt]
  (values 
   (+ (. slimeball :x-pos) (* (. slimeball :x-vel) dt))
   (+ (. slimeball :y-pos) (* (. slimeball :y-vel) dt))))

(fn new-slimeball [player]
  (let [player-x (. player :x-pos)
        player-y (. player :y-pos)
        player-width (. player :width)
        player-height (. player :height)
        orientation (. player :orientation)]
    {:is-slimeball true

     :width (. slimeball-sheet :width)
     :height (. slimeball-sheet :height)

     :x-pos (if (= :right orientation)
                (+ player-x player-width)
                (- player-x player-width))
     :y-pos player-y

     :x-vel (if (= :right orientation) 128 (- 128))
     :y-vel 0

     :next-position next-position
     :update update-slimeball
     :draw draw-slimeball}))

{:new new-slimeball}
