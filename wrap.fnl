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

;;;; ---

;;;; This module contains non-game-specific bits and mode-changing logic.

(global canvas-width 640)
(global canvas-height 480)

(local canvas (love.graphics.newCanvas 640 480))
(local font (love.graphics.newImageFont "art/font.png"
                                        (.. " !\"#$%&*()*+,-./"
                                            "0123456789"
                                            ":;<=>?@"
                                            "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
                                            "abcdefghijklmnopqrstuvwxyz"
                                            "[\\]^_`{|}~")))

(var scale 2)
(var mode (require :sandbox))

(fn set-mode [mode-name ...]
  (set mode (require mode-name))
  (when mode.activate
    (mode.activate ...)))

(fn love.load []
  (: canvas :setFilter "nearest" "nearest")
  (love.graphics.setFont font))

(fn love.draw []
  (love.graphics.setCanvas canvas)
  (love.graphics.clear)
  (love.graphics.setColor 1 1 1)
  (mode.draw)
  (love.graphics.setCanvas)
  (love.graphics.setColor 1 1 1)
  (love.graphics.draw canvas 0 0 0 scale scale))

(fn love.update [dt]
  (mode.update dt set-mode))

(fn love.keypressed [key]
  (if (and (= key "f11") (= scale 2))
    (let [(dw dh) (love.window.getDesktopDimensions)]
      (love.window.setMode dw dh {:fullscreen true :fullscreentype :desktop})
      (set scale (/ dh 225)))

    (= key "f11")
    (do (set scale 2) (love.window.setMode (* 720 scale) (* 450 scale)))

    (and (love.keyboard.isDown "lctrl" "rctrl" "capslock") (= key "q"))
    (love.event.quit)

    (love.keyboard.isDown "m")
    (sound.toggle)

    :else
    (mode.keypressed key set-mode)))
