;; Token Vesting Vault Contract

(define-data-var contract-owner (optional principal) none)

(define-map vestings
  { beneficiary: principal }
  { total: uint, start-height: uint, cliff-height: uint, end-height: uint, revoked: bool }
)

(define-data-var admin (optional principal) none)

;; Read-only function to get vested amount
(define-read-only (vested-amount (beneficiary principal))
  (match (map-get? vestings { beneficiary: beneficiary })
    v
    (if (get revoked v)
      u0
      (if (< stacks-block-height (get cliff-height v))
        u0
        (if (>= stacks-block-height (get end-height v))
          (get total v)
          (/ (* (- stacks-block-height (get start-height v)) (get total v))
             (- (get end-height v) (get start-height v)))
        )
      )
    )
    u0
  )
)

;; Create vesting schedule
(define-public (create-vesting
  (beneficiary principal)
  (total uint)
  (start uint)
  (cliff uint)
  (end uint)
)
  (begin
    (asserts! (is-eq tx-sender (unwrap! (var-get admin) (err u1))) (err u1))
    (asserts! (> total u0) (err u2))
    (asserts! (> end start) (err u3))
    (asserts! (and (>= cliff start) (<= cliff end)) (err u4))
    (map-set vestings
      { beneficiary: beneficiary }
      { total: total, start-height: start, cliff-height: cliff, end-height: end, revoked: false }
    )
    (ok true)
  )
)

;; Revoke vesting schedule
(define-public (revoke (beneficiary principal))
  (begin
    (asserts! (is-eq tx-sender (unwrap! (var-get admin) (err u1))) (err u1))
    (match (map-get? vestings { beneficiary: beneficiary })
      v
      (begin
        (map-set vestings
          { beneficiary: beneficiary }
          (merge v { revoked: true })
        )
        (ok true)
      )
      (err u5)
    )
  )
)

;; Get vesting details
(define-read-only (get-vesting (beneficiary principal))
  (map-get? vestings { beneficiary: beneficiary })
)
