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

(local tile-sheet (. (require :world) :tile-sheet))

;; TODO: Document this
(fn focus-on-object [camera object dt]
  (let [last-x (. camera :x-pos)
        last-y (. camera :y-pos)
        max-x (. camera :max-x)
        max-y (. camera :max-y)
        object-x (. object :x-pos)
        object-y (. object :y-pos)
        width (. object :width)
        height (. object :height)
        screen-width (. camera :screen-width)
        screen-height (. camera :screen-height)
        x-offset (math.floor (- (/ screen-width 2) (/ width 2)))
        y-offset (math.floor (- (/ screen-height 2) (/ height 2)))
        x (lume.lerp last-x (- object-x x-offset) (* 4 dt))
        x (lume.clamp x 0 max-x)
        y (lume.lerp last-y (- object-y y-offset) (* 4 dt))
        y (lume.clamp y 0 max-y)]
    (values x y)))

;; Returns a new camera object, aware of the bounds of `world' and the camera
;; lock parameters entailed by the given screen dimensions.
(fn new-camera [world screen-width screen-height]
  (let [tile-width (. tile-sheet :width)
        tile-height (. tile-sheet :height)
        max-x (- (* tile-width (. world :width)) screen-width)
        max-y (- (* tile-height (. world :height)) screen-height)]
    {:x-pos 0
     :y-pos 0

     :screen-width screen-width
     :screen-height screen-height

     :max-x max-x
     :max-y max-y

     :focus-on-object focus-on-object}))

{:new new-camera}
