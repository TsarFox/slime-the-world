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

(local lume (require :lib.lume))

(local draw (require :draw))

(local gravity 128)

;; Returns a pair, (x, y) that represents the player's next position, assuming
;; that it did /not/ collide with anything. The role of collision detection, and
;; further, setting the player's position, is on the world.
(fn next-position [player dt]
  (let [x (+ (. player :x-pos) (* dt (. player :x-vel)))
        y (+ (. player :y-pos) (* dt (. player :y-vel)))]
    (values x y)))

(fn next-x-vel [player dt]
  (let [last-x-vel (. player :x-vel)
        moving-right (. player :action :right)
        moving-left (. player :action :left)
        abs-x-vel (. player :goal-x-vel)
        goal-x-vel (if moving-right abs-x-vel moving-left (- abs-x-vel) 0)]
    (lume.lerp last-x-vel goal-x-vel dt)))

(fn next-y-vel [player dt]
  (let [last-y-vel (. player :y-vel)
        jumping (. player :action :jump)
        grounded (. player :grounded)
        jumping-y-vel (- last-y-vel (. player :goal-y-vel))]
    (if (and jumping grounded) jumping-y-vel
        grounded 0
        :else (+ (. player :y-vel) (* gravity dt)))))

(fn impact-bottom [player]
  (tset player :grounded true))

(fn impact-top [player])

(fn impact-left [player])

(fn impact-right [player])

(fn move-right [player]
  (tset player :orientation :right)
  (tset player :action :right true)
  (tset player :action :left false)
  (tset player :x-vel (/ (. player :x-vel) 2)))

(fn stop-right [player]
  (tset player :action :right false)
  (tset player :x-vel (/ (. player :x-vel) 2)))

(fn move-left [player]
  (tset player :orientation :left)
  (tset player :action :left true)
  (tset player :action :right false)
  (tset player :x-vel (/ (. player :x-vel) 2)))

(fn stop-left [player]
  (tset player :action :left false)
  (tset player :x-vel (/ (. player :x-vel) 2)))

(local player-sheet
       {:img (love.graphics.newImage "art/swanky.png")
        :orientation-offset 128
        :width 24 :height 22
        :padding-x 8 :padding-y 10})

(fn draw-player [player x y]
  (let [x-offset (if (= (. player :orientation) :left) 4 0)]
    (draw.tile x y player-sheet x-offset 0)))

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

   :next-position next-position
   :next-x-vel next-x-vel
   :next-y-vel next-y-vel
   :impact-bottom impact-bottom
   :impact-top impact-top
   :impact-left impact-left
   :impact-right impact-right
   :move-right move-right
   :stop-right stop-right
   :move-left move-left
   :stop-left stop-left

   :draw draw-player})

{:new new-player}
