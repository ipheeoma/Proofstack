;; ProofStack: Trustless Reputation Engine
;; A decentralized reputation and participation scoring framework for community governance on the Stacks blockchain
(define-constant owner tx-sender)
(define-constant error-owner-only (err u100))
(define-constant error-participant-not-found (err u101))
(define-constant error-permission-denied (err u102))
(define-constant error-already-exists (err u103))
(define-constant error-missing-profile (err u104))
(define-constant error-invalid-contribution (err u105))
(define-constant error-invalid-input (err u106))

;; Allowed contribution types
(define-data-var allowed-contributions (list 3 (string-ascii 24)) (list "initiative" "decision" "task"))

;; Data Maps
(define-map participant-stats 
    principal 
    {
        reputation-score: uint,
        proposals: uint,
        votes: uint,
        last-contribution: uint,
        completions: uint
    }
)
(define-map contribution-types
    {contribution: (string-ascii 24)}
    {reward: uint}
)

;; Initialize default activity point values
(map-set contribution-types {contribution: "initiative"} {reward: u10})
(map-set contribution-types {contribution: "decision"} {reward: u5})
(map-set contribution-types {contribution: "task"} {reward: u15})

;; Helper functions for validation
(define-private (is-valid-contribution (contribution-type (string-ascii 24)))
    (is-some (index-of (var-get allowed-contributions) contribution-type))
)

;; Public functions
(define-public (join-network)
    (begin
        (asserts! (is-none (get-participant-profile tx-sender)) error-already-exists)
        (ok (map-set participant-stats tx-sender {
            reputation-score: u0,
            proposals: u0,
            votes: u0,
            last-contribution: stacks-block-height,
            completions: u0
        }))
    )
)

(define-public (record-proposal)
    (let (
        (profile (unwrap! (get-participant-profile tx-sender) error-missing-profile))
        (reward (get reward (unwrap! (map-get? contribution-types {contribution: "initiative"}) error-invalid-contribution)))
    )
    (ok (map-set participant-stats tx-sender (merge profile {
        reputation-score: (+ (get reputation-score profile) reward),
        proposals: (+ (get proposals profile) u1),
        last-contribution: stacks-block-height
    })))
    )
)

(define-public (record-vote)
    (let (
        (profile (unwrap! (get-participant-profile tx-sender) error-missing-profile))
        (reward (get reward (unwrap! (map-get? contribution-types {contribution: "decision"}) error-invalid-contribution)))
    )
    (ok (map-set participant-stats tx-sender (merge profile {
        reputation-score: (+ (get reputation-score profile) reward),
        votes: (+ (get votes profile) u1),
        last-contribution: stacks-block-height
    })))
    )
)

(define-public (record-completion)
    (let (
        (profile (unwrap! (get-participant-profile tx-sender) error-missing-profile))
        (reward (get reward (unwrap! (map-get? contribution-types {contribution: "task"}) error-invalid-contribution)))
    )
    (ok (map-set participant-stats tx-sender (merge profile {
        reputation-score: (+ (get reputation-score profile) reward),
        completions: (+ (get completions profile) u1),
        last-contribution: stacks-block-height
    })))
    )
)

;; Admin functions
(define-public (update-contribution-reward (contribution-type (string-ascii 24)) (new-reward uint))
    (let
        (
            ;; Define upper limit for rewards to prevent excessive values
            (max-reward-value u1000)
            ;; Validate reward is within reasonable bounds
            (validated-reward (if (> new-reward max-reward-value) max-reward-value new-reward))
        )
        (begin
            ;; Check that the caller is the contract owner
            (asserts! (is-eq tx-sender owner) error-owner-only)
            ;; Validate that the contribution type is allowed
            (asserts! (is-valid-contribution contribution-type) error-invalid-contribution)
            ;; Set the new reward value for the validated contribution type using the validated reward
            (ok (map-set contribution-types {contribution: contribution-type} {reward: validated-reward}))
        )
    )
)

;; Read-only functions
(define-read-only (get-participant-profile (participant principal))
    (map-get? participant-stats participant)
)

(define-read-only (get-contribution-reward (contribution-type (string-ascii 24)))
    (map-get? contribution-types {contribution: contribution-type})
)

;; Private helper function
(define-private (calculate-decay (base uint) (period uint))
    (let (
        (attenuation (/ period u1000))
    )
    (if (> attenuation u0)
        (/ base attenuation)
        base
    ))
)

;; Merit calculation with time-based decay
(define-read-only (get-active-reputation (participant principal))
    (let (
        (profile (unwrap! (get-participant-profile participant) error-participant-not-found))
        (dormancy (- stacks-block-height (get last-contribution profile)))
    )
    (ok (calculate-decay (get reputation-score profile) dormancy))
    )
)