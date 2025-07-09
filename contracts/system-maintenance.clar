;; System Maintenance Contract
;; Tracks sprinkler head performance and repairs

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u500))
(define-constant ERR_SPRINKLER_NOT_FOUND (err u501))
(define-constant ERR_INVALID_STATUS (err u502))
(define-constant ERR_MAINTENANCE_RECORD_NOT_FOUND (err u503))

;; Data Variables
(define-data-var next-sprinkler-id uint u1)
(define-data-var next-maintenance-id uint u1)

;; Data Maps
(define-map sprinkler-heads
  { sprinkler-id: uint }
  {
    zone-id: uint,
    status: (string-ascii 20), ;; "active", "maintenance", "broken"
    last-maintenance: uint,
    performance-score: uint,
    total-runtime: uint,
    installation-date: uint
  }
)

(define-map maintenance-records
  { maintenance-id: uint }
  {
    sprinkler-id: uint,
    maintenance-type: (string-ascii 30),
    performed-by: principal,
    date: uint,
    cost: uint,
    notes: (string-ascii 100)
  }
)

(define-map performance-metrics
  { sprinkler-id: uint, date: uint }
  {
    water-pressure: uint,
    coverage-area: uint,
    flow-rate: uint,
    efficiency-rating: uint
  }
)

(define-map maintenance-schedules
  { sprinkler-id: uint }
  {
    next-maintenance: uint,
    maintenance-interval: uint, ;; blocks between maintenance
    priority: uint ;; 1-5, 5 being highest
  }
)

;; Public Functions

;; Register a new sprinkler head
(define-public (register-sprinkler-head (zone-id uint))
  (let ((sprinkler-id (var-get next-sprinkler-id)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)

    (map-set sprinkler-heads
      { sprinkler-id: sprinkler-id }
      {
        zone-id: zone-id,
        status: "active",
        last-maintenance: block-height,
        performance-score: u100,
        total-runtime: u0,
        installation-date: block-height
      }
    )

    ;; Set initial maintenance schedule
    (map-set maintenance-schedules
      { sprinkler-id: sprinkler-id }
      {
        next-maintenance: (+ block-height u4320), ;; ~30 days
        maintenance-interval: u4320,
        priority: u3
      }
    )

    (var-set next-sprinkler-id (+ sprinkler-id u1))
    (ok sprinkler-id)
  )
)

;; Update sprinkler status
(define-public (update-sprinkler-status (sprinkler-id uint) (status (string-ascii 20)))
  (let ((sprinkler (unwrap! (map-get? sprinkler-heads { sprinkler-id: sprinkler-id }) ERR_SPRINKLER_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)

    (map-set sprinkler-heads
      { sprinkler-id: sprinkler-id }
      (merge sprinkler { status: status })
    )

    (ok true)
  )
)

;; Record maintenance activity
(define-public (record-maintenance
  (sprinkler-id uint)
  (maintenance-type (string-ascii 30))
  (cost uint)
  (notes (string-ascii 100)))
  (let ((maintenance-id (var-get next-maintenance-id))
        (sprinkler (unwrap! (map-get? sprinkler-heads { sprinkler-id: sprinkler-id }) ERR_SPRINKLER_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)

    ;; Record maintenance
    (map-set maintenance-records
      { maintenance-id: maintenance-id }
      {
        sprinkler-id: sprinkler-id,
        maintenance-type: maintenance-type,
        performed-by: tx-sender,
        date: block-height,
        cost: cost,
        notes: notes
      }
    )

    ;; Update sprinkler maintenance date
    (map-set sprinkler-heads
      { sprinkler-id: sprinkler-id }
      (merge sprinkler {
        last-maintenance: block-height,
        status: "active"
      })
    )

    ;; Update maintenance schedule
    (let ((schedule (unwrap! (map-get? maintenance-schedules { sprinkler-id: sprinkler-id }) ERR_SPRINKLER_NOT_FOUND)))
      (map-set maintenance-schedules
        { sprinkler-id: sprinkler-id }
        (merge schedule {
          next-maintenance: (+ block-height (get maintenance-interval schedule))
        })
      )
    )

    (var-set next-maintenance-id (+ maintenance-id u1))
    (ok maintenance-id)
  )
)

;; Update performance metrics
(define-public (update-performance-metrics
  (sprinkler-id uint)
  (water-pressure uint)
  (coverage-area uint)
  (flow-rate uint))
  (let ((date (/ block-height u144)) ;; Daily blocks
        (efficiency (calculate-performance-score water-pressure coverage-area flow-rate))
        (sprinkler (unwrap! (map-get? sprinkler-heads { sprinkler-id: sprinkler-id }) ERR_SPRINKLER_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)

    ;; Record performance metrics
    (map-set performance-metrics
      { sprinkler-id: sprinkler-id, date: date }
      {
        water-pressure: water-pressure,
        coverage-area: coverage-area,
        flow-rate: flow-rate,
        efficiency-rating: efficiency
      }
    )

    ;; Update sprinkler performance score
    (map-set sprinkler-heads
      { sprinkler-id: sprinkler-id }
      (merge sprinkler { performance-score: efficiency })
    )

    (ok true)
  )
)

;; Update runtime
(define-public (update-runtime (sprinkler-id uint) (additional-minutes uint))
  (let ((sprinkler (unwrap! (map-get? sprinkler-heads { sprinkler-id: sprinkler-id }) ERR_SPRINKLER_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)

    (map-set sprinkler-heads
      { sprinkler-id: sprinkler-id }
      (merge sprinkler {
        total-runtime: (+ (get total-runtime sprinkler) additional-minutes)
      })
    )

    (ok true)
  )
)

;; Private Functions

;; Calculate performance score
(define-private (calculate-performance-score (pressure uint) (coverage uint) (flow uint))
  (let ((pressure-score (if (>= pressure u30) u100 (/ (* pressure u100) u30)))
        (coverage-score (if (>= coverage u90) u100 (/ (* coverage u100) u90)))
        (flow-score (if (>= flow u20) u100 (/ (* flow u100) u20))))
    (/ (+ pressure-score coverage-score flow-score) u3)
  )
)

;; Read-only Functions

;; Get sprinkler head information
(define-read-only (get-sprinkler-head (sprinkler-id uint))
  (map-get? sprinkler-heads { sprinkler-id: sprinkler-id })
)

;; Get maintenance record
(define-read-only (get-maintenance-record (maintenance-id uint))
  (map-get? maintenance-records { maintenance-id: maintenance-id })
)

;; Get performance metrics
(define-read-only (get-performance-metrics (sprinkler-id uint) (date uint))
  (map-get? performance-metrics { sprinkler-id: sprinkler-id, date: date })
)

;; Get maintenance schedule
(define-read-only (get-maintenance-schedule (sprinkler-id uint))
  (map-get? maintenance-schedules { sprinkler-id: sprinkler-id })
)

;; Check if maintenance is due
(define-read-only (is-maintenance-due (sprinkler-id uint))
  (match (map-get? maintenance-schedules { sprinkler-id: sprinkler-id })
    schedule (>= block-height (get next-maintenance schedule))
    false
  )
)

;; Get sprinklers needing maintenance
(define-read-only (get-sprinkler-status (sprinkler-id uint))
  (match (map-get? sprinkler-heads { sprinkler-id: sprinkler-id })
    sprinkler (get status sprinkler)
    "not-found"
  )
)

;; Get total runtime
(define-read-only (get-total-runtime (sprinkler-id uint))
  (match (map-get? sprinkler-heads { sprinkler-id: sprinkler-id })
    sprinkler (get total-runtime sprinkler)
    u0
  )
)

;; Get performance score
(define-read-only (get-performance-score (sprinkler-id uint))
  (match (map-get? sprinkler-heads { sprinkler-id: sprinkler-id })
    sprinkler (get performance-score sprinkler)
    u0
  )
)
