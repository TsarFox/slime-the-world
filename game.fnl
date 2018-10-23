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

(local map (require :map))

(local player-sheet
       {:img (love.graphics.newImage "art/swanky.png")
        :orientation-offset 128
        :width 24 :height 22
        :padding-x 8 :padding-y 10})

(local player-animations
       {:idle {:offset 0 :frames 1}
        :walk {:offset 1 :frames 4}})

;; Returns a new player object, placed at the world coordinates, (`x', `y').
(fn make-player [x y]
  {:width (. player-sheet :width)
   :height (. player-sheet :height)

   :goal-x-vel 128
   :goal-y-vel 128

   :x-pos x
   :y-pos y

   :x-vel 0
   :y-vel 0

   :orientation :right
   :animation :idle
   :frame 0
   :frame-delay 4
   :frame-timer 4

   :grounded false

   :action {:jump false
            :right false
            :left false}})

(fn player-turn-right [player]
  (tset player :orientation :right)
  (tset player :action :right true)
  (tset player :action :left false)
  (tset player :x-vel (/ (. player :x-vel) 2)))

(fn player-turn-left [player]
  (tset player :orientation :left)
  (tset player :action :left true)
  (tset player :action :right false)
  (tset player :x-vel (/ (. player :x-vel) 2)))

;; Returns a new camera object initially focused at the given world coordinates,
;; (`x', `y').
(fn make-camera [x y]
  {:x-pos x
   :y-pos y})

;; Returns a new collision map containing `player' and everything in `map'.
(fn make-collision-map [player tiles]
  (let [world (bump.newWorld 32)
        width (# (. tiles 1))
        height (# tiles)]
    (: world :add player (. player :x-pos) (. player :y-pos) (. player :width) (. player :height))
    (for [x 0 (- width 1)]
      (for [y 0 (- height 1)]
        (let [tile (. tiles (+ 1 y) (+ 1 x))]
          (when (~= :empty (. tile :type))
            (: world :add tile (* x (. map :tiles :width)) (* y (. map :tiles :height)) (. map :tiles :width) (. map :tiles :height))))))
    world))

(local camera (make-camera 0 0))
(local player (make-player 128 128))
(local world (map.load "sandbox"))
(local collision-map (make-collision-map player (. world :tiles)))

;; Draws the slime effect for a given orientation at the screen coordinates,
;; (`x', `y').
(fn draw-slime-decal [tile orientation x y]
  (let [decal-offset (. map :slime :offsets orientation)]
    (let [quad (love.graphics.newQuad (+ (. map :slime :padding-x)
                                         (* (+ (. map :slime :width)
                                               (. map :slime :padding-x))
                                            decal-offset))
                                      (. map :slime :padding-y)
                                      (. map :slime :width)
                                      (. map :slime :height)
                                      (: (. map :slime :img) :getWidth)
                                      (: (. map :slime :img) :getHeight))]
      (love.graphics.draw (. map :slime :img) quad x y))))

(fn draw-slime [tile x y]
  (each [orientation slimed (pairs (. tile :slimed))]
    (when slimed
      (draw-slime-decal tile orientation x y))))

;; Draws a single tile at the screen coordinates, (`x', `y').
(fn draw-tile [tile x y]
  (let [tile-offset (. map :tiles :offsets (. tile :type))]
    (let [quad (love.graphics.newQuad (+ (. map :tiles :padding-x)
                                         (* (+ (. map :tiles :width) (. map :tiles :padding-x)) tile-offset))
                                      (. map :tiles :padding-y)
                                      (. map :tiles :width)
                                      (. map :tiles :height)
                                      (: (. map :tiles :img) :getWidth)
                                      (: (. map :tiles :img) :getHeight))]
      (love.graphics.draw (. map :tiles :img) quad x y))))

;; Drawing routine for rendering the tiles visible from a given camera offset.
(fn draw-tiles [tiles camera-x camera-y]
  (let [how-many-x (+ 1 (/ screen-width (. map :tiles :width)))
        how-many-y (+ 1 (/ screen-height (. map :tiles :height)))
        start-x (math.floor (/ camera-x (. map :tiles :width)))
        start-y (math.floor (/ camera-y (. map :tiles :height)))
        width (# (. tiles 1))
        height (# tiles)]
    (for [x-offset 0 how-many-x]
      (for [y-offset 0 how-many-y]
        (when (and (and (>= (+ start-x x-offset) 0) (< (+ start-x x-offset) width))
                   (and (>= (+ start-y y-offset) 0) (< (+ start-y y-offset) height)))
          (let [tile (. tiles (+ start-y y-offset 1) (+ start-x x-offset 1))
                x (- (* x-offset (. map :tiles :width)) (% camera-x (. map :tiles :width)))
                y (- (* y-offset (. map :tiles :height)) (% camera-y (. map :tiles :height)))]
            (when (~= :empty (. tile :type))
              (draw-tile tile x y)
              (draw-slime tile x y))))))))

;; Draws from a given sprite sheet, `sheet' to the screen coordinates (`x', `y')
;; with the given animation parameters.
(fn draw-sprite [sheet animation-offset frame orientation x y]
  (let [x-offset (+ (. sheet :padding-x)
                    (* frame (+ (. sheet :width) (. sheet :padding-x)))
                    (if (= orientation :right) 0 (. sheet :orientation-offset)))
        y-offset (+ (. sheet :padding-y)
                    (* animation-offset (+ (. sheet :height) (. sheet :padding-y))))]
    (let [quad (love.graphics.newQuad x-offset
                                      y-offset
                                      (. sheet :width)
                                      (. sheet :height)
                                      (: (. sheet :img) :getWidth)
                                      (: (. sheet :img) :getHeight))]
      (love.graphics.draw (. sheet :img) quad x y))))

(var fade-in-alpha 1)

(fn draw [message]
  (love.graphics.clear 1 1 1)  
  (draw-tiles (. world :tiles) (. camera :x-pos) (. camera :y-pos))
  (let [x (- (. player :x-pos) (. camera :x-pos))
        y (- (. player :y-pos) (. camera :y-pos))
        animation-offset (. player-animations (. player :animation) :offset)]
    (draw-sprite player-sheet
                 animation-offset
                 (. player :frame)
                 (. player :orientation)
                 x
                 y))
  (love.graphics.print (string.format "%d/%d" (. world :surfaces-slimed)
                                      (. world :surfaces-total))
                       0 0)

  (when (< 0 fade-in-alpha)
    (love.graphics.setColor 0 0 0 fade-in-alpha)
    (love.graphics.rectangle "fill" 0 0 screen-width screen-height)
    (set fade-in-alpha (- fade-in-alpha 0.01))))

;; Ideally, all the components of 'update will be refactored out like this.
(fn update-player-animation-state [player]
  (if (and (or (. player :action :right) (. player :action :left))
           (> 1 (math.abs (. player :y-vel))))
      (tset player :animation :walk)
      (tset player :animation :idle)))
  
(fn update [dt set-mode]
  (local gravity 128)
  (local camera-lock-goal-x (math.floor (- (/ screen-width 2)
                                           (/ (. player-sheet :width) 2))))
  (local camera-lock-goal-y (math.floor (- (/ screen-height 2)
                                           (/ (. player-sheet :height) 2))))

  ;; Update animations.
  (update-player-animation-state player)
  
  (tset player :frame-timer (- (. player :frame-timer) 1))
  (when (= 0 (. player :frame-timer))
    (tset player :frame-timer (. player :frame-delay))
    (tset player :frame (+ 1 (. player :frame)))
    (when (<= (. player-animations (. player :animation) :frames) (. player :frame))
      (tset player :frame 0)))

  ;; Update camera.
  (tset camera :x-pos (lume.lerp (. camera :x-pos)
                                 (- (. player :x-pos) camera-lock-goal-x) (* 4 dt)))
  (tset camera :y-pos (lume.lerp (. camera :y-pos)
                                 (- (. player :y-pos) camera-lock-goal-x) (* 4 dt)))

  ;; Lock camera so that it doesn't go out of bounds.
  (when (> 0 (. camera :x-pos))
    (tset camera :x-pos 0))

  (when (> 0 (. camera :y-pos))
    (tset camera :y-pos 0))

  (let [max-x (- (* (. map :tiles :width) (. world :width)) screen-width)]
    (when (>= (. camera :x-pos) max-x)
      (tset camera :x-pos max-x)))

  (let [max-y (- (* (. map :tiles :height) (. world :height)) screen-height)]
    (when (>= (. camera :y-pos) max-y)
      (tset camera :y-pos max-y)))

  ;; Update the the player's velocities to reflect controls.
  (let [goal-x-vel (if (. player :action :right) (. player :goal-x-vel)
                       (. player :action :left) (- (. player :goal-x-vel))
                       0)]
    (tset player :x-vel (lume.lerp (. player :x-vel) goal-x-vel dt)))

  (when (and (. player :action :jump) (. player :grounded))
    (tset player :y-vel (- (. player :y-vel) (. player :goal-y-vel))))

  ;; Update the y-velocity to reflect gravity.
  (if (and (. player :grounded) (not (. player :action :jump)))
      (tset player :y-vel 0)
      (tset player :y-vel (+ (. player :y-vel) (* gravity dt))))

  ;; Perform collision detection and update the player's position accordingly.
  (let [goal-x (+ (. player :x-pos) (* dt (. player :x-vel)))
        goal-y (+ (. player :y-pos) (* dt (. player :y-vel)))]
    (let [(x y collisions length) (: collision-map :move player goal-x goal-y)]
      (tset player :x-pos x)
      (tset player :y-pos y)

      (tset player :grounded false)
      (each [_ collision (ipairs collisions)]
        (let [tile (. collision :other)]
          ;; Touching top.
          (when (> 0 (. collision :normal :y))
            (tset player :grounded true)
            (when (not (. tile :slimed :top))
              (tset world :surfaces-slimed (+ 1 (. world :surfaces-slimed)))
              (tset tile :slimed :top true)))

          ;; Touching bottom.
          (when (< 0 (. collision :normal :y))
            (when (not (. tile :slimed :bottom))
              (tset world :surfaces-slimed (+ 1 (. world :surfaces-slimed)))
              (tset tile :slimed :bottom true)))

          ;; Touching left.
          (when (> 0 (. collision :normal :x))
            (when (not (. tile :slimed :left))
              (tset world :surfaces-slimed (+ 1 (. world :surfaces-slimed)))
              (tset tile :slimed :left true)))

          ;; Touching right.
          (when (< 0 (. collision :normal :x))
            (when (not (. tile :slimed :right))
              (tset world :surfaces-slimed (+ 1 (. world :surfaces-slimed)))
              (tset tile :slimed :right true))))))))


(fn keypressed [key set-mode]
  (when (= key "right")
    (player-turn-right player))

  (when (= key "left")
    (player-turn-left player))

  (when (= key "z")
    (tset player :action :jump true)))

(fn keyreleased [key set-mode]
  (when (= key "right")
    (tset player :action :right false))

  (when (= key "left")
    (tset player :action :left false))

  (when (= key "z")
    (tset player :action :jump false)))

{:draw draw
 :update update
 :keypressed keypressed
 :keyreleased keyreleased}
