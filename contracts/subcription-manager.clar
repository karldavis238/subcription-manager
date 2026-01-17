;; ---------------------------------------------------------
;; subscription-manager.clar
;; On-chain subscription management using block heights.
;; ---------------------------------------------------------

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CONSTANTS & ERRORS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-constant ERR-NOT-ADMIN (err u100))
(define-constant ERR-SUB-NOT-FOUND (err u101))
(define-constant ERR-SUB-EXPIRED (err u102))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DATA STORAGE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Contract administrator
(define-data-var admin principal tx-sender)

;; Subscription plans
(define-map plans
    { plan-id: uint }
    {
        duration: uint,   ;; duration in blocks
        price: uint       ;; price in microSTX (informational)
    }
)

;; User subscriptions
(define-map subscriptions
    { user: principal }
    {
        plan-id: uint,
        expires-at: uint
    }
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; READ-ONLY FUNCTIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-read-only (get-plan (plan-id uint))
    (map-get? plans { plan-id: plan-id })
)

(define-read-only (get-subscription (user principal))
    (map-get? subscriptions { user: user })
)

;; <CHANGE> Fixed: use (get field tuple) instead of tuple.field syntax
(define-read-only (is-active (user principal))
    (match (map-get? subscriptions { user: user })
        sub (>= (get expires-at sub) stacks-block-height)
        false
    )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; PUBLIC FUNCTIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Admin creates or updates a plan
(define-public (set-plan (plan-id uint) (duration uint) (price uint))
    (begin
        (asserts! (is-eq tx-sender (var-get admin)) ERR-NOT-ADMIN)
        (map-set plans
            { plan-id: plan-id }
            { duration: duration, price: price }
        )
        (ok plan-id)
    )
)

;; User subscribes to a plan
;; NOTE: attach STX to this call or enforce payment externally
;; <CHANGE> Fixed: use (get duration plan) instead of plan.duration, removed double (err ...) wrapping
(define-public (subscribe (plan-id uint))
    (match (map-get? plans { plan-id: plan-id })
        plan
        (let (
                (expiration (+ stacks-block-height (get duration plan)))
            )
            (begin
                ;; Payment logic intentionally left modular
                ;; e.g. attach STX or use stx-transfer? in production
                (map-set subscriptions
                    { user: tx-sender }
                    { plan-id: plan-id, expires-at: expiration }
                )
                (ok expiration)
            )
        )
        ERR-SUB-NOT-FOUND
    )
)

;; Renew an existing subscription
;; <CHANGE> Fixed: use (get field tuple) syntax throughout, removed double (err ...) wrapping
(define-public (renew)
    (match (map-get? subscriptions { user: tx-sender })
        sub
        (match (map-get? plans { plan-id: (get plan-id sub) })
            plan
            (let (
                    (new-expiration (+ (get expires-at sub) (get duration plan)))
                )
                (begin
                    (map-set subscriptions
                        { user: tx-sender }
                        { plan-id: (get plan-id sub), expires-at: new-expiration }
                    )
                    (ok new-expiration)
                )
            )
            ERR-SUB-NOT-FOUND
        )
        ERR-SUB-NOT-FOUND
    )
)