(in-package #:sparklines)

(defun draw-normal-range (range width thickness)
  (destructuring-bind (low . high) range
    (set-rgba-fill 0 0 0 0.2)
    (rectangle thickness low (- width (* thickness 2)) (- high low))
    (fill-path)))

(defun draw-line (coords thickness fill-limit color)
  (apply #'set-rgb-stroke color)
  (set-line-cap :round)
  (set-line-join :round)
  (set-line-width (max (/ thickness 2) 1))
  (move-to (car (car coords)) (cdr (car coords)))
  (mapc (lambda (next) (line-to (car next) (cdr next))) (cdr coords))
  (if fill-limit
      (progn
        (line-to (caar (last coords)) fill-limit)
        (line-to (caar coords) fill-limit)
        (close-subpath)
        (apply #'set-rgb-fill color)
        (fill-path))
      (stroke)))

(defun draw-point (point thickness &key color)
  (apply #'set-rgb-fill color)
  (centered-circle-path (car point) (cdr point) (max thickness 1))
  (fill-path))

(defparameter *normal-color* '(0.5 0.5 0.5))

(defun build-sparkline
    (image-dimensions coords min-point max-point normal-range fill-limit
     thickness hl-first hl-last hl-min hl-max)
  (vecto:with-canvas (:width (car image-dimensions)
                      :height (cdr image-dimensions))
    (if normal-range
        (draw-normal-range normal-range (car image-dimensions) thickness))
    (draw-line coords thickness fill-limit *normal-color*)
    (if hl-first (draw-point (car coords) thickness :color hl-first))
    (if hl-last (draw-point (car (last coords)) thickness :color hl-last))
    (if hl-min (draw-point min-point thickness :color hl-min))
    (if hl-max (draw-point max-point thickness :color hl-max))
    (with-open-stream
        (s (flexi-streams:make-in-memory-output-stream
            :element-type '(unsigned-byte 8)))
      (save-png-stream s)
      s)))

(defmethod draw-tick (datapoint image-height)
  (destructuring-bind (x onp bar highlight) datapoint
    (let ((mid (/ image-height 2))
          (end (if onp image-height 0)))
      (draw-line (list (cons x (+ mid (if onp 1 -1))) (cons x end))
                 2 nil
                 (or highlight *normal-color*))
      (if bar
          (draw-line (list (cons (- x (/ bar 2)) mid)
                           (cons (+ x (/ bar 2)) mid))
                     2 nil
                     *normal-color*)))))

(defun build-sparktick (data image-dimensions)
  (vecto:with-canvas
      (:width (car image-dimensions) :height (cdr image-dimensions))
    (mapc (lambda (datapoint) (draw-tick datapoint (cdr image-dimensions)))
          data)
    (with-open-stream
        (s (flexi-streams:make-in-memory-output-stream
            :element-type '(unsigned-byte 8)))
      (save-png-stream s)
      s)))