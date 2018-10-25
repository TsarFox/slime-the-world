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

(local logo (love.graphics.newImage "art/logo.png"))

(fn button-width [button]
  (: (love.graphics.getFont) :getWidth (. button :text)))

(fn button-height [button]
  (: (love.graphics.getFont) :getHeight))

(fn new-button [text offset function]
  {:text text
   :offset offset
   :function function})

(fn draw-logo [screen-width screen-height]
  (let [x (/ (- screen-width (: logo :getWidth)) 2)
        y (/ (- screen-height (: logo :getHeight)) 8)]
    (love.graphics.draw logo x y)))

(fn draw-button [button]
  (let [text (. button :text)
        offset (. button :offset)
        width (button-width button)
        height (button-height button)
        x (/ (- screen-width width) 2)
        y (+ (* height offset)
               (/ (- screen-height height) 2))]
    (love.graphics.print text x y)))

(fn play-clicked [set-mode]
  (set-mode :game))

(fn sound-clicked []
  (print "No sound"))

(fn quit-clicked []
  (love.event.quit))

(local buttons [(new-button "Play" 0 play-clicked)
                (new-button "Toggle Sound" 1 sound-clicked)
                (new-button "Quit" 2 quit-clicked)])

;; Demo world.
(local current-player (player.new))
(local current-world (world.new "demo" current-player))
(local current-camera (camera.new current-world screen-width screen-height))

(local demo-actions [:move-right 1 :stop-right 1 :move-left 1 :jump])
(var demo-action-index 1)
(var demo-action-timer 0)

(fn draw []
  (let [camera-x (. current-camera :x-pos)
        camera-y (. current-camera :y-pos)]
    (: current-world :draw camera-x camera-y screen-width screen-height))
  (draw-logo screen-width screen-height)
  (each [_ button (ipairs buttons)]
    (draw-button button)))

(fn update [dt]
  (set demo-action-timer (- demo-action-timer dt))
  (when (> 0 demo-action-timer)
    (if (= "number" (type (. demo-actions demo-action-index)))
        (set demo-action-timer (. demo-actions demo-action-index))
        (: current-player (. demo-actions demo-action-index)))
    (set demo-action-index (+ 1 demo-action-index))
    (when (> demo-action-index (# demo-actions))
      (set demo-action-index 1)))

  (: current-world :update dt)
  (: current-player :update dt)
  (let [(camera-x camera-y) (: current-camera :focus-on-object current-player dt)]
    (tset current-camera :x-pos camera-x)
    (tset current-camera :y-pos camera-y)))

(fn keypressed [])

(fn keyreleased [])

(fn click [mouse-x mouse-y set-mode]
  (each [_ button (ipairs buttons)]
    (let [offset (. button :offset)
          width (button-width button)
          height (button-height button)
          x (/ (- screen-width width) 2)
          y (+ (* height offset)
               (/ (- screen-height height) 2))]
      (when (and (>= mouse-x x) (<= mouse-x (+ x width))
                 (>= mouse-y y) (<= mouse-y (+ y height)))
        ((. button :function) set-mode)))))

{:activate activate
 :draw draw
 :update update
 :keypressed keypressed
 :keyreleased keyreleased
 :click click}
