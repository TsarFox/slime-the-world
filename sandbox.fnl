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
(local lume (require :lib.lume))

(local map (require :map))

(local sandbox (map.load "sandbox"))

(local tiles (love.graphics.newImage "art/tiles.png"))
(local tile-width 32)
(local tile-height 32)
(local tile-offsets {:bricks 0})

;; Drawing routine for rendering the tiles visible from a given camera offset.
(fn draw-tiles [map camera-x camera-y]
  (let [how-many-x (math.ceil (+ 3 (/ screen-width tile-width))) ; fixme: why +3?
        how-many-y (math.ceil (+ 2 (/ screen-height tile-height))) ; fixme: why +2?
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
              (love.graphics.draw tiles quad x y))))))))

;; (local swanky-tile-width 32)
;; (local swanky-tile-height 32)
;; (local swanky-width 24)
;; (local swanky-height 22)

;; Okay, here are the things we need to keep track of:
;; - Camera
;;   - camera-x
;;   - camera-y
;;   - camera-x-velocity
;;   - camera-y-velocity
;;
;; - Player
;;   - orientation (right vs left)
;;   - x
;;   - y
;;   - x-velocity
;;   - y-velocity
;;   - goal-x-velocity
;;   - goal-y-velocity
;;   - Whether or not is grounded
;;   - Jumping (?)
;;   - The current action (moving right, etc.)
;;
;; - Animations
;;   - offsets
;;   - whether or not to sustain
;;   - number of frames

;; ---

(local swanky-animation-offsets {:idle 0
                                 :jump 2
                                 :fall 3})
(local swanky-animation-sustains {:idle false
                                  :jump true
                                  :fall false})
(local swanky-animation-frame-counts {:idle 2
                                      :jump 4
                                      :fall 4})

(local swanky (love.graphics.newImage "art/swanky.png"))
(local swanky-width 32)
(local swanky-height 32)

(fn draw-swanky [x y animation frame orientation]
  (let [x-offset (+ (* frame swanky-width)
                    (if (= orientation :left) (* 4 swanky-width) 0))
        y-offset (* (. swanky-animation-offsets animation) swanky-height)]
    (let [quad (love.graphics.newQuad x-offset
                                      y-offset
                                      swanky-width
                                      swanky-height
                                      (: swanky :getWidth)
                                      (: swanky :getHeight))]
      (love.graphics.draw swanky quad x y))))

(var swanky-orientation :right)

(local swanky-animation-frame-delay 16)
(var swanky-animation-frame-timer swanky-animation-frame-delay)
(var swanky-animation-frame 0)
(var swanky-animation :idle)

(var swanky-animation-stack [])

(var swanky-x 128)
(var swanky-y 128)
(var swanky-x-vel 0)
(var swanky-y-vel 0)

(var swanky-moving-right false)
(var swanky-moving-left false)

(local swanky-x-vel-goal 128)
(local swanky-y-vel-goal 128)

(var swanky-jumping false)
(var swanky-grounded false)
(var swanky-should-play-grounding-animation true)

(var gravity 128)

(var camera-x 64)
(var camera-y 64)
(var camera-x-vel 0)
(var camera-y-vel 0)

(local camera-lock-goal-x (math.floor (+ (/ screen-width 2) (/ swanky-width 2))))
(local camera-lock-goal-y (math.floor (+ (/ screen-height 2) (/ swanky-height 2))))

(local world (bump.newWorld 32))
(: world :add :swanky swanky-x swanky-y swanky-width swanky-height)

(for [x 0 (- (. sandbox :width) 1)]
  (for [y 0 (- (. sandbox :height) 1)]
    (let [tile (. sandbox :tiles (+ 1 y) (+ 1 x))]
      (when (~= :empty tile)
        (: world :add [tile] (* x tile-width) (* y tile-height) tile-width tile-height)))))

(fn draw [message]
  (love.graphics.clear 1 1 1)
  (draw-tiles sandbox camera-x camera-y)
  (let [x (- swanky-x camera-x)
        y (- swanky-y camera-y)]
    (draw-swanky x y swanky-animation swanky-animation-frame swanky-orientation)))

(fn update [dt set-mode]
  ;; Update animations.
  (when (< 0 (# swanky-animation-stack))
    (set swanky-animation (table.remove swanky-animation-stack (# swanky-animation-stack)))
    (set swanky-animation-frame 0))

  (when (> 0 swanky-animation-frame-timer)
    (let [frame-count (. swanky-animation-frame-counts swanky-animation)
          sustain (. swanky-animation-sustains swanky-animation)]
      (if (and (= frame-count (+ 1 swanky-animation-frame)) (not sustain))
          (do
            (set swanky-animation-frame 0)
            (when (~= swanky-animation :idle)
              (set swanky-animation :idle)))
          (> frame-count (+ 1 swanky-animation-frame))
          (set swanky-animation-frame (+ 1 swanky-animation-frame))))
    (set swanky-animation-frame-timer swanky-animation-frame-delay))

  (set swanky-animation-frame-timer (- swanky-animation-frame-timer (* 64 dt)))

  ;; Update camera.
  (set camera-x (lume.lerp camera-x (- swanky-x camera-lock-goal-x) dt))
  (set camera-y (lume.lerp camera-y (- swanky-y camera-lock-goal-y) dt))

  ;; Lock camera so that it doesn't go out of bounds.
  (when (> 0 camera-x)
    (set camera-x 0))

  (when (> 0 camera-y)
    (set camera-y 0))

  (when (>= camera-x (- (* tile-width (- (. sandbox :width) 3)) screen-width))
    (set camera-x (- (* tile-width (- (. sandbox :width) 3)) screen-width)))

  (when (>= camera-y (- (* tile-height (- (. sandbox :height) 2)) screen-height))
    (set camera-y (- (* tile-height (- (. sandbox :height) 2)) screen-height)))

  ;; Update the swanky's velocities to reflect controls.
  (let [swanky-x-vel-goal (if swanky-moving-right swanky-x-vel-goal
                              swanky-moving-left (- swanky-x-vel-goal)
                              0)]
    (set swanky-x-vel (lume.lerp swanky-x-vel swanky-x-vel-goal dt)))

  (when (and swanky-jumping swanky-grounded)
    (set swanky-y-vel (- swanky-y-vel swanky-y-vel-goal)))

  ;; Update the y-velocity to reflect gravity.
  (if (and swanky-grounded (not swanky-jumping))
      (set swanky-y-vel 0)
      (set swanky-y-vel (+ swanky-y-vel (* gravity dt))))

  (when (and (> 0 swanky-y-vel) (not swanky-grounded))
      (set swanky-should-play-grounding-animation true))

  ;; Calculate the goal position for swanky.
  (set swanky-x (+ swanky-x (* dt swanky-x-vel)))
  (set swanky-y (+ swanky-y (* dt swanky-y-vel)))

  ;; Perform collision detection and update swanky's position accordingly
  (let [(actual-x actual-y collisions length) (: world :move :swanky swanky-x swanky-y)]
    (set swanky-x actual-x)
    (set swanky-y actual-y)
    (set swanky-grounded false)
    (each [_ collision (ipairs collisions)]
      (when (> 0 (. collision :normal :y))
        (set swanky-grounded true)
        (when swanky-should-play-grounding-animation
          (table.insert swanky-animation-stack :fall)
          (set swanky-should-play-grounding-animation false))))))

(fn keypressed [key set-mode]
  (if (= key "d")
      (do (set swanky-moving-right true)
          (set swanky-orientation :right))
      (= key "a")
      (do (set swanky-moving-left true)
          (set swanky-orientation :left))
      (= key "w")
      (do
        (set swanky-jumping true)
        (set swanky-animation :jump))))

(fn keyreleased [key set-mode]
  (if (= key "d")
      (do (set swanky-x-vel (/ swanky-x-vel 2))
          (set swanky-moving-right false))
      (= key "a")
      (do (set swanky-x-vel (/ swanky-x-vel 2))
          (set swanky-moving-left false))
      (= key "w")
      (set swanky-jumping false)))

{:draw draw
 :update update
 :keypressed keypressed
 :keyreleased keyreleased}
