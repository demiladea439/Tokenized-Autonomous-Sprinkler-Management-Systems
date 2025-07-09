;; Plant Requirements Contract
;; Customizes irrigation for different vegetation types

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u300))
(define-constant ERR_PLANT_TYPE_NOT_FOUND (err u301))
(define-constant ERR_PLANT_TYPE_EXISTS (err u302))
(define-constant ERR_INVALID_PARAMETERS (err u303))
(define-constant ERR_ZONE_ASSIGNMENT_NOT_FOUND (err u304))

;; Data Variables
(define-data-var next-plant-id uint u1)

;; Data Maps
(define-map plant-types
  { plant-id: uint }
  {
    name: (string-ascii 50),
    min-moisture: uint,
    max-moisture: uint,
    watering-frequency: uint, ;; hours between watering
    seasonal-adjustment: uint, ;; percentage adjustment for season
    active: bool
  }
)

(define-map zone-plant-assignments
  { zone-id: uint }
  { plant-id: uint }
)

(define-map watering-schedules
  { zone-id: uint, plant-id: uint }
  {
    last-watered: uint,
    next-watering: uint,
    duration-minutes: uint
  }
)

;; Public Functions

;; Add a new plant type
(define-public (add-plant-type
  (name (string-ascii 50))
  (min-moisture uint)
  (max-moisture uint)
  (watering-frequency uint))
  (let ((plant-id (var-get next-plant-id)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (< min-moisture max-moisture) ERR_INVALID_PARAMETERS)
    (asserts! (> watering-frequency u0) ERR_INVALID_PARAMETERS)

    (map-set plant-types
      { plant-id: plant-id }
      {
        name: name,
        min-moisture: min-moisture,
        max-moisture: max-moisture,
        watering-frequency: watering-frequency,
        seasonal-adjustment: u100,
        active: true
      }
    )

    (var-set next-plant-id (+ plant-id u1))
    (ok plant-id)
  )
)

;; Assign plant type to zone
(define-public (assign-plant-to-zone (zone-id uint) (plant-id uint))
  (let ((plant (unwrap! (map-get? plant-types { plant-id: plant-id }) ERR_PLANT_TYPE_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)

    (map-set zone-plant-assignments
      { zone-id: zone-id }
      { plant-id: plant-id }
    )

    ;; Initialize watering schedule
    (map-set watering-schedules
      { zone-id: zone-id, plant-id: plant-id }
      {
        last-watered: u0,
        next-watering: (+ block-height (get watering-frequency plant)),
        duration-minutes: u15
      }
    )

    (ok true)
  )
)

;; Update watering schedule
(define-public (update-watering-schedule
  (zone-id uint)
  (plant-id uint)
  (duration-minutes uint))
  (let ((schedule (unwrap! (map-get? watering-schedules { zone-id: zone-id, plant-id: plant-id }) ERR_ZONE_ASSIGNMENT_NOT_FOUND))
        (plant (unwrap! (map-get? plant-types { plant-id: plant-id }) ERR_PLANT_TYPE_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)

    (map-set watering-schedules
      { zone-id: zone-id, plant-id: plant-id }
      (merge schedule {
        last-watered: block-height,
        next-watering: (+ block-height (get watering-frequency plant)),
        duration-minutes: duration-minutes
      })
    )

    (ok true)
  )
)

;; Update seasonal adjustment
(define-public (update-seasonal-adjustment (plant-id uint) (adjustment uint))
  (let ((plant (unwrap! (map-get? plant-types { plant-id: plant-id }) ERR_PLANT_TYPE_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (<= adjustment u200) ERR_INVALID_PARAMETERS)

    (map-set plant-types
      { plant-id: plant-id }
      (merge plant { seasonal-adjustment: adjustment })
    )

    (ok true)
  )
)

;; Toggle plant type status
(define-public (toggle-plant-status (plant-id uint))
  (let ((plant (unwrap! (map-get? plant-types { plant-id: plant-id }) ERR_PLANT_TYPE_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)

    (map-set plant-types
      { plant-id: plant-id }
      (merge plant { active: (not (get active plant)) })
    )

    (ok true)
  )
)

;; Read-only Functions

;; Get plant type information
(define-read-only (get-plant-type (plant-id uint))
  (map-get? plant-types { plant-id: plant-id })
)

;; Get plant assignment for zone
(define-read-only (get-zone-plant-assignment (zone-id uint))
  (map-get? zone-plant-assignments { zone-id: zone-id })
)

;; Get watering schedule
(define-read-only (get-watering-schedule (zone-id uint) (plant-id uint))
  (map-get? watering-schedules { zone-id: zone-id, plant-id: plant-id })
)

;; Check if zone needs watering based on plant requirements
(define-read-only (zone-needs-watering (zone-id uint))
  (match (map-get? zone-plant-assignments { zone-id: zone-id })
    assignment
      (match (map-get? watering-schedules { zone-id: zone-id, plant-id: (get plant-id assignment) })
        schedule (>= block-height (get next-watering schedule))
        false
      )
    false
  )
)

;; Get adjusted watering duration based on season
(define-read-only (get-adjusted-duration (plant-id uint) (base-duration uint))
  (match (map-get? plant-types { plant-id: plant-id })
    plant
      (/ (* base-duration (get seasonal-adjustment plant)) u100)
    base-duration
  )
)
