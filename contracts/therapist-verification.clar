;; Therapist Verification Contract
;; Validates quantum consciousness therapists

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ALREADY_VERIFIED (err u101))
(define-constant ERR_NOT_FOUND (err u102))
(define-constant ERR_INVALID_CREDENTIALS (err u103))

;; Data structures
(define-map verified-therapists
  { therapist: principal }
  {
    verified: bool,
    certification-level: uint,
    specialization: (string-ascii 50),
    verification-date: uint,
    quantum-rating: uint
  }
)

(define-map pending-verifications
  { therapist: principal }
  {
    credentials-hash: (buff 32),
    submission-date: uint,
    quantum-score: uint
  }
)

(define-data-var total-verified-therapists uint u0)

;; Public functions
(define-public (submit-verification (credentials-hash (buff 32)) (quantum-score uint))
  (let ((therapist tx-sender))
    (asserts! (is-none (map-get? pending-verifications { therapist: therapist })) ERR_ALREADY_VERIFIED)
    (asserts! (>= quantum-score u1) ERR_INVALID_CREDENTIALS)
    (asserts! (<= quantum-score u100) ERR_INVALID_CREDENTIALS)

    (map-set pending-verifications
      { therapist: therapist }
      {
        credentials-hash: credentials-hash,
        submission-date: block-height,
        quantum-score: quantum-score
      }
    )
    (ok true)
  )
)

(define-public (verify-therapist (therapist principal) (certification-level uint) (specialization (string-ascii 50)) (quantum-rating uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-some (map-get? pending-verifications { therapist: therapist })) ERR_NOT_FOUND)
    (asserts! (<= certification-level u5) ERR_INVALID_CREDENTIALS)
    (asserts! (<= quantum-rating u100) ERR_INVALID_CREDENTIALS)

    (map-set verified-therapists
      { therapist: therapist }
      {
        verified: true,
        certification-level: certification-level,
        specialization: specialization,
        verification-date: block-height,
        quantum-rating: quantum-rating
      }
    )

    (map-delete pending-verifications { therapist: therapist })
    (var-set total-verified-therapists (+ (var-get total-verified-therapists) u1))
    (ok true)
  )
)

(define-public (revoke-verification (therapist principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-some (map-get? verified-therapists { therapist: therapist })) ERR_NOT_FOUND)

    (map-delete verified-therapists { therapist: therapist })
    (var-set total-verified-therapists (- (var-get total-verified-therapists) u1))
    (ok true)
  )
)

;; Read-only functions
(define-read-only (is-verified-therapist (therapist principal))
  (match (map-get? verified-therapists { therapist: therapist })
    therapist-data (get verified therapist-data)
    false
  )
)

(define-read-only (get-therapist-info (therapist principal))
  (map-get? verified-therapists { therapist: therapist })
)

(define-read-only (get-total-verified-therapists)
  (var-get total-verified-therapists)
)

(define-read-only (get-pending-verification (therapist principal))
  (map-get? pending-verifications { therapist: therapist })
)
