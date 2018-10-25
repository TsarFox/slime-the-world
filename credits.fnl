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

(local text ["And with that,"
             "our little"
             "slimewad friend"
             "was finally"
             "content. The"
             "basement was"
             "covered in"
             "slime!"
             ""
             "Thanks for"
             "taking the"
             "time to play"
             "my entry to"
             "this game jam!"
             ""
             "Be sure to read"
             "the README.org"
             "for greetz."
             ""
             "With love,"
             "Jakob"])

(var offset (- 216))

(fn draw []
  (each [i line (ipairs text)]
    (let [height (: (love.graphics.getFont) :getHeight)
          width (: (love.graphics.getFont) :getWidth line)
          x (/ (- screen-width width) 2)
          y (- (* height i) offset)]
      (love.graphics.print line x y))))

(fn update [dt set-mode]
  (set offset (+ offset (* 16 dt)))
  (when (> offset 420)
    (set-mode :menu)))

(fn keypressed []
  (set offset (+ offset 16)))

(fn keyreleased [])

(fn click []
  (set offset (+ offset 16)))

{:draw draw
 :update update
 :keypressed keypressed
 :keyreleased keyreleased
 :click click}
