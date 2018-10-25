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
(local slimeball (require :slimeball))
(local world (require :world))

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
  (when (= key "x")
    (: current-world :add-slimeball (slimeball.new current-player)))
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
