;; Entity Verification Contract
;; Validates financial institutions in the system

(define-data-var admin principal tx-sender)

;; Entity status: 0 = unverified, 1 = verified, 2 = suspended
(define-map entities principal
  {
    status: uint,
    name: (string-utf8 100),
    jurisdiction: (string-utf8 50),
    verification-date: uint,
    verifier: principal
  }
)

(define-read-only (get-entity (entity-id principal))
  (default-to
    {
      status: u0,
      name: u"",
      jurisdiction: u"",
      verification-date: u0,
      verifier: tx-sender
    }
    (map-get? entities entity-id)
  )
)

(define-read-only (is-verified (entity-id principal))
  (is-eq (get status (get-entity entity-id)) u1)
)

(define-public (register-entity (name (string-utf8 100)) (jurisdiction (string-utf8 50)))
  (begin
    (asserts! (not (is-eq (get status (get-entity tx-sender)) u0)) (err u1))
    (ok (map-set entities tx-sender
      {
        status: u0,
        name: name,
        jurisdiction: jurisdiction,
        verification-date: u0,
        verifier: tx-sender
      }
    ))
  )
)

(define-public (verify-entity (entity-id principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (not (is-eq (get status (get-entity entity-id)) u0)) (err u404))
    (ok (map-set entities entity-id
      (merge (get-entity entity-id)
        {
          status: u1,
          verification-date: block-height,
          verifier: tx-sender
        }
      )
    ))
  )
)

(define-public (suspend-entity (entity-id principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (not (is-eq (get status (get-entity entity-id)) u0)) (err u404))
    (ok (map-set entities entity-id
      (merge (get-entity entity-id)
        {
          status: u2,
          verification-date: block-height,
          verifier: tx-sender
        }
      )
    ))
  )
)

(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (var-set admin new-admin))
  )
)
