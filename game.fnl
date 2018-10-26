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

(local music [(love.audio.newSource "music/girl_from_mars.xm" "stream")
              (love.audio.newSource "music/key_generators.xm" "stream")
              (love.audio.newSource "music/miafan2010_-_speed_chip.s3m" "stream")
              (love.audio.newSource "music/october_chip.xm" "stream")
              (love.audio.newSource "music/the_dim_dungeon.xm" "stream")
              (love.audio.newSource "music/the_epic_chip.xm" "stream")])
(var current-music nil)

(fn update-music []
  (when current-music
    (: current-music :stop))
  (let [index (math.random 1 (# music))]
    (set current-music (. music index))
    (: current-music :setVolume 0.5)
    (: current-music :setLooping true)
    (: current-music :play)))

(local map-order ["sandbox" "babysteps" "bounce" "tubes"
                  "obstacle" "fall" "gimmick" "laststretch"])

(var screen-alpha 1)
(var welcome-message-y (- (: (love.graphics.getFont) :getHeight)))
(var welcome-message-timer 64)
(local welcome-message-goal-y (: (love.graphics.getFont) :getHeight))

(var current-player nil)
(var current-world nil)
(var current-camera nil)

(local spit-sfx (love.audio.newSource "sound/spit.wav" "static"))

(fn next-map []
  (let [map-name (table.remove map-order 1)]
    (when (~= nil map-name)
      (update-music)
      (set screen-alpha 1)
      (set welcome-message-y (- (: (love.graphics.getFont) :getHeight)))
      (set welcome-message-timer 64)
      (set current-player (player.new))
      (set current-world (world.new map-name current-player))
      (set current-camera (camera.new current-world screen-width screen-height)))
    (~= nil map-name)))

(next-map)

(fn draw-fade-in-mask []
  (let [(r g b a) (love.graphics.getColor)]
    (love.graphics.setColor 0 0 0 screen-alpha)
    (love.graphics.rectangle "fill" 0 0 screen-width screen-height)
    (love.graphics.setColor r g b a))
  (when (< 0 screen-alpha)
    (set screen-alpha (- screen-alpha 0.05))))

(fn draw-welcome-message []
  (when (< 0 welcome-message-timer)
    (let [msg (string.format "Welcome to %s" (. current-world :name))
          x (/ (- screen-width (: (love.graphics.getFont) :getWidth msg)) 2)]
      (love.graphics.print msg x welcome-message-y))
    (when (< welcome-message-y welcome-message-goal-y)
      (set welcome-message-y (+ welcome-message-y 1)))
    (when (= welcome-message-y welcome-message-goal-y)
      (set welcome-message-timer (- welcome-message-timer 1)))))

(fn draw [message]
  (let [camera-x (. current-camera :x-pos)
        camera-y (. current-camera :y-pos)]
    (: current-world :draw camera-x camera-y screen-width screen-height))
  (draw-welcome-message)
  (draw-fade-in-mask))

(fn update [dt set-mode]
  (: current-world :update dt)
  (: current-player :update dt)
  (let [(camera-x camera-y) (: current-camera :focus-on-object current-player dt)]
    (tset current-camera :x-pos camera-x)
    (tset current-camera :y-pos camera-y))

  (when (= (. current-world :surfaces-slimed) (. current-world :surfaces-total))
    (when (not (next-map))
      (set-mode :credits))))

(fn keypressed [key set-mode]
  (when (= key "x")
    (: spit-sfx :play)
    (: current-world :add-slimeball (slimeball.new current-player)))
  (let [method (if (= key "right") :move-right
                   (= key "left") :move-left
                   (= key "up") :face-upwards
                   (= key "z") :jump)]
    (when method
      (: current-player method))))

(fn keyreleased [key set-mode]
  (let [method (if (= key "right") :stop-right
                   (= key "left") :stop-left
                   (= key "up") :face-normal)]
    (when method
      (: current-player method))))

(fn click [])

(fn activate []
  (update-music))

{:activate activate
 :draw draw
 :update update
 :keypressed keypressed
 :keyreleased keyreleased
 :click click}
