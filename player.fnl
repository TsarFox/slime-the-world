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

(fn move-right [player]
  (tset player :orientation :right)
  (tset player :action :right true)
  (tset player :action :left false)
  (tset player :x-vel (/ (. player :x-vel) 2)))

(fn move-left [player]
  (tset player :orientation :left)
  (tset player :action :left true)
  (tset player :action :right false)
  (tset player :x-vel (/ (. player :x-vel) 2)))

(fn position-at [player x y]
  (tset player :x-pos x)
  (tset player :y-pos y))

(local player-sheet
       {:img (love.graphics.newImage "art/swanky.png")
        :orientation-offset 128
        :width 24 :height 22
        :padding-x 8 :padding-y 10})

(fn draw-player [player x y]
  (draw.tile x y player-sheet 0 0))

;; Returns a new player object.
(fn new-player []
  {:width (. player-sheet :width)
   :height (. player-sheet :height)

   :goal-x-vel 128
   :goal-y-vel 128

   :x-pos 0
   :y-pos 0

   :x-vel 0
   :y-vel 0

   :orientation :right
   ;; :frame 0
   ;; :frame-delay 4
   ;; :frame-timer 4

   :grounded false

   :action {:jump false
            :right false
            :left false}

   :position-at position-at
   :move-right move-right
   :move-left move-left

   :draw draw-player})

{:new new-player}
