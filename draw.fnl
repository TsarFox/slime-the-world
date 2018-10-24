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

;; Draws from the a given tile sheet to the screen coordinates, (`x', `y'),
;; accounting for padding and actual tile size.
(fn tile [x y sheet frame-x frame-y]
  (let [x-offset (+ (. sheet :padding-x)
                    (* frame-x (+ (. sheet :width) (. sheet :padding-x))))
        y-offset (+ (. sheet :padding-y)
                    (* frame-y (+ (. sheet :height) (. sheet :padding-y))))]
    (let [quad (love.graphics.newQuad x-offset
                                      y-offset
                                      (. sheet :width)
                                      (. sheet :height)
                                      (: (. sheet :img) :getWidth)
                                      (: (. sheet :img) :getHeight))]
      (love.graphics.draw (. sheet :img) quad x y))))

{:tile tile}
