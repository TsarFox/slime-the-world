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

(local camera (require :camera))
(local player (require :player))
(local world (require :world))

;; (local camera (camera.new 0 0))
;; (local player (player.new 128 128))
;; (local world (map.load "sandbox"))
;; (local collision-map (make-collision-map player (. world :tiles)))


;; (var fade-in-alpha 1)

;; (fn draw [message]
;;   (love.graphics.clear 1 1 1)
;;   (draw-tiles (. world :tiles) (. camera :x-pos) (. camera :y-pos))
;;   (let [x (- (. player :x-pos) (. camera :x-pos))
;;         y (- (. player :y-pos) (. camera :y-pos))
;;         animation-offset (. player-animations (. player :animation) :offset)]
;;     (draw-sprite player-sheet
;;                  animation-offset
;;                  (. player :frame)
;;                  (. player :orientation)
;;                  x
;;                  y))
;;   (love.graphics.print (string.format "%d/%d" (. world :surfaces-slimed)
;;                                       (. world :surfaces-total))
;;                        0 0)

;;   (when (< 0 fade-in-alpha)
;;     (love.graphics.setColor 0 0 0 fade-in-alpha)
;;     (love.graphics.rectangle "fill" 0 0 screen-width screen-height)
;;     (set fade-in-alpha (- fade-in-alpha 0.01))))


;; (fn update [dt set-mode]
;;   
;;   (local camera-lock-goal-x (math.floor (- (/ screen-width 2)
;;                                            (/ (. player-sheet :width) 2))))
;;   (local camera-lock-goal-y (math.floor (- (/ screen-height 2)
;;                                            (/ (. player-sheet :height) 2))))
;;   ;; Update animations.
;;   (tset player :frame-timer (- (. player :frame-timer) 1))
;;   (when (= 0 (. player :frame-timer))
;;     (tset player :frame-timer (. player :frame-delay))
;;     (tset player :frame (+ 1 (. player :frame)))
;;     (when (<= (. player-animations (. player :animation) :frames) (. player :frame))
;;       (tset player :frame 0)))

;;   ;; Update camera.
;;   (tset camera :x-pos (lume.lerp (. camera :x-pos)
;;                                  (- (. player :x-pos) camera-lock-goal-x) (* 4 dt)))
;;   (tset camera :y-pos (lume.lerp (. camera :y-pos)
;;                                  (- (. player :y-pos) camera-lock-goal-x) (* 4 dt)))

;;   ;; Lock camera so that it doesn't go out of bounds.
;;   (when (> 0 (. camera :x-pos))
;;     (tset camera :x-pos 0))

;;   (when (> 0 (. camera :y-pos))
;;     (tset camera :y-pos 0))

;;   (let [max-x (- (* (. map :tiles :width) (. world :width)) screen-width)]
;;     (when (>= (. camera :x-pos) max-x)
;;       (tset camera :x-pos max-x)))

;;   (let [max-y (- (* (. map :tiles :height) (. world :height)) screen-height)]
;;     (when (>= (. camera :y-pos) max-y)
;;       (tset camera :y-pos max-y)))

;;   ;; Update the the player's velocities to reflect controls.
;;   (let [goal-x-vel (if (. player :action :right) (. player :goal-x-vel)
;;                        (. player :action :left) (- (. player :goal-x-vel))
;;                        0)]
;;     (tset player :x-vel (lume.lerp (. player :x-vel) goal-x-vel dt)))

;;   (when (and (. player :action :jump) (. player :grounded))
;;     (tset player :y-vel (- (. player :y-vel) (. player :goal-y-vel))))

;;   ;; Update the y-velocity to reflect gravity.
;;   (if (and (. player :grounded) (not (. player :action :jump)))
;;       (tset player :y-vel 0)
;;       (tset player :y-vel (+ (. player :y-vel) (* gravity dt))))

;;   ;; Perform collision detection and update the player's position accordingly.
;;   (let [goal-x (+ (. player :x-pos) (* dt (. player :x-vel)))
;;         goal-y (+ (. player :y-pos) (* dt (. player :y-vel)))]
;;     (let [(x y collisions length) (: collision-map :move player goal-x goal-y)]
;;       (tset player :x-pos x)
;;       (tset player :y-pos y)

;;       (tset player :grounded false)
;;       (each [_ collision (ipairs collisions)]
;;         (let [tile (. collision :other)]
;;           ;; Touching top.
;;           (when (> 0 (. collision :normal :y))
;;             (tset player :grounded true)
;;             (when (not (. tile :slimed :top))
;;               (tset world :surfaces-slimed (+ 1 (. world :surfaces-slimed)))
;;               (tset tile :slimed :top true)))

;;           ;; Touching bottom.
;;           (when (< 0 (. collision :normal :y))
;;             (when (not (. tile :slimed :bottom))
;;               (tset world :surfaces-slimed (+ 1 (. world :surfaces-slimed)))
;;               (tset tile :slimed :bottom true)))

;;           ;; Touching left.
;;           (when (> 0 (. collision :normal :x))
;;             (when (not (. tile :slimed :left))
;;               (tset world :surfaces-slimed (+ 1 (. world :surfaces-slimed)))
;;               (tset tile :slimed :left true)))

;;           ;; Touching right.
;;           (when (< 0 (. collision :normal :x))
;;             (when (not (. tile :slimed :right))
;;               (tset world :surfaces-slimed (+ 1 (. world :surfaces-slimed)))
;;               (tset tile :slimed :right true))))))))


;; (fn keypressed [key set-mode]
;;   (when (= key "right")
;;     (player-turn-right player))

;;   (when (= key "left")
;;     (player-turn-left player))

;;   (when (= key "z")
;;     (tset player :action :jump true)))

;; (fn keyreleased [key set-mode]
;;   (when (= key "right")
;;     (tset player :action :right false))

;;   (when (= key "left")
;;     (tset player :action :left false))

;;   (when (= key "z")
;;     (tset player :action :jump false)))

(local current-player (player.new))
(local current-world (world.new "sandbox" current-player))
(local current-camera (camera.new current-world screen-width screen-height))
(: current-world :position-player-at 128 128)

(fn draw [message]
  (let [camera-x (. current-camera :x-pos)
        camera-y (. current-camera :y-pos)]
    (: current-world :draw camera-x camera-y screen-width screen-height)))

(fn update [dt set-mode]
  (: current-world :update dt)
  (: current-player :update dt)
  (let [(camera-x camera-y) (: current-camera :focus-on-object current-player dt)]
    (tset current-camera :x-pos camera-x)
    (tset current-camera :y-pos camera-y)))

(fn keypressed [key set-mode]
  (let [method (if (= key "right") :move-right
                   (= key "left") :move-left
                   (= key "z") :jump)]
    (when method
      (: current-player method))))

(fn keyreleased [key set-mode]
  (let [method (if (= key "right") :stop-right
                   (= key "left") :stop-left)]
    (when method
      (: current-player method))))

{:draw draw
 :update update
 :keypressed keypressed
 :keyreleased keyreleased}
